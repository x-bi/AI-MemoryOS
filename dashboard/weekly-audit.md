# Weekly Audit Dashboard

## Audit Notes

```dataview
TABLE file.mtime AS updated
FROM "logs/audits"
SORT file.mtime DESC
```

## Pending Queue

```dataview
TABLE file.mtime AS updated
FROM "proposals/pending"
SORT file.mtime DESC
```

## Checkpoints

- [[GOVERNANCE]]
- [[ROADMAP]]
- [[STATUS]]