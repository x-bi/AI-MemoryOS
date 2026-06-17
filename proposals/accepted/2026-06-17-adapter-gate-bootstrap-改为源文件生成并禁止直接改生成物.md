---
title: "adapter gate/bootstrap 改为源文件生成并禁止直接改生成物"
type: proposal
status: accepted
source: codex
source_episode: "conversation:2026-06-17-adapter-gate-bootstrap-sync"
created_at: "2026-06-17"
accepted_at: "2026-06-17"
decision_reason: "Codex / Claude adapter gate/bootstrap 已存在跨文件手工同步漂移风险；本次落地为共享源、adapter overlay、template 和 sync/check/validator 管线，保留真实入口路径并禁止直接改生成目标。"
scope: "adapter gate/bootstrap sync"
destination: "adapters/gate-source, adapter templates, tools/sync-adapter-gates.ps1, tools/validate-memory-os.ps1, core/change-companions.md, evals/router-test-cases.md, adapter gate Cross-Adapter Sync"
tags:
  - memory/pending
  - adapter/gate
  - sync
---

# Proposal: adapter gate/bootstrap 改为源文件生成并禁止直接改生成物

## Source 来源

- Date: 2026-06-17
- Trigger 触发原因：Codex / Claude adapter 已拆出每轮轻量 `bootstrap.md` 与按需完整 gate，但当前 `bootstrap.md` 和完整 gate 仍需要分别手写维护，存在跨适配器规则漂移。
- Related task 关联任务：讨论如何让 adapter bootstrap / full gate 由同一套源文件和脚本生成，同时保留 Codex / Claude 不同读取路径、文件名、格式和等级策略差异。
- Source Episode 溯源：conversation:2026-06-17-adapter-gate-bootstrap-sync

## Summary 摘要

将 Codex / Claude adapter 的 `bootstrap.md` 和完整 gate 改为由 `adapters/gate-source/**` 与 adapter templates 生成，并禁止直接修改 adapter 生成目标；后续规则变更必须改源文件后运行同步脚本和验证脚本。

## Scope 适用范围

- Global / domain / stack / project-specific：Global adapter maintenance
- Applies to 适用于：
  - `adapters/codex/bootstrap.md`
  - `adapters/codex/gate.md`
  - `adapters/claude/bootstrap.md`
  - `adapters/claude/CLAUDE.md`
  - adapter gate / bootstrap source and templates
  - adapter gate drift validation
- Does not apply to 不适用于：
  - 用户级真实入口文件的自动生成写入，例如 `C:\Users\btf\.codex\AGENTS.md`、`C:\Users\btf\.claude\CLAUDE.md`
  - managed skills 的 `tools/sync-skills.ps1` 机制本身
  - Cursor / Generic adapter 的独立读取策略
  - 已 accepted / rejected proposal 历史内容

## Proposed Destination 建议落点

- rules:
  - `adapters/codex/gate.md` 与 `adapters/claude/CLAUDE.md` 的 `Cross-Adapter Sync` / gate source 边界
  - `adapters/codex/bootstrap.md`、`adapters/codex/gate.md`、`adapters/claude/bootstrap.md`、`adapters/claude/CLAUDE.md` 顶部 generated marker
  - `core/change-companions.md` 中 adapter gate/bootstrap source、template、generated target 的 companion 边界
- workflow:
  - 可选新增或更新 adapter maintenance 文档，说明 source -> template -> generated target 的流程
- domain:
  - 无
- stack:
  - 无
- skill:
  - 无
- router:
  - 无
- eval:
  - `tools/validate-memory-os.ps1` 接入 `tools/sync-adapter-gates.ps1 -Check`
  - `evals/router-test-cases.md` 的 Write Companions 样例覆盖 gate source/template 修改与禁止直接改 adapter gate 生成目标

## Rationale 保留理由

当前 gate/bootstrap 变更需要人工同步 Codex 和 Claude，多处文件还存在 adapter 特有差异，例如 Codex L1 Tendency、Claude Temporary L2 Bias、不同真实入口路径和不同完整 gate 文件名。用共享源 + adapter overlay + adapter template 渲染，可以同时满足：

- 共享规则只维护一份，减少漂移；
- adapter 特殊策略保留在 overlay，不误伤另一个 adapter；
- 最终生成目标保持原路径和原文件名，不影响真实软件读取；
- validator 能用 `-Check` 发现 stale，而不是依赖人工记忆同步。

## Risks 风险

- 是否过度泛化：中等。应先只覆盖 Codex / Claude 的 bootstrap 和 full gate，不扩展到 Cursor / Generic adapter。
- 是否包含敏感信息：否。只涉及公开仓库内的 adapter 规则、路径和同步脚本。
- 是否与现有规则冲突：可能与当前 gate 中“手动同步 Codex / Claude gate”的 Cross-Adapter Sync 文字冲突；落地时应替换为“改 source/templates 后运行 sync/check/validate”，而不是继续要求手改两个 adapter gate。

