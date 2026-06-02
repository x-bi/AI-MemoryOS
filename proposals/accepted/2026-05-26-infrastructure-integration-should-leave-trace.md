---
title: "Infrastructure and tool integration should leave a trace"
type: proposal
status: accepted
source: manual
source_episode: "bug:codegraph-integration-missing-changelog;conversation:2026-05-26"
created_at: "2026-05-26"
updated_at: "2026-05-27"
accepted_at: "2026-05-27"
scope: global
destination: core/memory-rules.md, GOVERNANCE.md
decision_reason: "Infrastructure/tool integration events affect long-term Memory OS capability state; recording why/when prevents future audits from relying only on diff/blame and keeps integration history recoverable."
tags:
  - memory/accepted
---

# Accepted Proposal: Infrastructure and tool integration should leave a trace

## Review Decision

Accepted on 2026-05-27.

Reason: infrastructure/tool integration events change long-term Memory OS capability state. They need lightweight decision trace records so future audits can recover when a capability appeared, why it was introduced or removed, and what initial state mattered without storing runtime logs or sensitive data.

## Source

- Date: 2026-05-26, updated 2026-05-27
- Trigger: CodeGraph 已接入 Memory OS，但 changelog 中无对应条目，事后无法确认接入时间、动机和初始状态

## Summary

基础设施/工具的引入、移除等决策级事件应主动留痕，不能仅依赖代码 diff 和 git blame 回溯。本提案仅覆盖留痕，不涉及集成验证流程。

## Trace Levels 留痕级别

### P0 — 必须留痕

改变系统能力状态的事件。特征：事后问"这个能力什么时候来的/为什么来"，git diff 回答不了 why。

- 工具首次接入 Memory OS（如注册新 MCP server、新增 adapter）
- 工具停用或移除
- 工具版本升级/降级（跨大版本或涉及 breaking change）

### P1 — 建议留痕

扩展系统使用范围的事件。特征：不改变能力本身，但改变了能力覆盖的项目/场景。

- 项目首次注册使用某工具（如某项目首次 build CodeGraph 索引）
- 小版本升级（非 breaking，但值得记录版本号变化）

### P2 — 不留痕

日常操作和运行时行为。特征：高频、可重复、不改变系统状态。

- 日常使用操作（sync、query、build index、调用工具）
- 运行时日志、错误日志
- 使用说明/文档更新
- 重复注册/刷新已有配置

## Trace Content 留痕内容

每条留痕只记录决策上下文，不记录技术细节和运行时数据：

```
## YYYY-MM-DD <工具名> <动作>
- 动作：接入 / 移除 / 升级 / 项目注册
- 涉及工具/项目：<名称>
- 动机（why）：<一句话说明为什么做这个决策>
- 初始状态：<版本号、配置要点等>
```

不包含：token、密码、PII、调用日志、错误堆栈。

## Trace Location 留痕位置

- `logs/memory-changelog.md`（轻量，与现有 changelog 合并）
- 或 `logs/integration-events.md`（独立日志，当条目增多时拆分）

## Proposed Destination

- `core/memory-rules.md`：增加留痕规则（P0/P1/P2 分级）
- `GOVERNANCE.md`：审计节奏中补充集成事件 changelog 条目检查

## Rationale

1. **可回溯**：diff 只记录 what，不记录 why，主动留痕补上决策动机
2. **跨项目一致性**：多个项目先后接入同一工具时，需知道先后顺序和版本
3. **职责单一**：留痕只负责记录决策，不负责验证（验证属于集成 workflow 的前置步骤，不在本提案范围）

## Risks

- 过度泛化：通过 P0/P1/P2 分级控制，P2 明确排除日常操作
- 敏感信息：留痕内容与现有 memory-rules 一致，不含 token/密码/PII
- 与现有规则冲突：不冲突，是 memory-rules 和 GOVERNANCE 的补充
