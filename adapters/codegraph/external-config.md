# CodeGraph External Config Snapshot

This file records local configuration outside AI Memory OS that is needed to restore the CodeGraph integration. It is safe to commit because it must not contain tokens, passwords, cookies, account data, private logs, private project code, or PII.

## Tool Version

Pinned package:

```text
@colbymchenry/codegraph@0.9.4
```

Current observed command after install:

```text
C:\Program Files\nodejs\codegraph.ps1
```

## Install

Install the pinned version:

```powershell
npm install -g @colbymchenry/codegraph@0.9.4
```

Validate:

```powershell
codegraph --version
Get-Command codegraph
codegraph install --print-config codex
```

Do not run the interactive installer for AI Memory OS setup. The installer can write agent instruction files such as `CLAUDE.md` or `~/.codex/AGENTS.md`. AI Memory OS keeps those surfaces under its own bootstrap and adapter rules.

## OS Paths

| Purpose | Path |
|---|---|
| Memory OS repo | `C:\Users\btf\AI-MemoryOS` |
| CodeGraph integration policy | `C:\Users\btf\AI-MemoryOS\integrations\codegraph.md` |
| CodeGraph workflow | `C:\Users\btf\AI-MemoryOS\workflows\codegraph-assisted-project-analysis.md` |
| Shared wrapper | `C:\Users\btf\AI-MemoryOS\tools\codegraph-wrapper.ps1` |
| Project manager | `C:\Users\btf\AI-MemoryOS\tools\codegraph-project.ps1` |
| Private graph root | `C:\Users\btf\AI-MemoryOS\private\codegraph` |

## Restore Order

On a new machine or after reinstall:

1. Restore or clone `C:\Users\btf\AI-MemoryOS`.
2. Install Node.js and npm if missing.
3. Install `@colbymchenry/codegraph@0.9.4`.
4. Validate `codegraph --version`.
5. Merge the Codex MCP snippet only if Codex should use CodeGraph.
6. Add the Claude MCP command only if Claude should use CodeGraph.
7. Recreate project graph slots on demand. Do not copy private worktrees unless you intentionally trust the source machine and storage.

## Codex

Example config:

```text
adapters/codex/config/codegraph-mcp.example.toml
```

Merge manually into:

```text
C:\Users\btf\.codex\config.toml
```

Do not overwrite `C:\Users\btf\.codex\AGENTS.md`.

## Claude

Example restore commands:

```text
adapters/claude/codegraph-mcp.md
```

Use `claude mcp add` rather than copying auth/session files.

## Private Data Boundary

Do not commit:

- `C:\Users\btf\AI-MemoryOS\private\codegraph\`
- CodeGraph `.codegraph` indexes
- private project worktrees
- installer caches
- `node_modules`

Regenerate indexes after migration unless there is a specific reason to preserve the private cache.
