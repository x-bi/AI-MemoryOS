# Skill Trigger Test Cases

| Input | Expected Skill | Should Trigger | Reason |
|---|---|---|---|
| 这次经验沉淀一下 | memory-curator | yes | 明确要求沉淀 |
| 普通解释一下这个报错 | none | no | 解释任务不该触发记忆 |
| 帮我 review 一下当前 diff | pr-review | yes | 明确要求审查当前变更 |
| 看一下 staged changes 有没有明显问题 | pr-review | yes | 提交前代码审查入口 |
| 解释一下这个函数为什么这么写 | none | no | 解释代码不等于 PR review |
| 实现完这个功能后扫一遍风险 | pr-review | yes | L1 功能完成后的风险扫描入口 |
| 改了接口字段，帮我看下影响 | pr-review | yes | L1 字段契约影响检查 |
| 修改配置后提交前检查一下 | pr-review | yes | L1 配置变更提交前风险检查 |
| 帮我审一下这个前端组件 | frontend-component-review | yes | 明确前端组件 review |
| 这个 bug 修完加个回归测试 | bugfix-with-regression-test | yes | bugfix + regression |
| 刚才你的路由判断错了 | routing-auditor | yes | 明确纠正路由误判 |
| 检查当前 Vue 改动有没有回归风险 | vue-change-self-check | yes | Vue diff self-check |
| 处理 #2 | vue-change-self-check | yes | 延续上一轮编号风险处理 |
| git reset --soft HEAD~1 是什么意思 | git-ops-guide | yes | 解释具体 Git 命令但不执行 |
| 我想撤销刚刚的 commit 但保留改动，应该怎么做 | git-ops-guide | yes | 用户需要 Git 命令顺序指导 |
| 帮我执行 git status | none | no | 用户要求执行命令，不是只要 Git 指导 |
| 帮我规划功能实现 | none | no | feature-planning 仍是候选，未自动暴露 |
| 检查 CI 流水线 | none | no | ci-pipeline-review 仍是候选，未自动暴露 |
| 这个模块要不要拆成独立包 | none | no | 可触发 Memory OS 读取，但不等于触发写入类 skill |
| 这个 bug 修法会不会影响其他页面 | frontend-component-review | yes | 明确前端影响面 review，而不是 memory-curator |
| 这个经验以后怎么沉淀 | memory-curator | yes | 明确要求沉淀经验 |
| 这是复杂任务，帮我判断方案 | none | no | 复杂任务可读 Memory OS，但不自动写记忆 |
| 把这次路由误判整理成 proposal | routing-auditor | yes | 明确要求路由纠正 proposal |
| 检查 Memory OS 的 MCP 权限有没有漏洞 | none | no | 这是维护/安全实现检查，不等于触发 memory-curator |
| 给 Memory OS 做一次 weekly audit | none | no | 需要 L2 读取治理材料，但没有明确要求沉淀 proposal |
| Codex 和 Claude 的 Memory OS 接入是不是漂移了 | none | no | adapter drift 检查不是现有单一 skill 的触发边界 |
| Memory OS 里会不会误存 token 或客户日志 | none | no | 安全审计应先检查规则和实现，不自动写记忆 |
| 把这次 MCP 权限加固经验沉淀成 proposal | memory-curator | yes | 明确要求沉淀为 pending proposal |
