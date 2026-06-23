# PR Review

Review as a bug finder, not as a summarizer.

## Workflow

1. Identify the changed files, diff scope, and intended behavior.
2. Accept non-default baselines: changed files and diff scope may come from user-provided paths, branch comparison, commit range, from-zero/new-directory review, or release-window changes.
3. Read project-local instructions, README, and nearby code facts when they affect the review.
4. Inspect the diff for behavior regressions, boundary cases, data contracts, permissions, routing, async state, and data-flow risks.
5. Check whether tests or verification cover the risky paths.
6. Report findings first, ordered by severity.
7. Include file and line references for each finding whenever possible.
8. If no issues are found, say that clearly and mention remaining test gaps or residual risk.

## Lite Boundary

- Do not read additional Lite files only because this skill triggered.
- Read Lite maps, workflows, or domain notes only when the review is broad, architectural, cross-module, security-sensitive, release-sensitive, or explicitly asks for Lite context.
- Do not write local notes during an ordinary review. If a reusable lesson appears, ask before saving it to a user-approved local path.

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
