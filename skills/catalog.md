# Skill Catalog

## Active Codex Skills

| Skill | Status | Reason |
|---|---|---|
| memory-curator | active | 记忆复盘和 proposal 写入的核心入口 |
| routing-auditor | active | 路由误判修正和 eval 增长入口 |
| bugfix-with-regression-test | active | 高频工程任务，能减少重复 bug |
| frontend-component-review | active | 前端 MVP 领域的核心 review 能力 |
| vue-change-self-check | active | Vue / uni-app 提交前 diff 风险扫描，已在本地真实任务中验证 |

## Candidate Skills

| Skill | Status | Promote When |
|---|---|---|
| feature-planning | candidate | 多次需要复杂需求拆解 |
| refactor-with-safety | candidate | 重构任务频繁出现且有风险 |
| pr-review | candidate | 需要标准化 PR review 输出 |
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
