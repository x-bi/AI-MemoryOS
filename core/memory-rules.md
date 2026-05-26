# Memory Rules

## 可以沉淀

- 跨项目复用的工程规则。
- 经过验证的常见错误和反模式。
- 可复用工作流、review checklist、测试策略。
- 已脱敏的最小案例和抽象经验。

## 不允许沉淀

- token、密码、密钥、账号、auth 文件。
- PII、客户数据、生产日志原文。
- 未脱敏项目代码、商业敏感信息、报价、法务条款。
- 单个项目的临时偏好，除非明确标记 scope。

## 写入流程

1. 普通经验、规则、workflow、router、skill、docs 优化建议，先写 `proposals/pending/`。
2. 人工审核 scope、重复、过期、风险。
3. 通过后晋升到 rules / wiki / router / skills / evals。
4. 更新 changelog。

## 重大方向说明

- `proposals/future-directions/` 保存长期重大方向、架构意图和未来迁移背景。
- future direction note 不是普通 pending proposal，不进入“审核后直接晋升为正式规则”的流程。
- 只有用户明确要求记录长期方向、架构意图，或明确进入 Memory OS 维护模式时，才写入 `proposals/future-directions/`。
- 真正落地前，应基于 future direction note 再拆出具体 proposal、设计文档、迁移计划或任务清单。
- future direction note 不得包含 token、密码、密钥、账号、auth 文件、PII、客户数据、生产日志原文或未脱敏项目代码。

## 读取与写入边界

- 每个用户输入先读取 `adapters/codex/gate.md` 做 L0/L1/L2/L3 判定；读取 gate 只用于加载运行策略，不等于读取 Memory OS 正文。
- L0 不读取 Memory OS 正文。
- L1 可触发轻量 workflow / skill，但默认不读取 Memory OS 正文；如果 workflow / skill 本身需要读取 rules / domains / router 正文，应升级为 L2。
- L2 可自动读取 `_index.md`，并在预算内最多读取 3 个直接相关页面。
- 读取 Memory OS 不等于写入记忆。
- L3 仅在用户明确要求沉淀、复盘、更新 Memory OS、生成 proposal，或用户确认沉淀建议后，才写入 `proposals/pending/`。
- 重大长期方向说明是维护类写入；仅在用户明确要求记录长期方向或架构意图时，写入 `proposals/future-directions/`，且不得被当作可直接晋升的 pending proposal。

## 读取预算

- 普通 L2 的 Memory OS 正文读取预算默认目标为 2k tokens。
- 2k 是软预算：优先读 `_index.md` 和最相关片段；不是必须读满 3 个完整页面。
- 预计超过 2k tokens 时，先说明读取范围和原因，再继续。
- 2k 预算只统计 Memory OS 自身正文内容，不包含 gate、业务项目代码、diff、报错日志、接口文档、终端输出、用户当前对话或 Codex 系统上下文。
- MemoryOS 维护、weekly audit、proposal 晋升、skill 晋升等任务可临时放宽到 5k-8k tokens，但必须说明范围，并避免一次性展开无关候选 skills、历史日志或 proposal 堆积内容。
