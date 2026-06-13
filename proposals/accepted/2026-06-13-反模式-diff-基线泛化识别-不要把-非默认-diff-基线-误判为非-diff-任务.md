---
title: "反模式：diff 基线泛化识别 — 不要把非默认 diff 基线误判为非 diff 任务"
status: accepted
created_at: 2026-06-13T06:54:33.045Z
source: mcp
source_episode: conversation:2026-06-13-diff-baseline-skill-trigger
decision_reason: "Accepted and landed: updated skill trigger routing, shared review/self-check skill specs, skill trigger evals, changelogs, and regenerated adapter skill outputs."
---

# Proposal: 反模式：diff 基线泛化识别 — 不要把非默认 diff 基线误判为非 diff 任务

## Summary

判断 diff / review / self-check 类 skill 是否触发，应先看任务对象是否是一个变更集合（changeset），而不是只看用户是否字面提到 `diff`、`staged`、`commit` 或 `PR`。

新功能从零到现在的累计新增、跨多次提交的合并差异、feature 分支 vs master、上线前累计变更、cherry-pick 范围等都属于 diff 语义。它们只是 diff 基线不是当前工作区默认基线。把“非默认 diff 基线”误判为“不是 diff 任务”，会导致跳过 `vue-change-self-check`、`pr-review`、`frontend-component-review` 等 skill 探针，退化成人工 inline review。

## Scope

- Global / domain / stack / project-specific:
  - 全局规则，适用于 review / self-check / code review 类任务的 skill 触发判断。
- Applies to:
  - 用户要求审查一次已完成改动、一组新增文件、一个新增功能、某个 feature 分支、一次上线前整体变更、跨提交累计改动或从零到现在的完整实现。
  - `router/skill-map.md` 的 skill 触发判断。
  - `vue-change-self-check`、`pr-review`、`frontend-component-review` 的触发边界说明。
- Does not apply to:
  - 纯架构通读、模块解释、既有稳定模块说明，且没有“变更窗口”或“本次改动”语义。
  - 单点 debug、一次性问答、只解释某段代码为什么这样写。
  - 用户明确要求不要按变更集审查，而是做无基线的全文理解或文档化。

## Rationale

### Context

来源任务：审查 `D:\xiangmeifu\admin-vue\src\views\goods\goodsPurchaseBan` 文件夹。

用户原话摘要：

- “审查 goodsPurchaseBan 这个文件夹，因为这个功能为新增所以要审查全部的内容。”
- “diff 是因为之前有过分批提交，实际按从零到现在进行审查。”

误判流程：

1. 看到“按从零到现在”“全部内容”等表达后，把它理解为“不按 diff skill”。
2. 跳过 Skill Probe，直接读目标文件和 API 文件，输出 inline review。
3. 在 Final Trace 中把 `vue-change-self-check` 标成 inline，而没有按真实 skill 流程执行。
4. 用户追问“这不算是 diff 吗？”后才确认：这仍是 diff 任务，只是基线是文件首次出现之前或功能开始前。

### Reusable Lesson

判断要点：任务对象是不是一个变更集合，而不是用户有没有说出 `diff` 这个词。

以下表达仍属于 diff 语义，应触发 diff / review / self-check 类 skill 探针：

| 用户表达 | diff 基线 |
|---|---|
| “审查这次新增的功能” | 文件或功能首次出现之前 |
| “从零到现在” | 功能开始前或空目录/空文件状态 |
| “上线前的整体变更” | 上线前最近稳定 commit |
| “feature 分支 vs master” | master HEAD 或 merge-base |
| “这次合入的所有改动” | 合入前 base commit |
| “这一版的全部新增” | 上一版 tag |
| “这次 cherry-pick 的范围” | cherry-pick 起点 |
| “暂存 + 未暂存 + 上一次提交合起来看” | HEAD~1 或用户指定 commit |

不属于 diff 语义的典型情况：

- “讲讲这个模块怎么工作的。”
- “为什么这里这么写？”
- “这段稳定代码有没有明显 bug？”且没有变更窗口。
- “按文档化方式通读这个目录。”且用户明确排除变更审查。

### Misclassification Signals

