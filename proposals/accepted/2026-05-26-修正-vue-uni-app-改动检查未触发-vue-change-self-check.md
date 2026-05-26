---
title: "修正 Vue/uni-app 改动检查未触发 vue-change-self-check"
status: accepted
created_at: 2026-05-26T06:42:40.393Z
source: mcp
accepted_at: 2026-05-26T00:00:00+08:00
decision: 用户确认通过；晋升到 router / skill registry / eval，并同步 Codex 与 Claude adapter。
decision_reason: 降低明确的 Vue/uni-app 改动检查 skill 路由误判，改善前端 diff review 稳定性。
---

# Proposal: 修正 Vue/uni-app 改动检查未触发 vue-change-self-check

## Summary

当用户要求检查改动、未提交改动、commit 或 diff，且仓库或 diff 表明是 Vue/uni-app 前端项目时，应自动触发 vue-change-self-check，可与 pr-review 并行触发，并优先输出用户友好的编号风险清单。

## Scope

- Global / domain / stack / project-specific:
- Applies to:
- Does not apply to:

## Proposed Destination

- rules:
- workflow:
- domain:
- stack:
- skill:
- router:
- eval:

## Rationale

# 修正 Vue/uni-app 改动检查未触发 vue-change-self-check

## Context

本次在 `D:\xiangmeifu\h5-vue` 中，用户输入大意为：

> 检查我的改动，包含未提交改动和 `feat: 首页公共跳转方法增加京东锦礼 -btf` 提交中的改动。

实际改动集中在 Vue / uni-app / H5 前端项目中，包含 `.vue` 页面、订单页面、公共跳转方法、API 字段契约和页面入口联动风险。按预期，应触发 `vue-change-self-check`，因为该 skill 的核心价值是对 Vue / uni-app 前端 diff 做提交前或变更后风险扫描，并输出稳定编号风险。

实际结果：

- Codex 只触发了 `pr-review`。
- Claude 未明显触发相关 skill。
- 只有用户显式点名 `$vue-change-self-check` 后，才按正确 workflow 执行。

这说明当前路由对“泛化改动检查 + 前端仓库/diff 信号”的识别不足。

## Misclassification Example

输入类型：

- “检查我的改动”
- “检查未提交改动和某个 commit”
- “让 OS 检查我的改动”
- “看一下这个 H5/Vue 项目的改动有没有问题”

上下文信号：

- 当前仓库名或路径包含 `h5-vue`、`admin-vue`、Vue、uni-app、H5 前端项目特征。
- `git diff --name-only` 或 commit diff 命中 `.vue`、`src/pages.json`、`manifest.json`、页面目录、前端路由/导航配置、uni-app 分包页面等。

当前行为：

- 宽泛命中 `pr-review`。
- 没有基于仓库或 diff 事实补触发 `vue-change-self-check`。

期望行为：

- `pr-review` 可以继续触发，用于通用代码审查。
- 但一旦 repo 或 diff 表明这是 Vue / uni-app 前端改动，应同时触发 `vue-change-self-check`。
- 如果两者同时触发，输出应优先采用 `vue-change-self-check` 的用户友好格式：变更影响扫描、稳定编号风险、建议验证路径、本次未覆盖盲区。

## Reusable Lesson

不要只根据用户是否显式说出 “Vue / 前端 / uni-app / 自检” 来触发 `vue-change-self-check`。

对于“检查改动 / diff / 未提交改动 / commit review / staged review”这类请求，应先识别项目和变更事实。如果项目或 diff 已经明确是 Vue / uni-app 前端改动，那么 `vue-change-self-check` 是关键 skill，不应被更泛化的 `pr-review` 吞掉。

## Proposed Memory OS Change

### 1. 更新 `router/skill-map.md`

建议把 `vue-change-self-check` 的 Use When 扩展为：

- Vue / uni-app / frontend 改动需要提交前自检、diff 风险扫描、编号风险清单。
- 用户要求检查当前改动、未提交改动、staged changes、commit、diff、提交前检查，且仓库或 diff 命中 Vue / uni-app / H5 前端信号时，也应触发。
- 可与 `pr-review` 同时触发；若目标是“检查改动风险”，前端项目中优先采用 `vue-change-self-check` 的编号风险输出。

