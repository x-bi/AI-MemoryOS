# Governance 治理规则

## 事实源

正式长期记忆以本仓库 Markdown + Git 为事实源。Codex 内建 memories 只能作为辅助召回，不作为正式规则来源。

## 写入规则

- 默认不写入长期记忆。
- 新经验只能先进入 `proposals/pending/`。
- 人工审核后，才可晋升到 rules / wiki / router / skills / evals。
- accepted / rejected 都要保留原因。
- `proposals/future-directions/` 用于重大方向说明和长期架构意图，不是 pending proposal 队列。
- future direction note 只能在用户明确要求记录长期方向、架构意图或进入维护模式时创建；它不直接晋升为正式规则。
- 当 future direction note 准备落地时，必须再拆成具体 proposal、设计文档、迁移计划或任务清单。

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
- 每月或专题：future direction notes 是否仍有效、是否需要拆出具体 proposal 或迁移计划。
- 每月：stale / duplicate / conflicting memory、skills description 重叠、router 臃肿。

- 基础设施/工具集成事件审计：检查 P0/P1 集成事件是否有对应 changelog 条目；P2 日常操作不要求留痕。

## 审计记录

- 每次审计生成 `logs/audits/YYYY-MM-DD.md`，优先从 `templates/weekly-audit.md` 复制。
- 审计记录至少包含 pending 数量、晋升/拒绝候选、future direction 回顾候选、冲突或过期内容、后续动作。
- 修改正式 rules / router / skills / evals 时，同步在审计或变更记录中留下原因和影响范围。
