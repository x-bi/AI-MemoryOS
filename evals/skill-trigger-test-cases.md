# Skill Trigger Test Cases

| Input | Expected Skill | Should Trigger | Reason |
|---|---|---|---|
| 这次经验沉淀一下 | memory-curator | yes | 明确要求沉淀 |
| 普通解释一下这个报错 | none | no | 解释任务不该触发记忆 |
| 帮我审一下这个前端组件 | frontend-component-review | yes | 明确前端组件 review |
| 这个 bug 修完加个回归测试 | bugfix-with-regression-test | yes | bugfix + regression |
| 刚才你的路由判断错了 | routing-auditor | yes | 明确纠正路由误判 |
| 检查当前 Vue 改动有没有回归风险 | vue-change-self-check | yes | Vue diff self-check |
| 处理 #2 | vue-change-self-check | yes | 延续上一轮编号风险处理 |
| 帮我规划功能实现 | none | no | feature-planning 仍是候选，未自动暴露 |
| 检查 CI 流水线 | none | no | ci-pipeline-review 仍是候选，未自动暴露 |
| 这个模块要不要拆成独立包 | none | no | 可触发 Memory OS 读取，但不等于触发写入类 skill |
| 这个 bug 修法会不会影响其他页面 | frontend-component-review | yes | 明确前端影响面 review，而不是 memory-curator |
| 这个经验以后怎么沉淀 | memory-curator | yes | 明确要求沉淀经验 |
| 这是复杂任务，帮我判断方案 | none | no | 复杂任务可读 Memory OS，但不自动写记忆 |
| 把这次路由误判整理成 proposal | routing-auditor | yes | 明确要求路由纠正 proposal |
