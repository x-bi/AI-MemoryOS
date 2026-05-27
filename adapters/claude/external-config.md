# Claude External Config Snapshot

This file records local configuration outside AI Memory OS that is needed to connect Claude Code to the repository. It is safe to commit because it must not contain tokens, passwords, cookies, account data, private logs, or PII.

## Paths

| Purpose | Path |
|---|---|
| Memory OS repo | `C:\Users\btf\AI-MemoryOS` |
| Claude CLI | `C:\Users\btf\.local\bin\claude.exe` |
| Claude user instructions | `C:\Users\btf\.claude\CLAUDE.md` |
| Claude user config | `C:\Users\btf\.claude.json` |
| Claude settings | `C:\Users\btf\.claude\settings.json` |
| Claude skill discovery root | `C:\Users\btf\.claude\skills` |
| Memory OS Claude skill source | `C:\Users\btf\AI-MemoryOS\adapters\claude\skills` |
| Memory OS MCP server | `C:\Users\btf\AI-MemoryOS\adapters\mcp\server\obsidian-memory-os-mcp.mjs` |
| Node runtime used for MCP | `C:\Program Files\nodejs\node.exe` |

## Restore Order

On a new machine or after reinstalling Claude Code:

1. Restore or clone `C:\Users\btf\AI-MemoryOS`.
2. Install Claude Code and confirm the CLI path.
3. Restore user-level `CLAUDE.md`.
4. Add `ai_memoryos` MCP.
5. Create active Claude skill junctions.
6. Validate MCP, skills, and file paths.

Do not copy old Claude auth/session/cache files as part of Memory OS restore.

## Claude CLI

Current observed executable:

```powershell
C:\Users\btf\.local\bin\claude.exe
```

Validate:

```powershell
& C:\Users\btf\.local\bin\claude.exe --version
& C:\Users\btf\.local\bin\claude.exe --help
```

If Claude is installed elsewhere, update local commands to use the actual CLI path. Do not commit machine-specific discovery output unless it affects the documented restore process.

## User CLAUDE.md

`C:\Users\btf\.claude\CLAUDE.md` should be kept in sync with:

```text
adapters/claude/CLAUDE.md
```

It provides the Claude Code Memory OS gate:

- L0/L1 do not read Memory OS content by default.
- L2 reads `_index.md` plus at most 3 directly relevant pages.
- L3 writes only `proposals/pending/` after explicit user request or confirmation.
- `proposals/future-directions/` is long-term direction context, not a pending proposal queue and not directly promotable. It is normally read-only; local file writes there require an explicit future-direction or architecture-intent request.
- Project-local instructions and code facts override Memory OS general rules.
- Temporary Claude L2 Bias is enabled as a Claude-only adapter overlay while Claude has more available usage budget. Borderline L1/L2 tasks should prefer L2 when Memory OS context may prevent repeated mistakes. This overlay does not affect Codex, shared skill specs, or L3 write boundaries.

Restore command:

```powershell
Test-Path C:\Users\btf\AI-MemoryOS\adapters\claude\CLAUDE.md
New-Item -ItemType Directory -Force -Path C:\Users\btf\.claude | Out-Null
Copy-Item -LiteralPath C:\Users\btf\AI-MemoryOS\adapters\claude\CLAUDE.md `
  -Destination C:\Users\btf\.claude\CLAUDE.md -Force
```

## MCP Server

Claude Code should have a user-scope stdio MCP server named `ai_memoryos`.

Current command:

```text
C:\Program Files\nodejs\node.exe C:\Users\btf\AI-MemoryOS\adapters\mcp\server\obsidian-memory-os-mcp.mjs
```

Restore command:

```powershell
Test-Path "C:\Program Files\nodejs\node.exe"
Test-Path "C:\Users\btf\AI-MemoryOS\adapters\mcp\server\obsidian-memory-os-mcp.mjs"
& C:\Users\btf\.local\bin\claude.exe mcp add --transport stdio --scope user ai_memoryos -- `
  "C:\Program Files\nodejs\node.exe" `
  "C:\Users\btf\AI-MemoryOS\adapters\mcp\server\obsidian-memory-os-mcp.mjs"
```

Validate:

```powershell
& C:\Users\btf\.local\bin\claude.exe mcp list
& C:\Users\btf\.local\bin\claude.exe mcp get ai_memoryos
```

Expected result:

```text
ai_memoryos ... Status: Connected
```

MCP safety boundary:

- Read/search Memory OS text files, including `proposals/future-directions/` as read-only long-term direction notes.
- Create or append only `proposals/pending/`.
- Do not use MCP to directly modify formal rules, router, skills, evals, future direction notes, accepted proposals, or rejected proposals.
- Do not store tokens, passwords, secrets, cookies, account data, private logs, or PII in MCP config.

## Optional CodeGraph MCP Server

Claude Code may also have a user-scope stdio MCP server named `codegraph` when CodeGraph is enabled:

```powershell
& C:\Users\btf\.local\bin\claude.exe mcp add --transport stdio --scope user codegraph -- `
  powershell `
  -NoProfile `
  -ExecutionPolicy Bypass `
  -File C:\Users\btf\AI-MemoryOS\tools\codegraph-wrapper.ps1 `
  serve
```

