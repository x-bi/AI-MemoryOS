# AI Memory OS

跨模型、跨项目的工程记忆系统。Memory OS 本体保持模型无关；各模型通过 `adapters/` 接入。

## 设计原则

- 默认低消耗：普通任务不读取 Memory OS。
- 事实源可审计：长期记忆以 Markdown + Git 管理。
- 新经验先进入 `proposals/pending/`，不直接污染正式规则。
- 模型适配层单独放在 `adapters/`，避免被 Codex、Claude、Cursor 等工具锁定。

## 推荐使用方式

- Codex：读取 `adapters/codex/AGENTS.md` 的接入说明，并通过 symlink 暴露 `adapters/codex/skills/*` 到 `%USERPROFILE%\.agents\skills`。
- 其他模型：优先读取 `adapters/generic/SYSTEM.md`，再按需补充自己的 adapter。
