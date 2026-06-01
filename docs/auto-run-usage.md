---
title: Memory OS 自动化脚本使用说明
type: manual
status: active
created_at: 2026-05-29
scope: memory-os-auto
---

# Memory OS 自动化脚本使用说明

本文说明如何使用 `tools/auto/` 自审计、自迭代和自优化脚本，包括无人值守、AI 辅助、Codex profile、Claude profile、自定义 OpenAI-compatible profile、模型切换、调试顺序、审核和回滚边界。

## 1. 先记住三个安全结论

1. 普通调试先用 `-WhatIf`，不会写文件、不会创建分支、不会 commit、不会 push、不会真实调用模型。
2. 不要一开始就跑 full cycle。先调通 `model-semantic-audit.ps1` 的单模型调用，再跑 `run-all`，最后才跑 `start-cycle`。
3. 自动化终点是 `auto/*` 分支和运行日志，不会自动 merge 到 `main`。是否合并由人工审核决定。

## 2. 关键文件

| 文件 | 用途 |
|---|---|
| `tools/auto/model-profiles.json` | 模型 profile 配置入口。 |
| `tools/auto/model-profiles.example.json` | profile 示例。 |
| `tools/auto/config.json` | 禁用脚本配置。 |
| `tools/auto/run-all.ps1` | 编排单个 phase 或多个 phase。 |
| `tools/auto/model-semantic-audit.ps1` | 单独执行模型语义审计。 |
| `tools/auto/model-repair-plan.ps1` | 读取本轮 run log findings，再调用模型自动应用安全路径修复，或生成下一步 proposal / C-tier 审批单。 |
| `tools/auto/start-cycle.ps1` | 创建 auto 分支并执行完整 cycle 的入口。 |
| `tools/auto/review-cycle.ps1` | 生成审核摘要。 |
| `tools/auto/repair-failed-cycle.ps1` | 对 failed/partial cycle 做有限确定性修复。 |
| `logs/auto-runs/` | 自动运行日志和 cycle summary。 |
| `dashboard/auto-runs.md` | Obsidian 中查看自动运行状态。 |

## 3. 模型选择优先级

模型 profile 的解析优先级是：

1. 命令参数：`-ModelProfile <name>`
2. 环境变量：`AI_MEMORYOS_AUTO_MODEL_PROFILE`
3. `tools/auto/model-profiles.json` 里的 `default`
4. fallback：`codex`

示例：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\auto\model-semantic-audit.ps1 -ModelProfile claude -WhatIf
```

环境变量切换：

```powershell
$env:AI_MEMORYOS_AUTO_MODEL_PROFILE = "claude"
powershell -NoProfile -ExecutionPolicy Bypass -File tools\auto\model-semantic-audit.ps1 -WhatIf
```

临时恢复默认：

```powershell
Remove-Item Env:\AI_MEMORYOS_AUTO_MODEL_PROFILE -ErrorAction SilentlyContinue
```

## 4. Profile 配置

配置文件：

```text
tools/auto/model-profiles.json
```

当前内置 profile：

| Profile | provider | 用途 |
|---|---|---|
| `codex` | `codex` | 通过本机 Codex CLI 非交互调用。需先确认本机 `codex` 命令可用。 |
| `claude` | `claude` | 通过 Claude Code CLI 非交互调用。建议配置 `--print`。 |
| `custom` | `openai-compatible` | 通过 HTTP endpoint 调用 OpenAI-compatible API。 |

重要：`model-profiles.json` 不保存 token/API key。密钥只通过环境变量读取。

### 4.1 Claude profile

Claude Code CLI 的非交互模式建议使用 `--print`。可把 `claude` profile 调成类似：

```json
{
  "provider": "claude",
  "command": "claude",
  "arguments": ["--print", "--output-format", "text"],
  "model": "sonnet",
  "allowed_tasks": ["semantic-audit", "draft-proposal", "draft-approval-sheet", "draft-a-patch", "explain-failure", "suggest-repair"],
  "timeout_seconds": 120,
  "max_findings": 20
}
```

调试命令：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\auto\model-semantic-audit.ps1 -ModelProfile claude -Scope content-quality -WhatIf
```

