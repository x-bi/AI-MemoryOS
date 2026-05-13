# Codex Adapter

## 已接入

- 全局 `C:\Users\btf\.codex\AGENTS.md` 已追加 Memory OS 读取规则。
- `C:\Users\btf\.codex\config.toml` 已 trust `c:\users\btf\ai-memoryos`。
- `C:\Users\btf\AI-MemoryOS\adapters\codex\skills` 是 active skills 源目录。
- `C:\Users\btf\.codex\skills` 是 Codex Desktop 实际发现目录，active skills 通过 junction 映射到这里。
- `SKILL.md` 必须是 UTF-8 no BOM，确保 frontmatter 从第一个字节 `---` 开始。

## 使用边界

- 每个输入先做轻量 Memory OS Gate 判定，判定本身不读取 Memory OS。
- 普通 explain / debug / small implement 不读取 Memory OS。
- 架构、重构、复杂排错、长期规范、安全/权限/发布流程等任务可自动读 `C:\Users\btf\AI-MemoryOS\_index.md`。
- 记忆复盘只写 `proposals/pending/`。
- 外置仓库里的 AGENTS.md 不会自动生效；生效入口是全局 AGENTS 和当前项目 AGENTS。

## Skill 暴露策略

只映射高频、低误触发的 active skills。候选 skills 保留在 `skills/`，待真实案例验证后再映射到 Codex Desktop。
