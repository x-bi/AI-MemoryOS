# Install And Usage 安装与使用

## Codex 接入

当前已完成：

- `C:\Users\btf\.codex\AGENTS.md` 已追加 AI Memory OS 接入规则。
- `C:\Users\btf\.codex\config.toml` 已信任 `c:\users\btf\ai-memoryos`。
- `C:\Users\btf\AI-MemoryOS\adapters\codex\skills` 是 MemoryOS active skills 的源目录。
- `C:\Users\btf\.codex\skills` 是 Codex Desktop 实际发现目录，4 个 active skills 通过 junction 映射到这里。
- `SKILL.md` 必须是 UTF-8 no BOM；BOM 会导致 Codex 无法识别 frontmatter。

新开 Codex 会话后，已同步的 skills 会进入自动发现范围。

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

`--add-dir` 只授予访问权限，不会自动加载外置仓库里的 AGENTS 或 skills。Codex skills 必须出现在 Codex 可发现路径中；当前使用 junction 把 MemoryOS active skills 映射到 `.codex\skills`。

## Codex Skills 映射

源目录：

```text
C:\Users\btf\AI-MemoryOS\adapters\codex\skills
```

目标目录：

```text
C:\Users\btf\.codex\skills
```

只映射 4 个 active skills，不映射候选 skills，避免误触发和上下文膨胀。

## Optional MCP 可选 MCP

如果要启用 MCP，先验证：

```powershell
node C:\Users\btf\AI-MemoryOS\adapters\mcp\server\obsidian-memory-os-mcp.mjs
```

然后把以下示例合并到 `C:\Users\btf\.codex\config.toml`：

```text
adapters/mcp/config/codex-mcp.example.toml
```

MCP server 默认只写 `proposals/pending/`，不直接修改正式规则。
