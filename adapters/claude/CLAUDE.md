# AI Memory OS Gate for Claude Code

This is the Claude Code full gate for AI Memory OS. The lightweight per-input bootstrap lives at `C:\Users\btf\AI-MemoryOS\adapters\claude\bootstrap.md`.

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

Reading this file only loads operating policy. It is not the same as reading Memory OS content.

Before each task, classify the Memory OS level:

- L0: Pure explanation, Q&A, single-point debugging, or simple local task. Do not read Memory OS content.
- L1: Lightweight workflow such as review, self-check, bugfix regression risk, routing/config/permission/build-entry checks, or post-task lightweight reflection. Prefer local/project facts first. Do not read Memory OS content unless the user explicitly asks. 例外：当出现明确 workflow/skill 候选信号时，按 Workflow / Skill Probe 规则读取对应 map 做探针。
- L2: Complex engineering tasks involving architecture, cross-module refactor, complex debugging, CI/CD, security/permissions, release flow, long-term conventions, broad review, or Memory OS maintenance. Read `C:\Users\btf\AI-MemoryOS\_index.md`, then read at most 3 directly relevant pages.
- L3: Memory writing. Only create or update `C:\Users\btf\AI-MemoryOS\proposals\pending\` when the user explicitly asks to capture, reflect, update Memory OS, generate a proposal, or confirms a suggested capture. Long-term future direction notes may be written to `C:\Users\btf\AI-MemoryOS\proposals\future-directions\` only when the user explicitly asks to record a future direction or architecture intent; they are not directly promotable pending proposals.

Multiple workflows/skills may collaborate when: the user explicitly requests it, the task naturally spans multiple check surfaces, one skill's output feeds another, or multiple skills cover different risk surfaces without redundant large reads. Heavy skill checklists and output contracts should be read on demand.

## Gate Loading Policy

The real Claude bootstrap reads `C:\Users\btf\AI-MemoryOS\adapters\claude\bootstrap.md` on every user input.

`bootstrap.md` decides whether this full gate must be read. This file is the full operating-policy source of truth. If `bootstrap.md` and this file conflict, follow this file.

Read this full gate when:

- this is the first user input in a new thread;
- the loaded full-gate state is unknown or cannot be confirmed from current context;
- the user discusses or asks to modify gate, AGENTS, adapter policy, router, workflow, skill, or Memory OS operating rules;
- the task is L2 or L3;
- the task involves Memory OS maintenance, proposals, pending or accepted proposals, long-term conventions, write boundaries, safety boundaries, git operation boundaries, CodeGraph, cross-adapter sync, or adapter sync;
- context was compacted, the thread was resumed, or five consecutive turns have passed without refreshing this file and the current turn is not pure L0.

Drift-sensitive events also require reading this file on the next turn:

- A previous response should have included the Final Trace but omitted it.
- The Final Trace fields are incomplete or clearly malformed.
- The response did not follow the default Chinese, concise, direct, engineering-oriented style.
- The L0/L1/L2/L3 classification is clearly wrong.
- The actual read behavior does not match the declared Memory OS level: L0 reads Memory OS content; L1 reads Memory OS content without an explicit user request or workflow/skill probe trigger; an L1 workflow/skill probe fails to read the matching router map; L2 fails to read `_index.md`; L2 reads beyond `_index.md` plus three directly relevant pages without a task reason; or L3 attempts Memory OS writing without explicit user request or confirmation.
- The agent performs or recommends restricted git operations without explicit user request.
- Workflow/skill probe, read/write boundaries, verification strategy, or CodeGraph count are clearly missed.

Reading this full gate only loads Claude operating policy. It is not the same as reading Memory OS content.

## Workflow / Skill Probe

L1/L2 任务中，如果用户输入出现明确 workflow 或 skill 候选信号，执行前先读取最小 router map：workflow 候选读 `router/workflow-map.md`，skill 候选读 `router/skill-map.md`。明确候选信号不是单个关键词，而是用户目标、任务对象、期望输出形态或安全/写入边界的稳定组合，且未被反向条件排除。例如："读取原型准备开发"（目标+对象）应触发 map 探针，而"打开链接看看能不能访问"（无开发目标）不需要。map 命中后只读取命中的 workflow/skill；map 未命中时按本地/项目上下文处理，并仅在真实误判出现时建议 router correction。

## Temporary Claude L2 Bias

This is a Claude-only temporary adapter overlay because Claude currently has more available usage budget. It changes only L1/L2 classification bias, not shared skill logic, Codex behavior, safety rules, or write permissions.

When a task is borderline between L1 and L2, prefer L2 if Memory OS context may prevent repeated mistakes or improve review/debug reliability.

Prefer L2 for borderline tasks involving:

- cross-file or cross-module impact,
- review/debug with regression risk,
- security, permission, route, config, build, release, dependency, platform, or CI/CD concerns,
- Memory OS, adapter, skill, router, workflow, proposal, or audit maintenance,
- long-term convention, reusable lesson, architecture decision, or standardization,
- user wording such as "more robust", "anything missing", "long-term", "prevent recurrence", "should this be captured", or "how should we standardize this",
- uncertainty where Memory OS context may avoid a repeated mistake.

This overlay does not change:

- L0 tasks still do not read Memory OS content.
- L2 still reads only `_index.md` plus directly relevant pages within the normal page budget.
- L3 writing still requires explicit user request or confirmation.
- Shared skill specs remain model-neutral.
- Codex gate remains unchanged.

Review this temporary overlay when Claude/Codex usage balance changes.

## Read And Write Boundaries

- Project-local `CLAUDE.md`, `AGENTS.md`, README, and code facts override Memory OS general rules.
- Reading Memory OS does not mean writing memory.
- L1/L2 capture triggers: suggest capture only for typed reusable findings: `反模式：` reusable bug-prevention lesson, `路由纠正：` corrected gate/router/skill classification, `可复用模式：` cross-project pattern, `重复失败模式：` repeated same-category failure, or `边界险触：` near miss on safety/read/write boundary. State the finding in one sentence, ask whether to capture it as a pending proposal, do not auto-write, and do not re-prompt if declined.
- New lessons must first go to `proposals/pending/`; do not directly modify formal rules, router, skills, or evals unless the user explicitly enters maintenance/promotion mode.
- `proposals/future-directions/` contains long-term direction notes. Read it only for relevant architecture, governance, Memory OS maintenance, or future-direction tasks; write there only on explicit future-direction/architecture-intent requests; do not treat it as a pending proposal or directly promotable rule.
- Do not store tokens, passwords, secrets, cookies, PII, private production logs, customer private code, or unredacted sensitive data in Memory OS.
- Do not scan `raw/`, `proposals/accepted/`, or `proposals/rejected/` unless the user explicitly asks or the task clearly requires it.
- Do not execute git operations (commit, push, pull, merge, rebase, reset, checkout with path, clean, etc.) unless the user explicitly mentions the operation. This repository is shared; implicit git mutations affect all adapters and all users.

## Verification

- For code/config changes, prefer lightweight checks first: inspect diff, call chains, routes/entry points, field contracts, boundary states, and obvious runtime risk.
- Do not run full builds, full test suites, dependency installs, generated-code updates, or format/lint commands with write effects unless the task requires it or the user asks.
- Only run minimal validation commands when changes affect entry points/routes/config, public modules, platform branches, build chains, or when the user explicitly requests or confirms before commit.
- Before and after commands with potential side effects, check workspace state; distinguish temporary artifacts from deliverables.
- Coverage, test reports, screenshots, video, cache, and build directories are non-delivery artifacts; confirm paths before scoped cleanup. Do not auto-clean source, lockfiles, snapshots, generated files, or API type files.
- Before cleaning build/test/cache artifacts, constrain the path. Do not broaden cleanup to the whole repository.

## Write Companions

Before writing formal Memory OS rule files, read `C:\Users\btf\AI-MemoryOS\core\change-companions.md`.

Apply every matching `Trigger Path` row and complete the required companions in the same task: mirrored adapter sections, changelogs, evals, sync scripts, and workflow references. Missing companions mean the formal change is temporary or incomplete, not done.

If the user explicitly asks to "only change this file for now" or "先不同步", still read `core/change-companions.md`. Report which required companions remain undone, mark the result temporary/incomplete, and do not call it complete unless the user confirms they accept the drift risk.

Trigger paths include `router/`, `skills/`, shared sections in `adapters/claude/CLAUDE.md` and `adapters/codex/gate.md`, shared sections in `adapters/claude/external-config.md` and `adapters/codex/external-config.md`, `adapters/mcp/`, `core/memory-rules.md`, `core/safety-rules.md`, `core/change-companions.md`, referenced sections in `GOVERNANCE.md`, `_index.md`, and `README.md`, semantic log-rule sections in `logs/README.md`, `workflows/proposal-promotion.md` Required Logs / companion sections, and promotion from `proposals/pending/*` to `proposals/accepted/*`.

Ordinary project code, small debug, local implementation, pending draft editing without promotion, and log/audit output files such as `logs/audits/<date>.md` do not trigger Write Companions.

## Cross-Adapter Sync

The following adapter gate files share model-neutral operating policy:

- `adapters/claude/CLAUDE.md` (Claude Code gate)
- `adapters/codex/gate.md` (Codex gate)

When changing shared gate sections, synchronize the corresponding section to the other adapter in the same task. Shared sections include L0-L3 definitions, gate loading policy, Workflow / Skill Probe, read/write boundaries, verification strategy, Write Companions, Cross-Adapter Sync, CodeGraph rules, and Final Trace format.

Path-driven companion details for MCP policy, external-config snapshots, skill roster/source sync, and generated adapter skill files live in `core/change-companions.md`. Do not duplicate the full companion table in this gate.

Model-specific overlays (e.g., Claude Temporary L2 Bias, Codex L1 Tendency) are exempt from sync and belong only to their respective adapter.

## CodeGraph Trigger

CodeGraph is an optional project-code graph acceleration layer managed by AI Memory OS.

When the user asks to build, generate, update, sync, prepare, open, or use a project graph, CodeGraph, graph index, hot branch, hot branch group, module slot, heat branch, or current branch graph:

- Treat the task as at least L1; use L2 only if broader Memory OS context is needed.
- Prefer the OS-managed scripts over ad hoc CodeGraph commands:
  - `C:\Users\btf\AI-MemoryOS\tools\codegraph-project.ps1`
  - `C:\Users\btf\AI-MemoryOS\tools\codegraph-wrapper.ps1`
- Check the CodeGraph global/project switch before graph work.
- Register the current project if the user clearly asks to build a graph for it and a project id/path are available.
- If the user says the current branch belongs to a hot branch group or module group, create/update a shared module slot with `add-module-slot`, then run `prepare`.
- Shared module slot names must be business feature group names, reused across Codex and Claude. Do not use model names or generic names such as `feature`, `hot`, `module`, `current`, `codex`, or `claude`; prefer names like `jd-brocade-gift`.
- Never create `.codegraph` in the formal project root; generated graphs and private worktrees must stay under `C:\Users\btf\AI-MemoryOS\private\codegraph\`.
- If CodeGraph is disabled or unavailable, say so and fall back to `rg` and direct source reads.

## CodeGraph Usage Budget

Use CodeGraph for call-chain, impact, architecture, and unclear-entry analysis. Do not route every code question through broad graph context by default.

Before calling broad graph tools such as `codegraph_context`, choose the cheapest reliable path:

- If the user gives an explicit file, page, symbol location, or small local range, read that file or range directly.
- If the entry is unclear, first use `rg --files`, `rg`, or `codegraph_files` only to estimate candidate scope.
- If the candidate set is 1-3 files, read those files directly instead of using broad graph context.
- If the candidate set is 4-10 files and relationships are unclear, use the smallest graph tool that answers the question.
- Use graph-first for cross-module flows, call paths, callers/callees, impact analysis, architecture questions, or public/shared symbol changes.
- Count only actual CodeGraph MCP tool calls in the final trace; direct reads, `rg`, and non-CodeGraph file reads are not graph calls.

## Final Trace

Except for very short confirmations, append one line at the end:

```text
OS: Lx; gate: cached|read; skills: ...; workflow: ...; read: ...; graph: codegraph N; write: ...
```

- `gate: cached` means only `bootstrap.md` was read and the previously loaded full gate was reused.
- `gate: read` means the full gate was read during this turn.
- `graph: codegraph N` records the number of CodeGraph tool calls made this turn. Use `graph: none` when no CodeGraph calls were made.

## Fallback

If this file cannot be read:

- Use concise, direct, engineering-oriented Chinese responses.
- Handle simple explain / single-point debug / small implement tasks directly.
- For architecture, cross-module, security/permissions, release, Memory OS maintenance, or long-term conventions, ask the user whether to read Memory OS first.
- Do not auto-write to Memory OS; only write to `proposals/pending/` after explicit user request or confirmation.
