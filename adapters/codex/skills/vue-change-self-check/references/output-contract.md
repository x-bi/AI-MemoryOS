# Vue Change Self Check Output Contract

Always respond in this order:

1. `变更影响扫描`
2. `风险清单`
3. `建议验证路径`
4. `本次未覆盖盲区`

Each risk item must use a stable number and this shape:

```md
[#1] 风险标题
级别：高
置信度：中
分类：确定问题
类型：页面状态
位置：[xx.vue:142](src/pages/xx/xx.vue#L142)
状态：可修复
证据：...
原因：...
建议动作：直接修复
影响面：...
复现步骤：
- 1. 操作 → 预期 / 实际
- 2. ...
修复方向：
- 方案 A：在 [useUserStore.ts:90](src/stores/useUserStore.ts#L90) 切换前缓存 token，切换后重写
```

## 路径基准

默认基准 = 当前会话上下文中明确的工作区根。当工作区根与 `git diff` 的相对路径基准不一致（含 monorepo 子包、IDE 打开在 `src/` 等子目录、或仓库根之上打开 IDE），**强制**在 `变更影响扫描` 段顶部声明 `路径基准：<base>`，并保证所有 markdown 链接的相对路径都基于该 `<base>`。无声明时输出方默认按"工作区根 = 仓库根"判定，并对此承担漂移责任。

## Position

`位置` 必须使用 markdown 链接，主链接形如 `[file:line](relative/path#Lline)` 或 `[file:line-line](relative/path#Lline-Lline)`。多个位置（含同文件多段、跨文件多位置）一律用 `、` 分隔，单条最多 4 个链接，超出部分聚合到 `证据` 字段说明。

禁止只写裸路径或反引号路径。

约定的几种特殊形态：

- **同文件多段**：用 `、` 分隔多个链接（≤ 4），超出聚合到 `证据`。
  示例：`位置：[mine.vue:142](src/pages/mine/mine.vue#L142)、[mine.vue:156-160](src/pages/mine/mine.vue#L156-L160)`
- **整段配置 / 无具体行号**：跳到段落起始行号，并在证据中说明覆盖范围。**禁止**用 `#锚点` 形式（VSCode 对非 markdown 文件的 `#anchor` 不做属性锚点解析，无法点击）。
  示例：`位置：[pages.json:17](src/pages.json#L17)（subPackages 段，覆盖 17-46 行，详见证据）`
- **缺失项 / 应当存在但不存在**：主链接指向应改的文件，不要伪造行号，可直接用文件级链接。
  示例：`位置：（缺失）应在 [pages.json](src/pages.json) 添加 subPackage 注册`
- **跨文件多位置**：用 `、` 分隔，同样 ≤ 4 个。
  示例：`位置：[mine.vue:142](src/pages/mine/mine.vue#L142)、[useUserStore.ts:88-95](src/stores/useUserStore.ts#L88-L95)`

反例（禁止形态）：

- ❌ `位置：src/pages/mine/mine.vue 第 142 行`
- ❌ `` 位置：`src/pages/mine/mine.vue:142` ``
- ❌ `位置：mine.vue#L142`（无可点击链接）
- ❌ `位置：[pages.json#subPackages](src/pages.json)`（非 markdown 文件锚点不可跳）
- ✅ `位置：[mine.vue:142](src/pages/mine/mine.vue#L142)`

## Severity

- `阻塞`: likely to break entry, request success, page render, route access, login flow, payment, or a critical business path.
- `高`: likely visible regression, but not guaranteed hard failure.
- `中`: plausible issue, missing guard, or behavior that should be verified.

## Confidence

- `高`: direct code evidence shows a mismatch or defect.
- `中`: strong signal, but confirmation depends on nearby code, runtime data, or backend contract.
- `低`: suspicious pattern with limited evidence.

## Category

- `确定问题`: direct evidence shows a defect or inconsistent binding.
- `待确认风险`: confirmation depends on runtime data, backend contract, or business expectation.

## Type

`类型` 固化两组枚举集合，避免触发条件漂移：

- **行为类**（`复现步骤` 必填）：`页面状态` / `路由` / `导航` / `交互流程` / `登录态` / `渲染异常`
- **契约类**（`复现步骤` 填「不适用」）：`接口字段` / `配置项` / `构建入口` / `权限/菜单` / `静态资源`

归类边界（避免双重计数 / 静默吞掉）：

