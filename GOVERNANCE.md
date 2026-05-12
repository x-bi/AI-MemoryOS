# Governance 治理规则

## 事实源

正式长期记忆以本仓库 Markdown + Git 为事实源。Codex 内建 memories 只能作为辅助召回，不作为正式规则来源。

## 写入规则

- 默认不写入长期记忆。
- 新经验只能先进入 `proposals/pending/`。
- 人工审核后，才可晋升到 rules / wiki / router / skills / evals。
- accepted / rejected 都要保留原因。

## 晋升条件

一条 proposal 至少满足一项：

- 跨项目重复出现。
- 能减少明确的重复错误。
- 能改善 review / debug / testing 的稳定性。
- 能降低路由误判或技能误触发。

## 拒绝条件

- 只适用于单个项目。
- 没有真实案例支撑。
- 过度抽象或泛化。
- 包含敏感信息。
- 与项目本地事实冲突。

## 审计节奏

- 每周：pending proposals、重复项、明显过期项。
- 每月：stale / duplicate / conflicting memory、skills description 重叠、router 臃肿。