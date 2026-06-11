---
title: "将 Skill 同步升级为 Adapter Shell 渲染与漂移检测管线"
status: pending
created_at: 2026-06-11T03:31:46.881Z
source: mcp
source_episode: conversation:2026-06-11;report:self-optimize-2026-06-09;report:self-optimize-2026-06-10
---

# Proposal: 将 Skill 同步升级为 Adapter Shell 渲染与漂移检测管线

## Summary

把现有 skills/<skill>/SKILL_SPEC.md + skills/registry.json 到 Claude/Codex adapter SKILL.md 的同步机制，升级为保留适配器可识别壳子的渲染管线，并增加 check 防漂移、workflow 触发和 validate/dashboard 使用入口。

## Scope

- Global / domain / stack / project-specific: Memory OS global adapter / skill maintenance infrastructure.
- Applies to: managed skills synced from `skills/<skill>/SKILL_SPEC.md` and `skills/registry.json` into Claude / Codex adapter skill discovery roots; the sync/check tooling and its maintenance workflow.
- Does not apply to: using an existing skill in a normal conversation; app/project business features called "skills"; unmanaged/manual adapter skills; changing model behavior by mapping Claude / Codex directly to raw `skills/<skill>/SKILL_SPEC.md`.

## Proposed Destination

- rules: no direct rule change in the first landing step; update adapter gate notes only if the sync contract changes.
- workflow: `workflows/skill-maintenance.md`.
- domain: none.
- stack: PowerShell maintenance tooling for Memory OS.
- skill: `skills/registry.json`, `skills/<skill>/SKILL_SPEC.md`, `adapters/<adapter>/templates/skill.md.tmpl`, generated `adapters/<adapter>/skills/<skill>/SKILL.md`.
- router: `router/workflow-map.md`.
- eval: `evals/router-test-cases.md` for workflow routing coverage; `evals/skill-trigger-test-cases.md` only when skill trigger behavior or skill roster changes.
- dashboard: existing `dashboard/skills.md`.
- tools: `tools/sync-skills.ps1`, `tools/validate-memory-os.ps1`.

## Rationale

## Context

当前 AI Memory OS 已有 managed skill 同步机制：

- `skills/<skill>/SKILL_SPEC.md` 是模型无关的 skill 核心逻辑事实源。
- `skills/registry.json` 是 managed skill 名单、description、adapter output 和 agentName 的配置源。
- `tools/sync-skills.ps1` 读取 shared spec 与 registry，生成 `adapters/claude/skills/<skill>/SKILL.md` 和 `adapters/codex/skills/<skill>/SKILL.md`。
- Claude / Codex 实际读取的是各自 adapter 目录下的生成物，不直接读取 `skills/<skill>/SKILL_SPEC.md`。
- 当前生成脚本已经会为 adapter `SKILL.md` 添加可识别的 frontmatter、generated 注释、source hash，并展开 shared spec 正文；这保证了 Claude / Codex 可以从各自 skill discovery root 正常识别 skill。

需要优化的是：当前同步脚本主要是“生成/覆盖”，还缺少 check-only 漂移检测、adapter shell/template 显式化、registry/schema 校验、状态矩阵、workflow 触发和 validate/dashboard 的使用入口。

本 proposal 的重点不是取消 adapter 生成物，也不是让模型直接映射 `skills/` 原始目录，而是在保留“adapter 可识别生成物”的前提下，把同步机制升级为更清晰、更安全的管线。

## Reusable Lesson

Skill 同步管线应区分三类文件职责：

1. shared spec 控制 skill 的模型无关语义。
2. adapter shell/template 控制某个模型/工具如何识别和加载 skill。
3. adapter `SKILL.md` 是生成物，供对应模型实际读取，不作为长期事实源手工维护。

防漂移不应通过要求不同 adapter 的 `SKILL.md` 逐字一致实现，而应通过比较“当前 adapter 生成物”与“当前 shared spec + registry + 对应 adapter shell/template 的渲染结果”是否一致来实现。

## Proposed Memory OS Change

### 1. 保持当前读取模型不变

继续保持：

```text
skills/<skill>/SKILL_SPEC.md
  # shared skill 语义事实源，人工维护

skills/registry.json
  # skill 名单、description、adapter 输出、agentName 等元数据，人工维护

adapters/<adapter>/skills/<skill>/SKILL.md
  # 对应模型实际读取的 generated artifact，不手工维护
```