- `渲染异常` vs `页面状态`：按主导致原因归类——由数据/状态分支错误导致的渲染问题归 `页面状态`；由模板/样式/平台条件编译/资源加载导致的归 `渲染异常`。同一风险只归一类，不双重计数。
- `静态资源`：即使表现为渲染问题也归契约类，理由是无运行时复现路径（资源文件本身需通过构建/CDN 侧验证）。
- 不在两组内的新型类，回退到**主链路最相关的那一组**，由模型在「本次未覆盖盲区」段说明回退依据；若主链路无法判定，**行为类优先**（宁可多写一行 `复现步骤：不适用` 也不漏复现路径）。

## Action

- `直接修复`
- `先确认接口/业务规则`
- `只需回归验证`

## Field Triggers

`复现步骤` 与 `修复方向` 是字段触发耦合项，按 `类型` / `建议动作` 触发，避免无脑全填：

- **复现步骤**：
  - `类型` ∈ 行为类 → 必填，每条 ≤ 3 步，写「操作 → 预期 / 实际」。
  - `类型` ∈ 契约类 → 单行 `复现步骤：不适用，需接口 / 配置 / 构建侧验证`，不换行。
- **修复方向**（与 `建议动作` 取值耦合，**字段始终存在，不允许缺失**）：
  - `直接修复`：**必填**，给方案 A（必要时方案 B），只指明改哪一行 / 改哪个变量 / 走哪个分支，不出完整代码。
  - `先确认接口/业务规则`：
    - 不给候选倾向时，**强制**写为 `修复方向：暂不给出，待确认 X 后再定向`，其中 `X` 必须是具体待确认对象（接口字段名 / 业务规则名 / 后端联系人），禁止空泛词如 "待确认"、"待评估"。
    - 给候选倾向时，必须使用候选语气，禁止出现 `方案 A：` / `方案 B：` 等确定方案前缀，例：`修复方向：候选倾向 — 待确认 X 后，倾向在 [file:line](path#Lline) 切换分支`。候选倾向多条时按「Multi-line Fields」多行展开，使用 `- 候选倾向 A：…` / `- 候选倾向 B：…`，**仍禁用** `- 方案 A：` / `- 方案 B：` 前缀。
  - `只需回归验证`：**强制**写为 `修复方向：不适用，仅做回归验证`，不留空、不省略。

仍遵守 skill 边界：triage 阶段不自动改代码，等用户说 `处理 #N` 才动手。

## Multi-line Fields

`复现步骤` 与 `修复方向` 是 contract 中首次引入的多行字段，必须明确其格式以避免不同模型/adapter 的换行漂移：

- **单行形态**：当字段是「不适用」「暂不给出」「不留空占位」等单行语义时，保持 `key：<内容>` 单行，不换行、不缩进。
- **多行展开**：`key：` 后立即换行，下一行起每条用 markdown 无序列表项形态：
  - `复现步骤` 下：`- 1. …` / `- 2. …`
  - `修复方向` 下：`- 方案 A：…` / `- 方案 B：…`（候选倾向场景见「Field Triggers」）
  - `修复方向` 一旦给出方案/候选倾向（即不属于「不适用」「暂不给出」单行场景），即使只有一条方案，也必须 `修复方向：` 后换行、用 `- 方案 A：…` 列表项形态，禁止合并为单行 `修复方向：方案 A：…`。
- **终止条件（闭集，三选一即终止）**：
  1. 出现下一个 `[#N]` 标题；
  2. 出现下一行 **零缩进、行首即键名、紧接全角冒号 `：`** 的形态，键名严格属于 12 键闭集 `级别|置信度|分类|类型|位置|状态|证据|原因|建议动作|影响面|复现步骤|修复方向`；行内出现关键词（如列表项 `- 证据：…` 或方案文本里出现"证据""原因"）**不**视为终止；
  3. 出现空行。`复现步骤` / `修复方向` 列表项之间**不允许**出现空行；任何空行严格视为字段结束，下一非空行必须是 12 键之一或下一 `[#N]` 标题。
- **嵌套链接**：列表项内允许内嵌 markdown 链接，遵循「Position」段的位置链接规则。

## Numbering Rules

Number findings by practical impact:

1. Broken entry, registration, or navigation.
2. Broken API, auth, request, or payment flow.
3. Broken page state or shared component contract.
4. Likely regression or missing validation.
5. Lower-confidence observations.
