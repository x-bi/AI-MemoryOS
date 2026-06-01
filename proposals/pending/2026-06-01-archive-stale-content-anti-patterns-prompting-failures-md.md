---
title: "Archive stale content: anti-patterns\prompting-failures.md"
type: proposal
status: pending
source: auto-iterate
created_at: "2026-06-01"
scope: "Memory OS"
destination: "memory-cleanup"
generated_by: auto-iterate
tier: B
tags:
  - memory/pending
  - auto/round-1
---

# Proposal: Archive stale content: anti-patterns\prompting-failures.md

## 来源

- 日期：2026-06-01
- 触发来源：audit-content-quality
- 关联对象：anti-patterns\prompting-failures.md

## 摘要

Audit found content that appears hollow or placeholder-only and needs human review.

## 适用范围

- 适用于：AI Memory OS 维护。
- 不适用于：外部业务项目源码。

## 建议落点

- destination: `memory-cleanup`

## 为什么值得处理

该 proposal 由 Round 1 deterministic audit 生成。它只代表“值得人工复核”的候选项，不会自动晋升，也不会自动修改正式规则或内容。

## 风险与边界

- 是否过度泛化：需要人工确认。
- 是否包含敏感信息：生成前已执行敏感内容预检查。
- 是否与现有规则冲突：需要人工确认。

## 建议草稿

Review whether this page still has durable value.

- Finding category: hollow-content
- Evidence path: anti-patterns\prompting-failures.md
- Suggested action: If the content is confirmed as placeholder, stale, or not reusable, archive it or complete the body.
