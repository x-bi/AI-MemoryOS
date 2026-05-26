# Skill Catalog

## Active Codex Skills

| Skill | Status | Reason |
|---|---|---|
| memory-curator | active | 记忆复盘和 proposal 写入的核心入口 |
| routing-auditor | active | 路由误判修正和 eval 增长入口 |
| bugfix-with-regression-test | active | 高频工程任务，能减少重复 bug |
| frontend-component-review | active | 前端 MVP 领域的核心 review 能力 |
| git-ops-guide | active | Git 命令指导，不执行 Git 命令；shared spec 试点 |
| pr-review | active | 标准化 PR / diff / commit review 输出，作为真实案例收集入口 |
| vue-change-self-check | active | Vue / uni-app 提交前 diff 风险扫描，已在本地真实任务中验证 |

## Candidate Skills

| Skill | Status | Promote When |
|---|---|---|
| feature-planning | candidate | 多次需要复杂需求拆解 |
| refactor-with-safety | candidate | 重构任务频繁出现且有风险 |
| test-strategy-review | candidate | 测试方案反复需要审查 |
| prompt-improver | candidate | 提示词迭代成为高频任务 |
| memory-auditor | candidate | pending/accepted 开始堆积 |
| skill-updater | candidate | 需要稳定修改 SKILL.md |
| frontend-performance-audit | candidate | 前端性能问题高频出现 |
| backend-api-review | candidate | 后端 API review 高频出现 |
| script-automation | candidate | 批处理/脚本任务高频出现 |
| playwright-e2e-review | candidate | E2E 用例质量成为瓶颈 |
| ci-pipeline-review | candidate | CI/CD 失败和流水线 review 高频出现 |

## Promotion Rule

候选 skill 不自动暴露给 Codex。只有当真实任务证明其高频、边界清晰、低误触发时，才移动到 `adapters/codex/skills/`，再通过 junction 映射到 `.codex\skills`。


## Active Claude Skills

Claude Code uses separate adapted skill files under `adapters/claude/skills`.

| Skill | Status | Notes |
|---|---|---|
| memory-curator | active | Claude version writes only pending proposals after explicit request or confirmation. |
| routing-auditor | active | Claude version audits Memory OS routing and preserves proposal review boundaries. |
| bugfix-with-regression-test | active | Claude version keeps root-cause and regression-protection workflow. |
| frontend-component-review | active | Claude version reviews user-facing frontend behavior and UI interaction risk. |
| pr-review | active | Claude version keeps findings-first review output. |
| vue-change-self-check | active | Claude version keeps diff-first numbered risk scan and reference files. |
| git-ops-guide | active | Claude version gives Git guidance only and must not execute Git commands. |

For Claude Code, promote or update skills separately under `adapters/claude/skills`, then expose them through junctions in `C:\Users\btf\.claude\skills`. Do not point Claude directly at `adapters/codex/skills`.

## Managed Shared Specs

`skills/registry.json` is the source of truth for skills generated from shared specs. Managed skills keep model-independent instructions in `skills/<skill>/SKILL_SPEC.md` and generate adapter-specific `SKILL.md` files with `tools/sync-skills.ps1`.

Current managed active skills:

| Skill | Source | Generated Adapters |
|---|---|---|
| memory-curator | `skills/memory-curator/SKILL_SPEC.md` | Codex, Claude |
| routing-auditor | `skills/routing-auditor/SKILL_SPEC.md` | Codex, Claude |
| bugfix-with-regression-test | `skills/bugfix-with-regression-test/SKILL_SPEC.md` | Codex, Claude |
| frontend-component-review | `skills/frontend-component-review/SKILL_SPEC.md` | Codex, Claude |
| pr-review | `skills/pr-review/SKILL_SPEC.md` | Codex, Claude |
| vue-change-self-check | `skills/vue-change-self-check/SKILL_SPEC.md` | Codex, Claude |
| git-ops-guide | `skills/git-ops-guide/SKILL_SPEC.md` | Codex, Claude |
