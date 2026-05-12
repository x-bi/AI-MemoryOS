# Codex Adapter

此文件是 Codex 接入 AI Memory OS 的说明，不是全局事实源。

## Usage

- 普通任务不要读取 AI Memory OS。
- 复杂工程任务可先读 `C:\Users\btf\AI-MemoryOS\_index.md`，最多再读 3 个相关页面。
- 记忆复盘只写 `C:\Users\btf\AI-MemoryOS\proposals\pending\`。
- Codex Skills 以真实目录副本同步到 `%USERPROFILE%\.codex\skills`；同步由 `ai_memoryos` MCP 启动触发，不依赖外部仓库或 junction 自动发现。

## Important

`--add-dir` 只授予访问权限，不会自动加载本仓库内的 AGENTS 或 skills。MemoryOS active skills 由 MCP 启动同步到 Codex Desktop 的发现目录。
