# Codex Adapter

## 已接入

- 全局 `C:\Users\btf\.codex\AGENTS.md` 已追加 Memory OS 读取规则。
- `C:\Users\btf\.codex\config.toml` 已 trust `c:\users\btf\ai-memoryos`。
- `C:\Users\btf\.agents\skills` 已通过 junction 暴露 4 个 active skills。

## 使用边界

- 普通任务不读取 Memory OS。
- 复杂任务先读 `C:\Users\btf\AI-MemoryOS\_index.md`。
- 记忆复盘只写 `proposals/pending/`。
- 外置仓库里的 AGENTS.md 不会自动生效；生效入口是全局 AGENTS 和当前项目 AGENTS。

## Skill 暴露策略

只暴露高频、低误触发的 active skills。候选 skills 保留在 `skills/`，待真实案例验证后再暴露。