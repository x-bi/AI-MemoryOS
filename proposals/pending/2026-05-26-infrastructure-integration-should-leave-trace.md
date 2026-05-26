---
title: "Infrastructure and tool integration should leave a trace"
type: proposal
status: pending
source: manual
created_at: "2026-05-26"
scope: global
destination: core/memory-rules.md, GOVERNANCE.md
tags:
  - memory/pending
---

# Proposal: Infrastructure and tool integration should leave a trace

## Source 来源

- Date: 2026-05-26
- Trigger 触发原因：CodeGraph 已接入 Memory OS，但 memory-changelog.md 和其他日志中无对应条目，事后回顾时无法确认接入时间、动机和初始状态。
- Related task 关联任务：CodeGraph integration, memory changelog 补录

## Summary 摘要

基础设施/工具的引入、首次项目注册、版本升级等事件应主动留痕，不能仅依赖代码 diff 和 git blame 回溯。

## Scope 适用范围

- Global：适用于 Memory OS 管理的所有适配器和集成
- Applies to 适用于：工具首次接入、项目首次注册使用某工具/服务、工具版本升级、工具停用/移除
- Does not apply to 不适用于：日常使用中的普通操作（如为已注册项目重新 sync 索引）

## Proposed Destination 建议落点

- rules: `core/memory-rules.md` 增加留痕规则
- workflow: 可选，`workflows/` 下新增集成事件记录流程
- GOVERNANCE.md: 在审计节奏中补充集成事件审查

## Rationale 保留理由

1. **可回溯**：未来排查"何时引入、为什么引入"时，主动记录比 git blame 更可靠，因为 diff 只记录 what，不记录 why。
2. **决策留痕**：工具选型动机、替代方案排除理由不会自动出现在代码中。
3. **恢复依赖**：Restore Policy 记录恢复步骤，但"已安装"这个事实状态需要单独记录。
4. **跨项目一致性**：多个项目先后接入同一工具时，需知道谁先谁后、版本是否一致。

## Risks 风险

- 是否过度泛化：风险可控，只要求记录"引入/首次使用/升级/移除"等关键事件，不要求记录每次使用。
- 是否包含敏感信息：留痕内容应与现有 memory-rules 一致，不包含 token/密码/PII。
- 是否与现有规则冲突：不冲突，是 memory-rules 和 GOVERNANCE 的补充。

## Draft 草稿

### memory-rules.md 新增规则

基础设施和工具集成事件应主动留痕：

- **必须留痕**：工具首次接入 Memory OS、项目首次注册使用某工具、工具版本升级、工具停用或移除。
- **留痕位置**：`logs/memory-changelog.md`（轻量）或 `logs/integration-events.md`（独立日志）。
- **留痕内容**：时间、动作、涉及工具/项目、动机（why）、涉及文件、初始状态（版本号等）。
- **不需要留痕**：日常使用操作（如已注册项目的 sync、query）。

### GOVERNANCE.md 审计补充

审计节奏中增加：检查集成事件是否有对应 changelog 条目。
