---
run_id: "9b7a42a921b9"
script: "iterate-stale-content"
triggered_by: "manual"
model_profile: ""
model_invocations_count: 0
model_tokens_estimate: 0
started_at: "2026-06-01T14:27:16.1828799+08:00"
duration_seconds: 0
exit_code: 0
findings_count: 45
actions_count: 10
pending_decisions_count: 45
max_severity: "warning"
status: "ready"
branch: ""
lock_id: ""
repair_attempts: 0
---

# 自动运行日志：iterate-stale-content

## 运行上下文

- **仓库根目录**：C:\Users\btf\AI-MemoryOS
- **脚本阶段**：iterate
- **运行参数**：
- phase: iterate
- root: C:\Users\btf\AI-MemoryOS
- max_proposals: 10
- stale_days: 30

## 发现

| # | 严重度 | 类别 | 说明 | 路径 | 等级 |
|---|---|---|---|---|---|
| 1 | 警告 | 内容疑似空洞 | Markdown 正文疑似过短或只包含占位内容，需要人工复核。 | adapters\cursor\rules\memory-os.md | B 提案级 |
| 2 | 警告 | 内容疑似空洞 | Markdown 正文疑似过短或只包含占位内容，需要人工复核。 | anti-patterns\memory-pollution.md | B 提案级 |
| 3 | 警告 | 内容疑似空洞 | Markdown 正文疑似过短或只包含占位内容，需要人工复核。 | anti-patterns\prompting-failures.md | B 提案级 |
| 4 | 警告 | 内容疑似空洞 | Markdown 正文疑似过短或只包含占位内容，需要人工复核。 | anti-patterns\router-misrouting.md | B 提案级 |
| 5 | 警告 | 内容疑似空洞 | Markdown 正文疑似过短或只包含占位内容，需要人工复核。 | domains\backend\api-debugging.md | B 提案级 |
| 6 | 警告 | 内容疑似空洞 | Markdown 正文疑似过短或只包含占位内容，需要人工复核。 | domains\backend\api-design.md | B 提案级 |
| 7 | 警告 | 内容疑似空洞 | Markdown 正文疑似过短或只包含占位内容，需要人工复核。 | domains\backend\auth.md | B 提案级 |
| 8 | 警告 | 内容疑似空洞 | Markdown 正文疑似过短或只包含占位内容，需要人工复核。 | domains\backend\README.md | B 提案级 |
| 9 | 警告 | 内容疑似空洞 | Markdown 正文疑似过短或只包含占位内容，需要人工复核。 | domains\devops\ci-cd.md | B 提案级 |
| 10 | 警告 | 内容疑似空洞 | Markdown 正文疑似过短或只包含占位内容，需要人工复核。 | domains\devops\ci-debugging.md | B 提案级 |
| 11 | 警告 | 内容疑似空洞 | Markdown 正文疑似过短或只包含占位内容，需要人工复核。 | domains\devops\README.md | B 提案级 |
| 12 | 警告 | 内容疑似空洞 | Markdown 正文疑似过短或只包含占位内容，需要人工复核。 | domains\devops\rules.md | B 提案级 |
| 13 | 警告 | 内容疑似空洞 | Markdown 正文疑似过短或只包含占位内容，需要人工复核。 | domains\scripting\debugging.md | B 提案级 |
| 14 | 警告 | 内容疑似空洞 | Markdown 正文疑似过短或只包含占位内容，需要人工复核。 | domains\scripting\file-processing.md | B 提案级 |
| 15 | 警告 | 内容疑似空洞 | Markdown 正文疑似过短或只包含占位内容，需要人工复核。 | domains\scripting\README.md | B 提案级 |
| 16 | 警告 | 内容疑似空洞 | Markdown 正文疑似过短或只包含占位内容，需要人工复核。 | domains\security\dependency-security.md | B 提案级 |
| 17 | 警告 | 内容疑似空洞 | Markdown 正文疑似过短或只包含占位内容，需要人工复核。 | domains\security\README.md | B 提案级 |
| 18 | 警告 | 内容疑似空洞 | Markdown 正文疑似过短或只包含占位内容，需要人工复核。 | domains\security\rules.md | B 提案级 |
| 19 | 警告 | 内容疑似空洞 | Markdown 正文疑似过短或只包含占位内容，需要人工复核。 | domains\security\secrets.md | B 提案级 |
| 20 | 警告 | 内容疑似空洞 | Markdown 正文疑似过短或只包含占位内容，需要人工复核。 | domains\testing\e2e-testing.md | B 提案级 |
| 21 | 警告 | 内容疑似空洞 | Markdown 正文疑似过短或只包含占位内容，需要人工复核。 | domains\testing\regression-testing.md | B 提案级 |
| 22 | 警告 | 内容疑似空洞 | Markdown 正文疑似过短或只包含占位内容，需要人工复核。 | evals\router-correction-cases.md | B 提案级 |
| 23 | 警告 | 内容疑似空洞 | Markdown 正文疑似过短或只包含占位内容，需要人工复核。 | prompts\colloquial-routing.md | B 提案级 |
| 24 | 警告 | 内容疑似空洞 | Markdown 正文疑似过短或只包含占位内容，需要人工复核。 | prompts\memory-cleanup.md | B 提案级 |
| 25 | 警告 | 内容疑似空洞 | Markdown 正文疑似过短或只包含占位内容，需要人工复核。 | prompts\memory-retrospective.md | B 提案级 |
| 26 | 警告 | 内容疑似空洞 | Markdown 正文疑似过短或只包含占位内容，需要人工复核。 | prompts\proposal-promotion.md | B 提案级 |
| 27 | 警告 | 内容疑似空洞 | Markdown 正文疑似过短或只包含占位内容，需要人工复核。 | prompts\routing-audit.md | B 提案级 |
| 28 | 警告 | 内容疑似空洞 | Markdown 正文疑似过短或只包含占位内容，需要人工复核。 | prompts\routing-correction.md | B 提案级 |
| 29 | 警告 | 内容疑似空洞 | Markdown 正文疑似过短或只包含占位内容，需要人工复核。 | prompts\skill-update.md | B 提案级 |
| 30 | 警告 | 内容疑似空洞 | Markdown 正文疑似过短或只包含占位内容，需要人工复核。 | raw\README.md | B 提案级 |
| 31 | 警告 | 内容疑似空洞 | Markdown 正文疑似过短或只包含占位内容，需要人工复核。 | rules\code-review.md | B 提案级 |
| 32 | 警告 | 内容疑似空洞 | Markdown 正文疑似过短或只包含占位内容，需要人工复核。 | rules\documentation.md | B 提案级 |
| 33 | 警告 | 内容疑似空洞 | Markdown 正文疑似过短或只包含占位内容，需要人工复核。 | rules\naming.md | B 提案级 |
| 34 | 警告 | 内容疑似空洞 | Markdown 正文疑似过短或只包含占位内容，需要人工复核。 | stacks\nextjs\README.md | B 提案级 |
| 35 | 警告 | 内容疑似空洞 | Markdown 正文疑似过短或只包含占位内容，需要人工复核。 | stacks\node\README.md | B 提案级 |
| 36 | 警告 | 内容疑似空洞 | Markdown 正文疑似过短或只包含占位内容，需要人工复核。 | stacks\playwright\README.md | B 提案级 |
| 37 | 警告 | 内容疑似空洞 | Markdown 正文疑似过短或只包含占位内容，需要人工复核。 | stacks\python\README.md | B 提案级 |
| 38 | 警告 | 内容疑似空洞 | Markdown 正文疑似过短或只包含占位内容，需要人工复核。 | stacks\react\hooks-and-state.md | B 提案级 |
| 39 | 警告 | 内容疑似空洞 | Markdown 正文疑似过短或只包含占位内容，需要人工复核。 | stacks\react\README.md | B 提案级 |
| 40 | 警告 | 内容疑似空洞 | Markdown 正文疑似过短或只包含占位内容，需要人工复核。 | stacks\typescript\README.md | B 提案级 |
| 41 | 警告 | 内容疑似空洞 | Markdown 正文疑似过短或只包含占位内容，需要人工复核。 | stacks\vitest\README.md | B 提案级 |
| 42 | 警告 | 内容疑似空洞 | Markdown 正文疑似过短或只包含占位内容，需要人工复核。 | stacks\vue\README.md | B 提案级 |
| 43 | 警告 | 内容疑似空洞 | Markdown 正文疑似过短或只包含占位内容，需要人工复核。 | templates\auto-dashboard-home-link.md | B 提案级 |
| 44 | 警告 | 内容疑似空洞 | Markdown 正文疑似过短或只包含占位内容，需要人工复核。 | templates\obsidian-note.md | B 提案级 |
| 45 | 警告 | 内容疑似空洞 | Markdown 正文疑似过短或只包含占位内容，需要人工复核。 | wiki\README.md | B 提案级 |

