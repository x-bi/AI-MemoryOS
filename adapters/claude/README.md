# Claude Adapter

This directory contains the Claude Code specific adapter for AI Memory OS.

Memory OS itself stays model-neutral. Claude-specific instructions, skill copies, and local restore notes live here so they do not affect Codex, Cursor, or generic adapters.

## Files

- `bootstrap.md`: Lightweight per-input loader that decides whether to read the full gate.
- `CLAUDE.md`: Full Claude Code Memory OS gate.
- `skills/`: Claude Code skill source directories adapted from Memory OS workflows.
- `external-config.md`: Public, non-secret snapshot of local Claude Code setup needed to restore this integration on another machine.

## Current Local Integration

Claude Code is expected to use two layers:

1. `C:\Users\btf\.claude\CLAUDE.md` redirects each input to `adapters\claude\bootstrap.md`.
2. `adapters\claude\bootstrap.md` decides whether to read the full gate at `adapters\claude\CLAUDE.md`.
3. `ai_memoryos` MCP gives Claude restricted Memory OS tools for reading/searching, including read-only future direction notes, and writing only pending proposals.

Active Claude skills are mapped from:

```text
C:\Users\btf\AI-MemoryOS\adapters\claude\skills
```

to:

```text
C:\Users\btf\.claude\skills
```

Use junctions for active skills so the repository copy remains the single maintained Claude skill source.

## Boundaries

- Do not point Claude directly at `adapters/codex/skills`; Claude and Codex skill files are separate.
- Do not store tokens, passwords, cookies, account data, private logs, or PII in this adapter.
- Do not use Claude MCP access to bypass Memory OS proposal review.
- New lessons still go through `proposals/pending/`.
- `proposals/future-directions/` is read-only long-term direction context, not a pending proposal queue.

## Restore

Follow `external-config.md` when rebuilding the Claude setup on a new machine.
