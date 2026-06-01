---
title: Model-led Memory OS self-iteration automation plan
status: active-plan
created_at: 2026-05-29
related_source_path: C:\Users\btf\.claude\plans\effervescent-chasing-thunder.md
maintained_in: C:\Users\btf\AI-MemoryOS
document_type: implementation-plan
landing_strategy: two-round
round_1_status: implemented
round_2_status: implemented-non-model-verified
---

# Model-led Memory OS self-iteration automation plan

## Plan status

This file is the current implementation plan for model-led Memory OS self-audit, self-iteration, and self-optimization automation. The Claude plans path is a related draft/source path, but this repository copy is the maintained plan body used for execution.

This plan is not a skill and not a pending proposal. It is an implementation plan for building the `tools/auto/` automation framework under the normal repository maintenance process.

Implementation note on 2026-05-29: Round 1 is implemented and has produced Chinese-friendly run logs plus B-tier pending proposals. Round 2 implementation gaps are closed in code: model profile resolution, model invocation boundary, schema checks, ignored findings, locks, auto branch/commit helpers, cycle summary, repair/review support, dashboard integration, index registration, and validation checks are in place. Full model execution and full automation validation were intentionally not run, so the next step is user-led model-profile debugging before any real model-backed full cycle.

## Safety and sensitivity check

