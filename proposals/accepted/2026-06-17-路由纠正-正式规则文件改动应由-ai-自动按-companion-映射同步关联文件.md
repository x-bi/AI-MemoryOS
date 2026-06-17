---
title: "路由纠正：正式规则文件改动应由 AI 自动按 companion 映射同步关联文件"
status: accepted
created_at: 2026-06-16
source: manual
source_episode: "conversation:2026-06-16-changelog-companion-sync-gap;conversation:2026-06-17-write-companions-single-source;bug:5-accepted-proposals-skipped-required-logs"
decision_reason: "This corrects a repeated formal-rule write drift where accepted proposals and router/gate changes missed required changelog, eval, mirror, sync, or workflow companions; centralizing the mapping reduces future routing and governance omissions."
---

# Proposal: 路由纠正：正式规则文件改动应由 AI 自动按 companion 映射同步关联文件

## Summary

改 router / skills / adapter gate / MCP 策略 / governance 等正式规则文件时，AI 应当按一份显式的 companion 映射自动同步关联文件（changelog、eval 正反样例、cross-adapter 镜像段、sync 脚本、proposal Required Logs），而不是依赖用户每次追问"还有什么文件要一起改"。

当前现状：5 个 accepted proposal（2026-05-26 vue-uni-app、2026-06-04 两条 workflow-map、2026-06-05 L1 probe、以及部分先前晋升）都漏写了 `logs/router-changelog.md` 或 `logs/memory-changelog.md` 中的对应条目，需要在 2026-06-16 一次性回填。同期发现 `evals/router-correction-cases.md` 截至 2026-06-16 曾长期为空表，从未承接历史路由漂移档案，后续才一次性回填。这不是 AI 偷懒，是机制存在缝隙。

本 proposal 的核心取舍：**companion 明细合并到一个地方维护；gate / workflow 等使用处只保留触发式指针，且指针必须要求 AI 真的读取 `core/change-companions.md` 后再写入，不只是“详见”式书签。**

## Reusable Lesson

路由纠正：正式规则文件的"配套同步关系"是稳定的 1→N 映射，应当编码为独立 map，并由两端 gate 显式声明"写入这些路径前必须读 map"。把同步责任放在 AI 操作那次改动的会话里，而不是放在用户记忆里，也不是放在只在晋升任务里加载的 promotion workflow 里。

## Scope

- Global / domain / stack / project-specific：global，覆盖整个 Memory OS 的正式规则写入边界。
- Applies to：
  - `router/intent-map.md`、`router/domain-map.md`、`router/workflow-map.md`、`router/skill-map.md`
  - `skills/<skill>/SKILL_SPEC.md`、`skills/<skill>/references/**`、`skills/registry.json`
  - `adapters/claude/CLAUDE.md` 与 `adapters/codex/gate.md` 的共享规则段
  - `adapters/claude/external-config.md` 与 `adapters/codex/external-config.md` 的共享外部配置段
  - `adapters/mcp/tool-policy.md`、`adapters/mcp/allowed-ops.md`
  - `core/memory-rules.md`、`core/safety-rules.md`、`core/change-companions.md`
  - `GOVERNANCE.md`、`README.md`、`_index.md` 中被其他文件引用的小节
  - `logs/README.md` 中日志类型、记录原则、changelog 落点等语义性说明
  - `workflows/proposal-promotion.md` 中与 Required Logs / companion 同步有关的小节
  - `proposals/pending/*.md` 晋升到 `proposals/accepted/`
- Does not apply to：
  - 普通业务项目代码、diff、debug、small implement 等 L0/L1 任务
  - `proposals/pending/` 内部草稿编辑
  - `private/`、`raw/`、`reports/`、`logs/audits/<date>.md` 自身（这些本身就是同步终点，不再向外扩散）

### Special Handling：Deferred Companions

用户明确说"只改这一处，先不同步"时，不取消 Write Companions 触发；命中正式规则路径仍必须先读 `core/change-companions.md`。该请求只改变完成状态：AI 必须报告命中的 Required Companions 哪些未完成，并把结果标记为临时/未完成。除非用户确认接受漂移风险，否则不应声明正式规则改动已完成。

