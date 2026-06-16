# AI Memory OS Codex Fallback

本文件只是 Codex 项目级兜底入口，不是完整运行策略事实源。

Codex 的每轮加载入口和完整运行规则由以下文件维护：

```text
C:\Users\btf\AI-MemoryOS\adapters\codex\bootstrap.md
C:\Users\btf\AI-MemoryOS\adapters\codex\gate.md
```

每个 Codex 输入先读取 `adapters/codex/bootstrap.md`。该文件只负责判断是否需要读取完整 gate；完整运行规则仍由 `adapters/codex/gate.md` 维护。

如果本文件与 `adapters/codex/bootstrap.md` 或 `adapters/codex/gate.md` 冲突，以 `gate.md` 为准；如果项目代码事实与 Memory OS 通用规则冲突，以项目事实优先。

Claude Code 不使用本文件作为入口。Claude 每轮入口由 `adapters/claude/bootstrap.md` 维护，完整运行策略由 `adapters/claude/CLAUDE.md` 维护；用户级 `C:\Users\btf\.claude\CLAUDE.md` 只是指向 Memory OS bootstrap 的 redirect。

除非用户明确要求或确认，不自动写入 Memory OS；新经验默认只能写入 `proposals/pending/`。
