# Routing Rules

## Memory OS Gate

每个用户输入先做轻量边界判定，但判定本身不要读取 AI Memory OS。

- 如果任务只是解释、普通排错、小范围实现，或当前项目上下文已经足够，直接正常处理，不读取 AI Memory OS。
- 如果任务需要长期工程记忆参与判断，可以读取 AI Memory OS。
- 读取入口固定为 `_index.md`，最多再读 3 个直接相关文件。
- 读取 AI Memory OS 不等于写入记忆。
- 只有用户明确要求沉淀、复盘、更新 Memory OS、生成 proposal，或用户确认沉淀建议后，才写入 `proposals/pending/`。

## Read Boundary

满足任一条件，可以自动读取 AI Memory OS：

- 架构决策、技术选型、系统设计。
- 跨模块、跨端、跨服务、跨仓库影响。
- 重构、迁移、兼容性或回归风险评估。
- 多轮复杂排错，且可能关联历史约定或长期规范。
- 安全、权限、CI/CD、发布流程等高风险工程流程。
- 制定或调整长期规范、workflow、router、skill、eval。
- Memory OS 自身维护、审计、proposal 晋升。

以下情况默认不读取 AI Memory OS：

- 单点概念、命令、报错、API 用法解释。
- 局部 bug 排查或小范围代码修改。
- 当前项目代码、日志、报错已经足够判断。
- 一次性脚本、临时问题或没有明显复用价值的任务。

## Routing Order

1. 先判断用户目标，不按关键词机械触发。
2. 再做 Memory OS Gate，决定是否需要读取。
3. 再判断 task_type：explain / debug / implement / review / architecture / retrospective / maintenance。
4. 再判断 domain：frontend / testing / backend / scripting / devops / security。
5. 再选择 workflow / skill / markdown。
6. 低置信度时先问一个关键问题，不扩大读取。
7. 路由误判只能基于真实案例更新。
