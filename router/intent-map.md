# Intent Map

## task_type

- explain：解释概念、代码、报错。
- debug：排查问题、定位原因、给修复路径。
- implement：修改代码或生成脚本。
- review：代码审查，优先输出风险和问题。
- architecture：技术选型、重构、系统设计。
- retrospective：沉淀经验、生成 proposal。
- maintenance：审计、清理、晋升 Memory OS 内容。

## Routing Rules

- 用户不需要声明任务简单或复杂；先通过 Memory OS Gate 自动判断是否需要长期工程记忆参与。
- 当前阶段优先扩大真实任务输入：L1 轻量 workflow / skill 默认倾向触发；L2 正文读取和 L3 写入继续保守。
- L0：仅用于纯解释、纯问答、无文件改动、无决策影响的任务，不读 Memory OS 正文。
- L1：轻量 workflow / skill 默认倾向触发，但不读 Memory OS 正文。适用于 diff review、提交前自检、普通 bugfix 后回归检查、实现功能后的风险扫描、排错结束后的可复用经验判断、任务结束后的轻量 retrospective、修改配置/脚本/接口字段/路由/权限/构建入口时的轻量风险检查。
- L2：读取 `_index.md` + 最多 3 个直接相关页面。适用于架构决策、跨模块重构、复杂排错、CI/CD、安全权限、发布流程、长期规范、影响面大的 review。
- L3：写入 `proposals/pending/`。仅当用户明确要求沉淀、复盘、更新 Memory OS、生成 proposal，或用户确认沉淀建议。
- 读取 Memory OS 不等于写入；写入必须是用户明确要求或确认后的 `proposals/pending/`。
- 低置信度：先问清关键前提，不扩大读取。
