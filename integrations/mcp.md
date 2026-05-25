# MCP Integration

## 目标

MCP 只作为自动化工具层，不替代 Markdown + Git 事实源。

## 推荐混合架构

```text
AI-MemoryOS Markdown + Git
  ↓
Codex file edits + Codex skills
  ↓
MCP safe tools
  ↓
Obsidian dashboards / review UI
```

## 当前实现

本仓库提供一个受限 MCP server：

```text
adapters/mcp/server/obsidian-memory-os-mcp.mjs
```

它不依赖 Obsidian 插件，直接读写 Memory OS 文件，因此即使 Obsidian 没打开也可用。

## 权限边界

- 读：Memory OS 文本文件。
- 写：仅 `proposals/pending/*.md`。
- 不允许：删除、批量重写、直接修改正式规则。

## Codex 配置

参考：

```text
adapters/mcp/config/codex-mcp.example.toml
```

把片段合并到 `C:\Users\btf\.codex\config.toml` 后，重启 Codex。

## Claude Code Configuration

Claude Code also uses the same restricted MCP server under the user-scope name `ai_memoryos`.

Current command shape:

```text
C:\Program Files\nodejs\node.exe C:\Users\btf\AI-MemoryOS\adapters\mcp\server\obsidian-memory-os-mcp.mjs
```

Restore and validation steps are documented in:

```text
adapters/claude/external-config.md
```

The same MCP safety boundary applies to Claude: read/search Memory OS, list/create/append pending proposals, and do not directly modify formal rules, router, skills, evals, accepted proposals, or rejected proposals.
