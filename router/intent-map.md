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
- 普通 explain/debug/small implement：不读 Memory OS。
- architecture/review 且影响面大：可读 `_index.md`。
- 跨模块重构、复杂排错、CI/CD、安全权限、长期规范：可读 `_index.md`。
- retrospective/maintenance：按需读相关页面。
- 读取 Memory OS 不等于写入；写入必须是用户明确要求或确认后的 `proposals/pending/`。
- 低置信度：先问清关键前提，不扩大读取。
