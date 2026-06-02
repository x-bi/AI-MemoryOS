# Intent Map

## task_type

- explain：解释概念、代码、报错。
- debug：排查问题、定位原因、给修复路径。
- implement：修改代码或生成脚本。
- review：代码审查，优先输出风险和问题。
- architecture：技术选型、重构、系统设计。
- retrospective：沉淀经验、生成 proposal。
- maintenance：审计、清理、晋升 Memory OS 内容。

## Notes

- L0-L3 定义和 L1/L2 策略偏好由各适配器 gate 文件自行管理，本文件不重复。
- 先判断用户目标，不按关键词机械触发 task_type。
- 只有缺少关键环境信息会导致方案错误、多个执行路径风险差异明显，或用户要求修改代码/配置但目标不明确时，才先反问。
- 低置信度：先问清一个关键前提，不扩大读取。
- 路由误判只能基于真实案例更新，不靠想象扩写规则。