## Draft 草稿

### 1. 新增 gate source 和 templates

建议最小结构：

```text
adapters/gate-source/shared/bootstrap-core.md
adapters/gate-source/shared/gate-core.md
adapters/gate-source/overlays/codex-bootstrap.md
adapters/gate-source/overlays/codex-gate.md
adapters/gate-source/overlays/claude-bootstrap.md
adapters/gate-source/overlays/claude-gate.md

adapters/codex/templates/bootstrap.md.tmpl
adapters/codex/templates/gate.md.tmpl
adapters/claude/templates/bootstrap.md.tmpl
adapters/claude/templates/CLAUDE.md.tmpl
```

职责边界：

- `shared/bootstrap-core.md`：Codex / Claude 共用的轻量 bootstrap 读取判断规则。
- `shared/gate-core.md`：Codex / Claude 共用的完整 gate 主体规则，例如 L0-L3 基础定义、读写边界、验证策略、CodeGraph、Final Trace。
- `overlays/codex-*.md`：Codex 特有路径、文件名、Codex L1 Tendency、Codex Desktop skill discovery 等。
- `overlays/claude-*.md`：Claude 特有路径、文件名、Temporary Claude L2 Bias、Claude Code 入口说明等。
- `templates/*.tmpl`：保留不同 adapter 的最终文件格式和识别入口，不强行统一 Codex / Claude 文件名。

renderer 应定义最小 token 集，避免把可参数化的 adapter 名称、路径和文件名复制进两个 overlay，造成新的隐形漂移。建议至少支持：

```text
{{adapter_name}}
{{agent_name}}
{{bootstrap_path}}
{{full_gate_path}}
{{user_entry_path}}
{{full_gate_filename}}
{{shared_bootstrap_core}}
{{shared_gate_core}}
{{overlay_body}}
```

### 2. 新增同步脚本

新增：

```text
tools/sync-adapter-gates.ps1
```

建议接口：

```powershell
tools/sync-adapter-gates.ps1
tools/sync-adapter-gates.ps1 -Check
tools/sync-adapter-gates.ps1 -Adapter codex
tools/sync-adapter-gates.ps1 -Adapter claude
tools/sync-adapter-gates.ps1 -OutDir private/tmp/gate-render
```

`-OutDir` 只能接受 Memory OS root 内的相对路径，推荐写入 `private/` 下的临时目录；必须拒绝绝对路径、`..` path traversal、以及任何会逃逸 Memory OS root 的路径。`-OutDir` 不得覆盖正式 adapter 目标；与 `-Check` 同时使用时只允许渲染和比较，不写回正式目标。

`-Check` 输出语义应与 `tools/sync-skills.ps1 -Check` 保持一致：

```text
OK adapter-gates
STALE adapter-bootstrap codex adapters/codex/bootstrap.md
STALE adapter-gate codex adapters/codex/gate.md
STALE adapter-bootstrap claude adapters/claude/bootstrap.md
STALE adapter-gate claude adapters/claude/CLAUDE.md
ERROR ...
```

### 3. 首次落地必须保证生成结果不偏离当前内容

首次引入 source/template/script 时，目标不是重写 gate 文案，而是把当前已可用内容反向拆成 source/template。

验收标准：

```text
tools/sync-adapter-gates.ps1 -Check
```

必须显示 `OK adapter-gates`。如果出现 `STALE`，先修 source/template，不直接覆盖当前 adapter 文件。

renderer 输出必须稳定：UTF-8 without BOM，去除多余尾随换行后补一个单独结尾换行。`-Check` 应按最终文本或字节的严格一致性比较，不做宽松 normalize，避免掩盖真实漂移。

首次落地也可以先输出到临时目录做对比：

```powershell
tools/sync-adapter-gates.ps1 -OutDir private/tmp/gate-render
```

确认渲染结果与当前四个 adapter 目标一致后，再允许写回正式目标。

首次落地允许的目标文件内容差异应仅限 generated marker 及其必要的单结尾换行稳定化；除 marker 和换行稳定化外，不应重写 gate/bootstrap 正文语义。

### 4. 禁止直接修改 adapter bootstrap / gate 生成目标

脚本和 source 建立后，应将以下文件视为生成物，不允许手工直接修改：

```text
adapters/codex/bootstrap.md
adapters/codex/gate.md
adapters/claude/bootstrap.md
adapters/claude/CLAUDE.md
```

规则变更只能修改：

```text
adapters/gate-source/**
adapters/codex/templates/bootstrap.md.tmpl
adapters/codex/templates/gate.md.tmpl
adapters/claude/templates/bootstrap.md.tmpl
adapters/claude/templates/CLAUDE.md.tmpl
```

然后运行：

```powershell
tools/sync-adapter-gates.ps1
tools/sync-adapter-gates.ps1 -Check
tools/validate-memory-os.ps1
```

不得通过直接编辑 adapter 生成目标绕过同步脚本。

### 5. 生成目标顶部标记

