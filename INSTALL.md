# Install And Usage

## Codex

当前已完成：

- `C:\Users\btf\.codex\AGENTS.md` 已追加 AI Memory OS 接入规则。
- `C:\Users\btf\.codex\config.toml` 已信任 `c:\users\btf\ai-memoryos`。
- `C:\Users\btf\.agents\skills` 已通过 junction 暴露 Codex skills。
- `C:\Users\btf\.codex\skills` 也已通过 junction 暴露同一组 active skills；这是当前 Codex 桌面环境实际扫描的用户技能目录。

新开 Codex 会话后，skills 会进入自动发现范围。

## 日常用法

普通任务：

```text
这是普通低消耗任务。不要读取 AI Memory OS，也不要写入记忆。
```

复杂工程任务：

```text
这是复杂工程任务。可以读取 C:\Users\btf\AI-MemoryOS\_index.md，最多再读 3 个直接相关页面。不要自动写入记忆。
```

记忆复盘：

```text
请对这次任务做 memory retrospective，只生成 pending proposal，不直接改正式规则。
```

## 重要边界

`--add-dir` 只授予访问权限，不会自动加载外置仓库里的 AGENTS 或 skills。Codex skills 必须出现在 Codex 可发现路径中；当前同时维护 `.agents/skills` 和 `.codex/skills` 两组 junction。

## Optional MCP

如果要启用 MCP，先验证：

```powershell
node C:\Users\btf\AI-MemoryOS\adapters\mcp\server\obsidian-memory-os-mcp.mjs
```

然后把以下示例合并到 `C:\Users\btf\.codex\config.toml`：

```text
adapters/mcp/config/codex-mcp.example.toml
```

MCP server 默认只写 `proposals/pending/`，不直接修改正式规则。
