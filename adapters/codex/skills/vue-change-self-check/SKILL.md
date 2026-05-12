---
name: vue-change-self-check
description: Use when the user wants a pre-commit or post-change self-check for Vue, uni-app, or frontend code changes. Scan the current diff first, classify regression risks, output stable numbered findings such as #1 #2 #3, and wait for the user to choose which numbered risk to explain, verify, or fix. Do not use for ordinary bug fixing that should directly apply a fix and regression test.
---

# Vue Change Self Check

## Purpose

Run a focused, diff-first regression risk scan for Vue / uni-app / frontend changes.

This skill is for self-check and triage. If the user only asks for a scan, do not auto-fix. Number the risks and wait for the user to choose.

## Optional Private Overlay

If this file exists, read it before scanning project-specific repositories:

```text
C:\Users\btf\AI-MemoryOS\private\skills\vue-change-self-check.local.md
```

Use it only as local project guidance. Do not read `private/accounts/` or `private/secrets/` for this skill. Do not quote private overlay content into public MemoryOS files, proposals, logs, or commits.

## Workflow

1. Identify the target repository and current change set.
2. Read `git diff --name-only`, `git diff --stat`, and targeted hunks first.
3. Ignore generated output, dependency folders, lockfiles, and pure formatting noise unless the user explicitly asks.
4. Build the scan scope from the changed feature set, not from broad directory depth.
5. Add required linkage files when project structure implies they must change, such as page registration, route config, or navigation config.
6. Inspect changed-file usage of unchanged dependencies before opening dependency internals.
7. Expand into unchanged internals only when there is direct evidence, no other plausible source, or the user asks.
8. Classify risks and output numbered findings.
9. Stop after the scan unless the user asks to handle specific numbers.

## Common Checks

- Missing null / undefined handling.
- Field name changes without full consumer updates.
- Request parameter or response shape mismatch.
- Async branches that lost `await`, `return`, rejection handling, loading cleanup, or error handling.
- Missing loading / empty / error states after request changes.
- Shared component contract mismatches: props, emits, slots, model value, enum values.
- Page registration, route config, navigation target, permission, cache, or tab behavior regressions.
- Platform-specific branches that diverge after a shared change.
- Repeated submit, payment, or critical action without loading/debounce protection.

## Output Contract

Always respond in this order:

1. `变更影响扫描`
2. `风险清单`
3. `建议验证路径`
4. `本次未覆盖盲区`

Each risk item must use a stable number and this shape:

```md
[#1] 风险标题
级别：高
置信度：高
分类：确定问题
类型：页面状态
位置：path/to/file
状态：可修复
证据：...
原因：...
建议动作：直接修复
影响面：...
```

Severity:

- `阻塞`: likely to break entry, request success, page render, route access, login flow, payment, or a critical business path.
- `高`: likely visible regression, but not guaranteed hard failure.
- `中`: plausible issue, missing guard, or behavior that should be verified.

Confidence:

- `高`: direct code evidence shows a mismatch or defect.
- `中`: strong signal, but confirmation depends on nearby code, runtime data, or backend contract.
- `低`: suspicious pattern with limited evidence.

Category:

- `确定问题`: direct evidence shows a defect or inconsistent binding.
- `待确认风险`: confirmation depends on runtime data, backend contract, or business expectation.

Action:

- `直接修复`
- `先确认接口/业务规则`
- `只需回归验证`

## Numbering Rules

Number findings by practical impact:

1. Broken entry, registration, or navigation.
2. Broken API, auth, request, or payment flow.
3. Broken page state or shared component contract.
4. Likely regression or missing validation.
5. Lower-confidence observations.

When the user says `处理 #2` or `修复 #1 #3`, keep the original numbers and focus only on those items.

## Verification Paths

End with short checks tied to the diff, such as:

- open the changed page from its real entry path
- run one successful request and one error branch
- test query, reset, pagination, create/edit/close/reopen
- verify route/page registration and navigation
- verify platform-specific branches if conditional code changed
- verify repeated submit or critical action guard

## Blind Spots

State what was not verified, usually:

- runtime API response shape
- actual browser/device interaction
- unchanged dependency internals not opened
- backend-driven permission/menu data
- private overlay not available
