# Skills

这里保存模型无关的 skill 规格，不等于 Codex 自动发现的 skills。

Codex Desktop 自动发现入口是：

- `C:\Users\btf\.codex\skills`

MemoryOS 源目录是：

- `C:\Users\btf\AI-MemoryOS\adapters\codex\skills`

当前只映射 active skills：

- memory-curator
- routing-auditor
- bugfix-with-regression-test
- frontend-component-review
- git-ops-guide
- pr-review
- vue-change-self-check

## Shared Skill Specs

模型无关的核心逻辑放在 `skills/<skill>/SKILL_SPEC.md`。当 `skills/registry.json` 中某个 skill 标记为 `managed: true` 时，Codex / Claude adapter 的 `SKILL.md` 应由 `tools/sync-skills.ps1` 生成，不要手写两份完整内容。

当前 managed active skills：

- `memory-curator`
- `routing-auditor`
- `bugfix-with-regression-test`
- `frontend-component-review`
- `pr-review`
- `vue-change-self-check`
- `git-ops-guide`

修改 managed skill 的流程：

1. 修改 `skills/<skill>/SKILL_SPEC.md` 或 `skills/registry.json` 中的 adapter 外壳字段。
2. 运行 `tools/sync-skills.ps1 -Skill <skill>`，或运行 `tools/sync-skills.ps1` 同步全部 managed skills。
3. 运行 `tools/validate-memory-os.ps1`。
4. 如触发边界变化，更新 `evals/skill-trigger-test-cases.md`。

其他 skill 先作为候选规格保留，等真实任务验证后再通过 junction 映射到 Codex Desktop。

## Claude Code Skills

Claude Code uses a separate adapter-specific skill source:

- `C:\Users\btf\AI-MemoryOS\adapters\claude\skills`

Claude Code discovers active skills from:

- `C:\Users\btf\.claude\skills`

The Claude discovery directory uses junctions to the repository source, just like Codex. Generated Claude and Codex `SKILL.md` files stay separate, but their core logic comes from the same managed shared specs.

Current active Claude skills:

- memory-curator
- routing-auditor
- bugfix-with-regression-test
- frontend-component-review
- pr-review
- vue-change-self-check
- git-ops-guide
