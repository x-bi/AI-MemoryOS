---
title: "skill references 应作为 skills/<skill>/ 源文件并由 sync 脚本同步到 adapter"
status: accepted
created_at: 2026-06-13T08:51:37.037Z
updated_at: 2026-06-13T17:44:25.381+08:00
source: mcp
source_episode: conversation:2026-06-13
decision_reason: "Accepted and landed: promoted skill references into skills/<skill>/references source files, extended sync-skills.ps1 to sync/check adapter references, updated cross-adapter rules and changelogs, and verified sync/validation."
---

# Proposal: skill references 应作为 skills/<skill>/ 源文件并由 sync 脚本同步到 adapter

## Summary

当前 `tools/sync-skills.ps1` 只渲染 `SKILL.md`，不处理 references；`adapters/claude/skills/vue-change-self-check/references/` 与 `adapters/codex/skills/vue-change-self-check/references/` 已经漂移（`checklist.md`、`output-contract.md` 两端均不一致）。本提案将 references 提升到 `skills/<skill>/references/` 作为唯一事实源，扩展 sync 脚本以"复制同步"方式把源 references 写入两个 adapter 目录，把"修改后必须经 sync 脚本"写入 Cross-Adapter Sync，并把同步漂移接入 `tools/validate-memory-os.ps1` 作为验证级失败。

## Scope

- Global / domain / stack / project-specific: Memory OS 基础设施（skill 框架）
- Applies to: 所有 `managed=true` 的 skill；当前实际触发的 skill 是 `vue-change-self-check`
- Does not apply to: `proposals/`、`raw/`、`private/`；不修改任何具体 skill 的内容（vue-change-self-check 内容变更由独立 pending 处理）

## Proposed Destination

- rules: `adapters/claude/CLAUDE.md`、`adapters/codex/gate.md`（Cross-Adapter Sync 第 6 条扩展）
- workflow: 无新 workflow
- domain: 无
- stack: 无
- skill: 对所有 managed skill 生效；当前仅 `skills/vue-change-self-check/` 有 references
- router: 无
- eval: 无

## Rationale

### 背景与问题

排查 `vue-change-self-check` skill 模板时发现一个跨 skill 的流程缺口：

1. **源目录中没有 references**：`skills/vue-change-self-check/` 下只有 `SKILL_SPEC.md`，没有 `references/`，但 adapter 目录（`adapters/claude/skills/vue-change-self-check/references/`、`adapters/codex/skills/vue-change-self-check/references/`）都存在 `checklist.md`、`output-contract.md`。
2. **sync 脚本不处理 references**：`tools/sync-skills.ps1` 全脚本未出现 `references` 关键字，只渲染 `SKILL.md`。
3. **两端 references 已经漂移**：`diff -q` 显示 `checklist.md` 与 `output-contract.md` 在两个 adapter 下都不一致。

### 与现有 junction 架构的关系

`tools/validate-memory-os.ps1:141-186` 的现状：

```
~/.codex/skills/<skill>   →  adapters/codex/skills/<skill>   （directory junction）
~/.claude/skills/<skill>  →  adapters/claude/skills/<skill>  （directory junction）
```

也就是说 Claude / Codex 运行时实际读取的是 `adapters/<x>/skills/<skill>/`。本提案的 sync 写目标是 `adapters/<x>/skills/<skill>/references/`，写入后通过现有 junction 自动反映到用户主目录，无需额外处理这一层。换句话说：**本提案不引入新的 junction**，仅"复制源 references 到 adapter 目录"，现有 junction 链路保持不动。

### 选定的同步策略：复制（不使用 junction）

考虑过用 junction 让 adapter 的 `references` 子目录直接指向源（`adapters/<x>/skills/<skill>/references` → `skills/<skill>/references`）。最终选择"复制同步"，理由：

- 与现有 `SKILL.md` 的同步模型同构（都是"渲染/写出源到 adapter"），心智一致。
- 避免在同一 skill 目录下混用两种机制（普通文件 SKILL.md + junction 子目录 references）造成调试困惑。
- 与上层 junction（`~/.<adapter>/skills/<skill>` → adapter）叠加后，调试链路过长，问题定位成本高。
- git 对 junction 行为不一致，复制对 git/diff/历史更可预期。
- 漂移检测靠 `-Check` 已可覆盖；复制策略的成本主要在执行期，不在认知期。

junction 路线作为 Future Direction 留档（见末尾 "Future Considerations"），不在本提案范围内。

### 后果

- 当前用户/模型按 `Cross-Adapter Sync`（"改源再同步"）想修改 references 时找不到源，只能直接编辑 adapter 拷贝，违反同步原则。
- 两端 references 长期单边修改 → 模型在不同 adapter 下读到不一致的输出契约 / 检查清单。
- 该问题对将来任何需要 references 的 skill 都会复现，不是 vue-change-self-check 单点问题。

