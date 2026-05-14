# Memory Changelog 记忆变更日志

## 2026-05-14

- 删除旧版手动提示词 `prompts/low-cost.md` 和 `prompts/complex-task.md`；Codex 任务量级统一以 `adapters/codex/gate.md` 的 L0/L1/L2/L3 Gate 为准。
- 新增 `adapters/codex/external-config.md`，记录 OS 外部 Codex 本机配置副本，包括全局 `AGENTS.md` bootstrap、`config.toml` snippet、可选 MCP config、active skill junction 和验证步骤。
- 补充外部配置审计结果：Git local config 需要记录；Obsidian 配置已由仓库内 `.obsidian/` 跟踪，不需要单独外部副本；本机 `.codex` 中的 Lanhu MCP、其他 trusted projects、marketplace cache、未跟踪 `git-ops-guide` skill 不纳入 Memory OS 必需恢复项。
- 更新 `tools/validate-memory-os.ps1`，将 `gate.md`、`external-config.md` 和 `pr-review` active skill 纳入验证。
- 同步说明文件以匹配 Codex gate 入口和 L0-L3 触发机制。
- 更新 `adapters/codex/AGENTS.md`、`adapters/codex/prompts/global-agents-snippet.md`、`README.md`、`docs/usage-manual.md`、`router/routing-rules.md`、`core/codex-operating-rules.md`。
- 明确 Codex 每个输入先读取 `adapters/codex/gate.md`，L0/L1 不读取 Memory OS 正文，L1 默认倾向触发轻量 workflow / skill。
- 明确 L2 才读取 `_index.md` + 最多 3 个相关页面，L3 仍需用户明确要求或确认后写入 `proposals/pending/`。
- 更新 `core/memory-rules.md` 的读取与写入边界、读取预算表述，将旧的“普通/复杂任务”二分收敛为 L0/L1/L2/L3，并明确 2k 是普通 L2 的 Memory OS 正文软预算。
- 补充 OS Trace Footer 说明，并区分 Cursor / Generic adapter 不使用 Codex gate bootstrap。

## 2026-05-13

- 接受 proposal：`2026-05-13-frontend-regression-verification-strategy`。
- 新增 `workflows/frontend-regression-verification-strategy.md`，定义前端代码修改后的回归验证分层策略。
- 明确构建、测试、类型检查、lint / format 自动修复、代码生成、依赖安装、dev server、文档生成等验证副作用的处理边界。
- 在 `domains/frontend/README.md` 和 `domains/testing/README.md` 增加 workflow 引用。
- 增加 Memory OS Gate 读取边界：每个用户输入先做轻量判定，但判定本身不读取 Memory OS。
- 将“用户明确声明复杂任务才读取”调整为“Codex 自动判断是否需要长期工程记忆参与”。
- 保留写入边界：读取 Memory OS 不等于写入记忆，写入仍需用户明确要求或确认，并只写 `proposals/pending/`。

## 2026-05-12

- 接受 proposal：`2026-05-12-set-default-memoryos-read-budget-for-complex-tasks`。
- 将普通复杂任务的 MemoryOS 默认读取预算设为不超过 2k tokens。
- 在 `_index.md` 和 `core/memory-rules.md` 中写入读取预算边界。
- 明确 2k 预算只统计 MemoryOS 自身读取内容，不包含业务项目代码、diff、报错日志、接口文档、终端输出、当前对话或 Codex 系统上下文。
- 维护、weekly audit、proposal 晋升、skill 晋升等任务可临时放宽到 5k-8k tokens，但需要说明读取范围。

## 2026-05-11

- 创建 AI Memory OS 仓库。
- 增加低消耗读取策略：普通任务默认不读取 Memory OS。
- 建立 proposal-first 治理机制：新经验默认只写入 `proposals/pending/`。
- 建立 core / router / workflow / domain 基础骨架。
- 增加 frontend MVP 领域包和跨模型 adapters。

## 记录格式建议

```text
日期：
来源 proposal：
变更目标：rules / router / skills / evals / wiki
变更原因：
验证方式：
风险：
```
