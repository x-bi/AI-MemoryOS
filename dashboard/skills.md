# Skills

## Maintenance Commands

```powershell
pwsh tools/sync-skills.ps1
pwsh tools/sync-skills.ps1 -Check
pwsh tools/sync-skills.ps1 -Skill memory-curator
pwsh tools/sync-skills.ps1 -Skill memory-curator -Check
pwsh tools/sync-skills.ps1 -Adapter codex
pwsh tools/sync-skills.ps1 -Adapter codex -Check
pwsh tools/validate-memory-os.ps1
```

## Maintenance Rules

- Edit shared skill behavior in `skills/<skill>/SKILL_SPEC.md`.
- Edit trigger description and adapter output metadata in `skills/registry.json`.
- Edit adapter recognition shells in `adapters/<adapter>/templates/skill.md.tmpl`.
- Do not hand-edit `adapters/<adapter>/skills/<skill>/SKILL.md`; run `tools/sync-skills.ps1`.
- Use `tools/sync-skills.ps1 -Check` to detect generated output drift without writing files.

## Add Skill Checklist

1. Create `skills/<name>/SKILL_SPEC.md`.
2. Add the managed skill entry to `skills/registry.json`.
3. Run `pwsh tools/sync-skills.ps1 -Skill <name>`.
4. Run `pwsh tools/sync-skills.ps1 -Skill <name> -Check`.
5. If user-triggerable, update `router/skill-map.md` and `evals/skill-trigger-test-cases.md`.
6. Run `pwsh tools/validate-memory-os.ps1`.

## Modify Skill Checklist

1. Modify `skills/<skill>/SKILL_SPEC.md` or `skills/registry.json`.
2. Run `pwsh tools/sync-skills.ps1 -Skill <skill>`.
3. Run `pwsh tools/sync-skills.ps1 -Skill <skill> -Check`.
4. Run `pwsh tools/validate-memory-os.ps1`.

## Adapter Template Checklist

1. Modify `adapters/<adapter>/templates/skill.md.tmpl`.
2. Keep the first frontmatter shell compatible with the adapter skill discovery format.
3. Run `pwsh tools/sync-skills.ps1 -Adapter <adapter>`.
4. Run `pwsh tools/sync-skills.ps1 -Adapter <adapter> -Check`.
5. Run `pwsh tools/validate-memory-os.ps1`.

## Active Codex Skills

```dataview
TABLE file.folder AS folder
FROM "adapters/codex/skills"
WHERE file.name = "SKILL"
SORT file.folder ASC
```

## Skill Specs

```dataview
TABLE file.folder AS folder
FROM "skills"
WHERE file.name = "SKILL_SPEC"
SORT file.folder ASC
```

- [[skills/catalog]]