### 边界

本提案只解决 references 的源文件 / 同步链路 / 编辑边界三件事，**不**涉及具体 skill 的内容变更。`vue-change-self-check` 输出模板的字段调整（位置可跳转、复现步骤、修复方向）由独立 pending 处理，本提案落地后那份 pending 的编辑目标自动变成 `skills/vue-change-self-check/references/output-contract.md`（源）。

## 变更范围

### 1. 新增源目录 `skills/vue-change-self-check/references/`

作为 references 唯一事实源。内容来源是合并 `adapters/claude/.../references/` 与 `adapters/codex/.../references/` 两端当前差异，逐文件做一份统一基线。

合并差异处理协议：

- 落地阶段先生成 `Open Questions` 列表，每个差异段以 `claude 段` / `codex 段` / `选定方案` 三栏列出，由用户逐项确认。
- 确认结果作为变更证据落入提案 `Draft` 段，便于 review。
- 合并后**保留** adapter 目录下的 references 文件直到 sync 脚本改完并跑过一次成功的写入（避免脚本回归时丢失内容）；之后由 sync 脚本统一覆盖。

### 2. 修改 `tools/sync-skills.ps1`

在现有 `SKILL.md` 渲染逻辑后增加 references 同步阶段：

- **触发条件**：当且仅当 `skills/<skill>/references/` 目录存在时进入此阶段；不存在则**完全不动** adapter references（保持向后兼容、不丢内容）。
- **同步对象**：仅 `adapters/<x>/skills/<skill>/references/` 子树；不影响 `SKILL.md`、不影响其他子目录。
- **写入策略**：
  - 计算源目录与目标目录的文件清单及内容 hash。
  - 写入模式（默认）：缺失/不一致的文件按源覆盖；目标存在但源不存在的"幽灵"文件标记为 `EXTRA`，**不静默删除**，由用户决定下一步（避免脚本误删用户私下放置的内容）。如确需删除，需要带 `-PurgeExtra` 显式开关（本提案默认不打开）。
  - `-Check` 模式：仅比对，输出 `OK` / `STALE references` / `EXTRA references` 行；不写入。
- **路径守护**：所有写入路径继续走 `Test-PathInside` / `Join-MemoryOsPath`，并额外断言目标父目录是 `adapters/<x>/skills/<skill>` 且在 Memory OS 根下；任何越界一律 throw。
- **编码**：UTF-8 无 BOM，与现有 `SKILL.md` 写出一致。
- **报告行**：每个 skill 输出 `REFERENCES <skill> <adapter> synced=N stale=M extra=K`，使同步状态在 `-Check` 与写入模式下都显式可见。

### 3. 不修改 `skills/registry.json` schema

是否同步 references 由"源目录是否存在"决定（约定优于配置），但用 `REFERENCES ... synced=N` 报告行让状态显式。后续如需 per-adapter 关闭再单独提案加 `adapters.<x>.references: false`。

### 4. 修改 `adapters/claude/CLAUDE.md` 与 `adapters/codex/gate.md` 的 `Cross-Adapter Sync` 段

第 6 条统一改为下述措辞（两边同步）：

- "Skill 源是 `skills/<skill>/SKILL_SPEC.md` 与 `skills/<skill>/references/**`（如存在）。"
- "禁止直接编辑 `adapters/<x>/skills/<skill>/SKILL.md` 与 `adapters/<x>/skills/<skill>/references/**`，它们是 sync 输出，会被覆盖。"
- "修改源后立即依次跑 `tools/sync-skills.ps1` 与 `tools/validate-memory-os.ps1`，不询问、不动 git。"

把"会被覆盖"和"禁止编辑"统一为同一条措辞，避免现状里两种语气共存。

### 5. 修改 `tools/validate-memory-os.ps1`

把 references 漂移变成验证级失败：

- 现状核对：`tools/validate-memory-os.ps1` 已经调用 `tools/sync-skills.ps1 -Check`，并将非零退出输出纳入 `Managed skill sync problems` 失败汇总。
- 因此本提案不需要在 validate 中新增第二套 drift 解析；references 漂移应先由 `tools/sync-skills.ps1 -Check` 以非零退出报告，validate 继续复用现有调用链。
- 如需更清晰的 validate 文案，只做轻量输出归类，不复制 `sync-skills.ps1` 的 references 比对逻辑。

## 落地方案（待用户批准提案后执行）

### 已完成前置处理

