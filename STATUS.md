# AI Memory OS Status 当前状态

## 已完成

- 独立仓库：`C:\Users\btf\AI-MemoryOS`。
- Codex skill 源目录：`C:\Users\btf\AI-MemoryOS\adapters\codex\skills`。
- Codex Desktop 发现目录：`C:\Users\btf\.codex\skills`，active skills 通过 junction 指向 MemoryOS 源目录。
- 已验证：在 `SKILL.md` 为 UTF-8 no BOM 时，junction skill 可以被 Codex Desktop 正常呼出。
- 全局 Codex 接入：`C:\Users\btf\.codex\AGENTS.md` 已缩减为 bootstrap，实际运行策略由 `adapters/codex/gate.md` 维护。
- 全局 Codex config：已把 `c:\users\btf\ai-memoryos` 标记为 trusted。
- MVP skills：`memory-curator`、`routing-auditor`、`bugfix-with-regression-test`、`frontend-component-review`、`vue-change-self-check`。
- 核心骨架：core / router / workflows / domains / stacks / prompts / anti-patterns / templates / evals / logs。
- PR Review workflow：`workflows/pr-review.md` 已建立，并已去除 BOM，保持 UTF-8 no BOM。
- MCP adapter：已新增受限 MCP server，并已写入全局 Codex config；默认只允许读库和写 `proposals/pending/`。
- Obsidian 自动化：QuickAdd、Templater、Dataview、Advanced URI、Obsidian Git 已配置并可验证。
- Obsidian 首页：`dashboard/home.md` 已创建，模板 frontmatter 已补齐。
- Git：仓库 local 身份已设置为 `x-bi <924992512@qq.com>`，origin 指向个人 GitHub。
- Remote：`main` 已跟踪 `origin/main`，远程为 `https://github.com/x-bi/AI-MemoryOS.git`。
- Active skill：已将 `workflows/pr-review.md` 封装为 Codex 可发现的 `pr-review` skill。
- Shared skill spec：7 个 active skills 已由 `skills/<skill>/SKILL_SPEC.md` + `skills/registry.json` 管理，并通过 `tools/sync-skills.ps1` 生成 Codex / Claude adapter 外壳。
- 轻量入口：已新增 `diff-review-lite`、`pre-commit-self-check`、`retrospective-lite` workflow。
- 路由策略：已从简单/复杂两档调整为 L0-L3 分层；当前阶段收窄 L0、放宽 L1，让轻量 workflow / skill 默认倾向触发，但 L2 读取和 L3 写入仍保持保守。
- Codex Gate：已新增 `adapters/codex/gate.md`，统一维护回答风格、Memory OS Gate、验证策略和读写边界。
- Codex 外部配置副本：已新增 `adapters/codex/external-config.md`，记录全局 bootstrap、config snippet、skill junction 和验证步骤。
- 新开 Codex 会话后验证 7 个 active skills 是否出现在技能列表。

## 剩余工作

- 扩展 skills：feature-planning、refactor-with-safety、test-strategy-review、prompt-improver、memory-auditor、skill-updater、backend-api-review、script-automation、playwright-e2e-review、ci-pipeline-review。
- 补 router/evals 的真实样例，避免靠想象扩写。
- 建立 proposal 晋升流程和 accepted/rejected 记录规范。
- 为 Claude / Cursor / generic adapter 补更完整接入说明。
- 用真实任务生成第一批 pending proposals。

## 当前策略

先通过真实任务扩大样例输入，再分批扩展。每个输入先读取轻量 `gate.md`；L1 默认倾向触发轻量 workflow / skill，L2/L3 才按预算读取或写入。

## Claude Code Adapter Status

- Claude Code user gate is configured at `C:\Users\btf\.claude\CLAUDE.md` and synchronized from `adapters/claude/CLAUDE.md`.
- Claude `ai_memoryos` MCP is configured in user scope and verified connected.
- Claude skill source directory is `adapters/claude/skills`.
- Claude skill discovery directory is `C:\Users\btf\.claude\skills`; active skills are junctions to the repository source.
- Seven Claude skills are active: `memory-curator`, `routing-auditor`, `bugfix-with-regression-test`, `frontend-component-review`, `pr-review`, `vue-change-self-check`, and `git-ops-guide`.
- Claude migration/reinstall snapshot is documented in `adapters/claude/external-config.md`.
- Cursor / generic adapter still need deeper restore/setup documentation.
- Claude plugin and slash commands are optional future improvements, not required for current Memory OS access.
