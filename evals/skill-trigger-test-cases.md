# Skill Trigger Test Cases

| Input | Expected Skill | Should Trigger | Reason |
|---|---|---|---|
| 这次经验沉淀一下 | memory-curator | yes | 明确要求沉淀 |
| 普通解释一下这个报错 | none | no | 解释任务不该触发记忆 |
| 帮我审一下这个前端组件 | frontend-component-review | yes | 明确前端组件 review |
| 这个 bug 修完加个回归测试 | bugfix-with-regression-test | yes | bugfix + regression |
| 刚才你的路由判断错了 | routing-auditor | yes | 明确纠正路由误判 |
| 帮我规划功能实现 | none | no | feature-planning 仍是候选，未自动暴露 |
| 检查 CI 流水线 | none | no | ci-pipeline-review 仍是候选，未自动暴露 |