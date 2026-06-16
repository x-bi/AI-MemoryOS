---
title: "vue-change-self-check 输出模板增加可跳转位置与复现/修复字段"
status: accepted
created_at: 2026-06-13T08:42:27.641Z
updated_at: 2026-06-16T00:00:00.000Z
accepted_at: 2026-06-16
source: mcp
source_episode: "conversation:2026-06-16"
scope: skill
decision_reason: "用户在 2026-06-16 会话中明确确认落地（保留中文规则文本，pending 转 accepted）。源文件 skills/vue-change-self-check/SKILL_SPEC.md 与 references/output-contract.md 已按提案 §1-§6 完成编辑，tools/sync-skills.ps1 与 tools/validate-memory-os.ps1 均通过，三方 hash byte-equal。"
---

# Proposal: vue-change-self-check 输出模板增加可跳转位置与复现/修复字段

## Summary

`vue-change-self-check` 当前 output-contract 中 `位置` 是纯文本路径，无法在 IDE 中点击跳转；模板缺少「复现步骤」与「修复方向」字段，与用户实际工作流（按编号逐项复现并手动修改 / 反向指示改法）不匹配。本提案在 **唯一事实源** `skills/vue-change-self-check/` 下落地这三处变更，再由 `tools/sync-skills.ps1` 同步两个 adapter 的 references。

## Scope

- Global / domain / stack / project-specific: skill-level（仅 vue-change-self-check）
- Applies to: 所有 Vue / uni-app / 前端 diff 自检任务
- Does not apply to: 其他 skill / router / registry / eval

## Proposed Destination

- rules: 无
- workflow: 无
- domain: 无
- stack: 无
- skill: `vue-change-self-check`（SKILL_SPEC.md + references/output-contract.md）
- router: 无
- eval: 可选——后续可补「输出位置字段含 markdown 跳转链接率」「复现步骤/修复方向触发率与触发条件一致率」两个指标

## Rationale

# vue-change-self-check 输出模板补丁提案

## 背景

`vue-change-self-check` skill 当前输出契约存在两个执行漂移：

1. **位置字段不可跳转**：`references/output-contract.md` 第 18 行规定 `位置：path/to/file`，落地为纯文本路径，IDE 中需要手动定位。
2. **缺复现/修复字段**：模板只有 `建议动作` 一项，且取值锁死为 `直接修复` / `先确认接口/业务规则` / `只需回归验证`，无法承载具体复现路径或修复草稿。用户实际工作流为「对着每个 # 编号逐项复现 → 手动改或反向告诉模型怎么改」，当前模板不能直接服务这一回路。

## 单一事实源与变更范围

唯一事实源：

- `skills/vue-change-self-check/SKILL_SPEC.md`
- `skills/vue-change-self-check/references/output-contract.md`

`adapters/claude/skills/vue-change-self-check/**` 与 `adapters/codex/skills/vue-change-self-check/**` 均为 `tools/sync-skills.ps1` 的生成副本，**禁止直接编辑**。本提案仅改源文件 + 跑同步脚本。

## 模板调整细节

### 1. 位置字段强制为可跳转 markdown 链接

把：

```
位置：path/to/file
```

改为：

> `位置`：必须使用 markdown 链接，主链接形如 `[file:line](relative/path#Lline)` 或 `[file:line-line](relative/path#Lline-Lline)`。多个位置（含同文件多段、跨文件多位置）一律用 `、` 分隔，单条最多 4 个链接，超出部分聚合到 `证据` 字段说明。
>
> **路径基准（强制）**：默认基准 = 当前会话上下文中明确的工作区根。当工作区根与 `git diff` 的相对路径基准不一致（含 monorepo 子包、IDE 打开在 `src/` 等子目录、或仓库根之上打开 IDE），**强制**在 `变更影响扫描` 段顶部声明 `路径基准：<base>`，并保证所有 markdown 链接的相对路径都基于该 `<base>`。无声明时输出方默认按"工作区根 = 仓库根"判定，并对此承担漂移责任。
>
> 禁止只写裸路径或反引号路径。

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

### 2. 新增 `类型` 枚举（固化触发集合，避免漂移）

`类型` 在原契约中只示例 `页面状态` 一值，未给枚举集，导致 §3 触发规则不可机械判定。新增 `## Type` 段，固化两组：

- **行为类**（`复现步骤` 必填）：`页面状态` / `路由` / `导航` / `交互流程` / `登录态` / `渲染异常`
- **契约类**（`复现步骤` 填「不适用」）：`接口字段` / `配置项` / `构建入口` / `权限/菜单` / `静态资源`

