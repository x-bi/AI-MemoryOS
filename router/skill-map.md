# Skill Map

| Skill | Use When | Do Not Use When |
|---|---|---|
| memory-curator | 用户明确要求复盘、沉淀、更新 Memory OS | 普通编码、解释、排错 |
| routing-auditor | 用户明确要求路由审计或纠正误判 | 一般任务分类 |
| pr-review | 用户要求 review PR、commit、diff、staged changes、当前改动风险、提交前代码审查 | 只解释代码、只实现功能、没有变更范围的泛泛讨论 |
| bugfix-with-regression-test | 修 bug 且需要防回归 | 只解释报错 |
| frontend-component-review | 审查前端组件、交互、表单流程 | 非前端任务 |
| vue-change-self-check | Vue / uni-app / frontend 改动需要提交前自检、diff 风险扫描、编号风险清单 | 普通 bug 修复、非前端任务、只审查单个组件交互 |

原则：当前阶段优先扩大真实任务输入；L1 轻量 workflow / review skill 默认倾向触发，用于收集真实案例；读取 Memory OS 正文和写入 proposal 仍保持保守。
