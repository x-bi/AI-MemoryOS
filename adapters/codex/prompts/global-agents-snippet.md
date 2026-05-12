# AI Memory OS 接入规则

- 普通任务默认不要读取 `C:\Users\btf\AI-MemoryOS`。
- 复杂工程任务、架构决策、跨项目复盘、记忆维护时，才先读 `C:\Users\btf\AI-MemoryOS\_index.md`。
- 读取预算默认是 `_index.md` + 最多 3 个直接相关页面。
- 新经验只能先写入 `C:\Users\btf\AI-MemoryOS\proposals\pending\`，不要直接改正式 rules / router / skills / evals。
- 项目本地 AGENTS.md、README、代码事实优先于 AI Memory OS。
- Codex Desktop 从 `C:\Users\btf\.codex\skills` 发现用户 skills；AI Memory OS 的 active skills 通过 junction 映射到该目录。
- 不要假设外部仓库里的 skills 会自动发现。
