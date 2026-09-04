# Memory Changelog 记忆变更日志

## 2026-09-04

- 根据后续使用反馈停用低保真原型到 Figma 的默认流程：workflow 文件标记为 disabled，默认路由和 eval 已同步撤销；历史文件与 Figma 恢复说明保留。
- Codex 与 Claude `external-config.md` 同步标记 Figma 为 dormant optional capability，仅在用户显式要求 Figma 时使用，不再承担默认审美设计中间层。
- 接受 proposal：`2026-09-04-低保真原型通过官方-figma-skills-进入视觉设计流程`。
- 新增 `workflows/frontend-prototype-to-figma-design.md`，把低保真功能原型到高保真 Figma 设计、人工确认、design-to-code 的阶段边界固化为可复用流程。
- 明确 Memory OS 只编排 `figma-create-new-file`、`figma-use`、`figma-generate-design`、`figma-generate-library`、`figma-design-to-code` 等官方 Skills，不复制官方正文、不登记到 managed skill registry、不依赖版本化插件缓存路径。
- 同步更新 Codex 与 Claude `external-config.md`：分别记录官方集成首选安装方式、Remote MCP 手动回退、OAuth/Skill 可用性验证和敏感信息边界。
- 路由变化及回归样例记录见 `logs/router-changelog.md` 与 `evals/router-test-cases.md`。

## 2026-07-01

- 接受 proposal：`2026-07-01-新增文件删除安全守则-默认回收站-禁用绕过命令`。
- 在 `adapters/gate-source/shared/gate-core.md` 新增 `## File Deletion Safety`，Windows 环境下删除项目源码、配置或用户文件/目录时默认走系统回收站，禁止用 `rm` / `del` / `Remove-Item` / `rd` / `rmdir` 等绕过回收站的命令删除上述文件。
- 明确例外：构建/测试/缓存等非交付产物的路径受限清理仍按 `Verification` 段处理；`git clean`、`git rm`、`git checkout -- <path>`、`git reset --hard` 等 git 删除仍按 git 操作边界处理并需用户明确提及。
- 同步生成 `adapters/codex/gate.md` 与 `adapters/claude/CLAUDE.md`，并在 `evals/router-test-cases.md` 增加 `File Deletion Safety Cases` 行为回归样例。
- 验证：运行 `tools/sync-adapter-gates.ps1`、`tools/sync-adapter-gates.ps1 -Check`、`tools/validate-memory-os.ps1`。

## 2026-06-17

- 接受 proposal：`2026-06-17-收紧-l1-l2-capture-建议的高置信与静默边界`。
- 收紧 L1/L2 capture suggestion 规则：从“类型命中即可建议”收紧为高置信、有本次任务证据、当前上下文未覆盖/未拒绝、能减少未来错误才建议；明确 L1/L2 不为查重额外读取 Memory OS，用户确认 capture 进入 L3 后才执行查重；不确定时保持静默。
- 修改 `adapters/gate-source/shared/gate-core.md` → `Read And Write Boundaries` 的 L1/L2 capture trigger bullet，并通过 `tools/sync-adapter-gates.ps1` 同步生成 `adapters/claude/CLAUDE.md` 与 `adapters/codex/gate.md`。
- 不变更：L3 写入权限、pending-first 原则、五类 typed capture trigger、用户确认后写 pending、拒绝后不追问。
- Eval 处理：当前 eval 目录没有 gate behavior 专用用例入口，本次不新增 eval；以 adapter gate sync/check、`tools/validate-memory-os.ps1` 和本 changelog 作为必需 companion。

