# Skill Changelog 技能变更日志

## 2026-05-11

- 新增 active Codex skills：
  - `memory-curator`
  - `routing-auditor`
  - `bugfix-with-regression-test`
  - `frontend-component-review`
- 新增候选 skill specs 到 `skills/`。
- 候选 skills 暂不暴露给 Codex 自动发现，避免误触发和上下文膨胀。

## 记录原则

- active skill 必须边界清晰、触发稳定、低误触发。
- candidate skill 必须经过真实任务验证后再晋升。
- 修改 `description` 时要特别谨慎，因为它影响 Codex 是否触发 skill。
