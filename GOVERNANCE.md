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

不再强制周审/月审节奏。单人维护下，强制日历节奏会变成自我负担且容易空跑。改为**按需 + 触发条件审计**，触发任一即执行一次：

- `proposals/pending/` 堆积超过 5 条或最旧条目超过 14 天未处理。
- 同一类路由误判在 `evals/router-correction-cases.md` 中累计 ≥ 3 条。
- 出现冲突或过期内容（被新 proposal 推翻、与项目本地事实冲突、reference 链接失效）。
- skill description 重叠或误触发被实际命中。
- 跨项目重复出现的反模式 ≥ 2 次。
- future direction notes 出现可拆解信号（已具备落地 proposal、设计文档或迁移计划的条件）。
- 基础设施/工具集成出现 P0/P1 事件，且未在 changelog 留痕。
- 用户主动要求一次集中审计或 self-optimize 复盘。

P2 日常操作不要求留痕，也不触发审计。

## 审计记录

- 触发条件命中时生成 `logs/audits/YYYY-MM-DD.md`，优先从 `templates/weekly-audit.md` 复制（模板名保留，模板内容仍可复用）。
- 审计记录至少包含：触发条件、pending 数量与处理动作、晋升/拒绝候选、future direction 回顾候选、冲突或过期内容、后续动作。
- 修改正式 rules / router / skills / evals 时，同步在审计或变更记录中留下原因和影响范围。