确认 `-WhatIf` 没问题后，再单独去掉 `-WhatIf` 调真实模型：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\auto\model-semantic-audit.ps1 -ModelProfile claude -Scope content-quality
```

### 4.2 Codex profile

Codex profile 依赖本机可执行的非交互 Codex CLI。当前机器上如果 `codex --help` 返回 `Access is denied`，说明需要先修 Codex CLI 路径或权限，再跑真实 Codex profile。

建议先做本机命令验证：

```powershell
codex --help
```

如果你的 Codex CLI 需要类似 `--print`、`exec` 或其它非交互参数，把它写进 profile 的 `arguments`：

```json
{
  "provider": "codex",
  "command": "codex",
  "arguments": [],
  "model": "default",
  "allowed_tasks": ["semantic-audit", "draft-proposal", "draft-approval-sheet", "draft-a-patch", "explain-failure", "suggest-repair"],
  "timeout_seconds": 120,
  "max_findings": 20
}
```

调试顺序：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\auto\model-semantic-audit.ps1 -ModelProfile codex -Scope content-quality -WhatIf
```

`-WhatIf` 只验证脚本路径，不验证 Codex CLI 能否真实产出 JSON。真实模型调试要单独执行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\auto\model-semantic-audit.ps1 -ModelProfile codex -Scope content-quality
```

### 4.3 Custom OpenAI-compatible profile

`custom` profile 通过环境变量读取 endpoint 和 key：

```powershell
$env:AI_MEMORYOS_AUTO_ENDPOINT = "https://example.com/v1/chat/completions"
$env:AI_MEMORYOS_AUTO_API_KEY = "<不要写进仓库>"
```

配置示例：

```json
{
  "provider": "openai-compatible",
  "model": "your-model-id",
  "endpoint_env": "AI_MEMORYOS_AUTO_ENDPOINT",
  "api_key_env": "AI_MEMORYOS_AUTO_API_KEY",
  "allowed_tasks": ["semantic-audit"],
  "timeout_seconds": 120,
  "max_findings": 20
}
```

调试命令：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\auto\model-semantic-audit.ps1 -ModelProfile custom -Scope content-quality -WhatIf
```

