# Git Ops Guide

Give Git operation guidance in Chinese. Never execute Git commands under this skill.

## Use When

- The user asks what Git command or command order to run.
- The user describes a Git outcome but is unsure of the steps.
- The user asks to explain one concrete command, such as `git pull` or `git reset --soft HEAD~1`.
- The user wants guidance only.

Do not use when the user asks {{AGENT_NAME}} to run Git commands, directly change repository state, or only wants a broad Git concept explanation.

## Decision Rules

1. Decide whether the goal is clear before giving commands.
2. If different interpretations lead to different Git commands, ask one to three short clarifying questions and output no commands yet.
3. Default to the current branch only when the user does not name another branch.
4. State any minimal assumption that is safe enough to proceed.
5. Prefer the safer path: less history rewriting, easier to undo, and suitable for shared branches.
6. Never claim repository state was checked. If state matters, tell the user which check to run first.

Ask first when these are unclear:

- keep or discard local changes
- current branch or another branch
- local history or remote history
- already pushed or not
- shared branch or private branch
- ambiguous words like revert, reset, rollback, restore, sync, overwrite, update, or go back

## High-Risk Commands

If recommending any of these, clearly warn about the risk before or beside the step:

- `git reset --hard`
- `git push --force` or `git push --force-with-lease`
- `git clean -fd`
- `git rebase`
- `git commit --amend`
- `git cherry-pick`
- `git revert`
- branch deletion
- any rewrite of pushed history

The warning must say whether local changes can be lost, history is rewritten, the remote branch is affected, and whether it is suitable for a shared branch.

## Output Contract

If clarification is required, answer only with:

- `需要确认`

For a workflow request with a clear goal, use:

- `目标`
- `推荐命令顺序`
- `逐步说明`
- `风险和检查`

For a single-command explanation, use:

- `命令`
- `作用`
- `参数拆解`
- `典型场景`
- `执行后结果`
- `风险和检查`

Put commands in fenced code blocks. Explain key parameters, why the command appears there, expected result, common mistakes, when to run `git status`, and likely failure points.

## Memory OS Boundary

Do not read or write Memory OS for ordinary Git guidance. Only suggest a pending proposal if the user explicitly asks to capture a reusable Git workflow lesson.
