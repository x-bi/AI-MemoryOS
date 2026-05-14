# AI Memory OS Repository Rules

本仓库是跨模型工程记忆事实源，不是某个项目的临时上下文。

## 工作规则

- 普通任务不要读取本仓库。
- 新经验默认只写入 `proposals/pending/`。
- 不直接修改正式 rules / router / skills，除非用户明确进入维护或晋升模式。
- 不保存 token、密码、密钥、PII、生产日志原文、客户私有代码或未脱敏业务信息。
- 项目局部规则优先于本仓库通用规则。
- 修改正式内容时同步更新 `logs/`。

## 低消耗约束

- 复杂任务最多读取 `_index.md` + 3 个相关页面。
- 需要扩大读取范围时，先说明原因。
- 不自动扫描 `raw/`、`proposals/accepted/`、`proposals/rejected/`。
