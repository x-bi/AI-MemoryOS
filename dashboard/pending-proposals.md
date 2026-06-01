# Pending Proposals

```dataview
TABLE file.mtime AS updated, status, source
FROM "proposals/pending"
SORT file.mtime DESC
```

## Workflow

1. Review scope and sensitivity.
2. Decide accept / reject / defer.
3. Use Codex to apply accepted changes to rules / router / skills / evals.
