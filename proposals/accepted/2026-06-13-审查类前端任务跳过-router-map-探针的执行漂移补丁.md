---
title: "审查类前端任务跳过 router map 探针的执行漂移补丁"
status: accepted
created_at: 2026-06-13
source: manual
source_episode: "bug:goodsPurchaseBan-review-skill-map-probe-skipped-2026-06-13"
decision_reason: "Accepted and landed: updated workflow review routing for non-default baseline changesets, added router probe evals, and recorded router/memory changelogs."
---

# Proposal: 审查类前端任务跳过 router map 探针的执行漂移补丁

## Summary

补齐 `2026-06-05-l1-workflow-skill-候选信号应触发-router-map-轻量探针.md` 落地后的执行缝隙：gate 已有 `## Workflow / Skill Probe` 软约束规则，`router/skill-map.md` 也已写明"新增功能全量 / 从零到现在 / 上线前累计变更"等扩展基线触发条件，但 `router/workflow-map.md` 的 review workflow 仍只显式覆盖 diff / PR / commit / staged / current changes，未把"新增前端目录 / 从零到现在"这类非默认基线 changeset 写入 workflow 触发面。实际运行时模型可能凭记忆按普通 L1 review 自走，既没有读取 map，也没有进入 `vue-change-self-check` 的四段式输出。

本 proposal 不重写 gate 探针规则，也不在 Final Trace 上增加任何字段（trace 当前统计项已足够，不再扩张）。补丁只做两件事：

1. 在 `router/workflow-map.md` 的 review workflow 触发边界中显式加入"新增功能全量 / 从零到现在 / 上线前累计变更"等非默认基线 changeset，并要求前端文件范围命中时继续读取 `router/skill-map.md` 判定 `vue-change-self-check` / `frontend-component-review`。
2. 在 `evals/router-test-cases.md` 增加该场景的回归样例，**用输出形态判分**（是否走 vue-change-self-check 四段式：变更影响扫描 / 风险清单 / 建议验证路径 / 本次未覆盖盲区），而非依赖 trace 字段。

## Scope

- Global：影响 `router/workflow-map.md` 的 review workflow 触发边界 + `evals/router-test-cases.md` 的 probe 回归样例
- Applies to：`router/workflow-map.md` 的 `review diff / PR / commit / staged changes / current changes` 行；`evals/router-test-cases.md` 中已存在的 `## Workflow / Skill Probe Cases` 子表
- Does not apply to：L0 任务；`router/skill-map.md`（已正确覆盖 skill 分流，无需修改）；`router/intent-map.md`；L0-L3 定义；`adapters/claude/CLAUDE.md` / `adapters/codex/gate.md`；`## Final Trace` 格式
- Cross-Adapter Sync：不涉及 adapter gate、skills、registry、external-config 或工具路径同步；不触发 `tools/sync-skills.ps1`

## Proposed Destination

- workflow map：`router/workflow-map.md` 扩展 review workflow 行，覆盖非默认基线 changeset，并明确前端文件范围命中时继续读 `router/skill-map.md`
- eval：`evals/router-test-cases.md` 增加"审查类 + 前端目录任务"样例，判分点为是否命中 workflow map + skill map，并输出 vue-change-self-check 四段式
- logs：晋升落地时更新 `logs/router-changelog.md` 与 `logs/memory-changelog.md`
- 不修改：`adapters/claude/CLAUDE.md`、`adapters/codex/gate.md`、`router/skill-map.md`、`router/intent-map.md`、`## Final Trace` 格式

## Rationale

### Context

任务输入："审查 D:\xiangmeifu\admin-vue\src\views\goods\goodsPurchaseBan 这个文件夹，因为这个功能为新增所以要审查全部的内容，diff 是因为之前有过分批提交，实际按从零到现在进行审查"。

按 `router/skill-map.md` 已存在条目：

- `pr-review`："审查新增功能、从零到现在、跨提交累计、分支差异、上线前整体变更等非默认基线 changeset" → 命中
- `frontend-component-review`："审查新增页面、组件、表单或交互的完整实现" → 命中
- `vue-change-self-check`："当前端文件范围命中时，新增功能全量、从零到现在、跨提交累计、分支差异、上线前整体变更等非默认基线 changeset 也属于触发范围" → 命中
- Notes："当 pr-review 与 vue-change-self-check 同时命中时...优先使用 vue-change-self-check 的四段式结构"

`router/skill-map.md` 已经把扩展基线写得很清楚，但 `router/workflow-map.md` 的 review workflow 行仍停留在默认 diff/PR/staged/current changes 表述。实际执行时模型容易把"审查新增前端目录 / 从零到现在"当作普通 L1 review，而不是先进入 workflow map，再补读 skill map 判定 `vue-change-self-check`。

