---
name: pr-review
description: "Use when the user asks to review a PR, commit, diff, staged changes, or current code changes for bugs, regressions, risk, or missing tests. Do not use for simple explanations or implementation-only requests."
---
<!-- Generated from skills/pr-review/SKILL_SPEC.md; source-sha256: 6e720bb02698a398f2eca6d931c49fd2736831c42ad1a8f5e7e753851e7fe215; adapter: codex. Do not edit by hand; run tools/sync-skills.ps1. -->

# PR Review

Review as a bug finder, not as a summarizer.

## Workflow

1. Identify the changed files, diff scope, and intended behavior.
2. Read project-local instructions, README, and nearby code facts when they affect the review.
3. Inspect the diff for behavior regressions, boundary cases, data contracts, permissions, routing, async state, and data-flow risks.
4. Check whether tests or verification cover the risky paths.
5. Report findings first, ordered by severity.
6. Include file and line references for each finding whenever possible.
7. If no issues are found, say that clearly and mention remaining test gaps or residual risk.

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
- Prefer concrete, actionable findings over style opinions.