在四个生成目标顶部加入 generated marker：

```md
<!-- Generated from adapters/gate-source/** and adapter templates; render-sha256: <hash>; adapter: <adapter>; target: <bootstrap|full-gate>. Do not edit by hand; update source/templates and run tools/sync-adapter-gates.ps1. -->
```

`render-sha256` 应覆盖完整渲染输入，至少包括 shared source、adapter overlay、目标 template；如 renderer 行为会影响输出，也应纳入 hash 或通过脚本版本变更保证可追踪。render input hash 必须按固定 manifest 顺序计算，包含每个输入的相对路径、分隔符和 UTF-8 文本内容，不能依赖文件系统枚举顺序。

### 6. 接入 validator

`tools/validate-memory-os.ps1` 应调用：

```powershell
tools/sync-adapter-gates.ps1 -Check
```

并将 stale 结果纳入验证报告。validator 只检查漂移，不自动覆盖生成目标。

validator 必须把以下文件纳入 required 清单，缺失时直接失败，而不是跳过 adapter gate sync 检查：

```text
tools/sync-adapter-gates.ps1
adapters/codex/bootstrap.md
adapters/codex/gate.md
adapters/claude/bootstrap.md
adapters/claude/CLAUDE.md
adapters/gate-source/shared/bootstrap-core.md
adapters/gate-source/shared/gate-core.md
adapters/gate-source/overlays/codex-bootstrap.md
adapters/gate-source/overlays/codex-gate.md
adapters/gate-source/overlays/claude-bootstrap.md
adapters/gate-source/overlays/claude-gate.md
adapters/codex/templates/bootstrap.md.tmpl
adapters/codex/templates/gate.md.tmpl
adapters/claude/templates/bootstrap.md.tmpl
adapters/claude/templates/CLAUDE.md.tmpl
```

如果 `tools/sync-adapter-gates.ps1 -Check` 不存在、执行失败、输出 `STALE` 或输出 `ERROR`，`tools/validate-memory-os.ps1` 必须失败并报告原始问题摘要。

### 7. 更新 Write Companions 和 eval

落地时必须先更新：

```text
core/change-companions.md
evals/router-test-cases.md
```

`core/change-companions.md` 应新增或调整 adapter gate/bootstrap 相关 companion 边界：

- `adapters/gate-source/**`、`adapters/codex/templates/bootstrap.md.tmpl`、`adapters/codex/templates/gate.md.tmpl`、`adapters/claude/templates/bootstrap.md.tmpl`、`adapters/claude/templates/CLAUDE.md.tmpl` 是人工维护源。
- 修改这些源文件或模板后，必须运行 `tools/sync-adapter-gates.ps1`、`tools/sync-adapter-gates.ps1 -Check`、`tools/validate-memory-os.ps1`，并写 `logs/memory-changelog.md`。
- `adapters/codex/bootstrap.md`、`adapters/codex/gate.md`、`adapters/claude/bootstrap.md`、`adapters/claude/CLAUDE.md` 是生成目标，不得手工直接编辑后声明完成。
- 现有 shared gate row 不应继续要求手工同步两个 adapter gate；应改为要求修改 gate source/template 后通过 sync 脚本生成。

因为修改 `core/change-companions.md` 本身会触发它的自维护 companion，落地时还必须：

- 在 `logs/memory-changelog.md` 记录 companion map 变更来源和影响。
- 在 `evals/router-test-cases.md` 的 Write Companions cases 中增加正反样例：
  - 正向：修改 shared gate 规则时，应修改 `adapters/gate-source/**` 或对应 template，并运行 adapter gate sync/check/validate。
  - 反向：直接修改 adapter gate/bootstrap 生成目标时，不得声明正式完成；需要回到 source/template 或标记为临时未完成。

### 8. 更新文档和日志

落地时同步更新：

- `_index.md`
- `README.md`
- `STATUS.md`
- `adapters/codex/README.md`
- `adapters/claude/README.md`
- `adapters/codex/external-config.md`
- `adapters/claude/external-config.md`
- `logs/memory-changelog.md`

### 9. 保留真实软件读取兼容性

落地后必须同步更新 `adapters/codex/gate.md` 与 `adapters/claude/CLAUDE.md` 的 `Cross-Adapter Sync` 段落：共享规则不再要求手动分别修改两个 gate，而是要求修改 `adapters/gate-source/**` 或对应 template 后运行 `tools/sync-adapter-gates.ps1`、`tools/sync-adapter-gates.ps1 -Check`、`tools/validate-memory-os.ps1`。

不得改变真实读取入口：

```text
C:\Users\btf\.codex\AGENTS.md -> adapters/codex/bootstrap.md
C:\Users\btf\.claude\CLAUDE.md -> adapters/claude/bootstrap.md
```

不得改变最终 adapter 文件名：

```text
Codex full gate: adapters/codex/gate.md
Claude full gate: adapters/claude/CLAUDE.md
```

同步机制只改变维护方式，不改变运行时读取路径。
