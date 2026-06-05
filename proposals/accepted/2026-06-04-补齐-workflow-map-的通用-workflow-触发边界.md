---
title: "补齐 workflow-map 的通用 workflow 触发边界"
status: accepted
created_at: 2026-06-04T10:36:22.831Z
source: mcp
decision_reason: "补齐 workflow-map 中缺失的通用 workflow 触发边界条目"
source_episode: "workflow-map 缺少前端原型驱动 workflow 等条目的触发边界定义"
---

# Proposal: 补齐 workflow-map 的通用 workflow 触发边界

## Summary

为现有 Memory OS workflows 补齐 router/workflow-map.md 中的稳定触发边界，避免只有前端原型 workflow 有上层路由入口，同时防止泛化 workflow 误触发。

## Scope

- Global / domain / stack / project-specific: global workflow routing map.
- Applies to: Memory OS 已存在且具备稳定触发信号的 workflow。
- Does not apply to: 过于泛化、只是默认工程工作方法、没有明确触发边界的 workflow；这些不应强行进入 `workflow-map.md`。

## Proposed Destination

- rules: none
- workflow: none
- domain: none
- stack: none
- skill: none
- router: `router/workflow-map.md`
- eval: optional follow-up route examples for workflow trigger boundaries

## Rationale

在落地 `router/workflow-map.md` 后，当前正式 map 只包含 `workflows/frontend-prototype-driven-development.md` 一条触发规则。Memory OS 现有 `workflows/` 下还有多个可复用 workflow，其中部分已经有明确 Trigger，但没有上层 workflow map 入口，后续仍可能出现”workflow 存在但模型没有先读”的路由偏差。

本 proposal 目标是补齐稳定 workflow 触发边界，而不是把所有 workflow 细节搬进 router。`workflow-map.md` 应作为入口索引，保留简短、可执行、可反向排除的触发条件。

## Reusable Lesson

路由纠正：当 Memory OS workflow 已经具备明确 Trigger 或稳定任务信号时，应在 `router/workflow-map.md` 中补充简短入口；过于泛化的 workflow 不应进入 map，避免稀释路由判断。

## Proposed Memory OS Change

建议在 `router/workflow-map.md` 中保留现有前端原型条目，并补充以下 rows。

### 1. 明确触发，可直接补齐

```md
| Signal | Workflow | Use When | Do Not Use When |
|---|---|---|---|
| CodeGraph / 项目图 / graph / 调用链 / 影响面 / 架构定位 + CodeGraph enabled | `workflows/codegraph-assisted-project-analysis.md` | 用户要求使用或准备 CodeGraph，或任务需要大型项目结构、调用链、caller/callee、影响面、架构定位，且 CodeGraph 对当前项目启用 | 用户明确跳过 CodeGraph；当前项目未启用或准备失败；单文件/小范围问题可直接读源码 |
| review diff / PR / commit / staged changes / current changes | `workflows/diff-review-lite.md` | 用户要求审查 diff、PR、commit、staged changes 或当前代码改动，且不是广泛架构审查 | 用户要求直接实现功能；用户要求提交前自检时优先考虑 `pre-commit-self-check.md` 或相关 skill；diff 涉及跨模块契约、安全、权限、发布流、共享基础设施或长期规则时升级 L2 |
| 前端改动 + 回归验证 / 构建触发 / 验证副作用 / 平台验证 | `workflows/frontend-regression-verification-strategy.md` | 前端代码修改后需要选择最小验证路径、判断是否构建/测试、控制验证副作用 | 非前端任务；纯解释；用户已经明确指定具体验证命令且无需策略判断 |
| 复盘 / 沉淀 / 写入记忆 / 更新 Memory OS / 生成 proposal | `workflows/memory-retrospective.md` | 用户明确要求复盘、沉淀经验、写入记忆、更新 Memory OS 或生成 pending proposal | 任务结束后只是可能有经验但用户未要求写入时，用 `retrospective-lite.md` |
| 提交前检查 / 自检 / regression scan / look over current changes before commit | `workflows/pre-commit-self-check.md` | 用户要求提交前检查、自检当前改动、回归风险扫描或提交前看一遍改动 | 用户要求正式 review PR/diff 时可优先用 `diff-review-lite.md` 或 review skill；用户要求直接实现功能时不触发；改动触及路由/配置/构建入口/公共契约/安全/权限/共享模块时升级 L2 |
| 落地 pending / 晋升 proposal / accept proposal / reject proposal | `workflows/proposal-promotion.md` | 用户要求把 pending proposal 落地、晋升到正式规则、接受或拒绝 proposal | 只要求生成 pending proposal 时，用 `memory-retrospective.md` / memory-curator 边界；晋升 skill 类 proposal 时不要直接编辑 adapter SKILL.md，应走 `sync-skills.ps1` |
| weekly audit / 审计 pending / 清理重复或冲突 Memory OS 内容 | `workflows/weekly-audit.md` | 用户要求做 Memory OS 周审计、pending 审计、重复/冲突/过期内容检查 | 普通代码 review、自检、单个 proposal 生成或晋升；审计时不要直接删除正式规则/路由/skill 内容，只输出审计报告和清理 proposal |
| 任务结束后可能有可复用经验，但用户未明确要求写入 | `workflows/retrospective-lite.md` | 完成任务后发现可能存在跨项目或重复可用经验，需要判断是否建议 capture | 用户明确要求写入、更新 Memory OS、生成 proposal 时，用 `memory-retrospective.md`；无可复用经验时不触发 |
```

