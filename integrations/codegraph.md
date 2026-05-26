# CodeGraph Integration

CodeGraph is an optional project-code graph acceleration layer for AI Memory OS. It is not a required dependency for Memory OS itself.

## Role

```text
AI Memory OS = policy, routing, wrappers, restore notes
CodeGraph = local code graph index and MCP tools
Codex / Claude = model execution surfaces
Project repositories = source of truth for real code edits
```

Agents may use CodeGraph to locate symbols, trace calls, and estimate impact before reading source files. Final decisions still rely on project-local instructions, real source files, `git diff`, and verification results.

## Storage Policy

Do not create `.codegraph/` inside formal project repositories.

AI Memory OS stores CodeGraph worktrees and indexes under:

```text
C:\Users\btf\AI-MemoryOS\private\codegraph\
```

The `private/` directory is intentionally ignored by Git. It may contain business project worktrees and derived source indexes, so it must not be committed.

## Slot Model

Each registered project uses one reusable default slot plus a small number of hot slots. Hot slots can be pinned branch slots or shared module slots.

```text
private\codegraph\projects\<project-id>\
  slots\
    default\
      worktree\
      state.json
    main\
      worktree\
      state.json
    dev\
      worktree\
      state.json
    <active-module-slot>\
      worktree\
      state.json
```

Slot selection:

- `main` or `master`: use the pinned main/master slot.
- `dev`: use the pinned dev slot when the project has one.
- Current active module branch group: use its shared module slot.
- All other branches: reuse the fixed `default` slot.

The `default` slot is a fallback slot, not a real Git branch. It can represent only one non-hot branch at a time. When another non-hot branch needs CodeGraph, the same default slot is switched and synced to that branch or commit.

A shared module slot is also a reusable slot, but it is reserved for a current development cycle. Several closely related branches can share one slot when their differences are expected to stay small:

```text
feature-a
feature-a-dev
feature-a-fix
=> slot: feature-a-group
```

The shared module slot can represent only one concrete branch or commit at a time. When the current branch changes within the group, the slot worktree is switched and synced to that branch. If two related branches need simultaneous comparison or their differences grow large, split them into separate slots.

## Hot Branch Policy

Pinned branches:

- `main` or `master`
- `dev` when present

Active module slots:

- One or two module slots for the current development cycle.
- Each module slot may bind multiple closely related branches.
- Module slots are retained only while the development cycle is current.
- When the cycle ends, downgrade the slot and let it become removable instead of retaining it as a long-term graph.

Non-hot branches:

- Do not get dedicated branch slots.
- Use the reusable `default` slot only when CodeGraph is enabled and the current task benefits from a graph.

Do not scan every local branch. Do not prebuild graph indexes for remote branches.

## Switches

CodeGraph has three switch levels:

```text
global: disables all CodeGraph behavior in Memory OS
project: disables CodeGraph for one registered project
task: skips CodeGraph for the current task only
```

When CodeGraph is disabled at any level, agents must not:

- create private worktrees
- create `.codegraph` indexes
- run `codegraph init`, `index`, `sync`, or `status`
- call CodeGraph MCP tools
- auto-register projects
- auto-promote branches to hot slots

Use `rg` and direct source reads instead.

## Update Policy

Indexing is local CPU and disk work; it does not consume model tokens. Tokens are consumed only when graph query results are returned to the model.

```text
missing slot -> codegraph init -i
existing slot, changed commit -> codegraph sync
corrupt or badly stale graph -> codegraph index --force
```

Each project + slot must have a lock. Do not run multiple sync/index operations against the same slot concurrently.

Slot states:

```text
missing -> indexing -> ready
ready -> syncing -> ready
ready -> stale -> syncing -> ready
failed -> fall back to rg + source reads
```

## Adapter Policy

Codex and Claude should not maintain separate CodeGraph logic. They should call the same Memory OS wrapper:

```text
C:\Users\btf\AI-MemoryOS\tools\codegraph-wrapper.ps1
```

Adapter-specific files should contain only shell configuration needed to launch the wrapper.

## Restore Policy

Commit these files:

- integration policy
- workflow docs
- wrapper scripts
- MCP config templates
- install and restore notes

Do not commit:

- CodeGraph upstream source
- `node_modules`
- binary caches
- private project worktrees
- `.codegraph` indexes

On migration or reinstall, restore the OS repo, reinstall CodeGraph from the pinned version in `adapters/codegraph/external-config.md`, reapply Codex/Claude MCP shell configuration, and regenerate private graph indexes as needed.
