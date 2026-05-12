# Codex Adapter

## 已接入

- 全局 `C:\Users\btf\.codex\AGENTS.md` 已追加 Memory OS 读取规则。
- `C:\Users\btf\.codex\config.toml` 已 trust `c:\users\btf\ai-memoryos`。
- `C:\Users\btf\AI-MemoryOS\adapters\codex\skills` 是 active skills 源目录。
- `C:\Users\btf\.codex\skills` 是 Codex Desktop 实际发现目录，使用真实目录副本。
- `ai_memoryos` MCP 启动时会自动同步源目录到 Codex Desktop 发现目录。

## 使用边界

- 普通任务不读取 Memory OS。
- 复杂任务先读 `C:\Users\btf\AI-MemoryOS\_index.md`。
- 记忆复盘只写 `proposals/pending/`。
- 外置仓库里的 AGENTS.md 不会自动生效；生效入口是全局 AGENTS 和当前项目 AGENTS。

## Skill 暴露策略

只同步高频、低误触发的 active skills。候选 skills 保留在 `skills/`，待真实案例验证后再同步到 Codex Desktop。