### 2. 可补齐，但必须保留强反向边界

```md
| Signal | Workflow | Use When | Do Not Use When |
|---|---|---|---|
| refactor / 重构 / 整理结构 / 降低复杂度 + 行为不变或风险控制 | `workflows/refactor-with-safety.md` | 用户要求重构、整理代码结构、降低复杂度，并需要控制行为变化风险 | 普通小修、小功能实现、纯解释、无重构目标 |
| 脚本 / 批处理 / 文件处理 / 自动化 + 输入输出副作用 | `workflows/script-automation.md` | 用户要求编写或修改脚本、批处理、文件处理或自动化流程，且需要确认输入、输出、副作用和失败策略 | 一行命令解释；普通应用代码实现；没有副作用风险的简单命令 |
| 测试策略 / 覆盖方案 / 回归保护 / 单测集成 E2E 选择 | `workflows/test-strategy.md` | 用户询问测试策略、覆盖层级、回归保护或如何选择单测/集成测试/E2E | 用户只要求直接修 bug 或已有明确测试实现路径时，按具体 bugfix/test workflow 或 skill 处理 |
```

### 3. 不建议纳入显式 workflow-map

- `workflows/feature-development.md`

原因：该 workflow 更像普通实现任务的默认工程方法，触发范围覆盖几乎所有 feature implement。若放入 `workflow-map.md`，会稀释 map 的路由价值，使 workflow-map 从“触发边界索引”变成“所有任务都可命中的默认步骤表”。建议保留为实现习惯或领域通用参考，不作为显式 route row。

## Safety And Sensitivity Check

- 不包含 token、账号、cookie、客户数据、生产日志、私密代码或其他敏感信息。
- 不直接修改正式 `router/workflow-map.md`；本 proposal 仅提交到 pending，等待维护/晋升流程处理。
- 不改变 L0-L3 定义，不改变 skill 触发规则，不扩大默认 Memory OS 读取深度。新增行仅作路由索引，workflow 文件仍按 L1/L2 读取预算按需加载。
- 通过 `Do Not Use When` 限制泛化 workflow，降低误触发风险。

## Source Task Or Evidence Summary

- 当前 `router/workflow-map.md` 已正式建立，但只包含前端原型驱动开发 workflow 一条。
- 现有 `workflows/` 中多个 workflow 已具备明确 Trigger 或稳定任务信号，适合补充为上层 workflow map 入口。
- 目标是减少“workflow 已存在但未被路由选择”的偏差，同时避免把通用默认工程步骤误提升为显式 workflow route。

## Draft Landing Plan

1. 审核本 proposal 中的 rows，确认是否需要删减或调整 Signal 文案。
2. 将确认后的 rows 追加到 `router/workflow-map.md`。
3. 运行 `tools/validate-memory-os.ps1`。
4. 用正反样例自检：
   - `review 这个 staged diff` 应命中 `diff-review-lite.md` 或相关 review skill。
   - `提交前帮我自检当前改动` 应命中 `pre-commit-self-check.md`。
   - `实现一个按钮样式调整` 不应因为 `feature-development.md` 进入 workflow-map。

## Risks

- 是否过度泛化：`feature-development.md` 已排除；`refactor-with-safety.md`、`script-automation.md`、`test-strategy.md` 仍可能频繁命中，已通过 `Do Not Use When` 限制；需在落地后用正反样例自检命中率。
- 是否包含敏感信息：否。
- 是否与现有规则冲突：新增行客观上增加了 workflow 命中→读取的概率，与"不扩大默认读取范围"存在张力；已修正 Safety 措辞为"不扩大默认读取深度"，并补充路由索引说明。

## Draft

See Proposed Memory OS Change above — 新增行即实际落地内容，无需额外 draft。
