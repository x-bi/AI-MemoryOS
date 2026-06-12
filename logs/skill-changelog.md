# Skill Changelog 技能变更日志
## 2026-06-12

- 修正 `tools/sync-skills.ps1 -Check` 的状态汇总：registry、template、path safety 等 ERROR 不再被汇总为 STALE。
- 修正 adapter template 渲染顺序，避免 `SKILL_SPEC.md` 正文中的 `{{name}}`、`{{adapter}}` 等 literal 示例被元数据替换。
- 加强 registry description 的 YAML 双引号转义，覆盖换行、tab 和控制字符；`tools/validate-memory-os.ps1` 的 managed skill required 文件改为从 `skills/registry.json` 动态补齐。

## 2026-06-11

- 接受 proposal：`2026-06-11-将-skill-同步升级为-adapter-shell-渲染与漂移检测管线`。
- 新增 Codex / Claude adapter skill template，`tools/sync-skills.ps1` 通过 shared spec、registry 和 adapter template 渲染 generated `SKILL.md`。
- 新增 `tools/sync-skills.ps1 -Check`，以 expected render 和实际 generated output 的完整内容比较检测漂移。
- 不改变 active skill roster，不修改 skill trigger description。

## 2026-05-26

- 晋升 proposal：`修正 Vue/uni-app 改动检查未触发 vue-change-self-check`。
- 扩展 `vue-change-self-check` 的触发边界：当用户要求检查当前改动、未提交改动、staged changes、commit 或 diff，且当前仓库或轻量 diff 文件列表命中 Vue / uni-app / frontend 信号时，应触发该 skill。
- 明确 `pr-review` 与 `vue-change-self-check` 可以并行触发；前端 diff 自检场景优先使用稳定编号风险清单输出。
- 为 Codex / Claude adapter 同步更新 skill description，并补充正反 eval 用例，防止泛化 review 吞掉前端自检。

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