不要改成：

```text
模型 skill discovery root -> skills/<skill>/SKILL_SPEC.md
```

原因：`SKILL_SPEC.md` 缺少 adapter 可识别壳子、frontmatter、description 注入、adapter-specific 变量替换；直接映射可能导致 skill 不被发现、description 不参与触发、模型读取格式不兼容。

### 2. 将“脚本内置壳子”升级为 adapter shell/template

在保持当前生成文件可被 Claude / Codex 识别的前提下，逐步引入：

```text
adapters/claude/templates/skill.md.tmpl
adapters/codex/templates/skill.md.tmpl
```

模板第一版必须与当前 `tools/sync-skills.ps1` 的生成结构等价，避免升级后破坏 Claude / Codex skill discovery。

当前生成结构的关键兼容要求必须保留：

```md
---
name: <skill-name>
description: "<registry description>"
---
<!-- Generated from <source>; source-sha256: <hash>; adapter: <adapter>. Do not edit by hand; run tools/sync-skills.ps1. -->

<expanded shared spec body>
```

如果后续某个 adapter 的 skill 格式确实不同，只修改该 adapter 的 template，不污染 shared `SKILL_SPEC.md`，也不要求 Claude / Codex 生成物逐字一致。

### 3. sync 脚本从 copy/inline-shell 升级为 render/check 管线

`tools/sync-skills.ps1` 的语义应改为：

```text
render(adapter shell/template, skills/<skill>/SKILL_SPEC.md, skills/registry.json)
  -> adapters/<adapter>/skills/<skill>/SKILL.md
```

渲染变量建议最小包含：

```text
{{name}}
{{description}}
{{source}}
{{source_sha256}}
{{adapter}}
{{agent_name}}
{{body}}
```

其中：

- `{{body}}` 是 shared spec 全文，且应继续支持当前 `{{AGENT_NAME}}` 替换逻辑。
- `{{description}}` 来自 `skills/registry.json`，必须保持 YAML/frontmatter 安全转义。
- `{{source_sha256}}` 主要作为追踪和诊断元数据，不作为漂移检测的唯一依据。
- 漂移检测的事实源应是“用当前 shared spec + registry + adapter template 重新渲染 expected output，然后与当前 adapter output 做完整内容比较”。hash 可以帮助定位 source 是否变化，但不能替代 expected-vs-actual 比较，因为手工改 generated output 时 header hash 可能不变。
- 当前 `tools/validate-memory-os.ps1` 已有基于 generated header hash 和 frontmatter 的弱校验；它能发现一部分 source 变更未同步问题，但不能稳定发现 generated output 被手工改写。落地后应让 validate 调用或复用 `sync-skills.ps1 -Check` 的 expected-vs-actual 结果，而不是继续维护一套重复的弱漂移检测。
- `template_sha256` 暂不要求写入 generated output；如后续需要追踪 template 变化，可作为内部诊断或在确认不影响 skill discovery 后再加入 generated 注释。
- expected render 与 actual output 比较应把输出编码和换行策略视为 render contract 的一部分；生成文件继续使用 UTF-8 no BOM，并采用固定换行策略，避免 PowerShell 读写差异导致无意义 `STALE`。

### 4. 增加 check-only 漂移检测

新增命令：

```powershell
pwsh tools/sync-skills.ps1 -Check
```

行为：

- 不写文件。
- 不创建目录、不补齐缺失文件、不调用任何会改变文件系统状态的生成逻辑。
- 读取 shared spec、registry、adapter template 和当前 adapter output。
- 重新渲染 expected adapter output。
- 比较 expected output 与当前 `adapters/<adapter>/skills/<skill>/SKILL.md`。
- 如果不一致，报告 `STALE` 或相关错误并返回非 0。

重要边界：

- `-Check` 不比较 Claude 与 Codex 的 `SKILL.md` 是否逐字一致。
- `-Check` 只比较“某 adapter 当前文件”是否等于“该 adapter 当前渲染结果”。

建议对外结果保持简洁，适合模型对话流程消费：

```text
OK
SYNCED
STALE
ERROR
```

含义：

