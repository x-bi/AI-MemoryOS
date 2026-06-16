# Roadmap 路线图

> 标记规则：✅ 已完成 / ⚠️ 部分完成 / ❌ 未启动 / 🗑️ 已弃用。
> 最近一次盘点：2026-06-16，证据见 `STATUS.md`、`logs/`、`proposals/`、`reports/self-optimize-2026-06-16-1457.md`。

## 7 天 MVP（已完成基线）

- ✅ Day 1：建立独立仓库、全局 AGENTS 接入、Codex skills junction 映射。
- ✅ Day 2：补齐 core / router / workflows / frontend / proposals / evals。
- ✅ Day 3：完善前端 rules、review checklist、common failures、testing、performance。
- ✅ Day 4：扩充 router-test-cases 和 skill-trigger-test-cases。
- ✅ Day 5：在真实前端项目试跑复杂任务和 bugfix 任务。
- ✅ Day 6：选 2~3 个已完成任务做 retrospective，只写 pending proposals。
- ⚠️ Day 7：第一次 audit。`logs/audit-log.md` 已有初始审计段；`logs/audits/YYYY-MM-DD.md` 周审快照尚未落地（见下方"审计节奏调整"）。

## 当前已完成的 MVP 基线

- ✅ 独立仓库已推送到个人 GitHub。
- ✅ Codex active skills 已通过 junction 映射到 `.codex\skills`。
- ✅ Obsidian dashboard、QuickAdd、Templater、Dataview、Git 已配置。
- ✅ MCP adapter 已接入全局 Codex config，并已接入 Claude `ai_memoryos`。
- ✅ 验证脚本已通过。
- ✅ `pr-review` 已从 workflow 封装为 active Codex/Claude skill。
- ✅ 已新增轻量 workflow 入口（`diff-review-lite`、`pre-commit-self-check`、`retrospective-lite`），用于在真实任务中收集 review、自检和复盘样例。
- ✅ Shared skill spec 体系：7 个 active skills 由 `skills/<skill>/SKILL_SPEC.md` + `skills/registry.json` + `tools/sync-skills.ps1` 统一管理。
- ✅ Claude Code adapter baseline（gate、skills、external-config、MCP）。

## 当前阶段重点

- 轻量 workflow 可以适度多触发，用于扩大真实案例输入。
- Memory OS 正文读取仍限定在 L2 场景。
- 写入仍限定为用户明确要求或确认后的 pending proposal。
- 优先补真实 eval case 和 proposal 晋升样例，再扩展更多重型 skills。

## 30 天

- ⚠️ 按真实需求扩展 testing / Playwright / Vitest 相关 stack 页面（`stacks/playwright`、`stacks/vitest` 目录已建，内容仍偏骨架）。
- ✅ 持续完善 accepted / rejected proposal 流程和记录质量。当前 14 条 accepted、1 条 rejected，全部带原因。
- 🗑️ 每周一次 memory audit。一个人维护节奏未真正跑起来（`logs/audits/` 仅有 README.md），改为"按需 + 触发条件审计"，详见下方"审计节奏调整"。
- ⚠️ 路由纠正案例累计到 10~20 条。`evals/router-correction-cases.md` 已回填 5 条历史路由漂移（来自 2026-05-26 ~ 2026-06-13 的 accepted proposals），距离 10~20 条目标尚需积累；新增条目按"漂移发生 → 走 routing-auditor/memory-curator → accepted 后回填"的流程沉淀。
- ⚠️ 让 prompts 与 skills 开始互相引用。`prompts/` 7 个文件已建，但与 skills 的交叉引用尚未系统化。

## 90 天

- ⚠️ 加入 scripting / backend 基础包。`domains/backend`、`domains/scripting` 目录在，仅 README 级。
- ❌ 评估 private / team / public 分层。
- 🗑️ 建 monthly review。同样不强制节奏，转为"按需"，详见下方"审计节奏调整"。
- ❌ 把高频路由误判提升为正式 router 规则（依赖前置 30 天的路由纠正案例累计）。
- ❌ 对 stale memories 做归档。

## 审计节奏调整（2026-06-16）

放弃"周审 + 月审"的强制节奏。事实是：单人维护、`logs/audits/` 至今未落地、强制节奏只会变成自我负担。改为**按需 + 触发条件审计**：

触发条件（满足任一即审一次，并写 `logs/audits/YYYY-MM-DD.md`）：

- `proposals/pending/` 堆积超过 5 条或最旧条目超过 14 天未处理。
- 同一类路由误判在 evals 中累计 ≥ 3 条。
- 出现冲突或过期内容（被新 proposal 推翻、与项目本地事实冲突）。
- skill description 重叠或误触发被实际命中。
- 跨项目重复出现的反模式 ≥ 2 次。
- 用户主动要求一次集中审计或 self-optimize 复盘。

非强制项（不再要求每周/每月跑一次）：

- 普通 pending 数量统计、stale 扫描、skill description 例行核对——只在上面触发条件出现时执行，不靠日历提醒。

GOVERNANCE.md 的"审计节奏"段已同步调整。

## 自优化输入（2026-06-16 扫描）

`reports/self-optimize-2026-06-16-1457.md` 输出 14 条外部借鉴候选。下列是值得纳入未来路线但当前未启动的高价值条目（不自动写入 proposal，需用户确认后再走 `tools/new-proposal.ps1`）：

- ❌ trust-chain frontmatter + locator 锚点强化记忆可审计性（M / high）。
- ❌ 多阶段 skill 流水线 + 显式质量门，用于 feature-planning / refactor-with-safety 类复合任务（L / high）。
- ❌ 把架构集中到单一 ARCHITECTURE.md，收敛 README 与 _index.md 职责（S / med）。
- ❌ 显式 Skill Quality Standards 收录准入门槛（S / med）。
- ❌ 按 division/when_to_use 组织 skill 总览，强化人类发现性（S / med）。
- ❌ 多工具 adapter 的统一安装/转换脚本（M / med）。

## Claude Code Baseline

- ✅ Claude Code user gate 已是 bootstrap redirect 到 `adapters/claude/CLAUDE.md`。
- ✅ Claude Code `ai_memoryos` MCP 已通过共享受限 MCP server 接入。
- ✅ 7 个 active Claude skills 已通过 junction 从 `C:\Users\btf\.claude\skills` 映射到 `adapters/claude/skills`。
- ✅ Claude Code 换机/重装步骤已记录在 `adapters/claude/external-config.md`。
- ❌ 可选后续：把 Claude adapter 打包为 Claude plugin 并补充常用 Memory OS workflow 的 slash command。
