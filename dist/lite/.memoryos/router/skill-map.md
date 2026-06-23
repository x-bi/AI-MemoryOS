# Lite Skill Map

| Skill | Use When | Do Not Use When |
|---|---|---|
| pr-review | The user asks to review a PR, commit, diff, staged changes, current changes, feature slice, or implementation risk | The user only asks for implementation or explanation |
| bugfix-with-regression-test | The user wants a robust bug fix, root-cause analysis, or regression protection | The user only asks what an error means |
| frontend-component-review | The user asks to review frontend component, page, interaction, form, loading/error/empty state, accessibility, or UX risk | Non-frontend work |
| vue-change-self-check | Vue, uni-app, or frontend changes need pre-commit/post-change risk scanning | Non-frontend work, pure explanation, or direct implementation without scan request |
| git-ops-guide | The user asks for Git command guidance, command order, or explanation | The user asks the agent to execute Git operations directly |

## Notes

- Active skills must exist in `memoryos.config.json` `skills.active` and be rendered under the adapter skill directory.
- If no skill clearly matches, use project facts and the relevant workflow instead of forcing a skill.
