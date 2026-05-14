# Skill Changelog 技能变更日志

## 2026-05-14

- 新增 active Codex skill：`pr-review`。
- 该 skill 用于 PR、commit、diff、staged changes 和当前改动的风险审查。
- 输出顺序固定为 Findings / Open questions / Test gaps / Summary。
- 明确该 skill 触发不等于读取 Memory OS；只有影响面大、跨模块、安全或长期规则相关 review 才升级读取。
- 优化 `vue-change-self-check`：主 `SKILL.md` 压缩为触发和核心流程，详细 checklist / output contract 移入 `references/` 按需读取，降低常规触发 token 成本。

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
