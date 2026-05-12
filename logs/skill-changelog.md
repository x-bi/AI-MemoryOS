# Skill Changelog 技能变更日志

## 2026-05-12

- 新增 active Codex skill：`vue-change-self-check`。
- 该 skill 用于 Vue / uni-app / frontend 提交前 diff 风险扫描，输出稳定编号风险清单。
- 将项目私有路径和本地专项规则放入 `private/skills/vue-change-self-check.local.md`，并通过 `.gitignore` 排除，不进入远程仓库。
- 继续要求 active `SKILL.md` 使用 UTF-8 no BOM，确保 Codex 能识别 frontmatter。

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