### 真实根因（唯一一条）

模型没读 map，凭记忆和直觉做了路由判断。

延伸出来的两个机制层面的弱点：

1. **workflow map 触发面不完整**：`workflow-map` 的 review 行没有显式覆盖非默认基线 changeset，导致只读 workflow map 时不能稳定命中 review workflow。
2. **workflow 到 skill 的交接不显式**：前端文件范围命中时，需要继续读取 `skill-map` 判定 `vue-change-self-check` / `frontend-component-review`，否则可能停在通用 review 输出形态。

### 本提案与已有 accepted proposal 的边界

`2026-06-05-l1-workflow-skill-候选信号应触发-router-map-轻量探针.md` 解决"什么时候必须读 map"，本 proposal 解决"读 map 后 review workflow 如何覆盖非默认基线 changeset，并如何继续交接到前端审查 skill"。前者是 gate 到 map 的入口规则，后者是 map 内部触发边界补齐。两者不重复。

### 为什么不在 Final Trace 加 probe 字段

最初设想是在 Final Trace 中增加 `probe: skill-map matched=[...]` 字段使跳过可观测。但当前 trace 已统计 `OS / skills / workflow / read / graph / write` 六项，进一步扩张会让 trace 变成第二套 router 状态机，且无法防止"模型写了 probe 字段但仍未真读 map"这种纸面合规。改为通过**输出形态判分**（是否走四段式）从结果端验证，eval 上更稳，trace 上更轻。

## Reusable Lesson

路由纠正：当一类任务（如审查新增前端目录 / 从零到现在）已由 skill-map 覆盖但仍在执行中被普通 review 自走吞掉时，优先补齐 workflow-map 的触发边界和 workflow→skill 交接说明，而不是把具体分流规则复制进 gate 或扩张 Final Trace。

## Core Design

| 层 | 现状 | 补丁 |
|---|---|---|
| Gate Workflow / Skill Probe 主规则 | 已存在 | 不改 |
| Gate Workflow / Skill Probe 内联示例 | 仅有"读原型准备开发"正反例 | 不改，避免 gate 承载具体 router 事实 |
| Workflow Map | review 行未覆盖非默认基线 changeset | **扩展 review workflow 触发边界** |
| Skill Map | 已覆盖 pr-review / frontend-component-review / vue-change-self-check | 不改 |
| Final Trace | 已统计六项 | **不改，不扩张** |
| Eval | 暂无审查类 + 前端目录样例 | **新增样例，用输出形态判分** |

运行时流程变为：模型识别 review / 审查候选信号 → 读 `router/workflow-map.md` 命中 `diff-review-lite.md`（含非默认基线 changeset）→ 前端文件范围命中时继续读 `router/skill-map.md` → 命中 `vue-change-self-check` / `frontend-component-review` / `pr-review` → 输出四段式风险扫描。eval 从输出端反查该链路是否生效。

## Draft

### workflow-map 修改：扩展 review workflow 行

将 `router/workflow-map.md` 中当前 review 行：

```md
| review diff / PR / commit / staged changes / current changes | `workflows/diff-review-lite.md` | 用户要求审查 diff、PR、commit、staged changes 或当前代码改动，且不是广泛架构审查 | 用户要求直接实现功能；用户要求提交前自检时优先考虑 `pre-commit-self-check.md` 或相关 skill；diff 涉及跨模块契约、安全、权限、发布流、共享基础设施或长期规则时升级 L2 |
```

替换为：

```md
| review diff / PR / commit / staged changes / current changes / 新增功能全量 / 从零到现在 / 上线前累计变更 | `workflows/diff-review-lite.md` | 用户要求审查 diff、PR、commit、staged changes、当前代码改动，或审查新增功能、从零到现在、跨提交累计、分支差异、上线前整体变更等非默认基线 changeset，且不是广泛架构审查 | 用户要求直接实现功能；用户要求提交前自检时优先考虑 `pre-commit-self-check.md` 或相关 skill；前端文件范围命中时应继续读取 `router/skill-map.md` 判定 `vue-change-self-check` / `frontend-component-review`；diff 涉及跨模块契约、安全、权限、发布流、共享基础设施或长期规则时升级 L2 |
```

### eval 修改：在 `evals/router-test-cases.md` 已存在的 `## Workflow / Skill Probe Cases` 子表底部追加（不新建表，沿用现有列头 `| Input | Expected action |`）

