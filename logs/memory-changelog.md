# Memory Changelog 记忆变更日志

## 2026-06-01

- 放宽 `tools/auto/` 脚本分支的模型修复边界：`model-repair-plan.ps1` 可在 `auto/*` 分支上自动应用 A/B-tier 安全路径的 exact-match 模型编辑，并在写入后运行 `tools/validate-memory-os.ps1`；formal rules、router、skills、adapter gate、automation scripts 和核心治理文件仍走 C-tier 审批单。同步更新 `rules/auto-run-operations.md`、`docs/auto-run-usage.md` 和 `tools/auto/schemas/model-action.schema.json`。

## 2026-05-27

- 接受 proposal：`2026-05-26-infrastructure-integration-should-leave-trace`。在 `core/memory-rules.md` 增加基础设施/工具集成事件 P0/P1/P2 留痕规则，并在 `GOVERNANCE.md` 的审计节奏中加入集成事件 changelog 检查；留痕默认写入 `logs/memory-changelog.md`，当条目增多时可拆分为 `logs/integration-events.md`。
- Claude adapter 部署模型从"副本同步"迁移到"bootstrap redirect"：`C:\Users\btf\.claude\CLAUDE.md` 不再是 `adapters/claude/CLAUDE.md` 的完整副本，改为仅包含指向源文件的 redirect 指令；gate 变更后无需手动同步。同步更新 `_index.md`、`adapters/claude/external-config.md` 和 `tools/validate-memory-os.ps1` 的校验逻辑。

## 2026-05-26

- 在 Codex / Claude gate 中新增 CodeGraph 使用预算：明确单文件/小范围问题直接读文件，候选 1-3 个文件时优先 direct read，`codegraph_files` 仅作为候选范围判断，跨模块调用链/影响面/架构问题再优先使用 graph；同步更新 `adapters/codex/gate.md`、`adapters/claude/CLAUDE.md` 和 `C:\Users\btf\.claude\CLAUDE.md`。

- 新增 `proposals/future-directions/` 作为重大方向说明目录，用于保存长期架构意图和未来迁移背景，不作为可直接晋升的 pending proposal。
- 将“单一通用 OS + 本地配置隔离 overlay”记录迁入 future directions，并补齐 `_index.md`、`proposals/README.md`、dashboard、weekly audit、MCP search policy 和验证脚本入口。
- 接受 proposal：`2026-05-26-separate-daily-pending-proposals-from-future-direction-notes`。正式区分 `pending proposal` 与 `future direction note`，并在 `GOVERNANCE.md`、`core/memory-rules.md`、Codex / Claude gate 中写入读写边界。
- 补齐 Claude 侧连接说明：`adapters/claude/CLAUDE.md`、`adapters/claude/external-config.md`、`adapters/claude/README.md` 和 `integrations/mcp.md` 明确 `proposals/future-directions/` 可读可搜但不可通过 MCP 写入或直接晋升。
- 恢复 Claude user-scope `ai_memoryos` MCP 连接并同步 `C:\Users\btf\.claude\CLAUDE.md`；`tools/validate-memory-os.ps1` 增加 Claude user gate 与 `adapters/claude/CLAUDE.md` 的哈希一致性检查。
- 接入 CodeGraph 作为 Memory OS 可选项目代码图加速层：完成 Claude MCP 配置、wrapper 脚本、集成策略文档（`integrations/codegraph.md`）、slot 模型、热分支策略和恢复策略。CodeGraph 索引存储于 `private/codegraph/`，不在业务项目仓库内创建 `.codegraph/`。
- 在 Final Trace 增加 `graph: codegraph N` 字段，记录每轮 CodeGraph 工具调用次数；未调用时标记 `graph: none`。同步更新 `adapters/claude/CLAUDE.md` 和 `C:\Users\btf\.claude\CLAUDE.md`。
- 在 `adapters/claude/CLAUDE.md` 增加 Temporary Claude L2 Bias：仅 Claude adapter 在 L1/L2 边界任务上更倾向 L2，用于当前 Claude 使用量更充足阶段；不影响 Codex、shared skill specs、L0 和 L3 写入边界。
- 在 `adapters/claude/external-config.md`、`_index.md`、`STATUS.md` 留痕，方便后续根据 Claude/Codex 使用量变化回顾或移除该临时 overlay。

## 2026-05-25

- 收紧 MCP `memory_search` 默认范围：默认只搜索 active memory surface 和 `proposals/pending/`，accepted/rejected proposal 历史需要显式 `scope=history` 或 `scope=all`。
- 明确 MCP 不读取本机 `private/` overlay；这不影响人工、Codex 本地任务或 adapter-specific skill 在明确意图下读取自己的私有 overlay。
- 更新 `adapters/mcp/allowed-ops.md` 和 `adapters/mcp/tool-policy.md`，区分默认搜索、显式历史搜索、显式读取和写入边界。
- 加固 MCP server：新增 `realpath` 边界校验、pending proposal 敏感内容预检、multi-term search scoring。
- 扩展 `tools/validate-memory-os.ps1`：检查 Claude/Codex skill junction、敏感文件名、proposal status/frontmatter、broken wiki links。
- 新增 `logs/audits/README.md`，并在 `GOVERNANCE.md`、`templates/weekly-audit.md` 中明确审计记录落点。
- 补充 Memory OS 维护、安全和 adapter drift 相关 router / skill trigger eval 样例。
- 建立 shared skill spec 试点：新增 `skills/registry.json`、`skills/git-ops-guide/SKILL_SPEC.md` 和 `tools/sync-skills.ps1`，由共享核心生成 Codex / Claude 的 `git-ops-guide` 外壳，并在验证脚本中检查 source hash 防漂移。
- 将 7 个 active skills 全部迁移为 managed shared specs：`memory-curator`、`routing-auditor`、`bugfix-with-regression-test`、`frontend-component-review`、`pr-review`、`vue-change-self-check`、`git-ops-guide`。
- 扩展 skill trigger eval：每个 active skill 必须至少有一个正向触发样例，`git-ops-guide` 增加命令解释、命令顺序指导和“请求执行命令不触发”的样例。
- 加固 shared skill 和治理验证：`tools/sync-skills.ps1` 拒绝 registry 路径逃逸；`tools/validate-memory-os.ps1` 不再整体跳过 `.obsidian/`，仅跳过 workspace/cache；accepted/rejected proposal 必须保留决策原因。

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
