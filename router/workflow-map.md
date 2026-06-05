# Workflow Map

| Signal | Workflow | Use When | Do Not Use When |
|---|---|---|---|
| CoDesign / Lanhu / Figma / Axure / 原型 / 设计稿 / iframe + 后续开发 / 页面还原 | `workflows/frontend-prototype-driven-development.md` | 用户要求读取原型、设计稿或浏览器内嵌 iframe，并以后续开发、页面实现、页面还原、弹窗/表单/表格开发为目标 | 只解释字段含义、纯接口联调、纯代码 bugfix，且用户没有要求按原型还原页面 |
| CodeGraph / 项目图 / graph / 调用链 / 影响面 / 架构定位 + CodeGraph enabled | `workflows/codegraph-assisted-project-analysis.md` | 用户要求使用或准备 CodeGraph，或任务需要大型项目结构、调用链、caller/callee、影响面、架构定位，且 CodeGraph 对当前项目启用 | 用户明确跳过 CodeGraph；当前项目未启用或准备失败；单文件/小范围问题可直接读源码 |
| review diff / PR / commit / staged changes / current changes | `workflows/diff-review-lite.md` | 用户要求审查 diff、PR、commit、staged changes 或当前代码改动，且不是广泛架构审查 | 用户要求直接实现功能；用户要求提交前自检时优先考虑 `pre-commit-self-check.md` 或相关 skill；diff 涉及跨模块契约、安全、权限、发布流、共享基础设施或长期规则时升级 L2 |
| 前端改动 + 回归验证 / 构建触发 / 验证副作用 / 平台验证 | `workflows/frontend-regression-verification-strategy.md` | 前端代码修改后需要选择最小验证路径、判断是否构建/测试、控制验证副作用 | 非前端任务；纯解释；用户已经明确指定具体验证命令且无需策略判断 |
| 复盘 / 沉淀 / 写入记忆 / 更新 Memory OS / 生成 proposal | `workflows/memory-retrospective.md` | 用户明确要求复盘、沉淀经验、写入记忆、更新 Memory OS 或生成 pending proposal | 任务结束后只是可能有经验但用户未要求写入时，用 `retrospective-lite.md` |
| 提交前检查 / 自检 / regression scan / look over current changes before commit | `workflows/pre-commit-self-check.md` | 用户要求提交前检查、自检当前改动、回归风险扫描或提交前看一遍改动 | 用户要求正式 review PR/diff 时可优先用 `diff-review-lite.md` 或 review skill；用户要求直接实现功能时不触发；改动触及路由/配置/构建入口/公共契约/安全/权限/共享模块时升级 L2 |
| 落地 pending / 晋升 proposal / accept proposal / reject proposal | `workflows/proposal-promotion.md` | 用户要求把 pending proposal 落地、晋升到正式规则、接受或拒绝 proposal | 只要求生成 pending proposal 时，用 `memory-retrospective.md` / memory-curator 边界；晋升 skill 类 proposal 时不要直接编辑 adapter SKILL.md，应走 `sync-skills.ps1` |
| weekly audit / 审计 pending / 清理重复或冲突 Memory OS 内容 | `workflows/weekly-audit.md` | 用户要求做 Memory OS 周审计、pending 审计、重复/冲突/过期内容检查 | 普通代码 review、自检、单个 proposal 生成或晋升；审计时不要直接删除正式规则/路由/skill 内容，只输出审计报告和清理 proposal |
| 任务结束后可能有可复用经验，但用户未明确要求写入 | `workflows/retrospective-lite.md` | 完成任务后发现可能存在跨项目或重复可用经验，需要判断是否建议 capture | 用户明确要求写入、更新 Memory OS、生成 proposal 时，用 `memory-retrospective.md`；无可复用经验时不触发 |
| refactor / 重构 / 整理结构 / 降低复杂度 + 行为不变或风险控制 | `workflows/refactor-with-safety.md` | 用户要求重构、整理代码结构、降低复杂度，并需要控制行为变化风险 | 普通小修、小功能实现、纯解释、无重构目标 |
| 脚本 / 批处理 / 文件处理 / 自动化 + 输入输出副作用 | `workflows/script-automation.md` | 用户要求编写或修改脚本、批处理、文件处理或自动化流程，且需要确认输入、输出、副作用和失败策略 | 一行命令解释；普通应用代码实现；没有副作用风险的简单命令 |
| 测试策略 / 覆盖方案 / 回归保护 / 单测集成 E2E 选择 | `workflows/test-strategy.md` | 用户询问测试策略、覆盖层级、回归保护或如何选择单测/集成测试/E2E | 用户只要求直接修 bug 或已有明确测试实现路径时，按具体 bugfix/test workflow 或 skill 处理 |