真实调用：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\auto\model-semantic-audit.ps1 -ModelProfile custom -Scope content-quality
```

## 5. 最推荐的调试顺序

### 5.0 根目录快捷入口

项目根目录提供了 `auto.ps1`，用于避免每次手敲完整 `powershell -NoProfile -ExecutionPolicy Bypass -File tools\auto\start-cycle.ps1 ...` 命令。

默认是 dry run：

```powershell
.\auto.ps1
```

真实运行但不 push：

```powershell
.\auto.ps1 -Run
```

真实运行并 push `auto/*` 分支：

```powershell
.\auto.ps1 -Run -Push
```

切换范围或模型：

```powershell
.\auto.ps1 -Scope proposal-review -ModelProfile claude
```

### 5.1 只验证配置解析

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "& { Import-Module .\tools\auto\_shared.psm1 -Force; (Get-ModelProfile -Root . -Name claude).name }"
```

预期输出：

```text
claude
```

### 5.2 验证脚本 dry run

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\auto\model-semantic-audit.ps1 -ModelProfile claude -Scope content-quality -WhatIf
```

### 5.3 单脚本真实模型调用

只在 profile 调通后执行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\auto\model-semantic-audit.ps1 -ModelProfile claude -Scope content-quality
```

### 5.4 单 phase dry run

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\auto\run-all.ps1 -Phase semantic-audit -ModelProfile claude -WhatIf
powershell -NoProfile -ExecutionPolicy Bypass -File tools\auto\run-all.ps1 -Phase optimize -ModelProfile claude -WhatIf -MaxProposals 3
```

### 5.5 单 phase 真实运行

先跑 audit，再跑 semantic audit，不要直接跑 `all`：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\auto\run-all.ps1 -Phase audit -ModelProfile claude
powershell -NoProfile -ExecutionPolicy Bypass -File tools\auto\run-all.ps1 -Phase semantic-audit -ModelProfile claude
```

### 5.6 完整 cycle dry run

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\auto\start-cycle.ps1 -Scope content-quality -ModelProfile claude -WhatIf
```

### 5.7 完整 cycle 真实运行

只有在模型 profile、单脚本、单 phase 都确认后再跑：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\auto\start-cycle.ps1 -Scope content-quality -ModelProfile claude
```

如果要推送 `auto/*` 分支：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\auto\start-cycle.ps1 -Scope content-quality -ModelProfile claude -Push
```

`start-cycle.ps1` 会等 `run-all` 的全部脚本成功完成、写入 cycle summary 和 `start-cycle` run log 后，再统一创建一个提交。这样 `auto/*` 分支合并到 `main` 时默认只包含一个自动化提交。若 cycle 中途失败，脚本不会提交 partial work；失败日志和已产生的文件会留在当前 `auto/*` 分支的未提交工作区里，供人工检查、修复或直接丢弃分支后重跑。

真实创建 `auto/*` 分支前，脚本会验证当前必须在 `main`，工作区必须干净，且 `main` 相对 upstream 没有未推送或未同步的 commit。否则脚本会停止，避免把 `main` 上未提交的文件改动带到自动化功能分支。

## 6. Scope 怎么选

| Scope | 适用场景 | 主要脚本 |
|---|---|---|
| `content-quality` | 清理 stale、重复、孤立内容。 | `iterate-stale-content`、`iterate-duplicate-merge`、`optimize-unused-pages`、`optimize-frontmatter` |
| `router-cleanup` | 路由一致性、adapter gate 同步。 | `iterate-router-refinement`、`optimize-adapter-gate-sync` |
| `skill-health` | skill 覆盖率和 wrapper 一致性。 | `iterate-skill-gaps`、`optimize-skill-consistency` |
| `proposal-review` | proposal 健康和晋升候选。 | `iterate-promotion-candidates`、`audit-proposal-health` |
| `full` | 全量维护。 | 全部脚本 |

建议第一次真实运行只用 `content-quality` 或 `proposal-review`，不要直接 `full`。

## 7. Phase 怎么选

| Phase | 是否调用模型 | 是否可能写文件 | 说明 |
|---|---:|---:|---|
| `audit` | 否 | 是，写 run log | 确定性审计。 |
| `semantic-audit` | 是，除非 `-WhatIf` | 是，写 run log | 模型语义审计。 |
| `iterate` | 否 | 是，可能写 pending proposal | 根据 audit findings 生成 B-tier proposal。 |
| `optimize` | 否 | 是，A-tier 或 C-tier 审批单 | dashboard、frontmatter、C-tier 审批单等。 |
| `all` | 是，除非 `-WhatIf` | 是 | 全编排；完整 cycle 成功后还会运行 `model-repair-plan.ps1`，用模型消费本轮日志 findings，自动应用安全路径 A/B-tier 修复并生成下一步 action。不建议初次直接运行。 |

完整 cycle 在 `auto/*` 分支上允许 `model-repair-plan.ps1` 自动应用模型返回的 `apply-edits`，但只限非保护路径，例如 `docs/`、`dashboard/`、`proposals/pending/` 和普通 Markdown 内容。`adapters/`、`core/`、`router/`、`rules/`、`skills/`、`tools/`、正式索引和治理文件仍需要 C-tier 审批单。若只想生成计划、不自动改文件，可单独运行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\auto\model-repair-plan.ps1 -ModelProfile claude -Scope content-quality -PlanOnly
```

## 8. 无人值守运行

无人值守适合在模型 profile 稳定后使用。推荐先跑 `-WhatIf` 并人工确认日志。

### 8.1 使用环境变量选择模型

```powershell
$env:AI_MEMORYOS_AUTO_MODEL_PROFILE = "claude"
```

### 8.2 Windows Task Scheduler 示例

创建任务前先确认命令可手动成功运行。

```powershell
schtasks /Create /TN "AI-MemoryOS Auto Content Quality" /SC DAILY /ST 09:00 /TR "powershell -NoProfile -ExecutionPolicy Bypass -File C:\Users\btf\AI-MemoryOS\tools\auto\start-cycle.ps1 -Root C:\Users\btf\AI-MemoryOS -Scope content-quality -ModelProfile claude -Push"
```

如果仍在调试模型，把 `-Push` 去掉，或者只跑 `run-all.ps1 -Phase audit`。

### 8.3 无人值守建议

- 不要把 API key 写入 `model-profiles.json`。
- `custom` profile 的 key 只放环境变量或系统安全存储。
- 定时任务建议先跑窄 scope。
- 保留 `logs/auto-runs/`，不要自动清理失败日志。
- 自动化脚本不会 merge main，人工审核仍是必要步骤。

## 9. AI 辅助运行

AI 辅助指你让 Codex 或 Claude 帮你执行命令、解释日志、生成下一步建议。

### 9.1 Codex 中使用

适合让 Codex 执行安全的 `-WhatIf`、读取日志、生成审核摘要。

推荐提示：

```text
请只跑 -WhatIf，不要真实调用模型，不要创建分支、commit、push。
命令：powershell -NoProfile -ExecutionPolicy Bypass -File tools\auto\start-cycle.ps1 -Scope content-quality -ModelProfile claude -WhatIf
```

真实运行前要明确授权，例如：

```text
现在可以真实运行 model-semantic-audit 单脚本，但不要跑 full cycle，不要 push。
```

### 9.2 Claude Code 中使用

Claude Code 可以直接运行 PowerShell 命令。若让 Claude profile 调 Claude CLI，注意这是“Claude 调用 Claude”，要控制范围：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\auto\model-semantic-audit.ps1 -ModelProfile claude -Scope content-quality -WhatIf
```

真实调用：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\auto\model-semantic-audit.ps1 -ModelProfile claude -Scope content-quality
```

### 9.3 AI 辅助和无人值守的区别

| 模式 | 谁触发 | 是否有人看着 | 推荐用途 |
|---|---|---:|---|
| AI 辅助 | Codex/Claude 会话中手动触发 | 是 | 调试、解释日志、单次维护。 |
| 无人值守 | Task Scheduler/cron | 否 | 稳定后定期跑窄 scope。 |

## 10. 禁用某些脚本

配置文件：

```text
tools/auto/config.json
```

示例：

```json
{
  "disabled_scripts": [
    "optimize-core-rules.ps1",
    "optimize-adapter-gate-sync.ps1"
  ]
}
```

也可以用环境变量临时禁用：

```powershell
$env:AI_MEMORYOS_DISABLED_SCRIPTS = "optimize-core-rules.ps1,optimize-adapter-gate-sync.ps1"
```

清除：

```powershell
Remove-Item Env:\AI_MEMORYOS_DISABLED_SCRIPTS -ErrorAction SilentlyContinue
```

## 11. 忽略已知 finding

配置文件：

```text
tools/auto/.ignored-findings.json
```

示例：

```json
{
  "ignored_findings": [
    {
      "category": "hollow-content",
      "path": "docs/example.md",
      "message": ""
    }
  ]
}
```

也可以使用脚本计算出的 `id` 精确忽略。忽略 finding 后，iterate 脚本会记录 `skipped ignored finding`。

## 12. C-tier 审批单

C-tier 包括 adapter gate、core/rules/router 等高风险变更。

默认只生成审批单：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\auto\run-all.ps1 -Phase optimize -ModelProfile claude -WhatIf
```

审批单目录：

```text
logs/auto-runs/approval-sheets/
```

要执行 `-ApplyApproved`，审批单必须显式包含：

```text
- Approved: true
- Approved by: <name>
- Decision reason: <reason>
```

然后运行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\auto\optimize-core-rules.ps1 -ApplyApproved -ApprovalSheet logs\auto-runs\approval-sheets\<file>.md -WhatIf
```

确认 `-WhatIf` 后再去掉 `-WhatIf`。

## 13. 查看结果

命令行：

```powershell
Get-ChildItem logs\auto-runs -File | Sort-Object LastWriteTime -Descending | Select-Object -First 10
```

Obsidian：

```text
dashboard/auto-runs.md
```

运行日志包括：

- findings
- actions
- pending decisions
- structured JSON
- model profile
- model invocation count
- branch
- lock id
- repair attempts

## 14. 审核自动分支

生成 auto 分支后，用：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\auto\review-cycle.ps1 -Branch auto/YYYYMMDD-HHMMSS-content-quality
```

检查 Git：

```powershell
git status --short
git log --oneline --grep="^auto:"
```

合并 main 不是脚本自动做的。你需要人工决定整块 merge、cherry-pick，或直接删除 auto 分支。

成功的 `start-cycle.ps1` 默认只生成一个自动化提交。如果分支上没有提交但有未提交改动，通常表示 cycle 中途失败；先看 `logs/auto-runs/` 的 failed log，再决定修复、手动提交诊断结果，或删除该 `auto/*` 分支重跑。

## 15. 修复失败 cycle

先查看失败日志：

```powershell
Get-ChildItem logs\auto-runs -Filter *.md | Select-String -Pattern 'status: "failed"|status: failed'
```

dry run：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\auto\repair-failed-cycle.ps1 -Branch auto/YYYYMMDD-HHMMSS-content-quality -WhatIf
```

真实修复：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\auto\repair-failed-cycle.ps1 -Branch auto/YYYYMMDD-HHMMSS-content-quality
```

修复范围只应是结构性问题，例如 run log frontmatter、字段缺失、格式问题。语义规则不自动修。

失败 cycle 的现场默认不会自动提交。`repair-failed-cycle.ps1` 修复后仍需要人工检查工作区；只有确认要保留这次失败/修复结果时，才手动提交，否则可以丢弃分支并从 `main` 重新启动新的 cycle。

## 16. 常用命令速查

只跑确定性审计：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\auto\run-all.ps1 -Phase audit
```

只跑模型语义审计 dry run：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\auto\model-semantic-audit.ps1 -ModelProfile claude -Scope content-quality -WhatIf
```

只跑模型语义审计真实调用：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\auto\model-semantic-audit.ps1 -ModelProfile claude -Scope content-quality
```

只跑 proposal 迭代，最多 3 个：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\auto\run-all.ps1 -Phase iterate -MaxProposals 3
```

只跑优化 dry run：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\auto\run-all.ps1 -Phase optimize -MaxProposals 3 -WhatIf
```

完整 cycle dry run：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\auto\start-cycle.ps1 -Scope content-quality -ModelProfile claude -WhatIf
```

完整 cycle 真实运行但不 push：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\auto\start-cycle.ps1 -Scope content-quality -ModelProfile claude
```

完整 cycle 真实运行并 push auto 分支：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\auto\start-cycle.ps1 -Scope content-quality -ModelProfile claude -Push
```

## 17. 推荐路线

第一次使用：

1. 设置或确认 `tools/auto/model-profiles.json`。
2. 跑 `Get-ModelProfile` 函数级检查。
3. 跑 `model-semantic-audit.ps1 -WhatIf`。
4. 跑单脚本真实模型调用。
5. 跑 `run-all.ps1 -Phase audit`。
6. 跑 `run-all.ps1 -Phase semantic-audit`。
7. 跑 `start-cycle.ps1 -WhatIf`。
8. 最后再跑真实 `start-cycle.ps1`。

日常维护：

1. 每周看 `dashboard/auto-runs.md`。
2. 审核 `proposals/pending/`。
3. 需要时跑 `review-cycle.ps1`。
4. 不满意整批结果时，不合并 auto 分支即可。

## 18. 当前注意事项

- 本文档描述的是自动化脚本的使用方式，不代表应该立即跑 full cycle。
- Codex profile 需要本机 `codex` CLI 可非交互执行；如果 `codex --help` 报 `Access is denied`，先修 CLI 权限或路径。
- Claude profile 建议配置 `--print`，否则可能进入交互模式。
- `custom` profile 的 endpoint/key 必须通过环境变量提供。
- 不要把 token、password、secret、cookie、生产日志原文写入 Memory OS。
- 自动化不会自动 merge main。main 只能人工审核后更新。
