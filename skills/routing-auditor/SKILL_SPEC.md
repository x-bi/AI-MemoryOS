# Routing Auditor

Audit Memory OS routing without bypassing proposal review.

## Workflow

1. Confirm the user is asking about AI Memory OS routing, not application routes.
2. Read `C:\Users\btf\AI-MemoryOS\_index.md`.
3. Read `C:\Users\btf\AI-MemoryOS\router\intent-map.md` and only directly relevant router/domain/skill pages or eval notes.
4. Identify the misclassification pattern: task level, intent, domain, skill trigger, read budget, or write boundary.
5. Collect concrete examples and explain why the current route is wrong or ambiguous.
6. Propose a minimal correction that preserves existing safety boundaries.
7. Create a pending router correction proposal only when the user asks for a proposal or confirms the change should be captured.
8. Do not directly modify formal router files, rules, skills, or evals unless the user explicitly enters maintenance or promotion mode.

## MCP Use

Prefer `ai_memoryos` MCP tools when available:

- Search before reading broad areas.
- Read only `_index.md` plus directly relevant router pages.
- Write only to `proposals/pending/` unless the user explicitly directs a formal maintenance edit and the repository rules allow it.

## Output

For an audit, use:

1. Routing issue
2. Evidence
3. Proposed correction
4. Pending proposal recommendation
5. Files read

For a proposal, include:

- Title
- Misclassification example
- Current behavior
- Desired behavior
- Proposed router/skill/domain change
- Safety and regression notes

## Boundaries

- Do not scan all Memory OS content by default.
- Do not read `raw/`, `proposals/accepted/`, or `proposals/rejected/` unless the user asks or the route issue requires it.
- Do not store private examples, secrets, or unredacted project data in proposals.
