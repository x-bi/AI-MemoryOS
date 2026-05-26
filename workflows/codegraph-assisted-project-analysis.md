# CodeGraph Assisted Project Analysis

Use this workflow when a large external code project is being analyzed or edited and CodeGraph is enabled for that project.

## Entry Checks

1. Read the normal Memory OS gate for the current agent.
2. Check the CodeGraph global switch.
3. Check whether the current project is registered and enabled.
4. Honor any task-level request to skip CodeGraph.
5. If any check disables CodeGraph, use `rg`, project-local instructions, and direct source reads.

## Slot Selection

Resolve:

```text
project source path
current branch
current commit
```

Choose a slot:

- `main` or `master`: pinned main/master slot.
- `dev`: pinned dev slot.
- active module branch group: matching shared module slot.
- otherwise: reusable `default` slot.

An active module slot may bind several closely related branches from the same development cycle, such as `feature-a` and `feature-a-dev`. The slot is shared by the group and is synced to whichever concrete branch is current.

When creating an active module slot, use the business feature group name as the slot name. This name is shared by Codex and Claude and must not be a model name or a generic label such as `feature`, `hot`, `module`, or `current`.

## Prepare Graph

For the selected slot:

1. Acquire the project + slot lock.
2. Ensure the private worktree exists.
3. Sync the private worktree to the current branch or commit.
4. Run `codegraph init -i` if the slot has no graph.
5. Run `codegraph sync` if the commit changed.
6. Mark the slot `ready` only after sync succeeds.
7. Release the lock.

If preparation fails, mark the slot `failed` and fall back to `rg` plus direct source reads.

## Agent Use

Use CodeGraph for:

- where-is-X questions
- architecture orientation
- call traces
- caller/callee discovery
- impact analysis
- indexed file structure

After graph navigation, read the real project source files before editing. Do not edit the private worktree.

## Exit

Before final response:

- Report whether CodeGraph was used, skipped, or failed over.
- Keep graph output summaries concise.
- Ground code changes in real project files and verification results.
