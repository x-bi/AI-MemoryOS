# Memory OS Lite Index

This is the Lite package content index. Read it after the adapter gate says Lite content is needed.

The adapter gate decides the level and read/write boundary. This index only points to the minimum runtime content.

## Read Order

1. `adapters/<adapter>/bootstrap.md`: lightweight entry loaded from the user entry file.
2. `adapters/<adapter>/gate.md` or `adapters/<adapter>/CLAUDE.md`: full Lite runtime policy.
3. `_index.md`: this file, used before reading router, workflow, domain, or skill content.
4. `router/intent-map.md`: task type.
5. `router/domain-map.md`: domain hints.
6. `router/workflow-map.md`: workflow selection.
7. `router/skill-map.md`: skill selection.

After routing, read only the directly relevant workflow, domain, or skill files.

## Runtime Content

- `core/usage-rules.md`: short Lite usage boundary.
- `core/safety-rules.md`: secret, private-file, and external-context safety rules.
- `router/`: task, domain, workflow, and skill maps.
- `domains/`: lightweight domain notes for frontend, testing, backend, scripting, DevOps, and security.
- `workflows/`: reusable task workflows.
- `skills/registry.json`: Lite skill registry.
- `skills/<skill>/SKILL_SPEC.md`: shared skill instructions rendered to each adapter.

## Adapter Content

- `adapters/codex/bootstrap.md`
- `adapters/codex/gate.md`
- `adapters/codex/skills/`
- `adapters/claude/bootstrap.md`
- `adapters/claude/CLAUDE.md`
- `adapters/claude/skills/`

## Excluded From Lite

Lite does not include the full maintenance repository's governance and operations surfaces:

- proposal promotion and accepted / rejected history.
- dashboard, Obsidian, MCP server, CodeGraph management, eval suites, audits, self-optimize, or changelog companions.
- Write Companions or Cross-Adapter Sync governance.

Do not search for these surfaces during normal Lite runtime tasks.
