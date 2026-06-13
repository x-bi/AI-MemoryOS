---
name: pr-review
description: "Review pull requests, commits, diffs, staged changes, or current code changes for bugs, regressions, risky behavior, contract breaks, and missing tests. Use when the user asks for a code review, PR review, diff review, staged review, commit review, or asks whether recent changes are safe. Do not use for implementation-only requests or simple explanations."
---
<!-- Generated from skills/pr-review/SKILL_SPEC.md; source-sha256: 9422803f64fabb149a7cc5d33ce38ae3a9398bc9bfbd8b7350d74e6d48401a44; adapter: claude. Do not edit by hand; run tools/sync-skills.ps1. -->

# PR Review

Review as a bug finder, not as a summarizer.

## Workflow

1. Identify the changed files, diff scope, and intended behavior.
2. Accept non-default baselines: changed files and diff scope may come from user-provided paths, branch comparison, commit range, from-zero/new-directory review, or release-window changes. Treat the baseline as an input parameter instead of excluding the skill.
3. Read project-local instructions, README, and nearby code facts when they affect the review.
4. Inspect the diff for behavior regressions, boundary cases, data contracts, permissions, routing, async state, and data-flow risks.
5. Check whether tests or verification cover the risky paths.
6. Report findings first, ordered by severity.
7. Include file and line references for each finding whenever possible.
8. If no issues are found, say that clearly and mention remaining test gaps or residual risk.

## Memory OS Boundary

- Do not read Memory OS only because this skill triggered.
- Read `C:\Users\btf\AI-MemoryOS\_index.md` and at most 3 related pages only when the review is broad, architectural, cross-module, security-sensitive, release-sensitive, or explicitly asks for Memory OS context.
- Do not write Memory OS during an ordinary review. If a reusable lesson appears, ask whether to create a pending proposal.

## Output Order

1. Findings
2. Open questions
3. Test gaps
4. Summary

## Constraints

- Do not lead with a summary before findings.
- Do not give generic praise.
- Do not rewrite unrelated code during review.
- Do not convert a module explanation or architecture read into diff review unless the user gives a change window, changed files, commit range, branch range, or from-zero/new-feature scope.
- Prefer concrete, actionable findings over style opinions.
