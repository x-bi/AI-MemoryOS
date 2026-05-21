# AI Memory OS Gate for Claude Code

This is the Claude Code bootstrap template for AI Memory OS.

Recommended user-level location:

```text
C:\Users\btf\.claude\CLAUDE.md
```

Memory OS root:

```text
C:\Users\btf\AI-MemoryOS
```

## Default Language And Style

- Reply in Chinese by default.
- Keep code, commands, logs, error messages, API fields, and technical terms in their original form when clearer.
- Lead with the conclusion, then give reasons, options, and steps as needed.
- Be concise, direct, and engineering-oriented.

## Memory OS Gate

Reading this file only loads Claude operating policy. It is not the same as reading Memory OS content.

Before each task, classify the Memory OS level:

- L0: Pure explanation, Q&A, single-point debugging, or simple local task. Do not read Memory OS content.
- L1: Lightweight workflow such as review, self-check, bugfix regression risk, routing/config/permission/build-entry checks, or post-task lightweight reflection. Prefer local/project facts first. Do not read Memory OS content unless the user explicitly asks.
- L2: Complex engineering tasks involving architecture, cross-module refactor, complex debugging, CI/CD, security/permissions, release flow, long-term conventions, broad review, or Memory OS maintenance. Read `C:\Users\btf\AI-MemoryOS\_index.md`, then read at most 3 directly relevant pages.
- L3: Memory writing. Only create or update `C:\Users\btf\AI-MemoryOS\proposals\pending\` when the user explicitly asks to capture, reflect, update Memory OS, generate a proposal, or confirms a suggested capture.

## Read And Write Boundaries

- Project-local `CLAUDE.md`, `AGENTS.md`, README, and code facts override Memory OS general rules.
- Reading Memory OS does not mean writing memory.
- New lessons must first go to `proposals/pending/`; do not directly modify formal rules, router, skills, or evals unless the user explicitly enters maintenance/promotion mode.
- Do not store tokens, passwords, secrets, cookies, PII, private production logs, customer private code, or unredacted sensitive data in Memory OS.
- Do not scan `raw/`, `proposals/accepted/`, or `proposals/rejected/` unless the user explicitly asks or the task clearly requires it.

## Verification

- For code/config changes, prefer lightweight checks first: inspect diff, call chains, routes/entry points, field contracts, boundary states, and obvious runtime risk.
- Do not run full builds, full test suites, dependency installs, generated-code updates, or format/lint commands with write effects unless the task requires it or the user asks.
- Before cleaning build/test/cache artifacts, constrain the path. Do not broaden cleanup to the whole repository.

## Final Trace

Except for very short confirmations, append one line at the end:

```text
OS: Lx; skills: ...; workflow: ...; read: ...; write: ...
```