## 已执行操作

| # | 等级 | 操作 | 目标 | 状态 |
|---|---|---|---|---|
| 1 | B 提案级 | 创建或检查 proposal | Archive stale content: adapters\cursor\rules\memory-os.md | 已跳过：重复 |
| 2 | B 提案级 | 创建或检查 proposal | Archive stale content: anti-patterns\memory-pollution.md | 已跳过：重复 |
| 3 | B 提案级 | 创建或检查 proposal | Archive stale content: anti-patterns\prompting-failures.md | 已跳过：重复 |
| 4 | B 提案级 | 创建或检查 proposal | Archive stale content: anti-patterns\router-misrouting.md | 已跳过：重复 |
| 5 | B 提案级 | 创建或检查 proposal | Archive stale content: domains\backend\api-debugging.md | 已跳过：重复 |
| 6 | B 提案级 | 创建或检查 proposal | Archive stale content: domains\backend\api-design.md | 已跳过：重复 |
| 7 | B 提案级 | 创建或检查 proposal | Archive stale content: domains\backend\auth.md | 已跳过：重复 |
| 8 | B 提案级 | 创建或检查 proposal | Archive stale content: domains\backend\README.md | 已跳过：重复 |
| 9 | B 提案级 | 创建或检查 proposal | Archive stale content: domains\devops\ci-cd.md | 已跳过：重复 |
| 10 | B 提案级 | 创建或检查 proposal | Archive stale content: domains\devops\ci-debugging.md | 已跳过：重复 |

