# Codex Adapter

此文件是 Codex 接入 AI Memory OS 的说明，不是全局事实源。

## Usage

- 全局 `C:\Users\btf\.codex\AGENTS.md` 只作为 bootstrap，引导每个输入先读取 `C:\Users\btf\AI-MemoryOS\adapters\codex\gate.md`。
- `gate.md` 统一维护回答风格、Memory OS Gate、L0-L3、验证策略和读写边界。
- 读取 `gate.md` 只用于加载运行策略，不等于读取 Memory OS 正文。
- L0/L1 不读取 Memory OS 正文；L1 默认倾向触发轻量 workflow / skill，用于扩大真实任务样例。
- L2 才读取 `_index.md` + 最多 3 个直接相关页面。
- L3 只在用户明确要求或确认后写入 `proposals/pending/`。
- 最终回答按 `gate.md` 的 OS Trace Footer 记录本次 L 级别、skills、workflow、读取和写入。
- Codex Skills 通过 junction 映射到 `%USERPROFILE%\.codex\skills`；不要假设外部仓库里的 skills 会自动发现。

## Important

`--add-dir` 只授予访问权限，不会自动加载本仓库内的 AGENTS 或 skills。MemoryOS active skills 必须通过 junction 出现在 Codex Desktop 的发现目录。