Validate:

```powershell
& C:\Users\btf\.local\bin\claude.exe mcp get codegraph
```

CodeGraph is an optional project-code graph acceleration layer. Its runtime policy, wrapper, and restore notes are documented under `integrations/codegraph.md` and `adapters/codegraph/external-config.md`.

## Active Claude Skill Junctions

Claude Code discovers skills from:

```text
C:\Users\btf\.claude\skills
```

Active Claude skills should be junctions to:

```text
C:\Users\btf\AI-MemoryOS\adapters\claude\skills
```

Active `SKILL.md` files are generated from shared specs:

```text
skills/registry.json
skills/<skill>/SKILL_SPEC.md
tools/sync-skills.ps1
```

Do not edit generated adapter `SKILL.md` files by hand. Update the shared spec or registry adapter description, then run `tools/sync-skills.ps1`.

Active skills:

- `pr-review`
- `bugfix-with-regression-test`
- `memory-curator`
- `vue-change-self-check`
- `frontend-component-review`
- `git-ops-guide`
- `routing-auditor`

Restore command:

```powershell
$src = "C:\Users\btf\AI-MemoryOS\adapters\claude\skills"
$dst = "C:\Users\btf\.claude\skills"
New-Item -ItemType Directory -Force -Path $dst | Out-Null

foreach ($skill in @(
  "pr-review",
  "bugfix-with-regression-test",
  "memory-curator",
  "vue-change-self-check",
  "frontend-component-review",
  "git-ops-guide",
  "routing-auditor"
)) {
  $link = Join-Path $dst $skill
  $target = Join-Path $src $skill
  if (-not (Test-Path -LiteralPath $link)) {
    New-Item -ItemType Junction -Path $link -Target $target | Out-Null
  }
}
```

Validate:

```powershell
Get-ChildItem C:\Users\btf\.claude\skills | Select-Object Name,LinkType,Target
```

Expected result:

- The seven active skills appear under `.claude\skills`.
- Each entry is a junction to `AI-MemoryOS\adapters\claude\skills`.
- Each skill has a `SKILL.md` with valid frontmatter.
- Managed skill source hashes match `skills/<skill>/SKILL_SPEC.md`.

## Files Not Backed Up Here

Do not backup, copy, or commit these as part of Memory OS restore:

- `C:\Users\btf\.claude\settings.json` values that contain auth, provider, account, or private endpoint data.
- `C:\Users\btf\.claude\config.json` account or key state.
- `C:\Users\btf\.claude.json` except for manually re-adding the documented `ai_memoryos` MCP entry through `claude mcp add`.
- `C:\Users\btf\.claude\history.jsonl`.
- `C:\Users\btf\.claude\sessions\`.
- `C:\Users\btf\.claude\projects\`.
- `C:\Users\btf\.claude\cache\`.
- `C:\Users\btf\.claude\downloads\`.
- `C:\Users\btf\.claude\telemetry\`.
- Marketplace/plugin cache contents under `C:\Users\btf\.claude\plugins\` unless a specific Memory OS Claude plugin is intentionally created and documented later.

If any of these files are needed for debugging, inspect them locally and summarize only non-sensitive facts.

## Unmanaged Local Claude Config

`C:\Users\btf\.claude\settings.json`, `C:\Users\btf\.claude\config.json`, and `C:\Users\btf\.claude.json` may contain provider, authentication, plugin, project, or UI state unrelated to AI Memory OS.

Do not copy secrets or account-specific values into this repository. Only record the Memory OS-relevant paths, MCP server name, command shape, and skill junction layout.

Current observed unmanaged local directories include:

- `backups`
- `cache`
- `downloads`
- `ide`
- `plugins`
- `projects`
- `sessions`
- `telemetry`

Treat them as Claude runtime state, not Memory OS adapter source.

## Validation

Run after setup:

```powershell
Get-Content C:\Users\btf\.claude\CLAUDE.md -Encoding utf8
& C:\Users\btf\.local\bin\claude.exe mcp get ai_memoryos
Get-ChildItem C:\Users\btf\.claude\skills | Select-Object Name,LinkType,Target
rg -n "^---$|^name:|^description:" C:\Users\btf\AI-MemoryOS\adapters\claude\skills -g SKILL.md
```

Expected result:

- User `CLAUDE.md` matches `adapters/claude/CLAUDE.md`.
- `ai_memoryos` is connected.
- `ai_memoryos` uses the current repository MCP server, so `memory_search` can read `proposals/future-directions/` while writes remain limited to `proposals/pending/`.
- Seven active skills appear under `.claude\skills`.
- Active skills are junctions to `AI-MemoryOS\adapters\claude\skills`.
- Managed skill source hashes match the shared specs.
- Temporary Claude L2 Bias appears in `C:\Users\btf\.claude\CLAUDE.md` until explicitly removed or revised.
- Claude adapter files contain no tokens, passwords, cookies, private endpoint credentials, account data, or PII.

## Read Boundary

Normal Claude tasks should not read this file.

Read this file only when:

- setting up Claude Code on a new machine,
- repairing Claude Memory OS integration,
- auditing Claude external config,
- updating active Claude skill junctions,
- enabling or debugging `ai_memoryos` MCP.