## 待人工决策

| # | 事项 | 等级 | 路径 | 状态 |
|---|---|---|---|---|
| 1 | Markdown 正文疑似过短或只包含占位内容，需要人工复核。 | B 提案级 | adapters\cursor\rules\memory-os.md | pending |
| 2 | Markdown 正文疑似过短或只包含占位内容，需要人工复核。 | B 提案级 | anti-patterns\memory-pollution.md | pending |
| 3 | Markdown 正文疑似过短或只包含占位内容，需要人工复核。 | B 提案级 | anti-patterns\prompting-failures.md | pending |
| 4 | Markdown 正文疑似过短或只包含占位内容，需要人工复核。 | B 提案级 | anti-patterns\router-misrouting.md | pending |
| 5 | Markdown 正文疑似过短或只包含占位内容，需要人工复核。 | B 提案级 | domains\backend\api-debugging.md | pending |
| 6 | Markdown 正文疑似过短或只包含占位内容，需要人工复核。 | B 提案级 | domains\backend\api-design.md | pending |
| 7 | Markdown 正文疑似过短或只包含占位内容，需要人工复核。 | B 提案级 | domains\backend\auth.md | pending |
| 8 | Markdown 正文疑似过短或只包含占位内容，需要人工复核。 | B 提案级 | domains\backend\README.md | pending |
| 9 | Markdown 正文疑似过短或只包含占位内容，需要人工复核。 | B 提案级 | domains\devops\ci-cd.md | pending |
| 10 | Markdown 正文疑似过短或只包含占位内容，需要人工复核。 | B 提案级 | domains\devops\ci-debugging.md | pending |
| 11 | Markdown 正文疑似过短或只包含占位内容，需要人工复核。 | B 提案级 | domains\devops\README.md | pending |
| 12 | Markdown 正文疑似过短或只包含占位内容，需要人工复核。 | B 提案级 | domains\devops\rules.md | pending |
| 13 | Markdown 正文疑似过短或只包含占位内容，需要人工复核。 | B 提案级 | domains\scripting\debugging.md | pending |
| 14 | Markdown 正文疑似过短或只包含占位内容，需要人工复核。 | B 提案级 | domains\scripting\file-processing.md | pending |
| 15 | Markdown 正文疑似过短或只包含占位内容，需要人工复核。 | B 提案级 | domains\scripting\README.md | pending |
| 16 | Markdown 正文疑似过短或只包含占位内容，需要人工复核。 | B 提案级 | domains\security\dependency-security.md | pending |
| 17 | Markdown 正文疑似过短或只包含占位内容，需要人工复核。 | B 提案级 | domains\security\README.md | pending |
| 18 | Markdown 正文疑似过短或只包含占位内容，需要人工复核。 | B 提案级 | domains\security\rules.md | pending |
| 19 | Markdown 正文疑似过短或只包含占位内容，需要人工复核。 | B 提案级 | domains\security\secrets.md | pending |
| 20 | Markdown 正文疑似过短或只包含占位内容，需要人工复核。 | B 提案级 | domains\testing\e2e-testing.md | pending |
| 21 | Markdown 正文疑似过短或只包含占位内容，需要人工复核。 | B 提案级 | domains\testing\regression-testing.md | pending |
| 22 | Markdown 正文疑似过短或只包含占位内容，需要人工复核。 | B 提案级 | evals\router-correction-cases.md | pending |
| 23 | Markdown 正文疑似过短或只包含占位内容，需要人工复核。 | B 提案级 | prompts\colloquial-routing.md | pending |
| 24 | Markdown 正文疑似过短或只包含占位内容，需要人工复核。 | B 提案级 | prompts\memory-cleanup.md | pending |
| 25 | Markdown 正文疑似过短或只包含占位内容，需要人工复核。 | B 提案级 | prompts\memory-retrospective.md | pending |
| 26 | Markdown 正文疑似过短或只包含占位内容，需要人工复核。 | B 提案级 | prompts\proposal-promotion.md | pending |
| 27 | Markdown 正文疑似过短或只包含占位内容，需要人工复核。 | B 提案级 | prompts\routing-audit.md | pending |
| 28 | Markdown 正文疑似过短或只包含占位内容，需要人工复核。 | B 提案级 | prompts\routing-correction.md | pending |
| 29 | Markdown 正文疑似过短或只包含占位内容，需要人工复核。 | B 提案级 | prompts\skill-update.md | pending |
| 30 | Markdown 正文疑似过短或只包含占位内容，需要人工复核。 | B 提案级 | raw\README.md | pending |
| 31 | Markdown 正文疑似过短或只包含占位内容，需要人工复核。 | B 提案级 | rules\code-review.md | pending |
| 32 | Markdown 正文疑似过短或只包含占位内容，需要人工复核。 | B 提案级 | rules\documentation.md | pending |
| 33 | Markdown 正文疑似过短或只包含占位内容，需要人工复核。 | B 提案级 | rules\naming.md | pending |
| 34 | Markdown 正文疑似过短或只包含占位内容，需要人工复核。 | B 提案级 | stacks\nextjs\README.md | pending |
| 35 | Markdown 正文疑似过短或只包含占位内容，需要人工复核。 | B 提案级 | stacks\node\README.md | pending |
| 36 | Markdown 正文疑似过短或只包含占位内容，需要人工复核。 | B 提案级 | stacks\playwright\README.md | pending |
| 37 | Markdown 正文疑似过短或只包含占位内容，需要人工复核。 | B 提案级 | stacks\python\README.md | pending |
| 38 | Markdown 正文疑似过短或只包含占位内容，需要人工复核。 | B 提案级 | stacks\react\hooks-and-state.md | pending |
| 39 | Markdown 正文疑似过短或只包含占位内容，需要人工复核。 | B 提案级 | stacks\react\README.md | pending |
| 40 | Markdown 正文疑似过短或只包含占位内容，需要人工复核。 | B 提案级 | stacks\typescript\README.md | pending |
| 41 | Markdown 正文疑似过短或只包含占位内容，需要人工复核。 | B 提案级 | stacks\vitest\README.md | pending |
| 42 | Markdown 正文疑似过短或只包含占位内容，需要人工复核。 | B 提案级 | stacks\vue\README.md | pending |
| 43 | Markdown 正文疑似过短或只包含占位内容，需要人工复核。 | B 提案级 | templates\auto-dashboard-home-link.md | pending |
| 44 | Markdown 正文疑似过短或只包含占位内容，需要人工复核。 | B 提案级 | templates\obsidian-note.md | pending |
| 45 | Markdown 正文疑似过短或只包含占位内容，需要人工复核。 | B 提案级 | wiki\README.md | pending |

