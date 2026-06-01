# Auto Run Operations

This rule defines the operating boundary for `tools/auto/` scripts.

## Round 1 Boundary

- Round 1 scripts may write run logs under `logs/auto-runs/`.
- Round 1 iteration scripts may create B-tier proposal drafts under `proposals/pending/`.
- Round 1 scripts must support `-WhatIf` before any write path.
- Round 1 scripts must not create branches, commit, push, merge, rebase, force-push, or delete branches.
- Round 1 scripts must not write formal `core/`, `router/`, `rules/`, `skills/`, or adapter gate files.

## Tiers

- A-tier: formatting, dashboard synchronization, and fully reversible non-semantic updates. Round 2 only.
- B-tier: semantic suggestions and safe-path content repairs. On `auto/*` script branches, Round 2 may apply exact-match model edits to non-protected paths after schema, sensitive-content, path-boundary, and repository validation checks. When a direct fix is not reliable, write proposal drafts under `proposals/pending/`.
- C-tier: changes to formal rules, router, skills, core memory, adapter gates, automation scripts, release/security policy, or protected paths. Generate approval sheets by default. Applying approved changes remains explicit and must not be merged to `main` automatically.

Protected paths for model auto-repair include `adapters/`, `core/`, `router/`, `rules/`, `skills/`, `tools/`, `logs/auto-runs/`, `private/`, `raw/`, `proposals/accepted/`, `proposals/rejected/`, `_index.md`, `GOVERNANCE.md`, `INSTALL.md`, `README.md`, `ROADMAP.md`, and `STATUS.md`.

## Safety

- Do not write secrets, tokens, cookies, private production logs, customer private code, or unredacted sensitive content.
- Logs and proposals may record paths, line ranges, rule names, hashes, and counts, but should not copy sensitive values.
- Generated proposals must be idempotent by title.

## Round 2 Boundary

Round 2 may add model semantic audit, `auto/*` branch handling, repair, review summaries, and optional push behavior under explicit script policy. It must still never merge to main automatically.
