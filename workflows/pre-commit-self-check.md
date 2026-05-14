# Pre-commit Self-check Workflow

## Trigger

Use when the user asks for a commit-ready check, self-check, regression scan, or "look over the current changes before commit".

## Memory OS Level

L1: inspect the local diff and nearby call chain without reading Memory OS by default.

Escalate to L2 only when the change touches routing, configuration, build entry points, public contracts, security, permissions, or shared modules.

## Steps

1. Check working tree status and current diff.
2. Identify changed entry points, route/config changes, shared modules, and contract changes.
3. Look for obvious runtime risks, boundary states, platform branches, and missing verification.
4. Recommend the smallest necessary validation command when needed.
5. Do not run full build, full test, code generation, dependency install, or write-mode lint/format unless the user asked or the risk requires it.

## Output

1. Blocking risks
2. Non-blocking risks
3. Suggested verification
4. Files reviewed
