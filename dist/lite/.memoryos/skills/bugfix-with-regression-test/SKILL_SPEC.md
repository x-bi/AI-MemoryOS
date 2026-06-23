# Bugfix With Regression Test

Fix the cause, protect the behavior, and keep the change scoped.

## Workflow

1. Reproduce or localize the bug from the user report, failing test, logs, or code path.
2. Identify the root cause before editing. Avoid changing only the visible symptom.
3. Make the smallest fix that matches existing project patterns.
4. Add or update a focused regression test when the project has a practical test surface for the bug.
5. If a regression test is not practical, explain why and provide the closest useful verification.
6. Verify the fix with the smallest meaningful command or inspection path.
7. If a reusable cross-project lesson appears, ask before saving it to a user-approved local path.

## Lite Boundary

- Do not read additional Lite files for ordinary single-bug fixes.
- Read Lite maps, workflows, or domain notes only when the bug spans architecture, cross-module contracts, security/permissions, release flow, long-term conventions, or the user asks for Lite context.
- Do not write local notes unless the user explicitly confirms the target path.

## Verification

- Prefer lightweight checks first: relevant unit test, targeted integration test, focused manual path, or diff/call-chain inspection.
- Do not run full builds, full test suites, dependency installs, generated-code updates, or write-effect format/lint commands unless the task requires it or the user asks.
- Before cleaning artifacts, constrain the path and avoid repository-wide cleanup.

## Final Response

Include:

1. Root cause
2. Fix summary
3. Regression protection or why it was not added
4. Verification performed
5. Residual risk, if any