- 接受 proposal：`2026-06-17-adapter-gate-bootstrap-改为源文件生成并禁止直接改生成物`。
- 新增 `adapters/gate-source/**`、Codex / Claude gate/bootstrap templates 和 `tools/sync-adapter-gates.ps1`，将 `adapters/codex/bootstrap.md`、`adapters/codex/gate.md`、`adapters/claude/bootstrap.md`、`adapters/claude/CLAUDE.md` 转为生成目标并加 generated marker。
- 更新 `core/change-companions.md`、`evals/router-test-cases.md`、`tools/validate-memory-os.ps1`、adapter README / external-config、`_index.md`、`README.md` 和 `STATUS.md`，要求改 gate/bootstrap 源后运行 adapter gate sync/check/validate，禁止直接手写生成目标。
- 接受 proposal：`2026-06-17-路由纠正-正式规则文件改动应由-ai-自动按-companion-映射同步关联文件`。
- 新增 `core/change-companions.md` 作为正式规则写入 companion 映射的单一事实源，覆盖 router、skill source、adapter gate、MCP policy、external-config、proposal 晋升、core/governance、`logs/README.md`、自身维护和 `workflows/proposal-promotion.md` 的配套同步关系。
- 在 `adapters/codex/gate.md` 与 `adapters/claude/CLAUDE.md` 新增 `## Write Companions`，要求写入正式规则路径前先读 `core/change-companions.md`，并把 `## Cross-Adapter Sync` 收敛为高层共享边界，避免 gate 与 companion map 双轨维护。
- 修改 `workflows/proposal-promotion.md` 的 `Required Logs`，改为晋升前读取 `core/change-companions.md` 的 proposal-promotion 行，避免 Required Logs 静态列表与 companion map 漂移。
- 风险与验证：首版不落地 companion lint；通过 `evals/router-test-cases.md` 的 Write Companions cases 固化回归样例，并运行 `tools/validate-memory-os.ps1` 做结构验证。

## 2026-06-16

- 将 Codex / Claude adapter 读取结构拆为每轮轻量 `bootstrap.md` 与按需完整 gate：新增 `adapters/codex/bootstrap.md`、`adapters/claude/bootstrap.md`，并同步更新真实软件入口、adapter README、external-config 和 `_index.md`。
- 在 Codex / Claude Final Trace 增加 `gate: cached|read` 字段，用于记录本轮完整 gate 是复用已加载策略还是重新读取；保留 `bootstrap.md` 作为每轮固定轻量入口。

## 2026-06-13

- 接受 proposal：`2026-06-13-skill-references-应作为-skills-skill-源文件并由-sync-脚本同步到-adapter`。
- 将 managed skill references 纳入 shared source 边界：`skills/<skill>/references/**`（如存在）作为唯一人工编辑源，adapter `references/**` 由 `tools/sync-skills.ps1` 复制同步生成。
- 同步更新 Codex / Claude gate 的 Cross-Adapter Sync 第 6 条，禁止直接编辑 adapter `SKILL.md` 和 adapter `references/**`。
- 接受 proposal：`2026-06-13-审查类前端任务跳过-router-map-探针的执行漂移补丁`。
- 将审查新增前端目录 / 从零到现在这类非默认基线 changeset 落地到 `router/workflow-map.md` 的 review workflow 触发边界，并补充 `evals/router-test-cases.md` 回归样例。
- 保持边界：不修改 Codex / Claude gate，不扩张 Final Trace，不修改 `router/skill-map.md`；前端文件范围命中时由 workflow map 显式交接到 skill map 判定四段式 self-check。
- 接受 proposal：`2026-06-13-反模式-diff-基线泛化识别-不要把-非默认-diff-基线-误判为非-diff-任务`。
- 将“非默认 diff 基线仍是 changeset”的反模式落地到 `router/skill-map.md`、`skills/vue-change-self-check/SKILL_SPEC.md`、`skills/pr-review/SKILL_SPEC.md`、`skills/frontend-component-review/SKILL_SPEC.md` 和 `evals/skill-trigger-test-cases.md`。
- 保留排除边界：没有变更窗口的模块解释、架构通读、单点 debug 不强行触发 diff 类 skill。

## 2026-06-11

- 接受 proposal：`2026-06-11-将-skill-同步升级为-adapter-shell-渲染与漂移检测管线`。
- 将 managed skill 同步机制升级为 adapter template 渲染与 `-Check` 漂移检测管线。
- 新增 `workflows/skill-maintenance.md` 和 `dashboard/skills.md` 维护命令入口，明确 shared spec、registry、adapter template 与 generated `SKILL.md` 的职责边界。
- `tools/validate-memory-os.ps1` 改为调用 `tools/sync-skills.ps1 -Check` 聚合 generated skill 漂移问题。

## 2026-06-05 (回填 2026-06-16)

