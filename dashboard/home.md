# AI Memory OS Home

## Daily Entry

- [[dashboard/pending-proposals]]
- [[dashboard/weekly-audit]]
- [[dashboard/skills]]
- [[dashboard/router-evals]]

## Core

- [[docs/usage-manual]]

- [[STATUS]]
- [[ROADMAP]]
- [[GOVERNANCE]]
- [[INSTALL]]
- [[REMOTE]]
- [[OBSIDIAN_SETUP]]

## Workflows

- [[workflows/memory-retrospective]]
- [[workflows/proposal-promotion]]
- [[workflows/weekly-audit]]

## Pending Queue

```dataview
TABLE file.mtime AS updated, status, source, destination
FROM "proposals/pending"
SORT file.mtime DESC
```