**归类边界（避免双重计数 / 静默吞掉）**：

- `渲染异常` vs `页面状态`：按主导致原因归类——由数据/状态分支错误导致的渲染问题归 `页面状态`；由模板/样式/平台条件编译/资源加载导致的归 `渲染异常`。同一风险只归一类，不双重计数。
- `静态资源`：即使表现为渲染问题也归契约类，理由是无运行时复现路径（资源文件本身需通过构建/CDN 侧验证）。
- 不在两组内的新型类，回退到**主链路最相关的那一组**，由模型在「本次未覆盖盲区」段说明回退依据；若主链路无法判定，**行为类优先**（宁可多写一行 `复现步骤：不适用` 也不漏复现路径）。

### 3. 新增 `复现步骤`、`修复方向` 两个字段

字段位置紧跟原 `建议动作` / `影响面` 之后，整体形状：

```
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
- 方案 B：让 switchRole() 不再调 clearAll()，仅清业务态
```

### 4. 字段填写规则（按 `类型` / `建议动作` 触发，避免无脑全填）

- **复现步骤**：
  - `类型` ∈ 行为类（§2）→ 必填，每条 ≤ 3 步，写「操作 → 预期 / 实际」。
  - `类型` ∈ 契约类（§2）→ 单行 `复现步骤：不适用，需接口 / 配置 / 构建侧验证`，不换行。
- **修复方向**（与 `建议动作` 取值耦合，**字段始终存在，不允许缺失**）：
  - `直接修复`：**必填**，给方案 A（必要时方案 B），只指明改哪一行 / 改哪个变量 / 走哪个分支，不出完整代码。
  - `先确认接口/业务规则`：
    - 不给候选倾向时，**强制**写为 `修复方向：暂不给出，待确认 X 后再定向`，其中 `X` 必须是具体待确认对象（接口字段名 / 业务规则名 / 后端联系人），禁止空泛词如 "待确认"、"待评估"。
    - 给候选倾向时，必须使用候选语气，禁止出现 `方案 A：` / `方案 B：` 等确定方案前缀，例：`修复方向：候选倾向 — 待确认 X 后，倾向在 [file:line](path#Lline) 切换分支`。候选倾向多条时按 §5 多行展开，使用 `- 候选倾向 A：…` / `- 候选倾向 B：…`，**仍禁用** `- 方案 A：` / `- 方案 B：` 前缀。
  - `只需回归验证`：**强制**写为 `修复方向：不适用，仅做回归验证`，不留空、不省略。
- 仍遵守 skill 边界：triage 阶段不自动改代码，等用户说 `处理 #N` 才动手。

### 5. 多行字段格式约定（新增段落）

`复现步骤` 与 `修复方向` 是 contract 中首次引入的多行字段，必须明确其格式以避免不同模型/adapter 的换行漂移：

- **单行形态**：当字段是「不适用」「暂不给出」「不留空占位」等单行语义时，保持 `key：<内容>` 单行，不换行、不缩进。
- **多行展开**：`key：` 后立即换行，下一行起每条用 markdown 无序列表项形态：
  - `复现步骤` 下：`- 1. …` / `- 2. …`
  - `修复方向` 下：`- 方案 A：…` / `- 方案 B：…`（候选倾向场景见 §4）
  - `修复方向` 一旦给出方案/候选倾向（即不属于「不适用」「暂不给出」单行场景），即使只有一条方案，也必须 `修复方向：` 后换行、用 `- 方案 A：…` 列表项形态，禁止合并为单行 `修复方向：方案 A：…`。
- **终止条件（闭集，三选一即终止）**：
  1. 出现下一个 `[#N]` 标题；
  2. 出现下一行 **零缩进、行首即键名、紧接全角冒号 `：`** 的形态，键名严格属于 12 键闭集 `级别|置信度|分类|类型|位置|状态|证据|原因|建议动作|影响面|复现步骤|修复方向`；行内出现关键词（如列表项 `- 证据：…` 或方案文本里出现"证据""原因"）**不**视为终止；
  3. 出现空行。`复现步骤` / `修复方向` 列表项之间**不允许**出现空行；任何空行严格视为字段结束，下一非空行必须是 12 键之一或下一 `[#N]` 标题。
- **嵌套链接**：列表项内允许内嵌 markdown 链接，遵循 §1 的位置链接规则。

