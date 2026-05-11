---
name: routing-auditor
description: Use when the user explicitly asks to audit routing, fix route misclassification, or improve task/domain/skill routing in Memory OS.
---

# Routing Auditor

## Workflow

1. 读取 `_index.md`。
2. 读取 `router/intent-map.md` 和相关 evals。
3. 找出误判样例。
4. 生成 router correction proposal。
5. 不直接改正式 router，除非用户明确确认。