## Proposed Destination

- core：新建 `core/change-companions.md`，集中维护改动 → 同步关联文件的映射表，作为 companion 明细的单一事实源。
- gate：在 `adapters/claude/CLAUDE.md` 与 `adapters/codex/gate.md` 共享段中新增 `## Write Companions` 触发式短规则，要求写入命中路径前必须读取 `core/change-companions.md`。
- gate cleanup：把现有 `## Cross-Adapter Sync` 中属于 1→N companion 映射的明细迁入 `core/change-companions.md`；gate 中保留触发条件、读取动作、例外与高层边界，不再维护重复明细。
- workflow：在 `workflows/proposal-promotion.md` 的 Required Logs 段引用 `core/change-companions.md` 中的 `proposals/pending/*.md → proposals/accepted/` 行，避免 Required Logs 双轨。
- tools：后续增强项，在 `tools/validate-memory-os.ps1` 中加 companion lint（warn，不阻断），作为事后兜底；不作为首版落地的必达条件。
- evals：在 `evals/router-test-cases.md` 或更合适的 eval 文件中增加正反样例验证 Write Companions 是否被触发。
- 不修改：L0-L3 定义、router map 触发含义、skill spec 业务内容、Final Trace 格式。

## Rationale

### 为什么靠 AI 自觉不可靠

1. `workflows/proposal-promotion.md` 已经在 Required Logs 段列出了 `logs/memory-changelog.md` / `logs/router-changelog.md` / `logs/skill-changelog.md`。
2. 5 次 accepted proposal 仍然全漏。
3. 根因：promotion workflow 只在 AI 识别到"晋升任务"信号时才被加载（candidate 信号见 `router/workflow-map.md`）。
4. 当用户直接说"改一行 map" / "把这条 Use When 加上" / "同步两端 gate"时，AI 把它当作普通编辑，不会主动读 promotion workflow，也就不会触发 Required Logs。
5. 同时 gate 中没有通用机制在写入 `router/`、`skills/registry.json`、`adapters/*/gate` 等路径时主动读取 companion 映射并补齐同步文件。
6. 结果：靠 AI 当次自觉 = 等下次再漏；靠用户口头追问 = 把同步责任错置在用户记忆上。

### 为什么不能把明细都塞 gate

- companion 关系条目会很长（router → changelog + eval；skills → sync-skills + adapter SKILL.md + skill-changelog；MCP 策略 → 两端 external-config；proposal 晋升 → Required Logs……），全塞 gate 会污染所有 L0/L1 任务的读取预算。
- 与 Workflow / Skill Probe 同样的设计取舍：**gate 精简到触发规则，详细映射放独立 map**。
- gate 只承担"什么时候必须去读这份 map"，map 承担"读了之后照哪条同步"。

### 为什么指针必须是触发器，不是书签

单纯写"详见 `core/change-companions.md`"不够，AI 可能只知道有这个文件但没有实际读取。gate 中的句式必须采用触发式约束：

- 条件：写入 Memory OS 正式规则 / router / skill / adapter / MCP / governance 等命中路径前。
- 动作：**必须先读** `core/change-companions.md`。
- 执行：按命中的 Trigger Path 同步全部 Required Companions。
- 完成标准：companion 未补齐不算改完，这是写入边界的一部分，不是建议；如果用户要求暂不同步，只能明确报告未完成项和漂移风险，不能把它包装成正式完成。

这与现有 `## Workflow / Skill Probe` 的机制同构：出现明确 workflow / skill 候选信号时，先读对应 router map；出现正式规则写入路径时，先读 companion map。

### 为什么需要处理 Cross-Adapter Sync 的关系

现有 gate 的 `## Cross-Adapter Sync` 段已经包含多条 1→N companion 关系，例如：

