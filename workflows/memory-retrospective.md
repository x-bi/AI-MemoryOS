# Memory Retrospective Workflow

## Trigger

仅当用户明确要求“复盘、沉淀、写入记忆、更新 Memory OS、生成 proposal”时使用。

## Steps

1. 总结本次任务中的可复用经验。
2. 判断是否跨项目有效。
3. 检查是否包含敏感或项目私有内容。
4. 选择目标类型：rule / workflow / domain / stack / skill / router / eval。
5. 只生成 pending proposal。
6. 不直接晋升正式内容。

如果目标类型是 skill，proposal 应指向 `skills/<skill>/SKILL_SPEC.md` 或 `skills/registry.json`；adapter `SKILL.md` 由 `tools/sync-skills.ps1` 生成，不作为手工晋升目标。

## Output

写入 `proposals/pending/YYYY-MM-DD-short-title.md`。
