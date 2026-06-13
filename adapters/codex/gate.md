# Codex Gate

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

## Workflow / Skill Probe

L1/L2 任务中，如果用户输入出现明确 workflow 或 skill 候选信号，执行前先读取最小 router map：workflow 候选读 `router/workflow-map.md`，skill 候选读 `router/skill-map.md`。明确候选信号不是单个关键词，而是用户目标、任务对象、期望输出形态或安全/写入边界的稳定组合，且未被反向条件排除。例如："读取原型准备开发"（目标+对象）应触发 map 探针，而"打开链接看看能不能访问"（无开发目标）不需要。map 命中后只读取命中的 workflow/skill；map 未命中时按本地/项目上下文处理，并仅在真实误判出现时建议 router correction。

## Codex L1 Tendency

This is a Codex-only temporary adapter overlay. The current priority is expanding real task coverage: L1 defaults to triggered; L2 content reads and L3 writes remain conservative.

This overlay does not change:

- L0 tasks still do not read Memory OS content.
- L2 still reads only `_index.md` plus directly relevant pages within the normal page budget.
- L3 writing still requires explicit user request or confirmation.
- Shared skill specs remain model-neutral.
- Claude gate remains unchanged.

Codex Desktop discovers skills from `C:\Users\btf\.codex\skills`; active skills are junction-mapped. Do not assume external repo skills are auto-discovered.

Review this overlay when task coverage or model balance changes.

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

## Cross-Adapter Sync

The following shared sections exist in BOTH adapter gate files. When modifying any of these sections, you MUST synchronize the change to the other adapter:

- `adapters/claude/CLAUDE.md` (Claude Code gate)
- `adapters/codex/gate.md` (Codex gate)

Sync scope:

1. **Gate rules** (L0-L3 definitions, verification strategy, trace format, read/write boundaries) — any change must be applied to both files.
2. **CodeGraph rules** (trigger, usage budget) — same.
3. **MCP safety boundary** — when modifying `adapters/mcp/tool-policy.md` or `adapters/mcp/allowed-ops.md`, also update the MCP safety description in both `adapters/claude/external-config.md` and `adapters/codex/external-config.md`.
4. **Skill roster changes** — when adding, removing, or renaming an active skill, update `skills/registry.json` then run `tools/sync-skills.ps1`. Skill descriptions are shared at the skill level; do not add per-adapter descriptions.
5. **Shared tool paths** (wrapper, MCP server script, etc.) — when changing a path, update both external-config files.
6. **Skill source changes** — when modifying `skills/<skill>/SKILL_SPEC.md` or `skills/registry.json`, run `tools/sync-skills.ps1` then `tools/validate-memory-os.ps1` immediately as the closing step of the same task, then report the result. Do not ask the user to confirm before running these two scripts; do not run any git operation. Do not directly edit adapter `SKILL.md` files; they are generated copies and will be overwritten by sync. The shared spec (`SKILL_SPEC.md`) is the single source of truth.

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
OS: Lx; skills: ...; workflow: ...; read: ...; graph: codegraph N; write: ...
```

- `graph: codegraph N` records the number of CodeGraph tool calls made this turn. Use `graph: none` when no CodeGraph calls were made.

## Fallback

If this file cannot be read:

- Use concise, direct, engineering-oriented Chinese responses.
- Handle simple explain / single-point debug / small implement tasks directly.
- For architecture, cross-module, security/permissions, release, Memory OS maintenance, or long-term conventions, ask the user whether to read Memory OS first.
- Do not auto-write to Memory OS; only write to `proposals/pending/` after explicit user request or confirmation.
