# Proposal Promotion Workflow

## Input

- `proposals/pending/` 中的 proposal。
- 相关 rules / workflow / domain / router / skill / eval 文件。
- 如果 proposal 涉及 skill，`skills/registry.json` 和 `skills/<skill>/SKILL_SPEC.md` 是事实源；adapter `SKILL.md` 文件由 `tools/sync-skills.ps1` 生成。

## Review Checklist

- scope 是否正确。
- 是否有真实案例支撑。
- 是否过度泛化。
- 是否重复或冲突。
- 是否包含敏感信息。
- 是否有明确目标落点。

## Source Episode Preservation 溯源链保留

晋升时必须保留 pending proposal 的溯源信息，确保知识从源头可追溯：

1. **frontmatter `source_episode` 字段**：晋升到 `proposals/accepted/` 时原样保留。
2. **晋升到 wiki/domain 页面**：在目标页面 frontmatter 中增加 `source_episode` 字段，值与原 proposal 一致。
3. **source_episode 格式**：`<类型>:<标识>`，例如：
   - `conversation:2026-06-02` — 源自某次对话
   - `issue:#42` — 源自某个 issue
   - `commit:8175367` — 源自某个 commit
   - `bug:vue-uni-app-self-check-not-triggered` — 源自某个 bug
   - 多个来源用分号分隔，如 `conversation:2026-06-02;commit:8175367`
4. **晋升前检查**：如果 pending proposal 的 `source_episode` 为空，审核时应要求补充后再晋升（紧急修复可豁免，但需在 accepted 文件中注明 `source_episode: exempt`）。

## Outcomes

- accept：移动到 `proposals/accepted/`，保留 `source_episode`，并修改目标文件（目标文件也保留 `source_episode`）。
- reject：移动到 `proposals/rejected/`，写明原因。
- defer：保留 pending，补充需要验证的信息。

## Skill Promotion

晋升 skill 相关 proposal 时：

1. 修改 `skills/<skill>/SKILL_SPEC.md` 或 `skills/registry.json`。
2. 运行 `tools/sync-skills.ps1` 同步 Codex / Claude adapter 外壳。
3. 运行 `tools/validate-memory-os.ps1` 验证 source hash 和注册表一致性。
4. 不直接手写 `adapters/*/skills/*/SKILL.md`；这些文件会被同步脚本覆盖。

## Required Logs

Before promoting `proposals/pending/*.md` to `proposals/accepted/`, read `core/change-companions.md` and apply the proposal-promotion row.

At minimum, promotion must preserve `source_episode`, land the target files, and write the required changelog entries. If the proposal fixes routing drift or changes router/eval behavior, update the relevant router correction or trigger eval in the same task.
