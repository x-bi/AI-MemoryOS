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

1. 先写 `proposals/pending/`。
2. 人工审核 scope、重复、过期、风险。
3. 通过后晋升到 rules / wiki / router / skills / evals。
4. 更新 changelog。