### 2. 增强 `vue-change-self-check` 的 adapter 描述

Codex 当前描述偏窄，建议增强为类似：

> Use for Vue, uni-app, or frontend pre-commit/post-change self-checks. Also use when the user asks to inspect current changes, unstaged/staged changes, a commit, or a diff and the current repo or diff indicates Vue/uni-app/frontend files such as `.vue`, `pages.json`, `manifest.json`, frontend route/page/navigation config, or uni-app subpackage pages. Scan diff first, output stable numbered risks, and wait for user choice before fixing.

Claude adapter 也应保持同等语义，避免 Codex / Claude 漂移。

### 3. 增加 eval 用例

建议加入以下测试用例：

| Input | Context | Expected Skill | Reason |
|---|---|---|---|
| 检查我的改动，包含未提交改动和某个提交 | 当前仓库为 `h5-vue` | `pr-review + vue-change-self-check` | 泛化改动检查 + 前端仓库信号 |
| 检查当前 diff 有没有问题 | diff 命中 `.vue` / `src/pages.json` | `pr-review + vue-change-self-check` | diff 事实表明是 Vue / uni-app 风险扫描 |
| 看一下这个 H5 改动有没有回归风险 | 当前仓库为 uni-app 项目 | `vue-change-self-check` | 明确 H5 / 前端回归风险 |
| 检查当前 diff 有没有问题 | diff 只命中后端服务代码 | `pr-review` | 非前端改动不应误触发 Vue skill |
| 处理 #2 | 上一轮输出来自 `vue-change-self-check` | `vue-change-self-check` | 稳定编号风险的延续处理 |

## Additional Routing Optimizations

### A. 两阶段触发：先粗判，再用 diff 事实补判

对“检查改动”这类请求，不应只在读 diff 前做一次 skill 选择。建议采用两阶段：

1. 粗判：命中 `pr-review`，读取 `git diff --name-only`、`git diff --stat`、commit 文件列表。
2. 补判：如果文件列表显示 Vue / uni-app 前端信号，则补触发 `vue-change-self-check`。

这样不要求用户必须说出 skill 名，也不要求模型提前猜到文件类型。

### B. 明确并行关系，避免互相吞掉

`pr-review` 是通用审查入口，`vue-change-self-check` 是前端 diff 自检入口。二者不是互斥关系。

建议规则：

- 泛化 review + 前端 diff：两者并行。
- 只审单个前端组件交互：优先 `frontend-component-review`。
- 提交前或变更后扫描整个 Vue / uni-app diff：优先 `vue-change-self-check`。

### C. 输出格式面向用户审查

用户是来审查改动风险的，不是来读路由内部术语的。`vue-change-self-check` 触发后，输出应保持中文、稳定编号、可选择处理：

1. 变更影响扫描
2. 风险清单（`#1`、`#2`、`#3`）
3. 建议验证路径
4. 本次未覆盖盲区

每个风险尽量包含：严重程度、置信度、文件位置、为什么会影响用户、建议处理方式。这样用户可以直接说“处理 #1 #3”。

### D. Codex / Claude adapter 需要一致

目前 Claude 的 `vue-change-self-check` 描述比 Codex 更强，但实际仍可能因泛化 review 被绕过。建议以 shared spec / registry 为中心同步两端描述，避免一个模型能触发、另一个模型不触发。

### E. 本地 overlay 只在 skill 触发后读取

`vue-change-self-check.local.md` 仍应保持私有 overlay，只在该 skill 已触发后读取。不要为了判定是否触发而读取私有 overlay，避免扩大读取范围。

## Safety And Sensitivity Check

- 本 proposal 不包含 token、账号、密钥、客户日志或生产隐私数据。
- 只记录抽象路由问题和泛化后的项目类型信号。
- 不直接修改正式 router、skill、eval 或 adapter 文件。
- 后续正式修改应通过维护/晋升流程进行，并保留 changelog。

## Source Task Or Evidence Summary