- `OK`: check 通过，没有发现漂移。
- `SYNCED`: 执行同步后产物已写入或保持最新。
- `STALE`: check 发现当前 adapter output 与 expected render 不一致。
- `ERROR`: registry、source、template、path safety 或输出路径存在问题；具体原因写在错误消息中，不要求调用方理解大量细分状态码。

状态与 exit code 约定：

- `-Check` 模式只产生 `OK` / `STALE` / `ERROR`，不产生 `SYNCED`。
- sync 模式可产生 `SYNCED` / `ERROR`。
- 全部 `OK` 或 `SYNCED` 时返回 exit code 0；任一 `STALE` 或 `ERROR` 时返回非 0。
- 多 skill / 多 adapter 场景应输出一行 summary 和 per-item 明细，便于 `validate-memory-os.ps1` 或模型对话流程透传具体问题。

内部实现可以继续区分 `SOURCE_MISSING`、`TEMPLATE_MISSING`、`INVALID_REGISTRY`、`PATH_ESCAPE`、`ORPHAN_OUTPUT` 等原因，但这些不必成为对外 API。

### 5. 增加精确范围参数

建议支持：

```powershell
pwsh tools/sync-skills.ps1
pwsh tools/sync-skills.ps1 -Check
pwsh tools/sync-skills.ps1 -Skill memory-curator
pwsh tools/sync-skills.ps1 -Skill memory-curator -Check
pwsh tools/sync-skills.ps1 -Adapter claude
pwsh tools/sync-skills.ps1 -Adapter claude -Check
```

参数设计原则：这是主要给模型 workflow 和 validate 调用的维护脚本，不是面向人工日常频繁手敲的 CLI。首轮落地只保留能稳定完成同步和漂移检测的最小参数集，避免 `-Matrix`、`-Strict` 等额外开关增加维护成本和误用空间。模型若需要状态矩阵，可通过读取 `skills/registry.json` 和执行 `-Check` 的结果生成对话层摘要。

### 6. 增加 registry/schema 基础校验

对 managed skill 校验：

```text
name
status
source
managed
description
adapters
```

对 enabled adapter 校验：

```text
enabled
output
agentName
```

可选校验：

```text
template
```

建议规则：

- `name` 使用 kebab-case。
- `source` 默认形如 `skills/<name>/SKILL_SPEC.md`。
- `output` 默认形如 `adapters/<adapter>/skills/<name>/SKILL.md`。
- `description` 非空。
- active + managed skill 至少启用一个 adapter。
- registry 中所有 path 必须是相对路径，且不能逃出 Memory OS root；保留当前脚本已有路径安全边界。

### 7. 新增 skill-maintenance workflow

新增：

```text
workflows/skill-maintenance.md
```

职责：

- 新增 managed skill。
- 修改 existing skill 的 shared spec 或 registry description。
- 修改 adapter shell/template。
- 同步 adapter generated skill。
- 检查 generated skill 是否漂移。
- 删除/重命名 skill 时检查 router / dashboard / workflow / eval 引用。

添加一个 `Do not use when` 边界：用户只是要求使用已有 skill；用户只是生成/审查 pending proposal 时走 memory-retrospective / proposal-promotion；用户只是普通 diff review、自检或 bugfix。

重要优先级：

- 当任务对象是 `proposals/pending/*`，且用户要求审查、接受、拒绝、晋升或落地 proposal 时，主 workflow 仍然是 `proposal-promotion`。
- 即使 pending 内容涉及 skill 同步、adapter template 或 managed skill 维护，也不要直接改由 `skill-maintenance` 接管审查/晋升流程。
- `skill-maintenance` 只在 proposal 被接受后的实施阶段提供具体维护步骤，或在用户直接要求新增、修改、同步、校验 managed skill 且任务对象不是 pending proposal 时作为主 workflow。

建议在 `router/workflow-map.md` 增加触发项：

```text
新增 skill / 修改 skill / SKILL_SPEC / skills registry / sync-skills / adapter skill / Claude-Codex skill 同步
```

Use when：

```text
用户要求新增、修改、删除、重命名、同步或校验 Memory OS managed skill；或修改 skills/<skill>/SKILL_SPEC.md / skills/registry.json / adapter skill template。
```

Do not use when：

```text
用户只是使用已有 skill；普通项目里的“技能”泛称；非 Memory OS adapter skill；用户正在审查、接受、拒绝、晋升或落地 proposals/pending/*。
```