- `source_episode` 已补充为 `conversation:2026-06-13`，满足 proposal 晋升溯源要求。
- Claude / Codex 两端 references 差异已写入 `Draft / Open Questions（已确定）`。
- 初始统一基线已确定：`skills/vue-change-self-check/references/checklist.md` 与 `output-contract.md` 均采用当前 Claude adapter 版本。
- validator 章节已修正：不新增第二套 drift 检测，继续通过现有 `tools/validate-memory-os.ps1` 调用 `tools/sync-skills.ps1 -Check` 汇总失败。

### 执行阶段

1. **Preflight：确认当前事实**
   - 运行 `tools/sync-skills.ps1 -Check`，预期当前 `SKILL.md` 全部 `OK`。
   - 确认 `skills/vue-change-self-check/references/` 尚不存在，adapter 两端 references 仍存在且 codex 与 claude 内容不一致。

2. **建立源 references**
   - 新建 `skills/vue-change-self-check/references/`。
   - 从 `adapters/claude/skills/vue-change-self-check/references/checklist.md` 复制生成源 `checklist.md`。
   - 从 `adapters/claude/skills/vue-change-self-check/references/output-contract.md` 复制生成源 `output-contract.md`。
   - 不删除 adapter 下旧 references；旧文件在 sync 写入前保留为回退和 diff 对照。

3. **扩展 `tools/sync-skills.ps1`**
   - 增加 references 同步阶段，触发条件仅为 `skills/<skill>/references/` 存在。
   - `-Check` 模式只比较源/目标清单和内容，发现缺失或内容不一致时返回 `STALE`，发现目标存在但源不存在的幽灵文件时返回 `EXTRA`，不写入。
   - 写入模式只覆盖缺失或内容不一致的目标文件；默认不删除 `EXTRA`。
   - 如实现 `-PurgeExtra`，必须作为显式开关，且不在本次默认同步路径使用。
   - 写入边界限定在 `adapters/<adapter>/skills/<skill>/references/` 子树内，继续复用 `Join-MemoryOsPath` / `Test-PathInside` 做越界防护。
   - 保持 `OK` / `STALE` / `ERROR` 语义：内容漂移是 `STALE`，路径/registry/template/脚本异常是 `ERROR`。

4. **验证 stale 检出能力**
   - 在正式写入前运行 `tools/sync-skills.ps1 -Skill vue-change-self-check -Check`。
   - 预期 `codex` references 至少报 `STALE`；`claude` references 应与源基线一致或接近一致。
   - 运行 `tools/sync-skills.ps1 -Skill not-a-real-skill -Check`，预期保持 `ERROR` 类失败，不被误报为 `STALE`。

5. **执行同步**
   - 运行 `tools/sync-skills.ps1`。
   - 预期 adapter 两端 `SKILL.md` 继续由模板生成，adapter 两端 references 被源 references 同步覆盖。
   - 用 `git diff` 核对变更范围：新增 `skills/vue-change-self-check/references/**`，修改 `tools/sync-skills.ps1`，修改 codex adapter references；claude adapter references 如已等同源则不应出现实质内容变更。

6. **回归验证**
   - 运行 `tools/sync-skills.ps1 -Check`，预期全量 `OK`。
   - 运行 `tools/validate-memory-os.ps1`，预期通过；如 references 漂移存在，validate 应通过现有 `Managed skill sync problems` 暴露。
   - 视实现复杂度补一个临时 root 或最小 fixture 检查，覆盖：源 references 不存在时不触碰 adapter references、源存在时可检测 stale、默认不删除 extra。

7. **更新规则与记录**
   - 同步修改 `adapters/claude/CLAUDE.md` 与 `adapters/codex/gate.md` 的 Cross-Adapter Sync 第 6 条，明确 `skills/<skill>/references/**` 也是源，adapter references 是生成输出。
   - 更新 `logs/memory-changelog.md`：记录接受本 proposal 和同步规则边界变更。
   - 更新 `logs/skill-changelog.md`：记录 managed skill references 纳入 source / sync / check 管线。
   - 不需要更新 `logs/router-changelog.md`，本提案不改 router / eval。

8. **晋升收口**
   - 将本 proposal 从 `proposals/pending/` 移到 `proposals/accepted/`，保留 `source_episode`。
   - accepted 文件中保留 Draft 的差异决策，作为统一基线选择证据。
   - 不执行 git commit / push / branch 操作；落地后由用户决定提交时机和粒度。

### 验收标准

- `skills/vue-change-self-check/references/checklist.md` 和 `output-contract.md` 存在，并成为唯一人工编辑源。
- `tools/sync-skills.ps1 -Check` 能同时检查 generated `SKILL.md` 与源 references 到 adapter references 的漂移。
- `tools/sync-skills.ps1` 默认同步 references 但不静默删除 extra 文件。
- `tools/validate-memory-os.ps1` 无重复 drift 实现，继续通过 `sync-skills.ps1 -Check` 汇总 managed skill sync 问题。
- Codex / Claude gate 的 Cross-Adapter Sync 第 6 条一致。
- `logs/memory-changelog.md` 与 `logs/skill-changelog.md` 有本次晋升记录。

