# Adapters

Memory OS 本体保持模型无关，模型差异放在 `adapters/`。

## 当前适配层

- `codex/`：Codex AGENTS、skills、config 片段和使用说明。
- `claude/`：Claude Code 读取入口、行为约束、Claude 专用 skills 和外部配置恢复说明。
- `cursor/`：Cursor rules 接入入口。
- `generic/`：任意模型可读的通用系统说明。
- `mcp/`：受限 MCP 自动化入口，只允许读库和写 pending proposal。

## 原则

- 通用知识不写进 adapter。
- adapter 只负责“如何接入”和“该模型的能力边界”。
- Codex skills 不直接等于通用 skills；通用规格放 `skills/`，Codex 可发现版本放 `adapters/codex/skills/`。
- MCP 不替代 Git 审核流程；MCP 写入默认只能进入 `proposals/pending/`。
