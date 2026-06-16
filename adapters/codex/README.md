# Codex Adapter

## 已接入

- 全局 `C:\Users\btf\.codex\AGENTS.md` 只保留 bootstrap redirect，引导每个输入读取 `C:\Users\btf\AI-MemoryOS\adapters\codex\bootstrap.md`。
- `C:\Users\btf\AI-MemoryOS\adapters\codex\bootstrap.md` 是轻量加载入口，只判断是否需要读取完整 gate。
- `C:\Users\btf\AI-MemoryOS\adapters\codex\gate.md` 是 Codex 回答风格、Memory OS Gate、验证策略和读写边界的完整策略入口。
- `C:\Users\btf\.codex\config.toml` 已 trust `c:\users\btf\ai-memoryos`。
- `C:\Users\btf\AI-MemoryOS\adapters\codex\skills` 是 active skills 源目录。
- `C:\Users\btf\.codex\skills` 是 Codex Desktop 实际发现目录，active skills 通过 junction 映射到这里。
- `SKILL.md` 必须是 UTF-8 no BOM，确保 frontmatter 从第一个字节 `---` 开始。
- OS 外部配置副本记录在 `adapters/codex/external-config.md`，用于换机或新软件快速恢复 Codex 本机配置。

## 使用边界

- 每个输入先读取 `bootstrap.md`；必要时再读取 `gate.md`，并按其中规则做 L0-L3 判定。
- 读取 `gate.md` 只用于加载运行策略，不等于读取 Memory OS 正文。
- L0 直接执行；L1 可触发轻量 workflow / skill；L2 才读取 `_index.md` + 最多 3 个相关页面。
- 记忆复盘只写 `proposals/pending/`。
- 外置仓库里的 AGENTS.md 不会自动生效；生效入口是全局 AGENTS 和当前项目 AGENTS。

## Skill 暴露策略

只映射高频、低误触发的 active skills。候选 skills 保留在 `skills/`，待真实案例验证后再映射到 Codex Desktop。

## 外部配置副本

需要在 `C:\Users\btf\.codex` 下配置的内容，包括全局 `AGENTS.md` bootstrap、`config.toml` snippet、可选 MCP config、active skill junction 和验证命令，统一记录在：

```text
adapters/codex/external-config.md
```
