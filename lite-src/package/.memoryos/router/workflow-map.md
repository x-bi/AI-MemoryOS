# Lite Workflow Map

| Signal | Workflow | Use When | Do Not Use When |
|---|---|---|---|
| prototype / design / Figma / Lanhu / Axure / iframe + development | `.memoryos/workflows/frontend-prototype-driven-development.md` | The user asks to read a design or prototype for page/component implementation | The user only asks to explain fields, debug an API, or inspect a link without development intent |
| review diff / PR / commit / staged changes / current changes / release-window changes | `.memoryos/workflows/diff-review-lite.md` | The task is a change-set review and not a broad architecture review | The user asks to directly implement rather than review |
| frontend regression / route or build validation / platform verification | `.memoryos/workflows/frontend-regression-verification-strategy.md` | Frontend changes need minimal validation strategy or build side-effect control | Non-frontend tasks or user already gave the exact validation command |
| new feature / implementation / add page / add script / build behavior | `.memoryos/workflows/feature-development.md` | The user asks to build or modify behavior and no more specific workflow dominates | The user asks only for review or explanation |
| bugfix / root cause / regression protection | `.memoryos/workflows/bugfix-with-regression-test.md` | A bug fix needs cause analysis and recurrence protection | The user only asks what an error means |
| pre-commit check / self-check / regression scan / look over before commit | `.memoryos/workflows/pre-commit-self-check.md` | The user asks for a commit-ready or post-change self-check | The user asks for a formal PR/diff review |
| refactor / reduce complexity / behavior should stay unchanged | `.memoryos/workflows/refactor-with-safety.md` | The user asks for refactoring with behavior control | Ordinary small fixes or feature work |
| script / batch / file processing / automation | `.memoryos/workflows/script-automation.md` | The task has script inputs, outputs, side effects, or rollback concerns | One-line command explanation |
| test strategy / coverage / regression protection / unit vs integration vs E2E | `.memoryos/workflows/test-strategy.md` | The user asks how to test or what coverage level to use | A concrete bugfix already has a clear test path |
| post-task reusable lesson / local reflection | `.memoryos/workflows/retrospective-lite.md` | A reusable lesson may exist and the user has not asked to write formal memory | No reusable lesson, or the user explicitly asks for package maintenance |
