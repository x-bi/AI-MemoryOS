# AI Memory OS 接入规则

- 每个用户输入先做轻量 Memory OS Gate 判定，但判定本身不要读取 `C:\Users\btf\AI-MemoryOS`。
- 用户不需要声明任务简单或复杂；由 Codex 根据任务范围、风险、跨模块程度、是否涉及长期工程决策自动判断。
- 普通 explain / debug / small implement 默认不要读取 `C:\Users\btf\AI-MemoryOS`。
- 架构决策、跨模块重构、复杂排错、长期规范、安全/权限/发布流程、跨项目复盘、记忆维护时，可先读 `C:\Users\btf\AI-MemoryOS\_index.md`。
- 读取预算默认是 `_index.md` + 最多 3 个直接相关页面。
- 读取 Memory OS 不等于写入记忆；只有用户明确要求沉淀、复盘、更新 Memory OS、生成 proposal，或用户确认沉淀建议后，才写入 `C:\Users\btf\AI-MemoryOS\proposals\pending\`。
- 新经验只能先写入 `C:\Users\btf\AI-MemoryOS\proposals\pending\`，不要直接改正式 rules / router / skills / evals。
- 项目本地 AGENTS.md、README、代码事实优先于 AI Memory OS。
- Codex Desktop 从 `C:\Users\btf\.codex\skills` 发现用户 skills；AI Memory OS 的 active skills 通过 junction 映射到该目录。
- 不要假设外部仓库里的 skills 会自动发现。
