# Install And Usage 安装与使用

## Codex 接入

当前已完成：

- `C:\Users\btf\.codex\AGENTS.md` 只保留 bootstrap，引导读取 `C:\Users\btf\AI-MemoryOS\adapters\codex\gate.md`。
- `C:\Users\btf\AI-MemoryOS\adapters\codex\gate.md` 维护 Codex 回答风格、OS Gate、验证策略和读写边界。
- `C:\Users\btf\.codex\config.toml` 已信任 `c:\users\btf\ai-memoryos`。
- `C:\Users\btf\AI-MemoryOS\adapters\codex\skills` 是 MemoryOS active skills 的源目录。
- `C:\Users\btf\.codex\skills` 是 Codex Desktop 实际发现目录，active skills 通过 junction 映射到这里。
- `SKILL.md` 必须是 UTF-8 no BOM；BOM 会导致 Codex 无法识别 frontmatter。
- OS 外部 Codex 配置副本见 `adapters/codex/external-config.md`。

新开 Codex 会话后，已同步的 skills 会进入自动发现范围。

## 日常用法

普通任务会先读取 `gate.md`，再按 L0-L3 判定：

```text
L0：直接执行，不读取 Memory OS 正文。
L1：触发轻量 workflow / skill，不读取 Memory OS 正文。
L2：读取 _index.md + 最多 3 个相关页面。
L3：用户明确要求或确认后，写 proposals/pending。
```

记忆复盘：

```text
请对这次任务做 memory retrospective，只生成 pending proposal，不直接改正式规则。
```

## 重要边界

`--add-dir` 只授予访问权限，不会自动加载外置仓库里的 AGENTS 或 skills。Codex 全局 AGENTS 只负责 bootstrap；实际运行策略在 `adapters/codex/gate.md`。Codex skills 必须出现在 Codex 可发现路径中；当前使用 junction 把 MemoryOS active skills 映射到 `.codex\skills`。

## Codex Skills 映射

源目录：

```text
C:\Users\btf\AI-MemoryOS\adapters\codex\skills
```

目标目录：

```text
C:\Users\btf\.codex\skills
```

只映射 active skills，不映射候选 skills，避免误触发和上下文膨胀。

完整的本机配置副本、可选 MCP 配置、junction 创建命令和验证步骤记录在：

```text
adapters/codex/external-config.md
```

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
