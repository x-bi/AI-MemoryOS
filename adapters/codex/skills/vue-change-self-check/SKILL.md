---
name: vue-change-self-check
description: "Use for Vue, uni-app, or frontend pre-commit/post-change self-checks. Also use when the user asks to inspect current changes, unstaged or staged changes, a commit, or a diff, and the current repo or lightweight diff file list indicates Vue/uni-app/frontend files such as .vue, pages.json, manifest.json, frontend route/page/navigation config, or uni-app subpackage pages. Can run alongside general PR review, but prefer stable numbered risk output and wait for the user to choose what to fix."
---
<!-- Generated from skills/vue-change-self-check/SKILL_SPEC.md; source-sha256: 7cbac27e61e7c673d7cc4058c5cda8115b16238c96352209155fca23165b5c44; adapter: codex. Do not edit by hand; run tools/sync-skills.ps1. -->

# Vue Change Self Check

Scan frontend diffs for regression risk before making more edits.

## Purpose And Boundary

This is triage. If the user asks only for a scan, do not auto-fix. Number risks with stable IDs and wait for the user to choose which numbers to handle.

### Numbered Interaction Boundary

When the user says `处理 #N`:

- `建议动作=直接修复` 且 `修复方向` 已给方案 A → 可直接落地方案 A，落地完成后才再问是否需要方案 B。
- `建议动作=先确认接口/业务规则` → 仍需先确认契约或业务规则，不直接落地任何候选方向；同时**主动产出最小待确认问题清单**（每项点名待确认对象：哪个接口字段 / 哪条业务规则 / 向谁确认），不能仅回一句"还要确认"。
- `建议动作=只需回归验证` → 仅给回归验证清单，不写代码。

## Optional Private Overlay

If `C:\Users\btf\AI-MemoryOS\private\skills\vue-change-self-check.local.md` exists, read it before project-specific scans.

Do not read `private/accounts/` or `private/secrets/`. Do not quote private overlay content into public Memory OS files, proposals, logs, or commits.

## Workflow

1. Identify the repo and change set.
2. Identify the baseline. The change set may use a non-default baseline, such as from-zero, feature branch vs base, cumulative commits, or release-window changes. Treat the baseline as an input parameter instead of excluding the skill.
3. Read lightweight scope first: `git diff --name-only`, `git diff --stat`, `git diff <base>...HEAD --name-only`, `git show --name-only --stat <commit>`, user-provided paths, or a file list derived from a newly added directory.
4. Ignore generated output, dependencies, lockfiles, and pure formatting noise unless asked.
5. Scope from changed features, not broad directory depth.
6. Add implied linkage files: page registration, route config, navigation config, permission/menu config, tab/cache config.
7. Inspect changed-file usage of unchanged dependencies before opening internals.
8. Open unchanged internals only with direct evidence, no plausible alternative, or user request.
9. Classify risks, output numbered findings, then stop unless the user asks to handle specific numbers.

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

The exact field shape, severity words, confidence words, category words, and action words for each risk item are defined in `references/output-contract.md`. Read it before producing the risk list — do not improvise the field shape from this file alone. Notable contract points include the 位置 link format, 类型 enumeration, 复现步骤 / 修复方向 fields, and multi-line termination rules.

## Required References

Read before producing output:

- `references/output-contract.md`: strict risk item shape, severity, confidence, category, action, and numbering rules. This is the output contract; the `## Output` section above only fixes section order, not field shape.

## Optional References

Read only when needed:

- `references/checklist.md`: common Vue / uni-app regression checks, verification paths, and blind spots.