### 6. 编号交互边界（与 `处理 #N` 配套，落地到 SKILL_SPEC.md）

本节属于 **skill 行为边界**，不是输出字段形状，因此落地到 `SKILL_SPEC.md` 的 `## Purpose And Boundary`，**不写入** `references/output-contract.md`，避免 contract 反向规定 skill 边界、破坏「字段形状委托给 contract」的单一事实源原则。

`处理 #N` 时：

- `建议动作=直接修复` 且 `修复方向` 已给方案 A → 可直接落地方案 A，落地完成后才再问是否需要方案 B。
- `建议动作=先确认接口/业务规则` → 仍需先确认契约或业务规则，不直接落地任何候选方向；同时**主动产出最小待确认问题清单**（每项点名待确认对象：哪个接口字段 / 哪条业务规则 / 向谁确认），不能仅回一句"还要确认"。
- `建议动作=只需回归验证` → 仅给回归验证清单，不写代码。

## 不变的部分

- `级别` / `置信度` / `分类` / `状态` / `建议动作` 取值集合保持不变。
- 编号规则不变。
- skill 的 Memory OS 边界、私有 overlay 规则不变。
- 不影响其他 skill、router、registry。

## 落地步骤（待用户批准提案后执行）

1. 编辑 `skills/vue-change-self-check/SKILL_SPEC.md`：
   - 在 `## Output` 段第 44 行 `Read it before producing the risk list — do not improvise the field shape from this file alone.` 之后另起一句：`Notable contract points include the 位置 link format, 类型 enumeration, 复现步骤 / 修复方向 fields, and multi-line termination rules.`，**不引入**具体格式细则；不在此处提及 `处理 #N` 边界（属 skill 行为边界，落地到 `## Purpose And Boundary`）。
   - 在 `## Purpose And Boundary` 末尾追加 §6 全文（编号交互边界），含三种 `建议动作` 取值的不同落地行为与「先确认接口/业务规则」的最小待确认问题清单要求。
2. 编辑 `skills/vue-change-self-check/references/output-contract.md`，按 §1-§5 落地（这是唯一需要直接编辑的 contract 文件；§6 不写入 contract）。
3. 运行 `tools/sync-skills.ps1`，由脚本生成两个 adapter 的副本（claude / codex），不要手改 adapter 副本。
4. 运行 `tools/validate-memory-os.ps1`。
5. 校对 adapter 副本是否与源 byte-equal：若 `tools/validate-memory-os.ps1` 不覆盖该校验，则用 `Get-FileHash` 对 `skills/vue-change-self-check/SKILL_SPEC.md` 与两份 adapter 副本，以及 `references/**` 各文件分别比对哈希；任意不一致即说明 sync 漂移，须重跑 sync。
6. 不执行任何 git 操作。

## 待用户确认

- 字段触发偏好：已收敛为按 §4 规则触发（`复现步骤` 仅行为类必填；`修复方向` 字段始终存在，按 `建议动作` 取值耦合给方案 / 候选倾向 / 占位）。原 (a) 默认全开方案不再保留。
- `类型` 枚举两组（行为类 / 契约类）已明确，并已固化归类边界（`渲染异常` vs `页面状态`、`静态资源` 强制归契约类、未覆盖类型回退行为类优先），避免触发条件无闭集导致漂移。
- `路径基准` 默认 = 当前会话工作区根；与 git 仓库根不一致时强制声明 `路径基准：<base>`。

## Risks

- 是否过度泛化：低。仅改 vue-change-self-check 一条 skill 的 source，不影响其他 skill / router / registry。
- 是否包含敏感信息：无。
- 是否与现有规则冲突：无。SKILL_SPEC.md `## Output` 段保持「字段形状委托给 output-contract」的单一事实源原则；新增多行字段在 contract 中显式定义终止/缩进规则与 12 键闭集，避免跨模型漂移。
- 触发漂移：低-中。§2 已固化两组枚举与归类边界（`渲染异常` vs `页面状态` 按主导致原因归类、`静态资源` 强制归契约类、未覆盖类型回退行为类优先），落地后此风险归零；剩余风险来自具体业务里新型类的出现频率，依赖用户后续反馈滚动修订枚举。

## Draft

按 §1-§5 落地到 `references/output-contract.md`、§6 落地到 `SKILL_SPEC.md` 的 `## Purpose And Boundary`，并按「落地步骤」中的位置标注实现。修订版补丁未直接写入 spec / contract，等用户批准后再走 sync 流程。