- 用户在 `h5-vue` 项目中要求检查未提交改动和指定 commit。
- 实际 diff 包含 `.vue` 页面、uni-app 页面配置相关路径、公共跳转方法和订单详情联动。
- `pr-review` 被触发，但 `vue-change-self-check` 未自动触发。
- 用户显式点名 `$vue-change-self-check` 后，正确 workflow 才执行。
- 该问题在 Codex 和 Claude 路由中都可能复现，属于共享路由/skill 触发规则需要修正的问题。

## Risks

- 是否过度泛化：
- 是否包含敏感信息：
- 是否与现有规则冲突：

## Draft

TODO


## MCP Update 2026-05-26T06:52:50.652Z

## 晋升前补充建议

以下内容用于把本 proposal 从“问题记录”补强为“可执行晋升单”。后续如果进入维护或晋升流程，建议优先按本节落地。

### 1. 补全 Scope 和 Proposed Destination

当前模板中的 `Scope`、`Proposed Destination`、`Risks`、`Draft` 仍有空项。建议晋升前明确为：

Scope：

- Global / domain / stack / project-specific：适用于全局 skill routing，但触发条件只覆盖 frontend / Vue / uni-app / H5 项目或 diff 信号。
- Applies to：用户要求检查当前改动、未提交改动、staged changes、commit、diff、提交前检查、变更后风险扫描，且仓库或 diff 命中 Vue / uni-app / frontend 文件或配置。
- Does not apply to：纯后端 diff、纯解释任务、没有变更范围的泛泛讨论、用户要求直接实现或修 bug 而不是做自检的任务。

Proposed Destination：

- router：`router/skill-map.md`，补充 `vue-change-self-check` 与 `pr-review` 的并行触发边界。
- skill：`skills/vue-change-self-check/SKILL_SPEC.md` 或 `skills/registry.json` 中对应 adapter description，并同步 `adapters/codex/skills/vue-change-self-check/SKILL.md`、`adapters/claude/skills/vue-change-self-check/SKILL.md`。
- eval：`evals/skill-trigger-test-cases.md`，加入正例和负例。
- workflow：必要时在 review/self-check 相关 workflow 中补充“两阶段触发”。
- domain：如已有 frontend domain 入口，可补充前端 diff review 优先使用 `vue-change-self-check` 的提示。

### 2. 明确“两阶段触发”的读取边界

为避免 skill 选择只能依赖用户显式说出 “Vue / 前端 / uni-app”，建议对“检查改动 / diff / commit / staged”类请求允许轻量预读变更范围：

1. 先根据用户意图粗判为 review / self-check 类 L1 任务。
2. 允许读取轻量文件列表和统计，例如 `git diff --name-only`、`git diff --stat`、`git show --name-only --stat <commit>`、`git status --short`。
3. 如果文件列表命中 `.vue`、`src/pages.json`、`manifest.json`、uni-app 分包页面、前端路由/导航/页面配置、`src/pages/**`、`src/pagesOrder/**`、`src/pageAttraction/**`、`src/pagesTool/**`、`src/pagesExpand/**`、`src/secondaryPage/**` 等信号，则补触发 `vue-change-self-check`。
4. 这一步只读取变更范围，不打开大量源码，不读取私有 overlay；私有 overlay 仍只在 skill 确认触发后读取。

这条边界可以解决本次根因：模型在读 diff 前无法知道这是 Vue / uni-app 改动，但又不应该要求用户每次显式说出 skill 名。

### 3. 明确并行触发后的输出优先级

当 `pr-review` 与 `vue-change-self-check` 同时命中时，建议输出优先级固定为：

1. 使用 `vue-change-self-check` 的四段式结构：变更影响扫描、风险清单、建议验证路径、本次未覆盖盲区。
2. `pr-review` 发现的问题并入稳定编号风险清单，例如 `#1`、`#2`、`#3`。
3. 不再额外输出一套 `Findings / Open questions / Test gaps / Summary`，避免用户看到两套审查格式。
4. 每个风险尽量包含严重程度、置信度、文件位置、用户影响、建议处理方式。
5. 如果用户后续说“处理 #2”或“修复 #1 #3”，沿用原编号。

