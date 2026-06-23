# Frontend Component Review

Review the user-facing behavior first, then implementation details that affect that behavior.

## Workflow

1. Identify the component, page, form, or interaction under review.
2. If the user asks to review a newly added page, component, form, or interaction as a full implementation, treat that target as a change set even when there is no default `git diff` baseline.
3. Inspect the changed files, nearby component contracts, route/page entry, and design-system usage.
4. Check the main workflow: initial render, user input, submit/action path, success path, and return/navigation path.
5. Check boundary states: loading, error, empty, disabled, readonly, validation, permission, and unauthenticated states.
6. Check repeated actions, race conditions, stale state, duplicate submit, optimistic updates, cleanup, and async cancellation.
7. Check whether existing shared components, tokens, icons, and local design patterns are reused correctly.
8. Check accessibility and usability risks visible from code.
9. Check whether tests or manual verification cover the risky paths.

## Lite Boundary

- Do not read additional Lite files for ordinary component reviews.
- Read Lite maps, workflows, or domain notes only when the review is broad, architectural, design-system-level, route/permission-system-level, or explicitly asks for Lite context.
- If a reusable frontend lesson appears, ask before saving it to a user-approved local path.

## Output

Use this order:

1. Findings
2. Open questions
3. Suggested verification
4. Summary

Prioritize concrete issues and risks before suggestions. If no issues are found, say so and mention residual test or runtime gaps.

## Constraints

- Do not rewrite code during a review unless the user asks for fixes.
- Do not focus on visual preference unless it affects usability, consistency, accessibility, or the stated design goal.
- Prefer file and line references for each finding whenever possible.