路由验证应优先补充 `evals/router-test-cases.md` 的 Workflow / Skill Probe Cases，确保“新增/修改/同步 managed skill”命中 `workflows/skill-maintenance.md`，同时确保“审查/晋升 skill 维护类 pending proposal”仍命中 `workflows/proposal-promotion.md`。只有 skill roster 或 skill description/trigger 变化时，才补充 `evals/skill-trigger-test-cases.md`。

### 8. 接入 validate 与 dashboard

将 `sync-skills.ps1 -Check` 接入 `tools/validate-memory-os.ps1`：在 validate 运行时对每个 enabled managed skill 执行 -Check，如果任何 skill 状态为 STALE 或 ERROR，validate 返回非 0 并列出具体问题。

validate 接入时应捕获并聚合 `sync-skills.ps1 -Check` 的 stdout/stderr 与 exit code，将结果加入现有 `$skillSyncProblems` 或等价问题列表；不要让子进程的非 0 exit code 在 `$ErrorActionPreference = "Stop"` 下提前中断整体 validate，导致后续检查无法继续执行。

不要求初始版本支持 `-Strict` 模式；基础 -Check 足够保证在总体验证流程中发现漂移。如果后续需要更严格的校验（orphan output、disabled skill output 残留、adapter 目录异常），可再补充，但不影响首轮落地是否通过。

与此同时增加或完善 `dashboard/skills.md`，用于记录：

- sync/check/matrix 常用命令。
- 新增 skill checklist。
- 修改 skill checklist。
- adapter shell/template 修改流程。
- generated artifact 不手改原则。
- 当前 active skill 覆盖矩阵或手动检查入口。

## Usage After Landing

### 新增 skill

```text
1. 新建 skills/<name>/SKILL_SPEC.md。
2. 更新 skills/registry.json，添加 source、description、adapter output、agentName。
3. 运行 pwsh tools/sync-skills.ps1 -Skill <name>。
4. 运行 pwsh tools/sync-skills.ps1 -Skill <name> -Check。
5. 运行 pwsh tools/validate-memory-os.ps1。
6. 若这是用户可直接触发的 skill，更新 router/skill-map.md 和 evals/skill-trigger-test-cases.md。
```

### 修改 skill 语义或工作流

```text
1. 修改 skills/<skill>/SKILL_SPEC.md。
2. 如触发描述变化，修改 skills/registry.json description。
3. 不直接修改 adapters/*/skills/<skill>/SKILL.md。
4. 运行 pwsh tools/sync-skills.ps1 -Skill <skill>。
5. 运行 pwsh tools/sync-skills.ps1 -Skill <skill> -Check。
6. 运行 pwsh tools/validate-memory-os.ps1。
```

### 修改 adapter skill 壳子

```text
1. 修改 adapters/<adapter>/templates/skill.md.tmpl。
2. 保证第一版模板与当前适配器可识别格式等价，避免破坏 skill discovery。
3. 运行 pwsh tools/sync-skills.ps1 -Adapter <adapter>。
4. 运行 pwsh tools/sync-skills.ps1 -Adapter <adapter> -Check。
5. 必要时实际验证该 adapter 是否仍能发现和触发 skill。
```

### 检查是否漂移

```powershell
pwsh tools/sync-skills.ps1 -Check
```

### 查看覆盖矩阵

首轮不要求 `sync-skills.ps1` 提供 `-Matrix` 参数。需要覆盖矩阵时，由 dashboard 或模型对话层读取 `skills/registry.json`，并结合 `pwsh tools/sync-skills.ps1 -Check` 的结果生成摘要，避免为首轮同步/漂移检测引入额外 CLI 开关。

### 总体验证

```powershell
pwsh tools/validate-memory-os.ps1
```

## Safety And Compatibility Requirements

1. 不让 Claude / Codex 直接读取 `skills/<skill>/SKILL_SPEC.md`。
2. 不删除 `adapters/<adapter>/skills/<skill>/SKILL.md` 生成物路径；这些路径仍是模型实际 discovery/read 的入口。
3. 不要求不同 adapter 的 `SKILL.md` 逐字一致。
4. 不把 adapter-specific frontmatter、description、loader 格式写进 shared `SKILL_SPEC.md`。
5. 第一阶段不得改变当前 Claude / Codex 已验证可识别的 `SKILL.md` 外壳结构。
6. 如果引入 adapter template，第一版模板必须渲染出与当前脚本等价的结构，或只做最小、可验证的非破坏性增量。
7. 引用检查和删除安全：
   - 先检查 router、workflow、dashboard、eval 和 adapter generated output 引用，不应由脚本静默删除。