以下任一信号出现时，应先做 Skill Probe，而不是直接进入 inline review：

1. 时间窗口词：本次、这次、上线前、合入前、新增、改动、提交、这一版。
2. 变更范围词：所有、全部、整体、累计、从 X 到 Y、从零到现在。
3. 用户用“全部”“整体”“从零到现在”解释基线，而不是排除 diff。
4. 用户显式提到 `diff`、`staged`、`commit`、`PR`、分支对比、提交范围。

如果“全部 / 整体 / 从零到现在 / 不按默认 diff”可能有歧义，应问“是要扩大 diff 基线，还是要无基线全文通读？”不要默认理解成后者。

## Proposed Destination

- rules:
  - 不直接改 L0-L3 分级。
  - 不优先写入 adapter gate；若后续确实补 gate 示例，必须同步 Codex / Claude 两端共享 gate 段落。
- workflow:
  - 无需新增 workflow。
- domain:
  - 无需新增 domain 页面。
- stack:
  - 无需新增 stack 页面。
- skill:
  - `skills/vue-change-self-check/SKILL_SPEC.md`
  - `skills/pr-review/SKILL_SPEC.md`
  - `skills/frontend-component-review/SKILL_SPEC.md`
- router:
  - `router/skill-map.md`
- eval:
  - 建议追加或更新 skill/router 触发类用例；如果当前没有独立 skill eval 文件，可先记录在 changelog 或后续 eval proposal。

## Landing Plan

### 1. 修订 `router/skill-map.md`

目标：让 Skill Probe 能识别隐式 changeset，而不依赖用户说出默认 `git diff` 语境。

建议改动：

- 在 `pr-review` 的 `Use When` 中补充：用户要求审查新增功能、从零到现在、跨提交累计、分支差异、上线前整体变更等非默认基线 changeset 时也触发。
- 在 `vue-change-self-check` 的 `Use When` 中补充：当前端文件范围命中时，非默认基线 changeset 也属于 diff 风险扫描范围。
- 在 Notes 中补充一条通用判断：
  - “diff 类触发判断看任务对象是否为 changeset；`从零到现在`、`新增功能全量`、`feature vs base`、`上线前累计变更` 等是扩展基线，不是排除 diff。”
- 保留现有排除条件：无变更范围的解释、架构通读、单点 debug 不强行触发 diff skill。

### 2. 修订 `skills/vue-change-self-check/SKILL_SPEC.md`

目标：让前端自检 skill 明确接受扩展基线。

建议改动：

- 在 `Workflow` 第 1 步或第 2 步附近补一句：
  - “The change set may use a non-default baseline, such as from-zero, feature branch vs base, cumulative commits, or release-window changes. Treat the baseline as an input parameter instead of excluding the skill.”
- 第 2 步不应只写死 `git diff --name-only` / `git diff --stat`，应允许：
  - 用户给定目录或文件列表。
  - `git diff <base>...HEAD --name-only`
  - `git show --name-only --stat <commit>`
  - 从“新增目录全量”推导为 empty tree / feature start baseline。
- 不改变输出合同，仍使用 `references/output-contract.md`。

### 3. 修订 `skills/pr-review/SKILL_SPEC.md`

目标：通用 code review skill 明确 diff scope 可以来自非默认基线。

建议改动：

- 在 `Workflow` 第 1 步后增加说明：changed files / diff scope 可以由用户给定的范围、分支对比、提交范围、从零新增目录或上线窗口确定。
- 在 Constraints 中补充排除边界：没有变更窗口的模块解释不因“review”一词自动变成 diff review。

### 4. 修订 `skills/frontend-component-review/SKILL_SPEC.md`

目标：避免“新增组件全量审查”漏触发。

建议改动：

- 在 `Workflow` 第 1 步附近补充：当用户要求审查新增页面、组件、表单或交互的完整实现时，即使没有默认 `git diff`，也应先识别为目标组件/页面的 changeset。
- 保持该 skill 的重点是用户可见行为、交互、表单流、状态边界；不要把它扩展成所有前端 diff 的主 skill。前端 diff 风险扫描仍由 `vue-change-self-check` 主导，通用代码风险由 `pr-review` 支撑。