## Risks

- **是否过度泛化**：本提案对所有 managed skill 生效，但触发条件是"源 references 目录是否存在"，不会强制要求 skill 必须有 references。当前仅 `vue-change-self-check` 受影响，其他 skill 行为零变化。低风险。
- **是否包含敏感信息**：无。references 内容是 skill 输出契约与回归 checklist，非敏感。
- **是否与现有规则冲突**：与现有 Cross-Adapter Sync 第 6 条互补；与 junction 架构（`~/.<adapter>/skills/<skill>` → adapter）叠加无冲突，sync 写到 adapter 后由现有 junction 自动暴露给用户主目录。
- **合并差异有方向性**：claude vs codex 两端 references 不一致，统一基线时若选错方向会丢内容。缓解：步骤 1 强制 Open Questions 逐项确认，落地后留作 Draft 区证据。
- **sync 脚本回归**：references 写入逻辑写错可能误改 adapter 下其他文件。缓解：写入对象限定为 `references/` 子树；写入前后 `Test-PathInside` 守护；步骤 4 干跑、步骤 5 `git diff` 核对作为双重 gate。
- **幽灵文件误删**：默认**不**删除目标存在但源不存在的文件，仅标 `EXTRA`，需用户用 `-PurgeExtra` 显式触发；步骤 5 不会触及此分支。
- **回退**：步骤 3 脚本变更如出问题，可独立回退脚本而保留源 references；步骤 5 写入前 adapter 旧内容仍在 git 历史中，可恢复。

## Future Considerations

- 如未来确认 Memory OS 永久 Windows-only 且 junction 行为可控，可再次评估是否把 references 改为 junction（adapter → 源），消除复制成本。当前不在本提案范围。
- 如出现 references 中需要 agent-specific 内容的 skill，沿用 SKILL_SPEC.md 现有的 `{{AGENT_NAME}}` 模板替换机制扩展到 references 渲染阶段，而非在两端各放一份。

## 关联提案

- `proposals/pending/2026-06-13-vue-change-self-check-输出模板增加可跳转位置与复现-修复字段.md` —— 该提案的"落地步骤"依赖本提案先合并 references；本提案落地后，那份提案的编辑目标自动变成 `skills/vue-change-self-check/references/output-contract.md`（源）。

## Draft

### Open Questions（已确定）

| 差异点 | Claude 段 | Codex 段 | 选定方案 |
|---|---|---|---|
| `checklist.md` 空值措辞 | `Missing null or undefined handling.` | `Missing null / undefined handling.` | 选 Claude。使用完整自然语言，避免 slash 风格混入 checklist。 |
| `checklist.md` loading/empty/error 措辞 | `Missing loading, empty, or error states after request changes.` | `Missing loading / empty / error states after request changes.` | 选 Claude。语义一致，逗号版本更适合作为统一文档基线。 |
| `checklist.md` repeated submit 防护措辞 | `without loading or debounce protection.` | `without loading/debounce protection.` | 选 Claude。表达更明确，不改变检查范围。 |
| `checklist.md` Verification Paths / Blind Spots 条目格式 | 首字母大写，句末有句号。 | 首字母小写，句末无句号。 | 选 Claude。作为 reference 文档应保持完整句式和一致标点。 |
| `output-contract.md` 示例 `置信度` | `中` | `高` | 选 Claude。示例默认应保守，实际 finding 可按证据提升为 `高`。 |
| `output-contract.md` 示例 `分类` | `待确认风险` | `确定问题` | 选 Claude。self-check 默认不应把待确认项写成确定缺陷，除非有直接证据。 |
| `output-contract.md` 示例 `建议动作` | `先确认接口/业务规则` | `直接修复` | 选 Claude。与 `待确认风险` 默认分类一致，避免诱导直接修改未确认问题。 |

### 统一基线结论

- `skills/vue-change-self-check/references/checklist.md` 初始源文件采用当前 `adapters/claude/skills/vue-change-self-check/references/checklist.md` 内容。
- `skills/vue-change-self-check/references/output-contract.md` 初始源文件采用当前 `adapters/claude/skills/vue-change-self-check/references/output-contract.md` 内容。
- 选择 Claude 版不是引入 Claude-only 行为，而是把两端已有 references 中更保守、更完整句式的一份提升为模型无关源基线；Codex adapter 后续由 sync 脚本生成/覆盖。
- 后续关联提案若要调整输出字段或示例默认值，应编辑 `skills/vue-change-self-check/references/output-contract.md` 源文件，而不是直接编辑 adapter copies。
