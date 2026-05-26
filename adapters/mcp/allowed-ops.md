# Allowed Operations

## Default Search

- `README.md`
- `_index.md`
- `STATUS.md`
- `GOVERNANCE.md`
- `core/**/*.md`
- `router/**/*.md`
- `workflows/**/*.md`
- `domains/**/*.md`
- `stacks/**/*.md`
- `rules/**/*.md`
- `skills/**/*.md`
- `evals/**/*.md`
- `templates/**/*.md`
- `logs/**/*.md`
- `proposals/pending/*.md`
- `proposals/future-directions/*.md`

## Explicit History Search

Only when a maintenance, audit, promotion, or rejection-review task explicitly needs proposal history:

- `proposals/accepted/*.md`
- `proposals/rejected/*.md`

## Explicit Read

`memory_read` may read a specific relative file under the default search or explicit history search paths.

`proposals/future-directions/*.md` is read-only through MCP. New future direction notes should be created through explicit repository maintenance, not through the pending-proposal write tools.

Do not use MCP to read local private overlays. Human operators, Codex local tasks, or adapter-specific skills may still read `private/` only when explicitly intended and allowed by their own rules.

- `private/`

## Write

Only:

- `proposals/pending/*.md`

## Ignore

- `.git/`
- `.obsidian/workspace*.json`
- `private/`
- `raw/`
- `raw/videos/`
- `raw/sessions/`
- files larger than the configured read limit
