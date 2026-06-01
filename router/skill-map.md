# Skill Map

| Skill | Use When | Do Not Use When |
|---|---|---|
| memory-curator | 用户明确要求复盘、沉淀、更新 Memory OS | 普通编码、解释、排错 |
| routing-auditor | 用户明确要求路由审计或纠正误判 | 一般任务分类 |
| pr-review | 用户要求 review PR、commit、diff、staged changes、当前改动风险、提交前代码审查 | 只解释代码、只实现功能、没有变更范围的泛泛讨论 |
| bugfix-with-regression-test | 修 bug 且需要防回归 | 只解释报错 |
| frontend-component-review | 审查前端组件、交互、表单流程 | 非前端任务 |
| vue-change-self-check | Vue / uni-app / frontend 改动需要提交前自检、diff 风险扫描、编号风险清单；用户要求检查当前改动、未提交改动、staged changes、commit、diff、提交前检查，且当前仓库或轻量 diff 文件列表命中 `.vue`、`pages.json`、`manifest.json`、前端路由/页面/导航配置、uni-app 分包页面等信号时，也应触发 | 普通 bug 修复、非前端任务、只审查单个组件交互、纯解释任务、用户要求直接实现或修 bug 而不是先做自检 |
| git-ops-guide | 用户询问该用什么 Git 命令、命令顺序、想要某个 Git 结果但不确定步骤、或就 reset / revert / rebase / restore / branch / commit / pull / push / merge / stash / clean 等危险操作请求安全指导 | 用户要求 Claude 直接执行 Git 命令（应直接执行而不是讲解） |

原则：当前阶段优先扩大真实任务输入；L1 轻量 workflow / review skill 默认倾向触发，用于收集真实案例；读取 Memory OS 正文和写入 proposal 仍保持保守。

当 `pr-review` 与 `vue-change-self-check` 同时命中时，二者不是互斥关系。最终输出优先使用 `vue-change-self-check` 的四段式结构：变更影响扫描、风险清单、建议验证路径、本次未覆盖盲区；通用 review 发现并入稳定编号风险清单。

对“检查改动 / diff / commit / staged changes”类请求，允许先读取轻量变更范围（如 `git diff --name-only`、`git diff --stat`、`git show --name-only --stat <commit>`、`git status --short`）再补判是否触发前端 self-check。该预读只用于识别文件类型和范围，不默认打开大量源码，也不读取私有 overlay。
