# Codex Adapter

此文件是 Codex 接入 AI Memory OS 的说明，不是全局事实源。

## Usage

- 每个用户输入先做轻量 Memory OS Gate 判定，但判定本身不要读取 AI Memory OS。
- 普通 explain / debug / small implement 不读取 AI Memory OS。
- 复杂工程任务可自动读 `C:\Users\btf\AI-MemoryOS\_index.md`，最多再读 3 个相关页面。
- 记忆复盘只写 `C:\Users\btf\AI-MemoryOS\proposals\pending\`。
- Codex Skills 通过 junction 映射到 `%USERPROFILE%\.codex\skills`；不要假设外部仓库里的 skills 会自动发现。

## Important

`--add-dir` 只授予访问权限，不会自动加载本仓库内的 AGENTS 或 skills。MemoryOS active skills 必须通过 junction 出现在 Codex Desktop 的发现目录。