- 改 `adapters/claude/CLAUDE.md` 或 `adapters/codex/gate.md` 共享段 → 同步另一端。
- 改 `adapters/mcp/tool-policy.md` 或 `adapters/mcp/allowed-ops.md` → 同步两端 `external-config.md` 的 MCP safety 段。
- 改 `skills/<skill>/SKILL_SPEC.md` / `skills/<skill>/references/**` / `skills/registry.json` → 跑 `tools/sync-skills.ps1`、`tools/validate-memory-os.ps1`，不直接编辑 adapter 生成文件。

这些规则与 `core/change-companions.md` 的目标完全重叠。如果 gate 和 map 各维护一份明细，会制造新的双轨漂移。因此应当把 companion 明细合并到 `core/change-companions.md`，gate 只保留触发式读取规则与少量不可替代的高层边界。

### 为什么 1→N 映射可以稳定编码

- `router/*.md` 改动 → 必写 `logs/router-changelog.md` + 必加 `evals/router-test-cases.md` 或 `evals/skill-trigger-test-cases.md` 正反样例。这条规则在 `logs/router-changelog.md` 末尾已有"每次 router 变更都应补 eval case"的明文约定。
- `skills/<skill>/SKILL_SPEC.md` / `skills/<skill>/references/**` / `skills/registry.json` 改动 → 必跑 `tools/sync-skills.ps1` + `tools/validate-memory-os.ps1` + 必写 `logs/skill-changelog.md`；不直接编辑 adapter `SKILL.md`。这条规则已存在于 gate 的 Cross-Adapter Sync 第 6 条。
- `adapters/claude/CLAUDE.md` 与 `adapters/codex/gate.md` 共享段改动 → 必同步另一端镜像段；这条规则已存在于 Cross-Adapter Sync 第 1 条。
- `adapters/mcp/tool-policy.md` / `adapters/mcp/allowed-ops.md` → 必同步两端 `external-config.md` 的 MCP safety 段；这条规则已存在于 Cross-Adapter Sync 第 3 条。
- `proposals/pending/*` 晋升 → 必走 `workflows/proposal-promotion.md` 的 Required Logs；如属真实路由漂移修复，回填 `evals/router-correction-cases.md`。
- `core/memory-rules.md` / `core/safety-rules.md` / `GOVERNANCE.md` 改动 → 如 `README.md`、`_index.md`、两端 gate 中存在对修改段的具体引用（搜索命中或已有链接），则必须同步引用处；必写 `logs/memory-changelog.md`。
- `logs/README.md` 改动日志类型、记录原则、changelog 落点或审计记录说明 → 必检查 `core/memory-rules.md`、`GOVERNANCE.md`、`core/change-companions.md`、`workflows/proposal-promotion.md` 是否存在对应语义引用；必写 `logs/memory-changelog.md`。普通补字、格式整理或不改变记录语义的说明更新不触发向外扩散。

这些规则当前散落在 gate Cross-Adapter Sync 段、router-changelog 末尾、proposal-promotion workflow 等多处文档，从未集中。集中化是补齐执行衔接最低成本的路径。

### 与 Workflow / Skill Probe 的同构关系

可对照 2026-06-05 已 accepted 的 `l1-workflow-skill-候选信号应触发-router-map-轻量探针` proposal：

- 那次解决"L1 任务出现明确 workflow/skill 候选信号时如何读对应 map"。
- 本次解决"写入正式规则文件时如何读 companion map"。
- 都采用：gate 触发规则 + 独立 map 承载详细规则 + eval 做回归。
- 差异：本次必须避免"详见"式弱指针，明确写成"必须先读"，否则无法保证 AI 真的打开 map。

## Proposed Memory OS Change

### 1. 新建 `core/change-companions.md`

集中维护一张 companion 映射表，列以下字段：

