# AI Memory OS Status 当前状态

## 已完成

- 独立仓库：`C:\Users\btf\AI-MemoryOS`。
- Codex skill 暴露：`C:\Users\btf\.agents\skills` 使用 junction 指向 `adapters/codex/skills`。
- Codex skill 暴露：`C:\Users\btf\.codex\skills` 也使用 junction 指向 `adapters/codex/skills`，匹配当前 Codex 桌面技能发现路径。
- 全局 Codex 接入：`C:\Users\btf\.codex\AGENTS.md` 已追加低消耗读取规则。
- 全局 Codex config：已把 `c:\users\btf\ai-memoryos` 标记为 trusted。
- MVP skills：`memory-curator`、`routing-auditor`、`bugfix-with-regression-test`、`frontend-component-review`。
- 核心骨架：core / router / workflows / domains / stacks / prompts / anti-patterns / templates / evals / logs。
- MCP adapter：已新增受限 MCP server，并已写入全局 Codex config；默认只允许读库和写 `proposals/pending/`。
- Obsidian 自动化：QuickAdd、Templater、Dataview、Advanced URI、Obsidian Git 已配置并可验证。
- Obsidian 首页：`dashboard/home.md` 已创建，模板 frontmatter 已补齐。
- Git：仓库 local 身份已设置为 `x-bi <924992512@qq.com>`，origin 指向个人 GitHub。
- Remote：`main` 已跟踪 `origin/main`，远程为 `https://github.com/x-bi/AI-MemoryOS.git`。

## 剩余工作

- 扩展 skills：feature-planning、refactor-with-safety、pr-review、test-strategy-review、prompt-improver、memory-auditor、skill-updater、backend-api-review、script-automation、playwright-e2e-review、ci-pipeline-review。
- 补 router/evals 的真实样例，避免靠想象扩写。
- 建立 proposal 晋升流程和 accepted/rejected 记录规范。
- 为 Claude / Cursor / generic adapter 补更完整接入说明。
- 新开 Codex 会话后验证 4 个 active skills 是否出现在技能列表。
- 用真实任务生成第一批 pending proposals。

## 当前策略

先稳定 MVP，再分批扩展。普通任务默认不读本仓库；只有复杂工程任务、记忆复盘和维护模式才读取。