- No secrets, tokens, API keys, cookies, or production logs are intentionally added.
- This is a normal implementation plan; it does not by itself modify formal rules, router, skills, evals, or accepted/rejected proposals.
- The plan keeps model execution governed by scripts, A/B/C tiers, validation, sensitive-content checks, and auto/* branch boundaries.

## Two-round landing strategy

The detailed design below still lists the full target system, but implementation should land in two larger rounds instead of five small batches. The goal is to reduce coordination overhead while keeping each round independently reviewable and reversible.

### Round 1 - Foundation and proposal-capable audit loop

Round 1 proves that Memory OS can inspect itself, produce durable run records, and turn low-risk findings into B-tier proposal drafts without enabling unattended branching, automatic commits, pushes, or C-tier writes.

Scope:

1. Core infrastructure:
   - `templates/auto-run-log.md`
   - `templates/approval-sheet.md`
   - `rules/auto-run-operations.md`
   - `logs/auto-runs/.gitkeep`
   - `tools/auto/_shared.psm1`
   - `tools/auto/model-profiles.example.json`
   - `tools/auto/schemas/model-findings.schema.json`
   - `tools/auto/schemas/model-action.schema.json`
2. Deterministic audit scripts:
   - `audit-content-quality.ps1`
   - `audit-link-integrity.ps1`
   - `audit-skill-coverage.ps1`
   - `audit-router-consistency.ps1`
   - `audit-proposal-health.ps1`
3. B-tier iteration scripts:
   - `iterate-stale-content.ps1`
   - `iterate-duplicate-merge.ps1`
   - `iterate-skill-gaps.ps1`
   - `iterate-router-refinement.ps1`
   - `iterate-promotion-candidates.ps1`
4. Minimal orchestration:
   - `run-all.ps1 -Phase audit`
   - `run-all.ps1 -Phase iterate`
   - `-WhatIf` support
   - run-log writing
   - proposal dedupe and `-MaxProposals`
   - sensitive-content precheck

Round 1 explicit non-goals:

- No `auto/*` branch creation.
- No automatic commit or push.
- No unattended scheduled execution.
- No C-tier `--ApplyApproved`.
- No automatic changes to `core/`, `router/`, `rules/`, `skills/`, or adapter gates.
- Model semantic audit may be stubbed or schema-only until Round 2.

Round 1 acceptance:

1. `tools/auto/run-all.ps1 -Phase audit -WhatIf` reports intended checks and writes nothing.
2. `tools/auto/run-all.ps1 -Phase audit` writes structured logs under `logs/auto-runs/`.
3. `tools/auto/run-all.ps1 -Phase iterate -WhatIf` reports proposal candidates without writing proposals.
4. `tools/auto/run-all.ps1 -Phase iterate -MaxProposals 3` can create at most 3 B-tier pending proposals when findings exist.
5. Re-running the same inputs does not duplicate same-title proposals.
6. `tools/validate-memory-os.ps1` passes after Round 1 integration.

### Round 2 - Model-led automation and auto-branch review loop

Round 2 enables the full model-led cycle, including semantic audit, controlled A/C-tier handling, auto branches, repair, and human review assistance. It should start only after Round 1 has produced clean audit logs and proposal behavior.

Scope:

1. Model semantic audit:
   - `model-semantic-audit.ps1`
   - model profile resolution
   - schema validation
   - forbidden-action filtering
   - sensitive-content filtering
2. A-tier and C-tier optimization:
   - `optimize-frontmatter.ps1`
   - `optimize-dashboard-sync.ps1`
   - `optimize-skill-consistency.ps1`
   - `optimize-unused-pages.ps1`
   - `optimize-adapter-gate-sync.ps1`
   - `optimize-core-rules.ps1`
3. Full cycle entry and review:
   - `start-cycle.ps1`
   - full `run-all.ps1`
   - `repair-failed-cycle.ps1`
   - `review-cycle.ps1`
   - lock handling
   - `auto/*` branch handling
   - optional push only when explicitly enabled by script policy
4. Integration surfaces:
   - `dashboard/auto-runs.md`
   - `dashboard/home.md` link
   - `tools/validate-memory-os.ps1` required-file checks
   - `_index.md` reference to the new automation rule

Round 2 acceptance:

1. `tools/auto/start-cycle.ps1 -Scope content-quality -ModelProfile codex -WhatIf` completes a dry run with no file changes, no branch creation, no commit, and no push.
2. A real `start-cycle.ps1` run can create an `auto/*` branch, generate logs and summaries, and stop before any main merge.
3. C-tier changes generate approval sheets by default and execute only with explicit approved input.
4. `review-cycle.ps1` produces an audit summary and suggested human commands without merging, cherry-picking, switching main, or deleting branches.
5. Failure and repair paths leave enough logs to review what happened and never default to `git reset --hard` or force-push.
6. `tools/validate-memory-os.ps1` passes after Round 2 integration.

### Round 1 preparation checklist

Before implementing Round 1, confirm:

- `tools/auto/` is the only new script namespace for this automation.
- Round 1 writes only `logs/auto-runs/` and B-tier files under `proposals/pending/`.
- `-WhatIf` is implemented before any write path.
- Sensitive-content checks are available before any log or proposal write.
- Proposal creation reuses the existing `tools/new-proposal.ps1` behavior or matches its filename, encoding, and safety rules.
- The initial `run-all.ps1` supports only `audit` and `iterate` phases; `semantic-audit`, `optimize`, and `all` may return a clear "Round 2 not implemented" message.
- Any formal rule/index/dashboard updates required for Round 1 are kept small and are validated with `tools/validate-memory-os.ps1`.

## Detailed plan
# Memory OS Self-Audit / Self-Iterate / Self-Optimize 实施方案

## Context

AI Memory OS 当前有结构验证（`validate-memory-os.ps1`）和治理流程（GOVERNANCE.md），但缺少：

1. **内容质量检测** — 只有"文件有没有"，没有"内容好不好"
2. **自动发现问题** — 依赖人工审计才能发现 stale / duplicate / gap
3. **运行留痕** — 现有脚本只在终端输出，无结构化记录
4. **分级审批** — 没有区分哪些改动可以自动执行、哪些需要人审

本方案新增一套 `tools/auto/` 自动化框架，实现模型驱动的自审查 → 自迭代 → 自优化。模型是语义审查和优化判断主体；脚本负责调度、上下文打包、权限边界、结构校验、敏感内容过滤、A/B/C 分级、落盘、验证、commit + push 与留痕。每次运行产出完整记录，改动按 A/B/C 三级审批执行。

---

## 1. 核心设计

### 1.1 触发机制与模型主体定位

脚本支持两种触发模式，均通过同一套模型主体 + 脚本治理框架执行：

| 模式         | 触发方式                                                  | 适用场景                                                            |
| ------------ | --------------------------------------------------------- | ------------------------------------------------------------------- |
| **无人值守** | Windows 任务计划 / cron / PowerShell 定时任务             | 定期调用预设 model profile 自我审查，自生成 `auto/*` 分支供人工审核 |
| **AI 辅助**  | 用户在 Claude/Codex 中说“跑一下审计”或用 `/loop` 定时触发 | 当前会话模型辅助决策，脚本仍负责边界和落盘                          |

关键设计：**模型是自我迭代主体，脚本是治理外壳**。模型负责发现语义冲突、过时内容、重复概念、规则缺口、优化机会、proposal / 审批单 / patch 候选；脚本负责启动、上锁、读取与切分上下文、调用模型、校验结构化输出、敏感内容审查、A/B/C 分级拦截、validate、写入 `auto/*` 分支、commit + push 和运行留痕。

用户可以在运行前选择自动化使用的模型，例如 `codex`、`claude` 或自定义 OpenAI-compatible profile。选择方式：

- 命令参数：`-ModelProfile codex` / `-ModelProfile claude` / `-ModelProfile custom`
- 配置文件：`tools/auto/model-profiles.json`
- 环境变量覆盖：`AI_MEMORYOS_AUTO_MODEL_PROFILE`

`model-profiles.json` 只保存模型 profile 名称、调用方式、模型 id、端点环境变量名、超时、重试、预算和允许任务；不保存 token / API key 原文。密钥只能通过环境变量或系统安全存储读取。

模型允许执行的任务：

- `semantic-audit`：语义审查和优化点发现
- `draft-proposal`：生成 B 级 proposal 草稿
- `draft-approval-sheet`：生成 C 级审批单草稿
- `draft-a-patch`：生成 A 级可验证 patch 候选
- `explain-failure`：解释失败原因
- `suggest-repair`：给出 repair 建议

模型禁止直接执行：

- git 操作
- main 合并
- 删除分支
- 路径外写入
- 绕过 A/B/C 分级
- 绕过敏感内容检查
- 绕过 validate

**重要**：脚本只在用户主动触发时运行（手动调用、任务计划、或 AI 辅助模式下的显式指令），不会在正常使用 Memory OS 时自动挂载到会话开头/结尾，不挂在 git hook 上，不干扰日常开发。

**SelfMaintenance 放宽边界**：当且仅当运行 `tools/auto/*` 自我审计 / 自我迭代 / 自我优化脚本时，视为 Memory OS SelfMaintenance 模式。该模式允许脚本和被脚本调用的预设模型全量读取 Memory OS 仓库内容（包括 `raw/`、`proposals/accepted/`、`proposals/rejected/`、`core/`、`router/`、`rules/`、`adapters/`），因为目标就是审计系统自身；但写入仍必须按 A/B/C 分级，只能落在 `auto/*` 功能分支或运行日志 / proposal / 审批单等受控位置。此放宽不适用于普通 Codex/Claude 会话、业务项目、或非 `tools/auto/*` 脚本。

### 1.2 三级审批

| 等级  | 标准                                           | 执行方式                                                 | 示例                                           |
| ----- | ---------------------------------------------- | -------------------------------------------------------- | ---------------------------------------------- |
| **A** | 纯格式/汇总、完全可逆、不影响语义              | 脚本直接执行                                             | frontmatter 格式统一、dashboard 同步、日志写入 |
| **B** | 影响内容语义但不紧急                           | 只写 `proposals/pending/`，人审批后手动晋升              | 归档 stale 文件、合并重复、新增 skill 骨架     |
| **C** | 修改正式 rules/router/skills/core/adapter gate | 生成审批单 + diff 预览，人签字后 `--apply-approved` 执行 | 跨 adapter gate 同步、core 规则修改            |

### 1.3 运行记录

每次脚本运行产出 `logs/auto-runs/YYYY-MM-DD-HHMM-<script-name>.md`，中文为主、技术术语保留英文：

```markdown
---
run_id: ""
script: ""
triggered_by: "" # manual / scheduled / ai-assisted
model_profile: "" # codex / claude / custom
model_invocations_count: 0
model_tokens_estimate: 0
started_at: ""
duration_seconds: 0
exit_code: 0
findings_count: 0
actions_count: 0
pending_decisions_count: 0
max_severity: "" # critical / warning / info
status: "" # ready / failed / repaired / partial
branch: "" # auto/* branch, if any
lock_id: "" # concurrency lock id, if any
repair_attempts: 0
---

# 自动运行日志：<script>

## 运行上下文

- **功能分支**：auto/YYYY-MM-DD-<scope>
- **基线 commit**：<分支创建时的 main HEAD>
- **Memory OS 文件数**：
- **待审核 proposal 数**：
- **活跃 skill 数**：
- **关键目录快照**：
  - `proposals/pending/`：
  - `proposals/accepted/`：
  - `proposals/rejected/`：
  - `proposals/future-directions/`：
  - `logs/auto-runs/`：

## 输入

- **读取文件**：
- **运行参数**：

## 发现

| #   | 严重度 | 类别 | 说明 | 影响文件 | 审批等级 |
| --- | ------ | ---- | ---- | -------- | -------- |

## 已执行操作

| #   | 等级 | 操作 | 目标 | 状态 |
| --- | ---- | ---- | ---- | ---- |

## 待人工决策

| #   | 事项 | 等级 | proposal 路径或审批单 | 状态 |
| --- | ---- | ---- | --------------------- | ---- |

## 变更摘要

| 文件 | 新增行 | 删除行 | SHA256 |
| ---- | ------ | ------ | ------ |

## 修改后验证

- **validate-memory-os.ps1 结果**：通过 / 未运行
- **内容质量复查结果**：通过 / 未运行 / 回滚中

## 校验和

- **所有新/修改文件 SHA256**：
```

### 1.4 执行频率

不再是"每天一次"，改为**按类型分级频率**，资源充足时可连续执行：

| 阶段                 | 最小间隔         | 资源充足时                       | 理由                                    |
| -------------------- | ---------------- | -------------------------------- | --------------------------------------- |
| 审计（Phase 1A/1B）  | 无限制，随时可跑 | 可频繁跑；模型语义审计按预算控制 | 只读产出 findings，有模型成本和误报风险 |
| 迭代（Phase 2）      | 审计发现问题时   | 审计发现越多跑越多               | 只写 proposal，低风险                   |
| 优化 A 级（Phase 3） | 迭代完成后       | 审计→迭代→优化可连续跑           | 格式修改，低风险                        |
| 优化 B 级            | 同上             | 同上                             | proposal 通道                           |
| 优化 C 级            | 按需             | 人工审批后                       | 需签字                                  |

**核心原则**：模型语义审计是发现问题和优化机会的主体，可以多投入但必须受 token/时间/输出 schema 约束；确定性审计提供证据和兜底；迭代和优化是解决问题的手，按需投入。发现问题和解决问题可以不同频。以上频率仅指你主动触发脚本时，正常使用 Memory OS 不受影响。

**幂等保证**：同标题 proposal 不重复创建。但同一天对同一脚本多次运行是允许的（不再硬性限制），只是如果 findings 没有变化则不会产生新的 actions。

**修改后验证**：A 级/C 级修改完成后，自动重新运行 `audit-content-quality` 做验证，结果写入同一条运行日志的"修改后验证"章节。如果验证不通过，自动回滚（见 1.5 快照与回滚机制）。

### 1.5 基础设施层与产出层分离

**核心分层原则**：

| 层次           | 内容                                                               | 位置              | 提交方式                              |
| -------------- | ------------------------------------------------------------------ | ----------------- | ------------------------------------- |
| **基础设施层** | 脚本代码本身（`tools/auto/*.ps1`、模板、共享模块、治理规则）       | main 分支         | 正常开发流程，人工提交                |
| **产出层**     | 脚本运行产生的改动（proposal、frontmatter 修改、dashboard 同步等） | `auto/*` 功能分支 | 自动 commit + push，审核后合并到 main |

脚本必须先存在于 main 上，才能在功能分支上被调用执行。不能自己还不存在就跑。

### 1.6 功能分支策略

**所有自动产出的改动都在功能分支上**，main 上永远不会出现 `auto:` commit。

**分支命名**：`auto/YYYY-MM-DD-<scope>`

scope 由触发审计的发现领域决定：

| 分支名                            | 触发来源              | 包含的脚本                                                                 |
| --------------------------------- | --------------------- | -------------------------------------------------------------------------- |
| `auto/2026-05-28-content-quality` | 内容质量审计发现      | iterate-stale + iterate-duplicate + optimize-unused + optimize-frontmatter |
| `auto/2026-05-28-router-cleanup`  | 路由一致性审计发现    | iterate-router-refinement + optimize-adapter-gate-sync                     |
| `auto/2026-05-28-skill-health`    | skill 覆盖率审计发现  | iterate-skill-gaps + optimize-skill-consistency                            |
| `auto/2026-05-28-proposal-review` | proposal 健康审计发现 | iterate-promotion-candidates + iterate-stale-content                       |
| `auto/2026-05-28-full`            | 全量审计              | 全部脚本                                                                   |

**并发锁**：分支名不是锁。脚本启动时必须先原子创建 `logs/auto-runs/.locks/<scope>.lock/`，写入 `scope`、`branch`、`pid`、`started_at`、`triggered_by`。锁目录已存在时，同 scope 新任务拒绝启动；只有锁超时且进程不存在时，才允许按 stale lock 处理并记录日志。锁释放发生在 ready / failed / partial 状态写入完成之后。

**执行流程**：

```text
1. 抢占 scope lock，失败则退出并提示已有 cycle 在运行
2. 从 main 创建 auto/YYYY-MM-DD-<scope> 功能分支并切换
3. 在功能分支上运行脚本
4. 每个脚本有改动 → 自动 commit（message: auto: <script-name> - <简述>）+ push 当前 auto/* 分支
5. 如果脚本失败 → 写失败日志 + 标记 status=failed + commit/push 失败记录 + 停止后续产出型脚本
6. 如果脚本成功 → 生成 logs/auto-runs/<run-id>-cycle-summary.md → commit + push → 标记 status=ready
7. 释放 lock，等待用户人工审核功能分支
```

**审核与合并**：自动化脚本的终点是生成并推送 `auto/*` 功能分支。脚本阶段不执行 merge、不执行 cherry-pick、不污染 main。是否合并、何时合并、整块合并还是 cherry-pick，全部由后期人工审核并操作。

**回滚简化**：不合并就是回滚；最坏情况人工删除功能分支。脚本默认不使用 `git reset --hard`、不使用 `git push --force`。失败分支默认保留，用于审查失败日志和中间产物；删除失败分支只作为人工清理动作。

### 1.7 完整自我迭代的定义

一个功能分支上的自我迭代**完成**（即"分支就绪"，可以提交审核）= 满足以下全部条件：

**1. 流程闭环**：审计 → 迭代 → 优化三个阶段中，至少完成了审计和被触发的迭代/优化脚本

**2. 验证通过**：

- `validate-memory-os.ps1` 在分支上通过
- `audit-content-quality` 复查在分支上通过（findings 数量不增加）

**3. 产出完整**：

- 运行日志已写入 `logs/auto-runs/`，所有章节已填写
- 产出物已提交到分支：proposal 文件、修改的文件、审批单（如有 C 级）

**4. 闭环摘要**：在 `logs/auto-runs/` 下生成闭环摘要（与运行日志同目录，不污染仓库根目录），包含：

- 分支名、触发来源、运行时间
- 发现的问题数（按严重度分类）
- 执行的操作列表
- 需要人工审批的 B/C 级项目
- 验证结果
- 建议的合并策略（整块合并 / cherry-pick 指定 commit）

**5. 未合并前不算完成**：上面的条件是"分支就绪"，人审核合并后才算"迭代完成"。拒绝 = 删除分支，迭代中止。

### 1.8 自动 commit 与 push 规则

**授权边界**：用户授权本套自我迭代脚本在 Memory OS 仓库内自动创建、提交、推送 `auto/*` 功能分支；该授权不包含合并 main，也不扩展到其他仓库或普通对话。

允许：

- 仅在 `C:\Users\btf\AI-MemoryOS` 仓库内执行
- 仅由 `tools/auto/*.ps1` 触发 git 写操作
- 仅创建 / 切换 / 提交 / 推送 `auto/*` 分支
- 仅 push 当前 `auto/*` 分支
- commit message 使用 `auto: <script-name> - <中文简述>`

禁止：

- 不允许自动 merge 到 `main`
- 不允许直接 commit 到 `main`
- 不允许自动 rebase / force-push `main`
- 不允许操作其他仓库
- 默认不允许 `git push --force`

**仓库验证**：`Test-IsMemoryOsRepo` 必须同时验证：`$Root` 为 `C:\Users\btf\AI-MemoryOS` 或与 `AI_MEMORYOS_ROOT` 匹配；存在 `_index.md` + `GOVERNANCE.md` + `skills/registry.json`；`_index.md` 首行包含 `Memory OS Index`；当前 git root 等于 `$Root`；remote origin 包含 `AI-MemoryOS` 或处于明确允许的本地无 remote 模式。

**失败策略**：

| 场景                    | 默认策略                                                                         |
| ----------------------- | -------------------------------------------------------------------------------- |
| 脚本产出质量不合格      | 标记分支 `failed` 或 `partial`，保留分支供人工审查，不合并 main                  |
| 脚本中途出错            | 停止后续产出型脚本，写失败日志，commit + push 失败记录                           |
| 编排器中某个脚本失败    | 记录失败；已成功脚本的 commit 保留；后续是否继续只允许只读审计，不继续写入型脚本 |
| 脚本超时（默认 5 分钟） | 终止当前脚本，写 timeout finding，标记 `failed`                                  |
| 整个迭代不想要了        | 人工删除 `auto/*` 功能分支，main 无任何影响                                      |

**自我修复**：允许新增 `tools/auto/repair-failed-cycle.ps1` 对失败分支做有限次确定性修复，默认 `-MaxRepairAttempts 2`。修复范围只限结构性、可验证、可逆问题，例如 YAML/frontmatter 格式、日志字段缺失、UTF-8 no BOM / 换行、重复文件名、proposal stem 冲突、dashboard/dataview 生成格式、validate 明确指出的缺失文件。不得自动修复 rules/router/gate/core 的语义决策；这类问题只能生成 proposal / 审批单或等待人工处理。

**原子性保证**：A/C 级写操作必须先记录执行前 HEAD、文件 manifest 和每个目标文件 SHA256，再写入。失败时优先按 manifest 恢复本脚本触碰的文件；如果已经 push，则通过追加修复 commit 或 revert commit 处理，不默认重写远端历史。

**B 级脚本**：只写 `proposals/pending/`，写入前必须经过敏感内容审查，修改后自动 commit + push 当前 `auto/*` 分支。

**C 级脚本**：默认只生成审批单；只有明确 `-ApplyApproved` 且审批单签字项通过时，才在 `auto/*` 分支上执行对应修改并 commit + push。合并到 main 仍完全由人工决定。

### 1.9 权限处理

在 Claude Code 环境中，每个 Bash/Edit 都要人工确认权限。解决方案：

| 触发模式                         | 权限处理                                                                                      |
| -------------------------------- | --------------------------------------------------------------------------------------------- |
| **无人值守**（Windows 任务计划） | 脚本直接跑 PowerShell，无需 Claude 权限。在功能分支上工作，人审核分支后合并到 main            |
| **AI 辅助**（Claude 中执行）     | 用户可用 `/fewer-permission-prompts` skill 把 `tools/auto/*.ps1` 加入允许列表；或每次手动确认 |

脚本不依赖 Claude Code 的交互式权限确认；无人值守时由 PowerShell 主控，并可按 `ModelProfile` 调用 Codex / Claude / custom 模型。模型只负责语义审查、草稿和建议，不直接执行脚本、git 或文件写入；执行权仍在 PowerShell 脚本。

**main 分支保护**：脚本从不直接修改 main 分支。main 只通过人工审核合并功能分支来更新。

---

## 2. 新增文件清单

```
tools/auto/_shared.psm1                     # 共享工具模块
tools/auto/model-profiles.example.json       # 模型 profile 示例（不含 token）
tools/auto/schemas/model-findings.schema.json # 模型 semantic-audit 输出 schema
tools/auto/schemas/model-action.schema.json   # 模型 action / patch / proposal 输出 schema
tools/auto/audit-content-quality.ps1        # Phase 1: 内容质量审计
tools/auto/audit-link-integrity.ps1         # Phase 1: 链接完整性审计
tools/auto/audit-skill-coverage.ps1         # Phase 1: skill eval 覆盖率审计
tools/auto/audit-router-consistency.ps1     # Phase 1: 路由一致性审计
tools/auto/audit-proposal-health.ps1        # Phase 1A: proposal 生命周期审计
tools/auto/model-semantic-audit.ps1          # Phase 1B: 模型语义审查（自我迭代主体）
tools/auto/iterate-stale-content.ps1        # Phase 2: stale 内容归档 proposal
tools/auto/iterate-duplicate-merge.ps1      # Phase 2: 重复内容合并 proposal
tools/auto/iterate-skill-gaps.ps1           # Phase 2: skill 缺口 proposal
tools/auto/iterate-router-refinement.ps1    # Phase 2: 路由修正 proposal
tools/auto/iterate-promotion-candidates.ps1 # Phase 2: proposal 晋升候选标记
tools/auto/optimize-frontmatter.ps1         # Phase 3 A: frontmatter 标准化
tools/auto/optimize-dashboard-sync.ps1      # Phase 3 A: dashboard 同步刷新
tools/auto/optimize-skill-consistency.ps1   # Phase 3 B: skill 描述一致性
tools/auto/optimize-unused-pages.ps1        # Phase 3 B: 孤立页面归档
tools/auto/optimize-adapter-gate-sync.ps1   # Phase 3 C: 跨 adapter gate 同步
tools/auto/optimize-core-rules.ps1          # Phase 3 C: core 规则变更
tools/auto/run-all.ps1                      # 编排器：创建分支、运行脚本、生成闭环摘要
tools/auto/start-cycle.ps1                  # 入口脚本：创建功能分支 + 调用 run-all
tools/auto/repair-failed-cycle.ps1          # 失败分支确定性自修复脚本（有限重试）
tools/auto/review-cycle.ps1                 # 人工审核辅助：只生成审查摘要和建议命令，不执行合并
templates/auto-run-log.md                   # 运行记录模板
templates/approval-sheet.md                 # C 级审批单模板
templates/auto-cycle-summary.md             # 闭环摘要模板
logs/auto-runs/.gitkeep                     # 日志目录占位
tools/auto/.ignored-findings.json           # 忽略已知 finding 的配置
rules/auto-run-operations.md               # 自动运行治理规则
dashboard/auto-runs.md                      # 自动运行结果仪表盘
```

需要修改的现有文件：

- `dashboard/home.md` — 添加指向 `dashboard/auto-runs.md` 的链接
- `tools/validate-memory-os.ps1` — 添加新文件到 `$required` 检查列表
- `_index.md` — 引用 `rules/auto-run-operations.md`

---

## 3. 共享工具模块 `tools/auto/_shared.psm1`

复用 `validate-memory-os.ps1` 和 `sync-skills.ps1` 中的模式，提供统一接口：

### 3.1 路径安全函数

从 `validate-memory-os.ps1` 提取：

- `Get-MemoryOsRelativePath` — 绝对路径→相对路径
- `Test-MemoryOsPathInside` — 判断路径是否在 root 内
- `Resolve-MemoryOsRelativePath` — 相对路径→绝对路径（阻止目录遍历）
- `Test-ExcludedRepositoryScanPath` — 排除 .git/node_modules/private/.obsidian

### 3.2 运行日志函数

- `New-RunLog` — 创建日志文件，写入 frontmatter（run_id, script, triggered_by, started_at）
- `Add-RunLogContext` — 追加"运行上下文"章节
- `Add-RunLogInput` — 追加"输入"章节
- `Add-RunLogFinding` — 追加一条"发现"（严重度, 类别, 说明, 影响文件, 审批等级）
- `Add-RunLogAction` — 追加一条"已执行操作"（等级, 操作, 目标, 状态）
- `Add-RunLogPendingDecision` — 追加"待人工决策"项
- `Add-RunLogDiffSummary` — 追加"变更摘要"
- `Add-RunLogVerification` — 追加"修改后验证"结果
- `Complete-RunLog` — 计算校验和，更新 duration_seconds 和 exit_code

### 3.3 审批层函数

- `Invoke-ATierAction` — 执行 A 级动作：确认在 `auto/*` 功能分支上 → 记录执行前 HEAD + 文件 manifest + SHA256 → 内存中计算修改 → 一次性写入 → 自动 commit + push 当前 auto 分支 → validate + audit 复查 → 失败则按 manifest 恢复本脚本触碰的文件，必要时追加 revert/fix commit，不默认 `push --force`
- `New-BTierProposal` — 在 `proposals/pending/` 创建 proposal（复用 `templates/proposal.md` 格式，frontmatter 加 `generated_by: auto-iterate`），写入前强制 `Assert-NoSensitiveContent`，创建后自动 commit + push 当前 auto 分支
- `New-CTierApprovalSheet` — 在 `logs/auto-runs/` 创建审批单（使用 `templates/approval-sheet.md`）
- `Invoke-RepairAttempt` — 对 failed cycle 执行一次确定性修复尝试，记录 attempt 编号、修复类型、目标文件、验证结果；超过 `MaxRepairAttempts` 后停止

### 3.4 功能分支与并发管理函数

- `New-AutoBranch` — 从 main 创建 `auto/YYYY-MM-DD-<scope>` 分支并切换
- `Test-IsAutoBranch` — 检查当前是否在 `auto/*` 分支上，不在则拒绝执行产出层脚本
- `Get-AutoBranchScope` — 从分支名解析 scope，决定运行哪些脚本
- `New-AutoCycleLock` — 原子创建 `logs/auto-runs/.locks/<scope>.lock/`，防止同 scope 并发运行
- `Test-StaleAutoCycleLock` — 判断锁是否超时且进程不存在；只记录，不静默覆盖
- `Remove-AutoCycleLock` — ready / failed / partial 状态写入完成后释放锁
- `New-CycleReviewSummary` — 生成人工审核摘要和建议命令；不执行 merge / cherry-pick
- `Remove-AutoBranch` — 人工拒绝或合并后可清理功能分支；不由无人值守脚本默认执行

### 3.5 幂等与去重

- `Test-DuplicateProposal` — 检查 `proposals/pending/` 是否有同标题 stem 的 proposal
- `Test-DuplicateApprovalSheet` — 检查审批单是否已存在
- `Get-FindingFingerprint` — 基于 finding 类型、目标路径、规则名、规范化说明生成稳定 fingerprint

### 3.6 辅助函数

- `Get-FileSha256` — 包装 `Get-FileHash -Algorithm SHA256`
- `Assert-NoSensitiveContent` — 移植 MCP server 的 `SENSITIVE_PATTERNS` 检测逻辑；所有写入日志、proposal、审批单、dashboard、A/C 级修改前都必须经过审查
- `Read-MostRecentAuditLog` — 读取最近一次指定审计脚本的运行日志，供 iterate 脚本使用
- `Get-ActiveSkills` — 读取 `skills/registry.json` 提取 active skill 列表
- `Get-ModelProfile` — 读取 `tools/auto/model-profiles.json` / 环境变量，解析 `codex`、`claude` 或 custom profile；禁止读取明文 token
- `New-MemoryOsContextPack` — 按 scope 打包 Memory OS 上下文，输出文件清单、摘要、hash、相关片段和预算信息
- `Invoke-MemoryOsModel` — 按 profile 调用模型，只允许 `semantic-audit` / `draft-proposal` / `draft-approval-sheet` / `draft-a-patch` / `explain-failure` / `suggest-repair`
- `Assert-ModelOutputSchema` — 校验模型输出 JSON schema、必填字段、目标路径、tier、action 类型和置信度
- `Assert-ModelActionBoundary` — 拦截模型请求的 git/main/delete/path-outside/skip-validate 等越权动作
- `Invoke-AutoCommit` — 自动 commit + push 当前 `auto/*` 分支改动（message: `auto: <script-name> - <简述>`），返回 commit hash；拒绝 main 和非 Memory OS 仓库
- `Invoke-FailedCycleMark` — 写入 failed/partial 状态、失败原因、最后成功 commit、repair_attempts，并提交失败记录
- `Test-IsMemoryOsRepo` — 多重验证：`$Root` 匹配 Memory OS root；存在 `_index.md` + `GOVERNANCE.md` + `skills/registry.json`；`_index.md` 首行包含 `Memory OS Index`；git root 等于 `$Root`；remote origin 包含 `AI-MemoryOS` 或明确允许本地无 remote 模式

### 3.7 WhatIf / 演练模式

所有脚本必须使用 PowerShell 标准 `[CmdletBinding(SupportsShouldProcess)]`，所有写文件、commit、push、创建/删除分支、释放 stale lock 等动作都必须通过 `$PSCmdlet.ShouldProcess(...)`。`-WhatIf` 运行时只输出将要执行的动作，不写文件、不 commit、不 push。

---

---

## 4. 模板

### 4.1 `templates/auto-run-log.md`

```markdown
---
run_id: ""
script: ""
triggered_by: ""
started_at: ""
duration_seconds: 0
exit_code: 0
---

# 自动运行日志：<script>

## 运行上下文

- **功能分支**：auto/YYYY-MM-DD-<scope>
- **基线 commit**：<分支创建时的 main HEAD>
- **Memory OS 文件数**：
- **待审核 proposal 数**：
- **活跃 skill 数**：
- **关键目录快照**：
  - `proposals/pending/`：
  - `proposals/accepted/`：
  - `proposals/rejected/`：
  - `proposals/future-directions/`：
  - `logs/auto-runs/`：

## 输入

- **读取文件**：
- **运行参数**：

## 发现

| #   | 严重度 | 类别 | 说明 | 影响文件 | 审批等级 |
| --- | ------ | ---- | ---- | -------- | -------- |

## 已执行操作

| #   | 等级 | 操作 | 目标 | 状态 |
| --- | ---- | ---- | ---- | ---- |

## 待人工决策

| #   | 事项 | 等级 | proposal 路径或审批单 | 状态 |
| --- | ---- | ---- | --------------------- | ---- |

## 变更摘要

| 文件 | 新增行 | 删除行 | SHA256 |
| ---- | ------ | ------ | ------ |

## 修改后验证

- **validate-memory-os.ps1 结果**：通过 / 未运行
- **内容质量复查结果**：通过 / 未运行 / 回滚中

## 校验和

- **所有新/修改文件 SHA256**：
```

### 4.2 `templates/approval-sheet.md`

```markdown
---
run_id: ""
script: ""
created_at: ""
status: pending
---

# 审批单：<script>

## 待签字项目

| #   | 操作说明 | 目标文件 | 回滚命令 | 签字 |
| --- | -------- | -------- | -------- | ---- |

## 签字说明

1. 审阅上表每一项。
2. 同意的项目在"签字"列标记 `[x]`。
3. 运行脚本并传入 `--apply-approved <本文件路径>` 执行已签字项目。

## 执行记录

- **执行时间**：
- **执行人**：
- **已执行项目**：
```

### 4.3 `templates/auto-cycle-summary.md`

```markdown
---
branch: ""
scope: ""
triggered_by: ""
started_at: ""
completed_at: ""
status: ready # ready / approved / rejected / in-progress
baseline_head: "" # 分支创建时的 main HEAD
---

# 自我迭代闭环摘要：<scope>

## 基本信息

- **功能分支**：auto/YYYY-MM-DD-<scope>
- **基线 commit**：<main 分支创建分支时的 HEAD>
- **触发来源**：audit-content-quality / audit-router-consistency / full
- **运行时间**：<开始> ~ <结束>

## 发现统计

| 严重度 | 数量 |
| ------ | ---- |
| 严重   | 0    |
| 警告   | 0    |
| 信息   | 0    |

## 执行操作

| #   | 脚本 | 等级 | 操作说明 | 产出物 |
| --- | ---- | ---- | -------- | ------ |

## 待人工决策

| #   | 事项 | 等级 | proposal 路径或审批单 |
| --- | ---- | ---- | --------------------- |

## 验证结果

- **validate-memory-os.ps1**：通过 / 失败
- **audit-content-quality 复查**：通过 / 失败 / findings 数量变化

## 建议合并策略

- [ ] 整块合并（merge）
- [ ] Cherry-pick 指定 commit：列出 commit hash
- [ ] 需要修改后再审核

## 审核记录

- **审核人**：
- **审核时间**：
- **审核结论**：通过 / 拒绝 / 需修改
- **备注**：
```

---

## 5. 治理规则 `rules/auto-run-operations.md`

定义自动运行的运营合约：

- **审批等级映射**：明确哪些操作属于 A/B/C 级
- **触发方式**：支持无人值守（任务计划）和 AI 辅助（Claude/Codex 触发）两种模式；两种模式都可以指定 `ModelProfile`
- **执行频率**：审计无限制可频繁跑；迭代和优化按需。幂等保证不产生重复 proposal
- **失败/回滚策略**：不合并 = 回滚。脚本失败时保留 `auto/*` 分支、写 failed 日志并停止后续写入型脚本；可由 `repair-failed-cycle.ps1` 对确定性结构问题最多尝试 2 次修复。默认不使用 `git reset --hard` 或 `git push --force`，整批不想要可人工删除分支，main 永远不受影响
- **分支策略**：所有自动产出在 `auto/*` 功能分支上，脚本不在 main 上直接 commit。main 只通过人工审核合并功能分支来更新
- **自动提交与推送**：功能分支上自动 commit + push，commit message 以 `auto:` 前缀标识。此权限**仅限 Memory OS 仓库**，其他项目严禁 git 写操作。脚本内置 `Test-IsMemoryOsRepo` 验证，非 Memory OS 仓库拒绝执行
- **闭环摘要**：每次迭代完成后在 `logs/auto-runs/` 生成 `<run-id>-cycle-summary.md`，满足流程闭环 + 验证通过 + 产出完整 + 闭环摘要四个条件才算“分支就绪”
- **修改后验证**：A 级/C 级修改后必须通过 validate-memory-os.ps1 + deterministic audit + model semantic self-check 复查
- **超时保护**：单脚本默认 5 分钟超时，超时终止并回滚
- **敏感内容检测**：复用 MCP server 的 SENSITIVE_PATTERNS，写入 proposal 前必须检查
- **模型主体 / 脚本治理**：模型负责语义审查和优化判断；脚本负责上下文、权限、schema、敏感内容、A/B/C、validate、commit/push 边界
- **与 GOVERNANCE.md 的关系**：本规则是 GOVERNANCE.md 的补充，不替代其晋升/拒绝条件

---

## 6. Phase 1 脚本：自审查（模型主体 + 确定性证据）

Phase 1 分为两层：

- **Phase 1A deterministic audit**：脚本用固定规则收集事实证据，例如链接、frontmatter、registry、hash、文件存在性。
- **Phase 1B model semantic audit**：模型基于上下文包和 Phase 1A 证据做语义审查，是自我迭代的主体。

所有 Phase 1 脚本对 Memory OS 内容（rules/router/skills/core/proposals）只读，但会写入 `logs/auto-runs/` 运行日志。`model-semantic-audit.ps1` 可以调用用户预设 model profile；模型输出只作为 findings / proposal / patch 候选，必须经脚本治理校验后才允许进入 Phase 2/3。Phase 1B 不是“零风险”：它只读但会消耗模型预算，且可能误报，因此必须记录模型 profile、上下文预算、输出 schema 校验和 rejected outputs。

### 6.1 `audit-content-quality.ps1`（Phase 1A）

参数：`[string]$Root`, `[switch]$WhatIf`

逻辑：

1. 扫描所有 `.md` 文件（排除 .git/node_modules/private/.obsidian）
2. **重复检测**：去掉 frontmatter 和空白后计算内容 hash，>1 文件同 hash 报 warning
3. **空洞内容**：正文 <5 行 / 只含 TODO/TBD/placeholder 的报 warning
4. **过大文件**：>50KB 的 `.md` 报 info
5. **孤立文件**：不被任何文件链接、不在 `_index.md`/`STATUS.md`/`GOVERNANCE.md`/router/registry 中引用的报 info

### 6.2 `audit-link-integrity.ps1`（Phase 1A）

参数：同上

逻辑：

1. **Wiki link**：提取 wiki-link target，验证 target 路径 + `.md` 存在
2. **Markdown link**：提取 `[text](path)`，验证相对路径存在，跳过 http/https
3. **交叉引用一致性**：`_index.md`、router maps、`dashboard/`、`skills/registry.json` 引用的文件是否存在
4. **孤儿文件**：零入链且不在显式索引中

### 6.3 `audit-skill-coverage.ps1`（Phase 1A）

参数：同上

逻辑：

1. 读 `skills/registry.json` 提取 active skills
2. 读 `evals/skill-trigger-test-cases.md`，统计每个 active skill 的正/负例数
3. 缺少正例的 skill 报 critical；缺少负例的报 warning
4. 交叉检查 `validate-memory-os.ps1` 中硬编码的 `$activeSkills` 与 registry 是否一致
5. 检查 STATUS.md 列出的候选 skill 是否有 eval 覆盖

### 6.4 `audit-router-consistency.ps1`（Phase 1A）

参数：同上

逻辑：

1. 读三个 router map，提取所有 domain/task_type/skill 引用
2. 验证 skill-map 中的 skill 名与 registry.json active skills 匹配
3. 验证 domain-map 中的 domain 与 intent-map 引用的 domain 一致
4. 检测矛盾路由：同一信号在不同 map 中指向不同目标
5. 检查 `evals/router-test-cases.md` 中的 task_type/domain 是否在 map 中有定义

### 6.5 `audit-proposal-health.ps1`（Phase 1A）

参数：同上

逻辑：

1. 扫描 `proposals/pending/`：计算年龄，检查 frontmatter 完整性，检测重复主题
2. > 30 天的 pending proposal 报 warning；缺 frontmatter 字段报 critical
3. 扫描 accepted/rejected：检查是否有 decision_reason
4. 扫描 future-directions：验证 `type: future-direction-note` + `not_directly_promotable: true`
5. 识别晋升候选：>7 天、frontmatter 完整、scope 明确、无 TODO

### 6.6 `model-semantic-audit.ps1`（Phase 1B，模型主体）

参数：`[string]$Root`, `[ValidateSet("codex","claude","custom")][string]$ModelProfile`, `[string]$Scope`, `[int]$MaxFindings=20`, `[switch]$WhatIf`

逻辑：

1. 读取 `model-profiles.json` 和命令参数，确定使用 `codex` / `claude` / custom profile
2. 调用 `New-MemoryOsContextPack`，按 scope 打包 Memory OS 上下文和 Phase 1A 证据
3. 调用模型执行 `semantic-audit`，要求输出符合 `model-findings.schema.json` 的 JSON
4. 模型审查内容包括：语义冲突、重复概念、过时规则、缺失覆盖、proposal 质量、skill/eval 充分性、gate/core/router 不一致、可优化流程
5. 脚本执行 `Assert-ModelOutputSchema`、`Assert-ModelActionBoundary`、`Assert-NoSensitiveContent`、去重和 ignored finding 检查
6. 合格 findings 写入 run log，并作为 Phase 2/3 的输入；不合格输出记录为 rejected model output，不落盘为正式改动

---

## 7. Phase 2 脚本：自迭代（模型生成草稿，脚本只写 proposals/pending/，B 级）

### 7.1 `iterate-stale-content.ps1`

参数：`[string]$Root`, `[int]$StaleDays=30`, `[int]$MaxProposals=10`, `[switch]$WhatIf`

逻辑：

1. 读最近一次 `model-semantic-audit` 和 `audit-content-quality` 运行日志（无则跳过并 warning）
2. 对每个 stale/空洞 finding → 检查 `.ignored-findings.json` → `Test-DuplicateProposal` → `New-BTierProposal`（标题 "归档过期内容：<filename>"）
3. 达到 MaxProposals 上限后只记录不创建

### 7.2 `iterate-duplicate-merge.ps1`

参数：`[string]$Root`, `[switch]$WhatIf`

逻辑：

1. 读 `model-semantic-audit` / `audit-content-quality` 的重复 finding
2. 对每组重复 → `New-BTierProposal`（标题 "合并重复内容：<topic>"，列出所有重复文件，建议保留哪个）

### 7.3 `iterate-skill-gaps.ps1`

参数：`[string]$Root`, `[switch]$WhatIf`

逻辑：

1. 读 `STATUS.md` 剩余工作中的 skill 列表
2. 对比 `skills/registry.json`，找出缺失的 skill
3. 检查 eval 覆盖，缺覆盖的 → `New-BTierProposal`（标题 "补充 eval 覆盖：<skill-name>"）

### 7.4 `iterate-router-refinement.ps1`

参数：`[string]$Root`, `[switch]$WhatIf`

逻辑：

1. 读 `evals/router-correction-cases.md` 中的误分类
2. 对尚无对应 pending proposal 的 → `New-BTierProposal`（用 `templates/router-correction-proposal.md` 格式）

### 7.5 `iterate-promotion-candidates.ps1`

参数：`[string]$Root`, `[switch]$WhatIf`

逻辑：

1. 读 `audit-proposal-health` 的晋升候选 finding
2. 在候选 proposal 末尾追加 `## 自动检测：晋升候选` 段落（标注检测日期和满足的条件）
3. 不自动晋升

---

## 8. Phase 3 脚本：自优化（分级：A 自动 / B proposal / C 签字）

### 8.1 `optimize-frontmatter.ps1`（A 级）

参数：`[string]$Root`, `[switch]$WhatIf`

逻辑：

1. 扫描所有 `.md` 文件
2. 标准化：日期→ISO 8601、status 与目录位置一致、尾部换行一致
3. 记录执行前 HEAD hash + 文件 manifest + SHA256 → 内存中计算全部修改 → 一次性写入 → 自动 commit + push 当前 auto 分支 → validate → audit-content-quality 复查 → 失败则按 manifest 恢复本脚本触碰文件，或追加 fix/revert commit

### 8.2 `optimize-dashboard-sync.ps1`（A 级）

参数：`[string]$Root`, `[switch]$WhatIf`

逻辑：

1. 验证 `dashboard/skills.md` dataview 与 registry.json 一致
2. 验证 `dashboard/home.md` 链接完整
3. 验证 `dashboard/auto-runs.md` 存在且 dataview 正确
4. 记录执行前 HEAD hash + 文件 manifest + SHA256 → 更新 → 自动 commit + push 当前 auto 分支 → validate + audit 复查 → 失败则按 manifest 恢复本脚本触碰文件，或追加 fix/revert commit

### 8.3 `optimize-skill-consistency.ps1`（B 级）

参数：`[string]$Root`, `[switch]$WhatIf`

逻辑：

1. 对比每个 active skill 的 SKILL_SPEC.md 与 adapter SKILL.md 描述一致性
2. 不一致 → `New-BTierProposal`

### 8.4 `optimize-unused-pages.ps1`（B 级）

参数：`[string]$Root`, `[switch]$WhatIf`

逻辑：

1. 扫描零入链且不在 `$required` 列表中的 `.md`
2. → `New-BTierProposal`（标题 "归档孤立页面：<filename>"）

### 8.5 `optimize-adapter-gate-sync.ps1`（C 级）

参数：`[string]$Root`, `[switch]$ApplyApproved`, `[string]$ApprovalSheet`, `[switch]$WhatIf`

逻辑（无 `--ApplyApproved`）：

1. 对比 `adapters/codex/gate.md` 和 `adapters/claude/CLAUDE.md` 的 L0-L3 规则
2. 对比两个 `external-config.md`
3. 检测漂移 → `New-CTierApprovalSheet`（每项含 manifest restore / revert 说明，不要求自动执行 rollback）

逻辑（`--ApplyApproved`）：

1. 读取审批单，对签字项执行同步
2. validate + audit 复查 → 失败则按 manifest 恢复本脚本触碰文件，或追加 fix/revert commit；不默认重写远端历史

### 8.6 `optimize-core-rules.ps1`（C 级）

参数：同 8.5

逻辑：

1. 读 `core/`、`rules/`、`router/`，与 `_index.md` 和 `GOVERNANCE.md` 交叉引用
2. 找缺失引用和悬空引用 → `New-CTierApprovalSheet`

---

## 9. 入口与编排

### 9.1 `tools/auto/start-cycle.ps1`（入口脚本）

参数：`[string]$Root`, `[ValidateSet("content-quality","router-cleanup","skill-health","proposal-review","full")][string]$Scope="full"`, `[ValidateSet("codex","claude","custom")][string]$ModelProfile`, `[switch]$AuditOnly`, `[int]$MaxRepairAttempts=2`, `[switch]$Push`, `[switch]$WhatIf`

逻辑：

1. `Test-IsMemoryOsRepo` → 不是 Memory OS 仓库则拒绝
2. 抢占 `logs/auto-runs/.locks/<scope>.lock/`；锁存在且非 stale 时拒绝启动
3. 解析 `ModelProfile`：命令参数优先，其次 `AI_MEMORYOS_AUTO_MODEL_PROFILE`，最后读取 `model-profiles.json` 默认值
4. 如果 `-AuditOnly`：运行 Phase 1A deterministic audit + Phase 1B model semantic audit，输出到控制台 + `logs/auto-runs/`，不创建功能分支、不 commit、不 push，除非显式指定日志提交策略
5. 否则：`New-AutoBranch` → 运行 deterministic audit → 调用模型 semantic audit → 治理校验模型输出 → 运行迭代/优化脚本 → 有改动则 commit + push 当前 `auto/*` 分支 → 生成闭环摘要
6. 失败时：模型可执行 `explain-failure` / `suggest-repair`，脚本调用 `repair-failed-cycle.ps1` 最多 `MaxRepairAttempts` 次；仍失败则标记 `failed` 并停止
7. 成功时：标记 `ready`，输出分支名、model profile 和闭环摘要路径，等待用户审核
8. 释放 lock

### 9.2 `tools/auto/run-all.ps1`（编排器）

参数：`[string]$Root`, `[ValidateSet("audit","semantic-audit","iterate","optimize","all")][string]$Phase="all"`, `[ValidateSet("codex","claude","custom")][string]$ModelProfile`, `[int]$CycleTimeoutMinutes=30`, `[int]$SingleScriptTimeoutMinutes=5`, `[switch]$WhatIf`

执行顺序：

- Audit: 5 个 deterministic audit 脚本
- SemanticAudit: 1 个 model semantic audit 脚本
- Iterate: 5 个模型草稿 + 脚本治理的迭代脚本
- Optimize: 6 个模型建议 + 脚本治理的优化脚本

任何一个写入型脚本失败后，不继续执行后续写入型脚本；只允许继续只读审计和失败记录。编排器记录每个脚本的运行状态：

- 成功：日志中记录，必要时 commit + push 当前 auto 分支
- 失败：日志中标记，写 failed 状态，进入有限 repair 尝试
- 单脚本超时：终止当前脚本，写 timeout finding，标记 failed
- 全周期超时：终止剩余脚本，提交已有日志和失败摘要，标记 partial/failed

最终汇总输出：运行数、通过数、失败数、创建的 proposal 数、创建的审批单数、repair_attempts、最终 status。

### 9.3 `tools/auto/repair-failed-cycle.ps1`（失败自修复脚本）

参数：`[string]$Root`, `[string]$Branch`, `[int]$Attempt`, `[ValidateSet("codex","claude","custom")][string]$ModelProfile`, `[ValidateSet("frontmatter","encoding","runlog","proposal-stem","dashboard","validate-missing-file","all")][string]$RepairScope="all"`, `[switch]$WhatIf`

逻辑：

1. 验证当前分支是 `auto/*` 且有 failed/partial 运行日志
2. 读取失败日志、validate 输出、manifest 和最近一次 audit 结果
3. 可先调用模型执行 `explain-failure` / `suggest-repair`，但脚本只执行确定性结构修复：frontmatter、UTF-8 no BOM、日志字段、proposal stem、dashboard/dataview 格式、validate 明确缺失项
4. 每次 attempt 后运行最小验证
5. 修复成功则 commit + push 当前 auto 分支，并把 status 从 failed 更新为 repaired/ready
6. 修复失败且达到 `MaxRepairAttempts` 后停止，保留分支供人工审查

### 9.4 `tools/auto/review-cycle.ps1`（人工审核辅助）

参数：`[string]$Root`, `[string]$Branch`, `[switch]$WhatIf`

逻辑：

1. 验证分支存在且是 `auto/*` 前缀
2. 验证分支上有闭环摘要（确保迭代完整）
3. 生成审查摘要：变更文件、commit 列表、proposal/审批单、验证结果、敏感内容审查统计、建议人工命令
4. 不执行 merge、不执行 cherry-pick、不切换 main、不删除分支

## 10. 仪表盘 `dashboard/auto-runs.md`

用 Obsidian dataview 查询 `logs/auto-runs/` 目录，展示：

- 最近 20 次运行（脚本名, 退出码, 耗时, 开始时间）
- 待审批的审批单（status=pending）
- `dashboard/home.md` 的 Daily Entry 部分添加指向 `dashboard/auto-runs.md` 的链接

---

## 11. 实施顺序

Implementation uses the two-round landing strategy above. The Batch list below is retained as a detailed dependency map and file checklist, not as five separate delivery rounds.

- Round 1 includes Batch 1, the deterministic audit subset of Batch 2, Batch 3, and the minimal `run-all.ps1` orchestration needed for `audit` and `iterate`.
- Round 2 includes `model-semantic-audit.ps1`, Batch 4, the rest of Batch 5, dashboard/index integration, and full `start-cycle` / repair / review behavior.

### Batch 1 — 基础设施（无依赖）

1. `templates/auto-run-log.md`
2. `templates/approval-sheet.md`
3. `rules/auto-run-operations.md`
4. `logs/auto-runs/.gitkeep`
5. `tools/auto/_shared.psm1`
6. `tools/auto/model-profiles.example.json`
7. `tools/auto/schemas/model-findings.schema.json`
8. `tools/auto/schemas/model-action.schema.json`

### Batch 2 — Phase 1 审计脚本（依赖 Batch 1）

9. `audit-content-quality.ps1`
10. `audit-link-integrity.ps1`
11. `audit-skill-coverage.ps1`
12. `audit-router-consistency.ps1`
13. `audit-proposal-health.ps1`
14. `model-semantic-audit.ps1`

### Batch 3 — Phase 2 迭代脚本（依赖 Batch 2 审计结果）

15. `iterate-stale-content.ps1`
16. `iterate-duplicate-merge.ps1`
17. `iterate-skill-gaps.ps1`
18. `iterate-router-refinement.ps1`
19. `iterate-promotion-candidates.ps1`

### Batch 4 — Phase 3 优化脚本（依赖 Batch 2）

20. `optimize-frontmatter.ps1`
21. `optimize-dashboard-sync.ps1`
22. `optimize-skill-consistency.ps1`
23. `optimize-unused-pages.ps1`
24. `optimize-adapter-gate-sync.ps1`
25. `optimize-core-rules.ps1`

### Batch 5 — 编排与集成（依赖全部）

26. `start-cycle.ps1`
27. `run-all.ps1`
28. `repair-failed-cycle.ps1`
29. `review-cycle.ps1`
30. `dashboard/auto-runs.md`
31. 更新 `dashboard/home.md`（加链接）
32. 更新 `validate-memory-os.ps1`（加新文件到检查列表）
33. 更新 `_index.md`（引用新规则）

---

## 12. 验证策略

### 单脚本验证

1. `-WhatIf` 运行 → 无文件修改，只有控制台输出
2. 不带 `-WhatIf` 运行 → deterministic audit + model semantic audit 产生日志；迭代脚本使用模型草稿并产日志+proposal；优化 A 级产日志+自动修改；优化 C 级产日志+审批单
3. A 级修改后 → `validate-memory-os.ps1` 通过 + deterministic audit + model semantic self-check 复查通过
4. 运行日志 frontmatter → 合法 YAML
5. SHA256 → 与实际文件匹配

### 回滚 / 失败验证

1. 功能分支上脚本出错 → 写 failed 日志，commit + push 失败记录，保留 auto 分支
2. `repair-failed-cycle.ps1` 对确定性结构问题最多尝试 2 次，超过后停止
3. 整个迭代不想要 → 人工删除功能分支，main 无影响
4. 编排器中某个写入型脚本失败 → 不继续后续写入型脚本，只允许只读审计和失败记录
5. 超时场景 → 终止当前脚本，写 timeout finding，标记 failed/partial
6. `auto:` 前缀 commit 可通过 `git log --oneline --grep="^auto:"` 筛选
7. main 上没有任何 `auto:` commit

### 集成验证

1. `start-cycle.ps1 -Scope content-quality -ModelProfile codex -WhatIf` → 只报告将要执行的动作、模型 profile 和上下文预算，无文件修改、无 commit、无 push
2. `start-cycle.ps1 -Scope content-quality -ModelProfile codex` → 创建功能分支 → deterministic audit → model semantic audit → 脚本治理校验 → 生成闭环摘要 → push auto 分支
3. `run-all.ps1 -Phase audit` → 5 个 deterministic audit 脚本全部完成
4. `run-all.ps1 -Phase semantic-audit -ModelProfile claude` → 模型输出符合 schema 的 semantic findings
5. `run-all.ps1 -Phase iterate -ModelProfile claude` → 模型生成草稿，脚本治理后产出 proposals
6. `run-all.ps1 -Phase optimize -ModelProfile codex -WhatIf` → 只报告
7. `repair-failed-cycle.ps1 -Branch auto/2026-05-28-content-quality -ModelProfile codex` → 模型解释失败，脚本仅执行确定性结构修复
8. `review-cycle.ps1 -Branch auto/2026-05-28-content-quality` → 只生成审核摘要和建议命令，不合并 main
9. Obsidian dataview → `dashboard/auto-runs.md` 显示近期运行和 model profile

### 安全边界验证

1. 无脚本自动合并 main；自动化终点只能是 pushed `auto/*` 分支
2. 无脚本写入 `core/`、`router/`、`rules/`（除 C 级 `--ApplyApproved` 且仍只在 auto 分支）
3. B 级只写 `proposals/pending/`
4. C 级只创建审批单，`--ApplyApproved` 时只执行签字项
5. 路径遍历被阻止
6. 敏感内容检测阻止原文写入；日志只记录规则名、路径、行号范围、hash、统计数量
7. 模型输出包含 forbidden action（merge-main/direct-git/delete/path-outside/skip-validate）时被脚本拒绝
8. 同 scope 并发启动时，第二个实例因 lock 存在而退出### 关键复用文件

- `tools/validate-memory-os.ps1` — 路径安全模式、文件扫描逻辑、验证检查
- `tools/sync-skills.ps1` — SHA256 验证、UTF-8 no BOM 输出、registry 遍历
- `tools/new-proposal.ps1` — proposal 创建模式（日期前缀、安全文件名、UTF-8 no BOM 写入）
- `adapters/mcp/server/obsidian-memory-os-mcp.mjs` — `SENSITIVE_PATTERNS` 敏感内容检测、路径边界验证
- `skills/registry.json` — active skill 列表
- `GOVERNANCE.md` — 晋升/拒绝条件（自动运行规则必须与之一致）

---

## 13. 风险审查与修补记录

> 以下问题在方案设计审查中发现，并已作为修订纳入上方各章节或标注为“待实施时注意”。

### 13.1 已纳入方案的修复

| #   | 严重度 | 问题                                   | 修复方式                                                                                                                                 |
| --- | ------ | -------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------- |
| 1   | HIGH   | 审计脚本声称“不修改文件”但需写日志     | 明确：审计脚本对 Memory OS 内容只读，但可写 `logs/auto-runs/`。`-AuditOnly` 默认不创建分支、不 commit、不 push，除非显式配置日志提交策略 |
| 2   | HIGH   | 同日同名分支冲突 / 并发运行            | 新增 `logs/auto-runs/.locks/<scope>.lock/` 原子锁；分支名只用于产物归属，不作为并发锁                                                    |
| 3   | HIGH   | 自动脚本可能污染 main                  | 明确自动化终点是 pushed `auto/*` 分支；脚本不执行 merge/cherry-pick，不直接 commit main                                                  |
| 4   | HIGH   | 自动 commit/push 授权边界不清          | 授权仅限 `C:\Users\btf\AI-MemoryOS` + `tools/auto/*.ps1` + `auto/*` 分支；禁止其他仓库和 main 写入                                       |
| 5   | HIGH   | destructive rollback 可能丢人工改动    | 默认保留失败分支；按 manifest 恢复本脚本触碰文件；已 push 后追加 fix/revert commit，不默认 `push --force`                                |
| 6   | HIGH   | `Test-IsMemoryOsRepo` 三文件检查太弱   | 增加 root、git root、`_index.md` 首行、remote origin、`AI_MEMORYOS_ROOT` 多重校验                                                        |
| 7   | HIGH   | 失败后只能人工处理，自动闭环不足       | 新增 `repair-failed-cycle.ps1`，只对确定性结构问题做最多 2 次修复尝试                                                                    |
| 8   | HIGH   | 敏感内容可能被日志/proposal 二次扩散   | 所有写入口强制 `Assert-NoSensitiveContent`；日志只记录统计、规则名、路径、行号范围和 hash，不写 secret 原文                              |
| 9   | HIGH   | 无法忽略已知 finding（反复报同一问题） | 新增 `tools/auto/.ignored-findings.json`，iterate 脚本创建 proposal 前检查忽略列表                                                       |
| 10  | HIGH   | 方案重心误写成脚本主导                 | 明确模型是自我迭代主体，脚本是治理边界和执行外壳                                                                                         |
| 11  | HIGH   | 无人值守模型选择不清                   | 新增 `ModelProfile` 参数、`AI_MEMORYOS_AUTO_MODEL_PROFILE` 和 `model-profiles.json`，用户可预选 codex / claude / custom                  |

### 13.2 已纳入方案的设计优化

| #   | 优化                              | 说明                                                                                                                                |
| --- | --------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------- |
| 1   | SelfMaintenance 放宽读取          | `tools/auto/*` 自我维护脚本可全量读取 Memory OS 内容；普通会话仍按 gate 限制                                                        |
| 2   | 审计脚本可在 main 上运行          | 审计是发现问题的眼睛，不需要功能分支；默认只写本地日志，不自动提交 main                                                             |
| 3   | 运行日志 frontmatter 增加汇总字段 | 新增 `findings_count`、`actions_count`、`pending_decisions_count`、`max_severity`、`status`、`branch`、`lock_id`、`repair_attempts` |
| 4   | 标准 `-WhatIf` 语义               | 使用 `[CmdletBinding(SupportsShouldProcess)]` + `$PSCmdlet.ShouldProcess(...)`，演练模式不写文件、不 commit、不 push                |
| 5   | 迭代脚本不自行调用审计            | 缺少审计日志则跳过并 warning，由编排器保证 Phase 1 先于 Phase 2                                                                     |
| 6   | 新增全周期超时                    | `run-all.ps1` 整体超时 30 分钟，超时则终止剩余脚本并标记 partial/failed                                                             |
| 7   | 新增 `-MaxProposals` 参数         | 迭代脚本默认最多创建 10 个 proposal，超出部分只记录不创建                                                                           |
| 8   | 人工审核辅助替代合并脚本          | `review-cycle.ps1` 只生成审查摘要和建议命令，不执行合并                                                                             |
| 9   | Phase 1B 模型语义审查             | 新增 `model-semantic-audit.ps1`，用于发现固定脚本扫不出的语义冲突、重复概念、过时规则和优化机会                                     |
| 10  | 模型输出结构化治理                | 新增 model findings/action schema，所有模型输出必须先通过 schema、路径、tier、敏感内容和 forbidden action 校验                      |

### 13.3 待实施时注意（未纳入正文）

| #   | 严重度 | 问题                          | 建议                                                                                           |
| --- | ------ | ----------------------------- | ---------------------------------------------------------------------------------------------- |
| 1   | MEDIUM | validate 本身有 bug 导致误拒  | 可以提供 `--skip-validation` 调试参数，但必须只允许人工显式使用，且日志标记 validation skipped |
| 2   | MEDIUM | `_shared.psm1` 过大，50+ 函数 | 实施时考虑拆分为 `_paths.psm1` + `_runlog.psm1` + `_autocycle.psm1` + `_git.psm1`              |
| 3   | MEDIUM | 跨 scope finding 被遗漏       | 审计发现跨 scope finding 时记录为“超出本轮范围”，建议后续 cycle 处理                           |
| 4   | MEDIUM | 与 memory-curator skill 集成  | memory-curator 识别 `generated_by: auto-iterate` frontmatter，区分自动和手动 proposal          |
| 5   | MEDIUM | 周报审计模板需引用 auto-runs  | 更新 `templates/weekly-audit.md` 加入 auto-run 结果引用                                        |
| 6   | MEDIUM | 无人值守完成通知              | 周期完成时写入 `.flag` 文件或 Windows toast 通知                                               |
| 7   | LOW    | scope 映射硬编码              | 未来可提取为 `tools/auto/scopes.json` 配置                                                     |
| 8   | LOW    | 单脚本 enable/disable 配置    | 新增 `tools/auto/config.json` 或环境变量 `AI_MEMORYOS_DISABLED_SCRIPTS`                        |

## 14. 基线快照

- **Tag**: `auto-baseline/pre-scripts`
- **Commit**: `64ad752`
- **说明**: 自动脚本实施前的 main 状态，纯手动操作基线