| Input | Expected action |
|---|---|
| 审查 src/views/goods/goodsPurchaseBan 这个新增文件夹的完整内容（从零到现在）| 读 `router/workflow-map.md`，命中 `workflows/diff-review-lite.md`；因前端文件范围命中，继续读 `router/skill-map.md`，命中 `vue-change-self-check`（与 pr-review/frontend-component-review 共触发），输出走四段式：变更影响扫描 / 风险清单 / 建议验证路径 / 本次未覆盖盲区 |
| 看一下当前 staged 的 .vue 改动有什么风险 | 读 `router/skill-map.md`，命中 vue-change-self-check（不是只走通用 review 自走流程），输出四段式；与上方"帮我 review 一下当前 diff"的区别在于对象明确为 .vue，必须升级到 vue-change-self-check 的稳定输出形态 |
| 解释这个 vue 组件里 watch 是怎么工作的 | 不触发 skill probe，按 L0/L1 自走 |

> 注：第一行使用真实 episode 的具体路径而非 `src/views/xxx` 占位，避免模型把占位当通配泛化，降低信号强度。

判分点不依赖 trace 字段，直接看输出文档结构是否包含四段式标题。

## Risks

- **是否过度泛化**：只扩展 review workflow 的 changeset 边界，并用"且不是广泛架构审查"和现有 Do Not Use When 限制范围。不修改 gate、intent、skill-map、trace 格式或 L0-L3 定义。
- **是否包含敏感信息**：不含 token、cookie、账号、客户数据、生产日志、未脱敏私有代码。
- **是否与现有规则冲突**：无。`skill-map` 已覆盖具体 skill 分流，本 proposal 只让 workflow map 能稳定识别非默认基线 review，并显式交接到 skill map。
- **gate 膨胀风险**：不修改 gate，避免把具体 router 事实复制进 adapter gate。
- **workflow/skill 重叠风险**：明确"前端文件范围命中时继续读取 skill-map"，避免通用 `diff-review-lite.md` 抢占 `vue-change-self-check` 的输出形态。

## Safety And Sensitivity Check

- 不包含敏感信息。
- 本 proposal 只写入 pending；落地时只修改 `router/workflow-map.md`、`evals/router-test-cases.md` 和相关 changelog，不直接修改 adapter gate 或 skill 文件。
- 不扩大读取边界：仍严格按 `## Workflow / Skill Probe` 已定义的"明确候选信号"判断是否读 map。
- 不扩张 Final Trace：保留现有六项统计，不新增 probe 字段。

## Source Task Or Evidence Summary

- 真实误判：goodsPurchaseBan 文件夹完整审查任务（feature/feature-supportKilocalorie 分支，2026-06-13）跳过 router/skill-map.md 探针，未走 vue-change-self-check 四段式输出，被用户当场 catch。
- 正式事实：
  - `router/skill-map.md` 已包含 pr-review / frontend-component-review / vue-change-self-check 三条与扩展基线 changeset 描述
  - `router/workflow-map.md` 的 review 行当前只显式覆盖 diff / PR / commit / staged changes / current changes
  - `adapters/claude/CLAUDE.md` 与 `adapters/codex/gate.md` 已有 `## Workflow / Skill Probe` 规则，无需继续加厚 gate
  - `## Final Trace` 已统计六项，不再扩张
- 已有相邻 accepted proposal：`2026-06-05-l1-workflow-skill-候选信号应触发-router-map-轻量探针.md` 建立"何时探针"的规则；本 proposal 补齐"读 map 后 review workflow 如何覆盖非默认基线 changeset，并交接到前端审查 skill"。

## Landing Plan

1. 审核本 proposal 的 `workflow-map` 行替换文本与 eval 样例。
2. 修改 `router/workflow-map.md` 的 review 行，补齐非默认基线 changeset，并明确前端文件范围命中时继续读 `router/skill-map.md`。
3. 在 `evals/router-test-cases.md` 已有的 `## Workflow / Skill Probe Cases` 子表底部追加审查类 + 前端目录样例（沿用现有列头 `| Input | Expected action |`，不新建表，用输出形态判分）。
4. 更新 `logs/router-changelog.md` 与 `logs/memory-changelog.md`，记录 router/eval 落地。
5. 将本 proposal 移入 `proposals/accepted/`，保留 `source_episode: "bug:goodsPurchaseBan-review-skill-map-probe-skipped-2026-06-13"`。
6. 运行 `tools/validate-memory-os.ps1` 做 markdown / router-test-cases 一致性 lint。本 proposal 不涉及 `skills/<skill>/SKILL_SPEC.md` 或 `skills/registry.json` 改动，不触发 `tools/sync-skills.ps1`。