8. 模板 hash 不影响检查：检查不是依赖 header hash 匹配，而是重新渲染 expected output 并与当前文件逐字节比较。hash 只用于诊断日志，不作为 check pass/fail 的决定性依据。

## Non-goals

- 不引入重型 agent runtime 或运行时 skill include。
- 不把 `skills/` 原始目录直接作为 Claude / Codex skill discovery root。
- 不取消 adapter-specific generated artifacts。
- 不要求所有模型共享同一个物理 `SKILL.md` 文件。
- 不绕过 pending proposal / 人工审核机制直接修改正式长期规则。
- 不把关键验证推迟到后续对话：首轮落地若修改 sync/render/check/validate，必须在同一轮完成最小验证；dashboard、workflow、router map 应随实现范围同步，但不得声称未验证已完成。

## Acceptance Criteria

1. 修改 `skills/<skill>/SKILL_SPEC.md` 后，如果未同步，`pwsh tools/sync-skills.ps1 -Check` 能发现对应 adapter output `STALE`。
2. 运行 `pwsh tools/sync-skills.ps1 -Skill <skill>` 后，`-Check` 通过。
3. adapter generated `SKILL.md` 被手改后，`-Check` 能发现差异（不管 header hash 是否一致）。
4. Claude / Codex 可以使用不同 adapter template，但各自 generated skill 必须能被对应适配器识别。
5. 第一版 adapter template 不破坏当前已验证的 Claude / Codex skill discovery 行为。
6. registry 缺少必填字段或 path 逃逸 root 时，脚本报清晰 `ERROR`。
7. `workflows/skill-maintenance.md` 和 `router/workflow-map.md` 能让后续”新增/修改/同步 skill”对话稳定进入维护流程。
8. `evals/router-test-cases.md` 覆盖新增 workflow 的正向命中和 pending proposal 审查/晋升的反向排除；只有 skill roster 或 skill trigger 行为变化时才更新 `evals/skill-trigger-test-cases.md`。
9. `pwsh tools/sync-skills.ps1 -Check` 在 output 文件或目录缺失时只报告 `STALE` / `ERROR` 并返回非 0，不创建目录、不补文件、不写入任何 generated artifact。
10. `pwsh tools/validate-memory-os.ps1` 调用 `pwsh tools/sync-skills.ps1 -Check`，若发现 STALE/ERROR 则 validate 失败。

## Source Task Or Evidence Summary

本 proposal 来自对 2026-06-09 与 2026-06-10 self-optimize 报告中 Skill 同步、adapter 生成、资源包化与防漂移建议的复盘，以及后续关于“模型 skill discovery 是否应直接映射 skills 原始文件”的设计讨论。结论是：保留当前 adapter generated skill 作为模型实际读取入口，增强同步管线的渲染、检查和维护 workflow，避免为防漂移而破坏 adapter skill 可识别壳子。

## Safety And Sensitivity Check

- 不包含 token、密码、cookie、PII、客户私有代码或生产私密日志。
- 只涉及 Memory OS 自身 skill 同步与治理流程。
- 本 proposal 仅进入 `proposals/pending/`，不直接修改正式 rules/router/workflows/skills/evals。

## Risks

- 是否过度泛化：范围覆盖 sync 脚本、adapter template、validate、workflow、router map 和 dashboard，属于一次较完整的维护管线升级；落地时应优先保证 `sync-skills.ps1 -Check`、template 等价渲染和 validate 接入，其他文档入口随实现同步，不额外扩展 CLI 选项。
- 是否包含敏感信息：无；内容只涉及 Memory OS 自身 skill 同步、生成物和维护流程。
- 是否与现有规则冲突：不与“shared spec 是事实源、adapter SKILL.md 是 generated artifact”的现有规则冲突；需要注意不要手改 adapter generated skill，不要要求 Claude/Codex 生成物逐字一致，也不要把 `skills/` 原始目录直接作为模型 discovery root。
