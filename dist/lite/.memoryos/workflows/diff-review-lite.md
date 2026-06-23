# Diff Review Lite Workflow

## Trigger

Use when the user asks to review a diff, commit, PR, staged changes, or current code changes without requesting a broad architecture review.

## Memory OS Level

L1: use this lightweight workflow without reading Memory OS by default.

Escalate to L2 only when the diff involves cross-module contracts, security, permissions, release flow, shared infrastructure, or long-term engineering rules.

## Steps

1. Inspect the changed files and understand the intended behavior.
2. Prioritize behavior regressions, broken contracts, missing boundary handling, and missing verification.
3. Report findings first, ordered by severity.
4. Include file and line references when available.
5. If no issues are found, say so and state residual risk or test gaps.

## Output

1. Findings
2. Open questions
3. Test gaps
4. Summary
