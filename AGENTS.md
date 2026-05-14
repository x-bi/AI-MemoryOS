# AI Memory OS Repository Rules

本仓库是跨模型工程记忆事实源，不是某个项目的临时上下文。

## Codex 入口

- Codex 运行策略由 `adapters/codex/gate.md` 维护。
- 全局 `C:\Users\btf\.codex\AGENTS.md` 只作为 bootstrap，引导每个输入先读取 gate。
- 回答风格、Memory OS Gate、验证与回归自检策略都以 `adapters/codex/gate.md` 为准。
- 如果 gate 与本文件冲突，本仓库维护规则优先；如果项目代码事实与 Memory OS 冲突，项目事实优先。

## 工作规则

- 普通任务只读取 `adapters/codex/gate.md` 作为运行策略入口，不读取 Memory OS 正文。
- 新经验默认只写入 `proposals/pending/`。
- 不直接修改正式 rules / router / skills，除非用户明确进入维护或晋升模式。
- 不保存 token、密码、密钥、PII、生产日志原文、客户私有代码或未脱敏业务信息。
- 项目局部规则优先于本仓库通用规则。
- 修改正式内容时同步更新 `logs/`。

## 低消耗约束

- 复杂任务最多读取 `_index.md` + 3 个相关页面。
- 需要扩大读取范围时，先说明原因。
- 不自动扫描 `raw/`、`proposals/accepted/`、`proposals/rejected/`。