### 5. 生成 adapter skill 并验证

因为本 proposal 涉及 managed skill specs，落地时必须走生成与验证：

1. 修改 `skills/<skill>/SKILL_SPEC.md` 和 `router/skill-map.md`。
2. 运行 `pwsh tools/sync-skills.ps1`。
3. 运行 `pwsh tools/validate-memory-os.ps1`。
4. 不直接手写 `adapters/codex/skills/*/SKILL.md` 或 `adapters/claude/skills/*/SKILL.md`。

### 6. 更新记录

落地时需要更新：

- `logs/router-changelog.md`：记录 `router/skill-map.md` 的 diff 基线泛化触发补丁。
- `logs/skill-changelog.md`：记录三个 `SKILL_SPEC.md` 的触发边界补丁。
- `logs/memory-changelog.md`：记录 pending proposal 被接受和目标文件变更。

### 7. 晋升 pending

满足以下条件后可 accept：

- proposal 保留 `source_episode`。
- 目标文件已更新。
- sync 和 validate 通过。
- accepted 文件保留本 proposal 的溯源信息。

## Suggested Checklist

收到 review / 审查 / self-check 类任务时，自检顺序：

1. 任务对象是不是一个 changeset，包括非默认基线？
2. 用户是否用了时间窗口词或范围集合词？
3. 变更范围是否能通过用户给定路径、提交、分支、tag、目录新增历史或文件列表确定？
4. 不确定时是否问“基线是什么”，而不是问“要不要走 diff”？
5. 是否先做 Skill Probe 并读取命中的 `SKILL_SPEC.md`？
6. Final Trace 是否如实记录实际使用的 skill，而不是把 inline review 标成 skill？

## Safety and Sensitivity Check

- 不包含 token、密码、密钥、cookie、PII、生产日志原文、客户私有代码或未脱敏敏感业务数据。
- 业务模块名 `goodsPurchaseBan` 仅作为误判案例上下文出现，不包含字段、接口、规则或代码片段。
- 本机路径 `D:\xiangmeifu\admin-vue\src\views\goods\goodsPurchaseBan` 仅用于描述任务来源，不作为可复用规则依赖。

## Source Task or Evidence Summary

来源任务：商品禁购 `goodsPurchaseBan` 模块新增功能审查，发生于 2026-06-13。

证据摘要：

- 用户提交审查请求，明确说明“新增功能要审查全部内容”。
- 用户补充说明：此前分批提交导致默认 diff 不完整，实际应按“从零到现在”审查。
- AI 误判：把“从零到现在”理解为“非 diff 任务”，跳过 Skill Probe，走 inline review。
- 用户两次纠正后，确认正确理解应为：diff 类 skill 仍应触发，只是 diff 基线需要作为参数显式确定。

## Risks

- 过度泛化风险：
  - 可能把任意“审查 / 通读”都套成 diff 任务。
  - 缓解：规则必须要求存在变更窗口、changeset、时间范围、提交范围、分支范围或新增实现语义；无变更窗口的解释/通读排除。
- skill 职责混淆风险：
  - `vue-change-self-check`、`pr-review`、`frontend-component-review` 可能同时命中。
  - 缓解：`vue-change-self-check` 负责前端变更风险四段式输出，`pr-review` 提供通用 bug/regression review，`frontend-component-review` 聚焦用户可见行为和交互状态；最终输出按更具体的用户目标和现有 skill-map Notes 合并。
- Gate 变更风险：
  - 直接改 adapter gate 会触发跨适配器同步要求。
  - 缓解：本轮优先落 `router/skill-map.md` 和 `SKILL_SPEC.md`；除非后续确认必须补 gate 示例，否则不改 gate。

## Draft

建议接受后落地为：

1. `router/skill-map.md` 的 diff 类 skill 触发补丁。
2. `skills/vue-change-self-check/SKILL_SPEC.md`、`skills/pr-review/SKILL_SPEC.md`、`skills/frontend-component-review/SKILL_SPEC.md` 的非默认基线说明。
3. 同步生成 adapter skill。
4. 验证并记录 changelog。
