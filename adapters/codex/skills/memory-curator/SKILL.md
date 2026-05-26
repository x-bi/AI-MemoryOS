---
name: memory-curator
description: "Use when the user explicitly asks to capture reusable lessons, update Memory OS, create a memory proposal, or do a memory retrospective. Do not use for ordinary coding tasks."
---
<!-- Generated from skills/memory-curator/SKILL_SPEC.md; source-sha256: 49b9247482da6c34e48a93c6e0e0f6c28c76d5ea607ee20d7e0a81d02fa8ed43; adapter: codex. Do not edit by hand; run tools/sync-skills.ps1. -->

# Memory Curator

Curate reusable engineering lessons without bypassing review.

## Workflow

1. Confirm the user explicitly asked for capture, reflection, a proposal, or Memory OS update.
2. Read `C:\Users\btf\AI-MemoryOS\_index.md`.
3. Read only directly relevant Memory OS pages, with a default maximum of 3.
4. Extract the reusable lesson, separating durable principle from task-local details.
5. Remove or generalize secrets, tokens, PII, account data, private production logs, customer private code, and unredacted sensitive business data.
6. Create or update a Markdown proposal under `C:\Users\btf\AI-MemoryOS\proposals\pending\`.
7. Do not directly modify formal rules, router, skills, evals, or accepted/rejected proposals unless the user explicitly enters maintenance or promotion mode.

## Proposal Shape

Use a concise Markdown proposal with:

- Title
- Context
- Reusable lesson
- Proposed Memory OS change
- Safety and sensitivity check
- Source task or evidence summary

## MCP Use

Prefer the `ai_memoryos` MCP tools when available:

- Search Memory OS before creating a proposal.
- Read only the minimum relevant files.
- Create or append only in `proposals/pending/`.

If MCP is unavailable, use normal filesystem access with the same boundaries.

## Output

Report the created or updated pending proposal path and summarize what was captured.