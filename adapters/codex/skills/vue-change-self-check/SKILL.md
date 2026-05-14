---
name: vue-change-self-check
description: Use for Vue, uni-app, or frontend pre-commit/post-change self-checks. Scan diff first, output stable numbered risks, and wait for user choice before fixing. Do not use for ordinary bugfix implementation.
---

# Vue Change Self Check

## Purpose And Boundary

Diff-first regression risk scan for Vue / uni-app / frontend changes. This is triage: if the user asks only for a scan, do not auto-fix. Number risks and wait for the user to choose.

## Optional Private Overlay

If `C:\Users\btf\AI-MemoryOS\private\skills\vue-change-self-check.local.md` exists, read it before project-specific scans. Do not read `private/accounts/` or `private/secrets/`; do not quote private overlay content into public MemoryOS files, proposals, logs, or commits.

## Workflow

1. Identify repo and change set.
2. Read `git diff --name-only`, `git diff --stat`, and targeted hunks first.
3. Ignore generated output, dependencies, lockfiles, and pure formatting noise unless asked.
4. Scope from changed features, not broad directory depth.
5. Add implied linkage files: page registration, route config, navigation config.
6. Inspect changed-file usage of unchanged dependencies before opening internals.
7. Open unchanged internals only with direct evidence, no plausible alternative, or user request.
8. Classify risks, output numbered findings, then stop unless user asks to handle numbers.

## Output

Order: `变更影响扫描`、`风险清单`、`建议验证路径`、`本次未覆盖盲区`. Use stable numbers like `#1`; when user says `处理 #2` or `修复 #1 #3`, keep original numbers.

## References

Read only when needed:

- `references/checklist.md`: common Vue / uni-app regression checks, verification paths, and blind spots.
- `references/output-contract.md`: strict risk item shape, severity, confidence, category, action, and numbering rules.
