---
title: "Set default MemoryOS read budget for complex tasks"
status: accepted
created_at: 2026-05-12T03:44:56.443Z
accepted_at: 2026-05-12
source: mcp
---

# Accepted Proposal: Set default MemoryOS read budget for complex tasks

## Proposal

Original pending proposal:

```text
proposals/pending/2026-05-12-set-default-memoryos-read-budget-for-complex-tasks.md
```

## Accepted At

2026-05-12

## Destination

- `core/memory-rules.md`
- `_index.md`
- `docs/usage-manual.md`
- `evals/router-test-cases.md`
- `logs/memory-changelog.md`

## Reason

实测普通复杂任务读取 MemoryOS 的成本约为 0.5k-1.5k tokens，带一个 active skill 通常仍低于 2k。把默认预算量化为 2k tokens，可以保持低消耗，同时足够覆盖 `_index.md`、路由判断、领域规则和一个 workflow/skill。

## Files Changed

- `core/memory-rules.md`：新增读取预算规则。
- `_index.md`：在默认读取入口补充 2k 预算边界。
- `docs/usage-manual.md`：补充 2k 预算说明和不计入范围。
- `evals/router-test-cases.md`：新增复杂任务读取预算样例。
- `logs/memory-changelog.md`：记录本次晋升。

## Eval / Test Coverage

- 新增 router test case：复杂工程任务读取 MemoryOS 时，默认预算不超过 2k tokens，超出先说明范围。

## Accepted Rule

普通复杂任务默认 MemoryOS 读取预算不超过 2k tokens。

读取顺序：

1. 先读 `_index.md`。
2. 最多再读 3 个直接相关页面。
3. 如果预计超过 2k tokens，需要先说明原因和读取范围，再继续。

说明：2k 预算只统计 MemoryOS 自身内容，不包含业务项目代码、diff、报错日志、接口文档、终端输出、用户当前对话或 Codex 系统上下文。

例外：MemoryOS 维护、weekly audit、proposal 晋升、skill 晋升等任务可临时放宽到 5k-8k tokens，但必须说明读取范围，并避免一次性展开无关候选 skills、历史日志或 proposal 堆积内容。
