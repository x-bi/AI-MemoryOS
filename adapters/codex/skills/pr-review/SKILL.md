---
name: pr-review
description: Use when the user asks to review a PR, commit, diff, staged changes, or current code changes for bugs, regressions, risk, or missing tests. Do not use for simple explanations or implementation-only requests.
---

# PR Review

## Workflow

1. Identify the changed files, diff scope, and intended behavior.
2. Review for behavior regressions, boundary cases, contracts, permissions, routing, async state, and data flow risks.
3. Check whether tests or verification cover the risky paths.
4. Report findings first, ordered by severity.
5. Include file and line references for each finding whenever possible.
6. If no issues are found, say that clearly and mention remaining test gaps or residual risk.

## Output Order

1. Findings
2. Open questions
3. Test gaps
4. Summary

## Boundaries

- Do not lead with a summary before findings.
- Do not give generic praise.
- Do not rewrite unrelated code during review.
- Do not read Memory OS just because this skill triggered; only read it when the review is broad, architectural, cross-module, security-sensitive, or explicitly asks for Memory OS context.
