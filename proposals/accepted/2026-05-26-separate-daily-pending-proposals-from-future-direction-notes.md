---
title: "Separate Daily Pending Proposals From Future Direction Notes"
status: accepted
created_at: 2026-05-26
accepted_at: 2026-05-26
source: manual
scope: governance
decision_reason: "The distinction has already been implemented in repository structure, model-facing search boundaries, dashboards, validation, and adapter docs; formal governance now needs to record the accepted content model."
---

# Accepted Proposal: Separate Daily Pending Proposals From Future Direction Notes

## Proposal

Original pending proposal:

```text
proposals/pending/2026-05-26-pending-proposal-review-lanes.md
```

## Accepted At

2026-05-26

## Destination

- `GOVERNANCE.md`
- `core/memory-rules.md`
- `_index.md`
- `adapters/codex/gate.md`
- `adapters/claude/CLAUDE.md`
- `adapters/claude/external-config.md`
- `logs/memory-changelog.md`

## Reason

该 proposal 已通过真实维护任务验证：新增 `proposals/future-directions/` 后，重大方向说明已从普通 pending proposal 队列中拆出，并补齐 MCP search、dashboard、weekly audit、validation、Claude / Codex adapter 入口和日志记录。

该区分满足晋升条件：能降低治理误判，避免把长期架构方向误当作可直接晋升的日常 proposal，也能改善 Memory OS 维护和审计的稳定性。

## Files Changed

- `GOVERNANCE.md`：明确 future direction note 的用途、写入条件、审计节奏和非直接晋升边界。
- `core/memory-rules.md`：明确普通 pending proposal 与重大方向说明的不同写入流程。
- `_index.md`：更新 L3 写入边界，加入 future direction note 的明确入口。
- `adapters/codex/gate.md`：同步 Codex 运行策略，避免 future direction 被误写入 pending。
- `adapters/claude/CLAUDE.md`：同步 Claude 运行策略，限定 future direction note 的读写条件。
- `adapters/claude/external-config.md`：更新 Claude 恢复配置说明。
- `logs/memory-changelog.md`：记录本次晋升。

## Eval / Test Coverage

- `tools/validate-memory-os.ps1` 已校验 future direction note frontmatter 必须包含 `type: future-direction-note` 和 `not_directly_promotable: true`。
- `tools/validate-obsidian.ps1` 已校验 future directions dashboard 存在。
- MCP smoke test 已验证默认 `memory_search` 能搜索 `proposals/future-directions/`。
- Claude MCP 已验证 `ai_memoryos` connected，且用户级 `CLAUDE.md` 与仓库模板哈希一致。

## Accepted Rule

Memory OS 候选内容分为两类：

- `pending proposal`：具体、可审核、可转正的规则、workflow、router、skill、docs 或治理优化建议。默认写入 `proposals/pending/`，审核后才能晋升到正式内容。
- `future direction note`：重大架构方向、治理方向、仓库结构、跨 adapter 迁移或长期产品方向说明。写入 `proposals/future-directions/`，用于保存设计意图和未来理解背景，不直接晋升为正式规则。

当 future direction note 准备落地时，必须再拆成具体 proposal、设计文档、迁移计划或任务清单。future direction note 不得绕过敏感信息边界，也不得被当作 accepted proposal 使用。