- **Trigger Path Pattern**：触发的文件路径或 glob，如 `router/*.md`、`skills/<skill>/SKILL_SPEC.md`、`adapters/claude/CLAUDE.md` 共享段。
- **Required Companions**：必须同次同步的关联文件清单。
- **Forbidden Actions**：禁止动作，例如直接编辑 adapter 生成文件、跳过 sync/validate、把未补齐 companion 的结果声明为完成。
- **Required Verification**：必须执行或检查的验证动作，例如 sync 后立即 validate、检查 changelog/eval 行是否同次补齐。
- **Mechanism / Timing**：Manual（AI 写）/ Script（跑哪个脚本）/ Both；写入前读取 / 同次改动 / 晋升时 / 写入后验证。
- **Reference / Exception**：约定来源（gate 哪条 / governance 哪条 / 已有 changelog 末尾约定等）和可接受例外。

初版应至少覆盖以下行（细节落地时再 review 补全）：

```md
| Trigger Path | Required Companions | Forbidden Actions | Required Verification | Mechanism / Timing | Reference / Exception |
|---|---|---|---|---|---|
| router/intent-map.md, router/domain-map.md, router/workflow-map.md, router/skill-map.md | logs/router-changelog.md（必）；evals/router-test-cases.md 或 evals/skill-trigger-test-cases.md 正反样例（必） | 不得只改 router 而声明完成；不得把 eval 留给用户追问 | 检查 changelog 和 eval 是否同次补齐；如确有例外，写明未补齐原因 | Manual；写入前读 map；同次改动 | router-changelog 末尾约定 |
| skills/<skill>/SKILL_SPEC.md, skills/<skill>/references/**, skills/registry.json | tools/sync-skills.ps1（必跑）；tools/validate-memory-os.ps1（sync 后必跑）；logs/skill-changelog.md（必写） | 禁止直接编辑 adapters/*/skills/*/SKILL.md 或 adapters/*/skills/*/references/**；禁止跳过 sync/validate 后声明完成；禁止执行未被用户要求的 git 操作 | sync 后立即 validate，并报告结果；检查 adapter 生成物由脚本更新而非手写 | Both；写入前读 map；同次改动；sync 后立即验证 | Cross-Adapter Sync 第 6 条迁入 |
| adapters/claude/CLAUDE.md 共享段, adapters/codex/gate.md 共享段 | 另一端镜像段同步；logs/router-changelog.md 或 logs/memory-changelog.md（按改动类型必写） | 禁止只改一端共享段；禁止把 model-specific overlay 当成共享段强行同步 | 对照两端共享段；确认 model-specific overlay 例外是否成立 | Manual；写入前读 map；同次改动 | Cross-Adapter Sync 第 1 条迁入 |
| adapters/mcp/tool-policy.md, adapters/mcp/allowed-ops.md | adapters/claude/external-config.md MCP safety 段；adapters/codex/external-config.md MCP safety 段；logs/memory-changelog.md（必写） | 禁止只改 MCP 策略而不更新 adapter 外部配置快照 | 检查两端 external-config 的 MCP safety 描述是否同步 | Manual；写入前读 map；同次改动 | Cross-Adapter Sync 第 3 条迁入 |
| adapters/claude/external-config.md, adapters/codex/external-config.md 的共享 tool / MCP 配置段 | 另一端 external-config 对应段同步；logs/memory-changelog.md（如改变外部配置恢复规则） | 禁止一端外部配置长期漂移 | 对照两端对应段；确认本机私有差异不被误同步 | Manual；写入前读 map；同次改动 | Cross-Adapter Sync 共享配置规则迁入 |
| proposals/pending/*.md → proposals/accepted/ | 走 core/change-companions.md 中晋升行的 Required Logs；如属路由漂移修复，回填 evals/router-correction-cases.md | 禁止晋升后漏保留 source_episode；禁止只移动 proposal 不落地目标文件和日志 | 检查 accepted frontmatter、目标文件、Required Logs、相关 eval | Manual；晋升时 | proposal-promotion.md Required Logs 迁入 |
| core/memory-rules.md, core/safety-rules.md, GOVERNANCE.md | 如 README.md、_index.md、两端 gate 中存在对修改段的具体引用（搜索命中或已有链接），则同步引用处；logs/memory-changelog.md（必写） | 禁止只改核心规则而留下入口/索引/引用处反向漂移 | 搜索修改段标题或路径引用；检查被引用处是否需要同步 | Manual；写入前读 map；同次改动 | governance 改动隐含约定 |
| logs/README.md 中日志类型、记录原则、changelog 落点或审计记录说明 | 如 core/memory-rules.md、GOVERNANCE.md、core/change-companions.md、workflows/proposal-promotion.md 中存在对应语义引用，则同步引用处；logs/memory-changelog.md（必写） | 禁止只改日志目录说明而让 core/governance/workflow 中的记录规则继续指向旧语义；禁止把具体 changelog 条目当作规则源反向扩散 | 搜索被改日志名、记录原则关键词、Required Logs / 留痕 / 审计记录引用；确认改动是语义变化还是纯文字整理 | Manual；写入前读 map；同次改动；纯格式/错字修正可只报告不扩散 | logs/README.md 是日志规则说明源，不是普通 changelog 终点 |
| core/change-companions.md | logs/memory-changelog.md（必写）；如改变 Trigger Path、完成标准、Forbidden Actions、Required Verification 或例外语义，则补 `evals/router-test-cases.md` 的 Write Companions 样例；如影响 proposal 晋升行，则同步 `workflows/proposal-promotion.md` 引用段 | 禁止只改 companion map 而不记录规则来源和影响面；禁止让 gate/workflow 指针与 map 语义漂移 | 检查 changed rows 的 Reference / Exception 是否仍指向真实来源；检查 gate/workflow 触发式指针是否需要同步；检查 eval 是否覆盖语义变化 | Manual；写入前读 map；同次改动 | companion map 自维护规则 |
| workflows/proposal-promotion.md 的 Required Logs / companion 段 | core/change-companions.md 中 proposal 晋升行；logs/memory-changelog.md（必写） | 禁止在 workflow 与 companion map 双写完整明细 | 检查 workflow 是否只保留触发式读取规则，不复制完整 companion 表 | Manual；同次改动 | 避免 promotion workflow 与 companion map 双轨 |
```

