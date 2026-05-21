# Claude External Config Snapshot

This file records local configuration outside AI Memory OS that is needed to connect Claude Code to the repository. It is safe to commit because it must not contain tokens, passwords, cookies, account data, private logs, or PII.

## Paths

| Purpose | Path |
|---|---|
| Memory OS repo | `C:\Users\btf\AI-MemoryOS` |
| Claude user instructions | `C:\Users\btf\.claude\CLAUDE.md` |
| Claude user config | `C:\Users\btf\.claude.json` |
| Claude settings | `C:\Users\btf\.claude\settings.json` |
| Claude skill discovery root | `C:\Users\btf\.claude\skills` |
| Memory OS Claude skill source | `C:\Users\btf\AI-MemoryOS\adapters\claude\skills` |
| Memory OS MCP server | `C:\Users\btf\AI-MemoryOS\adapters\mcp\server\obsidian-memory-os-mcp.mjs` |
| Node runtime used for MCP | `C:\Program Files\nodejs\node.exe` |

## User CLAUDE.md

`C:\Users\btf\.claude\CLAUDE.md` should be kept in sync with:

```text
adapters/claude/CLAUDE.md
```

It provides the Claude Code Memory OS gate:

- L0/L1 do not read Memory OS content by default.
- L2 reads `_index.md` plus at most 3 directly relevant pages.
- L3 writes only `proposals/pending/` after explicit user request or confirmation.
- Project-local instructions and code facts override Memory OS general rules.

Restore command:

```powershell
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

- Read/search Memory OS text files.
- Create or append only `proposals/pending/`.
- Do not use MCP to directly modify formal rules, router, skills, evals, accepted proposals, or rejected proposals.

## Active Claude Skill Junctions

Claude Code discovers skills from:

```text
C:\Users\btf\.claude\skills
```

Active Claude skills should be junctions to:

```text
C:\Users\btf\AI-MemoryOS\adapters\claude\skills
```

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

## Unmanaged Local Claude Config

`C:\Users\btf\.claude\settings.json`, `C:\Users\btf\.claude\config.json`, and `C:\Users\btf\.claude.json` may contain provider, authentication, plugin, project, or UI state unrelated to AI Memory OS.

Do not copy secrets or account-specific values into this repository. Only record the Memory OS-relevant paths, MCP server name, command shape, and skill junction layout.

## Read Boundary

Normal Claude tasks should not read this file.

Read this file only when:

- setting up Claude Code on a new machine,
- repairing Claude Memory OS integration,
- auditing Claude external config,
- updating active Claude skill junctions,
- enabling or debugging `ai_memoryos` MCP.