这样可以保持用户审查体验稳定：用户看到的是一份可选择处理的风险清单，而不是 skill 内部路由细节。

### 4. 增加不要误触发的负例

除了已有“后端 diff 不触发 Vue skill”的负例，建议再加入以下 eval：

| Input | Context | Expected Skill | Reason |
|---|---|---|---|
| 解释一下这个 Vue 组件为什么这么写 | 只解释代码，没有要求检查改动 | none 或 frontend-component-review（视具体请求） | 解释任务不等于 diff self-check |
| 直接修复这个 Vue bug | 用户要求实现修复，不是先做自检 | bugfix-with-regression-test 或 implement workflow | 不应把实现任务误路由为只扫描不修 |
| 帮我审一下这个按钮交互 | 单个前端组件/交互审查 | frontend-component-review | 组件交互审查不同于整个 diff 自检 |
| 检查当前 diff 有没有问题 | diff 只命中后端服务、脚本或文档 | pr-review 或对应 domain skill | 非前端 diff 不应误触发 Vue skill |

这些负例用于防止修正规则过度扩大，避免 `vue-change-self-check` 变成所有 review 的默认入口。

### 5. 同时提供中文审查说明和英文 frontmatter 候选描述

为了方便用户审查，proposal 中应保留中文解释；为了方便 adapter `description` 落地，也应给出英文候选描述。

中文解释：

当用户要求检查改动、未提交改动、commit、staged changes 或 diff，且当前仓库或轻量 diff 文件列表显示这是 Vue / uni-app / H5 前端改动时，应触发 `vue-change-self-check`。该 skill 可以与 `pr-review` 并行，但最终输出优先使用稳定编号风险清单，方便用户选择处理某个风险编号。

英文候选 description：

> Use for Vue, uni-app, or frontend pre-commit/post-change self-checks. Also use when the user asks to inspect current changes, unstaged or staged changes, a commit, or a diff, and the current repo or lightweight diff file list indicates Vue/uni-app/frontend files such as `.vue`, `pages.json`, `manifest.json`, frontend route/page/navigation config, or uni-app subpackage pages. Can run alongside general PR review, but prefer stable numbered risk output and wait for the user to choose what to fix.

### 6. 建议验收标准

晋升后应满足：

- 在 `h5-vue` 中输入“检查我的改动，包含未提交改动和某个 commit”时，触发 `vue-change-self-check`，可同时触发 `pr-review`。
- 输出使用中文四段式结构，并包含稳定编号风险。
- 用户没有显式说 Vue / 前端 / uni-app，但 diff 命中 `.vue` 或 `src/pages.json` 时，也能触发。
- 纯后端 diff 或纯解释任务不会误触发。
- Codex 与 Claude adapter 行为保持一致。

### 7. 风险补全

- 是否过度泛化：如果只根据“检查 diff”就触发 Vue skill，会误伤后端项目；必须同时要求 repo 或 diff 前端信号。
- 是否包含敏感信息：proposal 只记录抽象路由规则和泛化文件类型，不记录业务秘密、账号、token、客户日志或生产隐私。
- 是否与现有规则冲突：不替代 `pr-review`，而是定义并行关系和输出优先级；不替代 `frontend-component-review`，单组件交互审查仍走组件 review。
- 是否增加读取成本：允许的预读应限制在文件列表和 diff stat，不默认打开大量源码或读取私有 overlay。

## Acceptance Decision

- Decision: accepted
- Reason: 该 proposal 能降低明确的 skill 路由误判，改善 Vue / uni-app 前端 diff review 的稳定性，并防止泛化 `pr-review` 吞掉关键的 `vue-change-self-check`。
- Applied changes: 更新 `router/skill-map.md`、`skills/registry.json`、`evals/skill-trigger-test-cases.md`，运行 `tools/sync-skills.ps1 -Skill vue-change-self-check` 同步 Codex / Claude adapter。
- Safety: 未写入敏感信息；触发条件要求 repo 或轻量 diff 命中前端信号，避免所有 review 都误触发 Vue self-check。