- 接受 proposal：`2026-06-05-l1-workflow-skill-候选信号应触发-router-map-轻量探针`。
- 补齐 gate 与 router map 之间的执行衔接：`adapters/claude/CLAUDE.md` 与 `adapters/codex/gate.md` 同步新增 `## Workflow / Skill Probe` 段；L1 描述加例外句"出现明确 workflow/skill 候选信号时按 Workflow / Skill Probe 规则读对应 map 做探针"。
- 不修改 L0-L3 定义、不修改 router map 内容、不扩张 Final Trace；`evals/router-test-cases.md` 新增 `## Workflow / Skill Probe Cases` 子表与 `## Signal Classification Reference` 做回归判分。
- 来源：`admin-vue` CoDesign 原型读取任务，模型按 L1 默认"不读 Memory OS 正文"自走，绕过 workflow-map 已有的原型 workflow 入口。

## 2026-06-04

- 接受 proposal：`2026-06-04-frontend-prototype-reading-must-include-visual-layout-constraints`。新增 `workflows/frontend-prototype-driven-development.md`，要求按 CoDesign / Lanhu / Figma / Axure 等原型开发前先提取字段/数据、交互/状态、API 边界和结构性视觉布局约束；同步在 `domains/frontend/README.md` 增加 workflow 引用。
- 接受 proposal：`2026-06-04-补充-workflow-map-以触发前端原型驱动开发流程`（回填 2026-06-16）。新建 `router/workflow-map.md` 作为 workflow 触发边界索引，首行登记前端原型驱动开发 workflow；`_index.md` Routing 第 4 步登记 workflow-map 入口。
- 接受 proposal：`2026-06-04-补齐-workflow-map-的通用-workflow-触发边界`（回填 2026-06-16）。在 `router/workflow-map.md` 补齐 11 行通用 workflow 触发边界（CodeGraph / diff-review-lite / regression / memory-retrospective / pre-commit-self-check / proposal-promotion / weekly-audit / retrospective-lite / refactor-with-safety / script-automation / test-strategy），每行带反向排除；显式排除 `workflows/feature-development.md` 避免泛化默认步骤稀释路由价值。

## 2026-06-03

- 收紧 Codex / Claude gate 中的 L1/L2 经验沉淀提示规则：把原先模糊的 "clearly reusable lesson" 改成单条类型化 capture trigger，要求用 `反模式：`、`路由纠正：`、`可复用模式：`、`重复失败模式：` 或 `边界险触：` 标注候选经验，并保持 `proposals/pending/` 确认后写入边界。

## 2026-05-27

- 接受 proposal：`2026-05-26-infrastructure-integration-should-leave-trace`。在 `core/memory-rules.md` 增加基础设施/工具集成事件 P0/P1/P2 留痕规则，并在 `GOVERNANCE.md` 的审计节奏中加入集成事件 changelog 检查；留痕默认写入 `logs/memory-changelog.md`，当条目增多时可拆分为 `logs/integration-events.md`。
- Claude adapter 部署模型从"副本同步"迁移到"bootstrap redirect"：`C:\Users\btf\.claude\CLAUDE.md` 不再是 `adapters/claude/CLAUDE.md` 的完整副本，改为仅包含指向源文件的 redirect 指令；gate 变更后无需手动同步。同步更新 `_index.md`、`adapters/claude/external-config.md` 和 `tools/validate-memory-os.ps1` 的校验逻辑。

## 2026-05-26

- 接受 proposal：`2026-05-26-修正-vue-uni-app-改动检查未触发-vue-change-self-check`（回填 2026-06-16）。扩展 `router/skill-map.md` 的 `vue-change-self-check` 触发边界（仓库或轻量 diff 命中 `.vue` / `pages.json` / `manifest.json` / 前端路由配置时也触发，可与 `pr-review` 并行）；同步更新 `skills/vue-change-self-check/SKILL_SPEC.md`、Codex / Claude adapter SKILL.md 和 `evals/skill-trigger-test-cases.md` 正反样例。来源：`h5-vue` 项目"检查我的改动 + 某个 commit"任务被 `pr-review` 单独吞掉。
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
- 更新 `adapters/codex/AGENTS.md`、`adapters/codex/prompts/global-agents-snippet.md`、`README.md`、`docs/usage-manual.md`、`router/routing-rules.md`、`core/codex-operating-rules.md`。（历史记录；其中部分文件后来已合并或删除。）
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
