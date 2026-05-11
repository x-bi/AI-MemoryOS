# Routing Rules

1. 先判断用户目标，不按关键词机械触发。
2. 普通任务不读 AI Memory OS。
3. 复杂任务最多读取 `_index.md` + 3 个直接相关文件。
4. retrospective / maintenance 可以读取相关规则，但只写 pending proposal。
5. 路由误判只能基于真实案例更新。