格式仅为初稿，落地时由审核者最终决定列名与内容。

### 2. 两端 gate 共享段新增 `## Write Companions`

`adapters/claude/CLAUDE.md` 与 `adapters/codex/gate.md` 同步新增触发式指针，而不是"详见"式弱引用：

```md
## Write Companions

写入 Memory OS 内的正式规则文件前，必须先读 `core/change-companions.md`，
按命中的 Trigger Path 同步全部 Required Companions（镜像段、changelog、eval、sync 脚本），
并在同一轮内完成同步与日志写入。companion 未补齐不算改完，这是写入边界，不是建议。

如果用户明确要求"只改这一处，先不同步"，AI 必须报告命中的 Required Companions
哪些未完成，并把结果标记为临时/未完成；除非用户确认接受漂移风险，
否则不应声明正式规则改动已完成。

触发路径：`router/`、`skills/`、`adapters/claude/CLAUDE.md`、`adapters/codex/gate.md`、
`adapters/claude/external-config.md`、`adapters/codex/external-config.md`、`adapters/mcp/`、
`core/memory-rules.md`、`core/safety-rules.md`、`core/change-companions.md`、
`GOVERNANCE.md`、`_index.md`、`README.md` 中被引用的小节，
`logs/README.md` 中日志类型、记录原则、changelog 落点等语义性说明，
以及 `proposals/pending/*` 晋升到 `proposals/accepted/`。
普通业务代码、diff、debug、small implement 不触发。

Model-specific overlays（Claude Temporary L2 Bias、Codex L1 Tendency）不在 companion 同步范围，
除非改动同时触及共享规则段。
```

加在现有 `## Read And Write Boundaries` 段附近，与 `## Workflow / Skill Probe` 同等地位。

### 3. 清理 `## Cross-Adapter Sync` 的重复明细

把 `## Cross-Adapter Sync` 中属于 1→N companion 的明细迁入 `core/change-companions.md`，gate 中不再重复维护这些条目。

迁移原则：

- 迁入 map：共享 gate 段同步、CodeGraph 共享规则同步、MCP safety external-config 同步、skill roster/source sync、shared tool path external-config 同步等路径驱动的 companion 明细。
- 迁入 map 时不能只迁 Required Companions，还必须迁入 Forbidden Actions 与 Required Verification，例如"不直接编辑 generated adapter SKILL.md"、"sync 后立即 validate"、"不执行未被用户要求的 git 操作"。
- `core/change-companions.md` 是 companion 明细事实源，必须有自维护行；修改 map 自身时至少写 `logs/memory-changelog.md`，改变触发语义或完成标准时补 Write Companions eval。
- gate 保留："哪些 adapter 文件属于共享边界"、"model-specific overlay 例外"、"写入前必须读 companion map"等高层行为规则。
- 不能只写"详见"；必须写"命中这些路径前先读 `core/change-companions.md`"，确保 AI 有实际读取动作。

### 4. `workflows/proposal-promotion.md` 引用 change-companions

把 `Required Logs` 段从静态列表改为引用 `core/change-companions.md` 中 `proposals/pending/*.md → proposals/accepted/` 行，避免 promotion workflow 和 companion map 双轨。示意：

```md
## Required Logs

晋升 `proposals/pending/*.md` 到 `proposals/accepted/` 前，先读 `core/change-companions.md`，
按其中 proposal 晋升行补齐 Required Logs；如属真实路由漂移修复，同时回填 router correction eval。
```

### 5. 后续增强：`tools/validate-memory-os.ps1` 加 companion lint（warn 模式）

companion lint 不作为本 proposal 首版落地的必达条件。首版先解决 gate 触发读取、单一 companion map、promotion workflow 双轨和 eval 回归。若落地 lint，只能作为 warn 模式事后兜底，不替代 gate 规则。

先采用最近 commit / 当前工作区 diff 的轻量启发式，warn 不阻断。推荐先实现最近 commit 兜底，减少 mtime 误报；后续如需要再增加工作区实时检查。

初版检测：

- `router/*.md` 改动 → 检查 `logs/router-changelog.md` 是否同次有新条目，且相关 eval 文件是否同次改动或明确豁免。
- `skills/<skill>/SKILL_SPEC.md`、`skills/<skill>/references/**` 或 `skills/registry.json` 改动 → 检查 `logs/skill-changelog.md` 是否同次有新条目，并检查 sync/validate 产物一致性。
- `adapters/claude/CLAUDE.md` 与 `adapters/codex/gate.md` 共享段任一改动 → 检查另一端是否同次也改了，或确认命中 model-specific overlay 例外。
- `adapters/mcp/tool-policy.md` / `adapters/mcp/allowed-ops.md` 改动 → 检查两端 `external-config.md` 是否同次更新 MCP safety 段。

不通过时 warn，不阻断。这是事后兜底，不替代 gate 规则。

### 6. eval 回归

在 `evals/router-test-cases.md` 或更合适的 eval 文件中增加正反样例：

- 用户输入"在 skill-map 加一条触发条件" → AI 应在写 `router/skill-map.md` 之前/之时主动读 `core/change-companions.md`，并在同一轮内补齐 `logs/router-changelog.md` 与相关 eval。
- 用户输入"改一下 vue-change-self-check 的 SKILL_SPEC.md，加一条触发条件" → AI 应主动读 `core/change-companions.md`，同次跑 `tools/sync-skills.ps1`、`tools/validate-memory-os.ps1`，写 `logs/skill-changelog.md`，且不直接编辑 adapter 生成的 `SKILL.md`。
- 用户输入"调整 adapters/mcp/tool-policy.md 的 allowed operation" → AI 应主动读 `core/change-companions.md`，同次同步 `adapters/claude/external-config.md` 与 `adapters/codex/external-config.md` 的 MCP safety 段，并写 `logs/memory-changelog.md`。
- 用户输入"同步两端 gate 加一段安全规则" → AI 应主动读 `core/change-companions.md`，同次同步 Claude/Codex 两端 gate，并写对应 changelog。
- 用户输入"修一下 src/views/foo 的按钮颜色" → 不触发 Write Companions，按普通 L0/L1 处理。
- 用户输入"只整理 pending proposal 草稿文字，不晋升" → 不触发正式规则 companion；仍按 pending proposal 写入边界处理。
- 用户输入"只改 router/skill-map.md 这一处，先不同步" → AI 仍应读 `core/change-companions.md`，列出未完成 Required Companions，并标记为临时/未完成；不得声明正式规则改动已完成。

## Risks

- **map 维护成本**：`core/change-companions.md` 本身也会随仓库结构演化；如果维护跟不上，可能与现实脱节。缓解：在 governance 月度回顾或按需审计触发条件中加入"companion map 与现实是否一致"的检查项。
- **gate 膨胀**：`## Write Companions` 段只写触发条件、必须读取动作、完成标准和范围，不直接列 companion 明细，与现有 `## Workflow / Skill Probe` 同等粒度，不构成显著膨胀。
- **弱指针失效**：如果 gate 只写"详见 `core/change-companions.md`"，AI 可能不实际读取。缓解：统一采用"必须先读"、"命中 Trigger Path"、"未补齐不算改完"的触发式句型。
- **过度泛化**：companion 检查可能误伤普通业务编辑。缓解：明确 Trigger Path 限定在 Memory OS 仓库内的正式规则路径，普通业务代码不触发。
- **与 promotion workflow / Cross-Adapter Sync 双轨**：如果这些文件与 `core/change-companions.md` 都维护同步明细，可能漂移。缓解：明细统一迁入 `core/change-companions.md`；使用处只保留触发式读取规则。
- **临时不同步例外被滥用**：用户可能明确要求"先只改一处"。缓解：这不是完成豁免；AI 必须列出未完成 companion、标记临时/未完成，并在用户确认接受漂移风险前不声明正式完成。
- **lint 误报**：启发式 git diff / commit diff 配对可能存在合理例外（如 changelog 单独整理）。缓解：lint 只 warn，不阻断；用户可以选择忽略或补豁免说明。
- **跨适配器不对称**：本 proposal 影响两端 gate，必须同步 Codex / Claude；落地时一并修改两端。

## Safety And Sensitivity Check

- 不包含 token、密码、cookie、PII、生产日志原文、客户私有代码或未脱敏敏感数据。
- 不直接修改正式 router、skill、gate、workflow、core 或 governance 文件；本 proposal 仅写入 `proposals/pending/`。
- 不扩大默认 Memory OS 读取深度：companion map 仅在写入正式规则文件时读取，普通 L0/L1 任务不触发。
- 不改 L0-L3 定义、不改 Final Trace 格式、不改 skill 触发边界。

## Source Task Or Evidence Summary

- 真实事件序列：
  - 2026-05-26：accepted `修正 Vue/uni-app 改动检查未触发 vue-change-self-check`，但 `logs/router-changelog.md` 与 `logs/memory-changelog.md` 同期未补条目（2026-06-16 已回填）。
  - 2026-06-04：accepted `补充 workflow-map 以触发前端原型驱动开发流程` 与 `补齐 workflow-map 的通用 workflow 触发边界`，`logs/router-changelog.md` 与 `logs/memory-changelog.md` 同期未补条目（2026-06-16 已回填）。
  - 2026-06-05：accepted `L1 workflow/skill 候选信号应触发 router map 轻量探针`，gate 共享段已同步两端，但 `logs/router-changelog.md` 与 `logs/memory-changelog.md` 同期未补条目（2026-06-16 已回填）。
  - 2026-06-13：两条 accepted proposal，changelog 当次写齐了，对照下来证明只要流程走全就能覆盖。
  - `evals/router-correction-cases.md` 直至 2026-06-16 仍是仅表头空表，5 次真实漂移档案直到本次会话才回填。
- 正式事实：
  - `workflows/proposal-promotion.md` Required Logs 段已存在但只在晋升任务里被加载。
  - Cross-Adapter Sync 中已有多条 companion 明细，但散落在 gate 中，且没有通用"写入前读 companion map"机制。
  - `logs/router-changelog.md` 末尾已有"每次 router 变更都应补 eval case"约定。
- 现有相邻 accepted proposal：`2026-06-05-l1-workflow-skill-候选信号应触发-router-map-轻量探针.md` 解决 gate 与 router map 之间的读取衔接；本 proposal 解决 gate 与 companion map 之间的写入衔接，结构同构、不重复。
- 2026-06-17 追加澄清：companion 明细应合并到一个地方，但 gate 等使用处必须写成"必须先读 `core/change-companions.md`"的触发式指针，不能只是"详见"。

## Landing Plan

1. 审核本 proposal 的 companion 表行项，必要时补全或删减。
2. 新建 `core/change-companions.md`，落地最终表格，作为 companion 明细单一事实源；表格必须包含 Required Companions、Forbidden Actions、Required Verification 和例外说明，并包含 `core/change-companions.md` 自维护行。
3. 在 `adapters/claude/CLAUDE.md` 与 `adapters/codex/gate.md` 共享段新增 `## Write Companions` 段（触发式指针句型："必须先读"），同步两端。
4. 清理 `## Cross-Adapter Sync` 中与 companion 表重复的 1→N 明细：迁入 `core/change-companions.md`；gate 保留触发条件、例外和高层边界。
5. 修改 `workflows/proposal-promotion.md` 的 Required Logs 段，引用 `core/change-companions.md` 的 proposal 晋升行。
6. 在 eval 中增加 Write Companions 正反样例，至少覆盖 router、skill、MCP、gate、普通业务代码、pending 草稿不晋升、用户要求暂不同步七类场景。
7. 同次写入 `logs/memory-changelog.md` 与 `logs/router-changelog.md`（本 proposal 自身就是 companion 机制的第一个验收用例）。
8. 如有 skill 源或 registry 影响，运行 `tools/sync-skills.ps1` 后立即运行 `tools/validate-memory-os.ps1`；否则至少运行 `tools/validate-memory-os.ps1`。
9. 移动 proposal 到 `proposals/accepted/`，保留 `source_episode`。
10. companion lint 暂不作为首版必达条件；如后续决定落地，只以 warn 模式上线，优先检测最近 commit / 当前 diff 的漏配套。

## Acceptance Criteria

晋升后应满足：

- 用户说"改一行 router/skill-map.md 加触发条件"时，AI 在同一轮主动读 `core/change-companions.md` 并补齐 `logs/router-changelog.md` + eval 样例。
- 用户说"改一下某个 SKILL_SPEC.md 的触发条件"时，AI 在同一轮主动读 `core/change-companions.md`，跑 sync/validate，写 `logs/skill-changelog.md`，且不直接编辑 adapter 生成文件。
- 用户说"调整 adapters/mcp/tool-policy.md"时，AI 在同一轮主动读 `core/change-companions.md`，同步两端 external-config 的 MCP safety 段，并写 `logs/memory-changelog.md`。
- 用户说"同步两端 gate 加一段安全规则"时，AI 在同一轮主动读 `core/change-companions.md`，同步 Codex/Claude 两端 gate，并补齐对应 changelog。
- 用户说"修复 src/views/foo 的按钮"时，不触发 Write Companions，按普通任务处理。
- 用户说"只改这一处，先不同步"时，AI 会列出未完成 companion 并标记为临时/未完成；除非用户确认接受漂移风险，否则不声明正式完成。
- gate / workflow 中不再重复维护 companion 明细；明细集中在 `core/change-companions.md`。
- 首版不要求 companion lint；若后续落地 lint，则只能 warn，不阻断后续操作。

## Draft

参见 Proposed Memory OS Change 中各小节。本节不再额外提供草稿。
