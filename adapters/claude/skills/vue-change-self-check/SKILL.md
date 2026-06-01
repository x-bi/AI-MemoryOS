---
name: vue-change-self-check
description: "Use for Vue, uni-app, or frontend pre-commit/post-change self-checks. Also use when the user asks to inspect current changes, unstaged or staged changes, a commit, or a diff, and the current repo or lightweight diff file list indicates Vue/uni-app/frontend files such as .vue, pages.json, manifest.json, frontend route/page/navigation config, or uni-app subpackage pages. Can run alongside general PR review, but prefer stable numbered risk output and wait for the user to choose what to fix."
---
<!-- Generated from skills/vue-change-self-check/SKILL_SPEC.md; source-sha256: e8c422f87121e0553019cf5163bdd366d012ae3a584dd15ee1ad5f11032c1f81; adapter: claude. Do not edit by hand; run tools/sync-skills.ps1. -->

# Vue Change Self Check

Scan frontend diffs for regression risk before making more edits.

## Purpose And Boundary

This is triage. If the user asks only for a scan, do not auto-fix. Number risks with stable IDs and wait for the user to choose which numbers to handle.

## Optional Private Overlay

If `C:\Users\btf\AI-MemoryOS\private\skills\vue-change-self-check.local.md` exists, read it before project-specific scans.

Do not read `private/accounts/` or `private/secrets/`. Do not quote private overlay content into public Memory OS files, proposals, logs, or commits.

## Workflow

1. Identify the repo and change set.
2. Read `git diff --name-only`, `git diff --stat`, and targeted hunks first.
3. Ignore generated output, dependencies, lockfiles, and pure formatting noise unless asked.
4. Scope from changed features, not broad directory depth.
5. Add implied linkage files: page registration, route config, navigation config, permission/menu config, tab/cache config.
6. Inspect changed-file usage of unchanged dependencies before opening internals.
7. Open unchanged internals only with direct evidence, no plausible alternative, or user request.
8. Classify risks, output numbered findings, then stop unless the user asks to handle specific numbers.

## Memory OS Boundary

- Do not read Memory OS for ordinary frontend scans.
- Read `C:\Users\btf\AI-MemoryOS\_index.md` and at most 3 related pages only when the scan is broad, architectural, route/permission-system-level, or explicitly asks for Memory OS context.
- If a reusable lesson appears, ask before creating a pending proposal.

## Output

Use this order:

1. `变更影响扫描`
2. `风险清单`
3. `建议验证路径`
4. `本次未覆盖盲区`

Use stable numbers such as `#1`. When the user says `处理 #2` or `修复 #1 #3`, keep the original numbers.

## References

Read only when needed:

- `references/checklist.md`: common Vue / uni-app regression checks, verification paths, and blind spots.
- `references/output-contract.md`: strict risk item shape, severity, confidence, category, action, and numbering rules.
