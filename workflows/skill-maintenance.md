---
source_episode: conversation:2026-06-11;report:self-optimize-2026-06-09;report:self-optimize-2026-06-10
---
# Skill Maintenance Workflow

## Trigger

Use this workflow when the user asks to add, modify, rename, delete, sync, or check a Memory OS managed skill, or when the task directly changes:

- `skills/<skill>/SKILL_SPEC.md`
- `skills/registry.json`
- `adapters/<adapter>/templates/skill.md.tmpl`
- `tools/sync-skills.ps1`
- generated adapter skill outputs through the sync script

Do not use this workflow when:

- the user only wants to use an existing skill.
- "skill" refers to an app or business feature outside Memory OS adapter skills.
- the task object is `proposals/pending/*` and the user asks to review, accept, reject, promote, or land a proposal. In that case, `workflows/proposal-promotion.md` remains the primary workflow.
- the task is a normal diff review, pre-commit self-check, or bugfix unrelated to Memory OS managed skills.

## Source Of Truth

- Shared skill semantics live in `skills/<skill>/SKILL_SPEC.md`.
- Skill metadata and adapter outputs live in `skills/registry.json`.
- Adapter recognition shells live in `adapters/<adapter>/templates/skill.md.tmpl`.
- Adapter `SKILL.md` files are generated artifacts. Do not edit them by hand.

## Steps

1. Identify the intended operation: add, modify, rename, delete, sync, or check.
2. Read `skills/registry.json` and the directly relevant `skills/<skill>/SKILL_SPEC.md`.
3. If changing an adapter shell, read the relevant `adapters/<adapter>/templates/skill.md.tmpl`.
4. Edit only the source files: shared spec, registry, adapter template, workflow/router/eval/dashboard as needed.
5. Run the scoped sync command:

```powershell
pwsh tools/sync-skills.ps1 -Skill <skill>
pwsh tools/sync-skills.ps1 -Adapter <adapter>
```

6. Run the scoped check command:

```powershell
pwsh tools/sync-skills.ps1 -Skill <skill> -Check
pwsh tools/sync-skills.ps1 -Adapter <adapter> -Check
```

7. Run the repository validation when the change affects shared behavior:

```powershell
pwsh tools/validate-memory-os.ps1
```

8. If adding, deleting, or renaming a user-triggerable skill, update router and eval coverage:

- `router/skill-map.md` for skill trigger boundaries.
- `evals/skill-trigger-test-cases.md` for skill trigger behavior.
- `router/workflow-map.md` and `evals/router-test-cases.md` only when workflow routing changes.

9. If deleting or renaming, first check references in router, workflows, dashboard, evals, registry, and adapter output paths. Do not let the sync script silently delete unrelated files.

## Output

- Summarize source files changed.
- Report sync/check/validate commands run and their results.
- Call out any generated adapter `SKILL.md` files changed by `tools/sync-skills.ps1`.
