---
name: frontend-component-review
description: Review frontend components, UI interactions, form flows, and user-facing frontend behavior. Use when the user asks to review a component, page interaction, form workflow, loading/error/empty state, accessibility, visual behavior, or frontend UX risk. Do not use for general backend review or implementation-only requests.
---

# Frontend Component Review

Review the user-facing behavior first, then implementation details that affect that behavior.

## Workflow

1. Identify the component, page, form, or interaction under review.
2. Inspect the changed files, nearby component contracts, route/page entry, and design-system usage.
3. Check the main workflow: initial render, user input, submit/action path, success path, and return/navigation path.
4. Check boundary states: loading, error, empty, disabled, readonly, validation, permission, and unauthenticated states.
5. Check repeated actions, race conditions, stale state, duplicate submit, optimistic updates, cleanup, and async cancellation.
6. Check whether existing shared components, tokens, icons, and local design patterns are reused correctly.
7. Check accessibility and usability risks that are visible from code: labels, focus, keyboard path, semantic controls, contrast-sensitive states, and responsive layout.
8. Check whether tests or manual verification cover the risky paths.

## Memory OS Boundary

- Do not read Memory OS for ordinary component reviews.
- Read `C:\Users\btf\AI-MemoryOS\_index.md` and at most 3 related pages only when the review is broad, architectural, design-system-level, route/permission-system-level, or explicitly asks for Memory OS context.
- If a reusable frontend lesson appears, ask before creating a pending Memory OS proposal.

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