## 结构化数据

~~~json
{
    "findings":  [
                     {
                         "severity":  "warning",
                         "category":  "hollow-content",
                         "message":  "Markdown body appears too short or placeholder-only.",
                         "path":  "adapters\\cursor\\rules\\memory-os.md",
                         "tier":  "B",
                         "data":  {

                                  }
                     },
                     {
                         "severity":  "warning",
                         "category":  "hollow-content",
                         "message":  "Markdown body appears too short or placeholder-only.",
                         "path":  "anti-patterns\\memory-pollution.md",
                         "tier":  "B",
                         "data":  {

                                  }
                     },
                     {
                         "severity":  "warning",
                         "category":  "hollow-content",
                         "message":  "Markdown body appears too short or placeholder-only.",
                         "path":  "anti-patterns\\prompting-failures.md",
                         "tier":  "B",
                         "data":  {

                                  }
                     },
                     {
                         "severity":  "warning",
                         "category":  "hollow-content",
                         "message":  "Markdown body appears too short or placeholder-only.",
                         "path":  "anti-patterns\\router-misrouting.md",
                         "tier":  "B",
                         "data":  {

                                  }
                     },
                     {
                         "severity":  "warning",
                         "category":  "hollow-content",
                         "message":  "Markdown body appears too short or placeholder-only.",
                         "path":  "domains\\backend\\api-debugging.md",
                         "tier":  "B",
                         "data":  {

                                  }
                     },
                     {
                         "severity":  "warning",
                         "category":  "hollow-content",
                         "message":  "Markdown body appears too short or placeholder-only.",
                         "path":  "domains\\backend\\api-design.md",
                         "tier":  "B",
                         "data":  {

                                  }
                     },
                     {
                         "severity":  "warning",
                         "category":  "hollow-content",
                         "message":  "Markdown body appears too short or placeholder-only.",
                         "path":  "domains\\backend\\auth.md",
                         "tier":  "B",
                         "data":  {

                                  }
                     },
                     {
                         "severity":  "warning",
                         "category":  "hollow-content",
                         "message":  "Markdown body appears too short or placeholder-only.",
                         "path":  "domains\\backend\\README.md",
                         "tier":  "B",
                         "data":  {

                                  }
                     },
                     {
                         "severity":  "warning",
                         "category":  "hollow-content",
                         "message":  "Markdown body appears too short or placeholder-only.",
                         "path":  "domains\\devops\\ci-cd.md",
                         "tier":  "B",
                         "data":  {

                                  }
                     },
                     {
                         "severity":  "warning",
                         "category":  "hollow-content",
                         "message":  "Markdown body appears too short or placeholder-only.",
                         "path":  "domains\\devops\\ci-debugging.md",
                         "tier":  "B",
                         "data":  {

                                  }
                     },
                     {
                         "severity":  "warning",
                         "category":  "hollow-content",
                         "message":  "Markdown body appears too short or placeholder-only.",
                         "path":  "domains\\devops\\README.md",
                         "tier":  "B",
                         "data":  {

                                  }
                     },
                     {
                         "severity":  "warning",
                         "category":  "hollow-content",
                         "message":  "Markdown body appears too short or placeholder-only.",
                         "path":  "domains\\devops\\rules.md",
                         "tier":  "B",
                         "data":  {

                                  }
                     },
                     {
                         "severity":  "warning",
                         "category":  "hollow-content",
                         "message":  "Markdown body appears too short or placeholder-only.",
                         "path":  "domains\\scripting\\debugging.md",
                         "tier":  "B",
                         "data":  {

                                  }
                     },
                     {
                         "severity":  "warning",
                         "category":  "hollow-content",
                         "message":  "Markdown body appears too short or placeholder-only.",
                         "path":  "domains\\scripting\\file-processing.md",
                         "tier":  "B",
                         "data":  {

                                  }
                     },
                     {
                         "severity":  "warning",
                         "category":  "hollow-content",
                         "message":  "Markdown body appears too short or placeholder-only.",
                         "path":  "domains\\scripting\\README.md",
                         "tier":  "B",
                         "data":  {

                                  }
                     },
                     {
                         "severity":  "warning",
                         "category":  "hollow-content",
                         "message":  "Markdown body appears too short or placeholder-only.",
                         "path":  "domains\\security\\dependency-security.md",
                         "tier":  "B",
                         "data":  {

                                  }
                     },
                     {
                         "severity":  "warning",
                         "category":  "hollow-content",
                         "message":  "Markdown body appears too short or placeholder-only.",
                         "path":  "domains\\security\\README.md",
                         "tier":  "B",
                         "data":  {

                                  }
                     },
                     {
                         "severity":  "warning",
                         "category":  "hollow-content",
                         "message":  "Markdown body appears too short or placeholder-only.",
                         "path":  "domains\\security\\rules.md",
                         "tier":  "B",
                         "data":  {

                                  }
                     },
                     {
                         "severity":  "warning",
                         "category":  "hollow-content",
                         "message":  "Markdown body appears too short or placeholder-only.",
                         "path":  "domains\\security\\secrets.md",
                         "tier":  "B",
                         "data":  {

                                  }
                     },
                     {
                         "severity":  "warning",
                         "category":  "hollow-content",
                         "message":  "Markdown body appears too short or placeholder-only.",
                         "path":  "domains\\testing\\e2e-testing.md",
                         "tier":  "B",
                         "data":  {

                                  }
                     },
                     {
                         "severity":  "warning",
                         "category":  "hollow-content",
                         "message":  "Markdown body appears too short or placeholder-only.",
                         "path":  "domains\\testing\\regression-testing.md",
                         "tier":  "B",
                         "data":  {

                                  }
                     },
                     {
                         "severity":  "warning",
                         "category":  "hollow-content",
                         "message":  "Markdown body appears too short or placeholder-only.",
                         "path":  "evals\\router-correction-cases.md",
                         "tier":  "B",
                         "data":  {

                                  }
                     },
                     {
                         "severity":  "warning",
                         "category":  "hollow-content",
                         "message":  "Markdown body appears too short or placeholder-only.",
                         "path":  "prompts\\colloquial-routing.md",
                         "tier":  "B",
                         "data":  {

                                  }
                     },
                     {
                         "severity":  "warning",
                         "category":  "hollow-content",
                         "message":  "Markdown body appears too short or placeholder-only.",
                         "path":  "prompts\\memory-cleanup.md",
                         "tier":  "B",
                         "data":  {

                                  }
                     },
                     {
                         "severity":  "warning",
                         "category":  "hollow-content",
                         "message":  "Markdown body appears too short or placeholder-only.",
                         "path":  "prompts\\memory-retrospective.md",
                         "tier":  "B",
                         "data":  {

                                  }
                     },
                     {
                         "severity":  "warning",
                         "category":  "hollow-content",
                         "message":  "Markdown body appears too short or placeholder-only.",
                         "path":  "prompts\\proposal-promotion.md",
                         "tier":  "B",
                         "data":  {

                                  }
                     },
                     {
                         "severity":  "warning",
                         "category":  "hollow-content",
                         "message":  "Markdown body appears too short or placeholder-only.",
                         "path":  "prompts\\routing-audit.md",
                         "tier":  "B",
                         "data":  {

                                  }
                     },
                     {
                         "severity":  "warning",
                         "category":  "hollow-content",
                         "message":  "Markdown body appears too short or placeholder-only.",
                         "path":  "prompts\\routing-correction.md",
                         "tier":  "B",
                         "data":  {

                                  }
                     },
                     {
                         "severity":  "warning",
                         "category":  "hollow-content",
                         "message":  "Markdown body appears too short or placeholder-only.",
                         "path":  "prompts\\skill-update.md",
                         "tier":  "B",
                         "data":  {

                                  }
                     },
                     {
                         "severity":  "warning",
                         "category":  "hollow-content",
                         "message":  "Markdown body appears too short or placeholder-only.",
                         "path":  "raw\\README.md",
                         "tier":  "B",
                         "data":  {

                                  }
                     },
                     {
                         "severity":  "warning",
                         "category":  "hollow-content",
                         "message":  "Markdown body appears too short or placeholder-only.",
                         "path":  "rules\\code-review.md",
                         "tier":  "B",
                         "data":  {

                                  }
                     },
                     {
                         "severity":  "warning",
                         "category":  "hollow-content",
                         "message":  "Markdown body appears too short or placeholder-only.",
                         "path":  "rules\\documentation.md",
                         "tier":  "B",
                         "data":  {

                                  }
                     },
                     {
                         "severity":  "warning",
                         "category":  "hollow-content",
                         "message":  "Markdown body appears too short or placeholder-only.",
                         "path":  "rules\\naming.md",
                         "tier":  "B",
                         "data":  {

                                  }
                     },
                     {
                         "severity":  "warning",
                         "category":  "hollow-content",
                         "message":  "Markdown body appears too short or placeholder-only.",
                         "path":  "stacks\\nextjs\\README.md",
                         "tier":  "B",
                         "data":  {

                                  }
                     },
                     {
                         "severity":  "warning",
                         "category":  "hollow-content",
                         "message":  "Markdown body appears too short or placeholder-only.",
                         "path":  "stacks\\node\\README.md",
                         "tier":  "B",
                         "data":  {

                                  }
                     },
                     {
                         "severity":  "warning",
                         "category":  "hollow-content",
                         "message":  "Markdown body appears too short or placeholder-only.",
                         "path":  "stacks\\playwright\\README.md",
                         "tier":  "B",
                         "data":  {

                                  }
                     },
                     {
                         "severity":  "warning",
                         "category":  "hollow-content",
                         "message":  "Markdown body appears too short or placeholder-only.",
                         "path":  "stacks\\python\\README.md",
                         "tier":  "B",
                         "data":  {

                                  }
                     },
                     {
                         "severity":  "warning",
                         "category":  "hollow-content",
                         "message":  "Markdown body appears too short or placeholder-only.",
                         "path":  "stacks\\react\\hooks-and-state.md",
                         "tier":  "B",
                         "data":  {

                                  }
                     },
                     {
                         "severity":  "warning",
                         "category":  "hollow-content",
                         "message":  "Markdown body appears too short or placeholder-only.",
                         "path":  "stacks\\react\\README.md",
                         "tier":  "B",
                         "data":  {

                                  }
                     },
                     {
                         "severity":  "warning",
                         "category":  "hollow-content",
                         "message":  "Markdown body appears too short or placeholder-only.",
                         "path":  "stacks\\typescript\\README.md",
                         "tier":  "B",
                         "data":  {

                                  }
                     },
                     {
                         "severity":  "warning",
                         "category":  "hollow-content",
                         "message":  "Markdown body appears too short or placeholder-only.",
                         "path":  "stacks\\vitest\\README.md",
                         "tier":  "B",
                         "data":  {

                                  }
                     },
                     {
                         "severity":  "warning",
                         "category":  "hollow-content",
                         "message":  "Markdown body appears too short or placeholder-only.",
                         "path":  "stacks\\vue\\README.md",
                         "tier":  "B",
                         "data":  {

                                  }
                     },
                     {
                         "severity":  "warning",
                         "category":  "hollow-content",
                         "message":  "Markdown body appears too short or placeholder-only.",
                         "path":  "templates\\auto-dashboard-home-link.md",
                         "tier":  "B",
                         "data":  {

                                  }
                     },
                     {
                         "severity":  "warning",
                         "category":  "hollow-content",
                         "message":  "Markdown body appears too short or placeholder-only.",
                         "path":  "templates\\obsidian-note.md",
                         "tier":  "B",
                         "data":  {

                                  }
                     },
                     {
                         "severity":  "warning",
                         "category":  "hollow-content",
                         "message":  "Markdown body appears too short or placeholder-only.",
                         "path":  "wiki\\README.md",
                         "tier":  "B",
                         "data":  {

                                  }
                     }
                 ],
    "actions":  [
                    {
                        "tier":  "B",
                        "action":  "proposal",
                        "target":  "Archive stale content: adapters\\cursor\\rules\\memory-os.md",
                        "status":  "skipped duplicate"
                    },
                    {
                        "tier":  "B",
                        "action":  "proposal",
                        "target":  "Archive stale content: anti-patterns\\memory-pollution.md",
                        "status":  "skipped duplicate"
                    },
                    {
                        "tier":  "B",
                        "action":  "proposal",
                        "target":  "Archive stale content: anti-patterns\\prompting-failures.md",
                        "status":  "skipped duplicate"
                    },
                    {
                        "tier":  "B",
                        "action":  "proposal",
                        "target":  "Archive stale content: anti-patterns\\router-misrouting.md",
                        "status":  "skipped duplicate"
                    },
                    {
                        "tier":  "B",
                        "action":  "proposal",
                        "target":  "Archive stale content: domains\\backend\\api-debugging.md",
                        "status":  "skipped duplicate"
                    },
                    {
                        "tier":  "B",
                        "action":  "proposal",
                        "target":  "Archive stale content: domains\\backend\\api-design.md",
                        "status":  "skipped duplicate"
                    },
                    {
                        "tier":  "B",
                        "action":  "proposal",
                        "target":  "Archive stale content: domains\\backend\\auth.md",
                        "status":  "skipped duplicate"
                    },
                    {
                        "tier":  "B",
                        "action":  "proposal",
                        "target":  "Archive stale content: domains\\backend\\README.md",
                        "status":  "skipped duplicate"
                    },
                    {
                        "tier":  "B",
                        "action":  "proposal",
                        "target":  "Archive stale content: domains\\devops\\ci-cd.md",
                        "status":  "skipped duplicate"
                    },
                    {
                        "tier":  "B",
                        "action":  "proposal",
                        "target":  "Archive stale content: domains\\devops\\ci-debugging.md",
                        "status":  "skipped duplicate"
                    }
                ],
    "parameters":  {
                       "phase":  "iterate",
                       "root":  "C:\\Users\\btf\\AI-MemoryOS",
                       "max_proposals":  10,
                       "stale_days":  30
                   }
}
~~~

## 验证

- `validate-memory-os.ps1`：not run by this script
- 内容质量复查：not run by this script
