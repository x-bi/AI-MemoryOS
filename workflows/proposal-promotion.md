# Proposal Promotion Workflow

## Input

- `proposals/pending/` 中的 proposal。
- 相关 rules / workflow / domain / router / skill / eval 文件。

## Review Checklist

- scope 是否正确。
- 是否有真实案例支撑。
- 是否过度泛化。
- 是否重复或冲突。
- 是否包含敏感信息。
- 是否有明确目标落点。

## Outcomes

- accept：移动到 `proposals/accepted/`，并修改目标文件。
- reject：移动到 `proposals/rejected/`，写明原因。
- defer：保留 pending，补充需要验证的信息。

## Required Logs

- `logs/memory-changelog.md`
- `logs/router-changelog.md`，如果涉及 router/evals。
- `logs/skill-changelog.md`，如果涉及 skill。
