---
title: "Set default MemoryOS read budget for complex tasks"
status: pending
created_at: 2026-05-12T03:44:56.443Z
source: mcp
---

# Proposal: Set default MemoryOS read budget for complex tasks

## Summary

普通复杂任务的 MemoryOS 读取预算默认控制在 2k tokens 以内；维护、审计、proposal/skill 晋升类任务可临时放宽，但需要先说明读取范围和原因。

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

## Source 来源

- Date: 2026-05-12
- Trigger 触发原因：验证单次复杂流程任务读取 MemoryOS 的上下文消耗后，确认默认读取成本约 0.5k-1.5k tokens，带 active skill 通常仍低于 2k。
- Related task 关联任务：MemoryOS 读取预算与低消耗策略校准。

## Summary 摘要

建议将普通复杂任务的 MemoryOS 默认读取预算设为 <= 2k tokens。

## Scope 适用范围

- Applies to 适用于：普通复杂工程任务、架构判断、复杂 review、bugfix 防回归等需要读取 MemoryOS 的任务。
- Does not apply to 不适用于：MemoryOS 维护、weekly audit、proposal 晋升、skill 晋升等需要系统性审计的任务。

## Proposed Destination 建议落点

- rules: `core/memory-rules.md`
- workflow: 可在相关 workflow 中引用
- wiki/docs: `docs/usage-manual.md` 或 `INSTALL.md`
- router: 无需修改，除非后续要把预算写入 routing 规则
- eval: 可补一个读取预算 eval case

## Rationale 保留理由

当前实测：

- `_index.md` 约 0.5k-0.7k tokens。
- `_index.md + 3 个直接相关页面` 约 0.7k-1.5k tokens。
- 复杂任务加一个 active `SKILL.md` 通常仍低于 2k tokens。

因此 2k tokens 足够覆盖“索引 + 路由 + 领域规则 + 一个 workflow/skill”，同时不会明显挤占业务代码、diff、报错日志等上下文空间。

## Risks 风险

- 是否过度泛化：中低。2k 是当前仓库体量下的经验值，后续 MemoryOS 变大后需要重新测量。
- 是否包含敏感信息：否。
- 是否与现有规则冲突：不冲突，属于对现有“_index.md + 最多 3 个直接相关页面”规则的量化补充。

## Draft 草稿

普通复杂任务默认 MemoryOS 读取预算 <= 2k tokens。

读取顺序：

1. 先读 `_index.md`。
2. 最多再读 3 个直接相关页面。
3. 如果预计超过 2k tokens，需要先说明原因和读取范围，再继续。

例外：MemoryOS 维护、weekly audit、proposal 晋升、skill 晋升等任务可临时放宽到 5k-8k tokens，但必须说明读取范围，并避免一次性展开无关候选 skills、历史日志或 proposal 堆积内容。

## Risks

- 是否过度泛化：
- 是否包含敏感信息：
- 是否与现有规则冲突：

## Draft

TODO
