# Routing Rules

## Memory OS Gate

Codex 每个输入先读取 `adapters/codex/gate.md` 做轻量边界判定。读取 gate 只用于加载运行策略，不等于读取 Memory OS 正文。

- L0：纯解释、纯问答、无文件改动、无决策影响，读 gate 后直接处理，不读取 Memory OS 正文。
- L1：轻量 workflow / skill 默认倾向触发，不读取 Memory OS 正文，用于扩大真实任务样例。
- L2：任务需要长期工程记忆参与时，读取入口固定为 `_index.md`，最多再读 3 个直接相关文件。
- L3：只有用户明确要求沉淀、复盘、更新 Memory OS、生成 proposal，或用户确认沉淀建议后，才写入 `proposals/pending/`。
- 读取 AI Memory OS 不等于写入记忆。

## Read Boundary

满足任一条件，可以进入 L2 并自动读取 Memory OS 正文：

- 架构决策、技术选型、系统设计。
- 跨模块、跨端、跨服务、跨仓库影响。
- 重构、迁移、兼容性或回归风险评估。
- 多轮复杂排错，且可能关联历史约定或长期规范。
- 安全、权限、CI/CD、发布流程等高风险工程流程。
- 制定或调整长期规范、workflow、router、skill、eval。
- Memory OS 自身维护、审计、proposal 晋升。

以下情况只停留在 L0/L1，不读取 Memory OS 正文：

- 单点概念、命令、报错、API 用法解释。
- 局部 bug 排查或小范围代码修改，但可触发 L1 轻量风险检查。
- 当前项目代码、日志、报错已经足够判断。
- 一次性脚本、临时问题或没有明显复用价值的任务。

## Routing Order

1. 先判断用户目标，不按关键词机械触发。
2. 再按 gate 做 Memory OS Gate，决定 L0/L1/L2/L3。
3. 再判断 task_type：explain / debug / implement / review / architecture / retrospective / maintenance。
4. 再判断 domain：frontend / testing / backend / scripting / devops / security。
5. 再选择 workflow / skill / markdown。
6. 低置信度时先问一个关键问题，不扩大读取。
7. 路由误判只能基于真实案例更新。
