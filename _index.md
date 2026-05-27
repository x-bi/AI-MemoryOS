# Memory OS Index 记忆索引

## Read Budget 读取预算

每个用户输入先读取 `adapters/codex/gate.md` 做轻量 Memory OS Gate 判定；读取 gate 只用于加载运行策略，不等于读取 Memory OS 正文。

- L0：纯解释、纯问答、无文件改动、无决策影响的任务，读 gate 后直接执行，不读 Memory OS 正文。
- L1：轻量 workflow / skill 默认倾向触发，读 gate 后不再读 Memory OS 正文。
- L2：复杂工程任务，可自动读本文件，最多再读 3 个直接相关页面。
- L3：仅用户明确要求或确认后写入 `proposals/pending/`；重大长期方向说明仅在用户明确要求记录方向或架构意图时写入 `proposals/future-directions/`。
- 记忆复盘：读本文件和少量相关 rules / workflows / domains / router 页面。
- 维护模式：可以审计、整理、晋升 proposal，但仍需保留变更记录。

普通复杂任务的 MemoryOS 读取预算默认不超过 2k tokens；该预算只统计 MemoryOS 自身内容，不包含业务项目代码、diff、报错日志、接口文档、终端输出、当前对话或 Codex 系统上下文。维护、weekly audit、proposal 晋升、skill 晋升等任务可临时放宽到 5k-8k tokens，但必须说明读取范围。

## Routing 路由

1. 先读 `adapters/codex/gate.md` 做 Memory OS Gate：判断任务处于 L0/L1/L2/L3。
2. 再判断 task_type：explain / debug / implement / review / architecture / retrospective / maintenance。
3. 再判断 domain：frontend / testing / backend / scripting / devops / security。
4. 再选择 workflow / skill / markdown。
5. 低置信度时先问一个关键问题，不扩大读取。

## Core Files 核心文件

- `STATUS.md`：当前完成度和剩余工作。
- `ROADMAP.md`：7 / 30 / 90 天推进路线。
- `GOVERNANCE.md`：proposal 晋升、拒绝和审计规则。
- `INSTALL.md`：Codex 接入和日常使用方式。
- `dashboard/home.md`：Obsidian 首页入口。
- `core/codex-operating-rules.md`：Codex 使用边界。
- `core/memory-rules.md`：记忆写入边界。
- `core/safety-rules.md`：敏感信息和安全规则。
- `router/intent-map.md`：任务类型路由。
- `router/domain-map.md`：领域路由。
- `router/skill-map.md`：Codex skill 触发边界。
- `workflows/`：可复用执行流程。
- `domains/frontend/`：前端优先领域包。
- `proposals/pending/`：唯一默认写入入口。
- `proposals/future-directions/`：重大方向说明和长期架构意图，不作为可直接晋升的 pending proposal。

## Domain Entry 领域入口

- 前端：`domains/frontend/README.md`
- 测试：`domains/testing/README.md`
- 后端：`domains/backend/README.md`
- 脚本：`domains/scripting/README.md`
- DevOps：`domains/devops/README.md`
- 安全：`domains/security/README.md`

## Adapter Files 适配器文件

- `adapters/codex/AGENTS.md`：Codex 接入说明。
- `adapters/codex/gate.md`：Codex 全局 bootstrap 读取的运行策略入口。
- `adapters/codex/external-config.md`：Codex OS 外部配置副本，用于换机或新软件快速恢复。
- `adapters/codex/skills/`：Codex 专用 skills 源目录。
- `skills/registry.json`：managed shared skill specs 的名单源，用于生成 Codex / Claude adapter skill 外壳。
- `skills/<skill>/SKILL_SPEC.md`：模型无关的 skill 核心逻辑。
- `adapters/codex/config/recommended-config.toml`：全局 config 合并建议。
- `adapters/generic/SYSTEM.md`：通用模型接入说明。
- `adapters/mcp/`：受限 MCP 自动化入口，只允许读库和写 pending proposal。

## Claude Adapter Current Entry

- `adapters/claude/CLAUDE.md`: Claude Code Memory OS Gate template. `C:\Users\btf\.claude\CLAUDE.md` is a bootstrap redirect that instructs Claude to read this file; it is not a copy and does not need to be synced after gate changes.
- Claude currently has a temporary Claude-only L2 Bias overlay in `adapters/claude/CLAUDE.md`: borderline L1/L2 tasks prefer L2 while Claude has more available usage budget. This does not affect Codex, shared skill specs, or L3 write boundaries.
- `adapters/claude/external-config.md`: Claude Code external setup snapshot for migration or reinstall.
- `adapters/claude/skills/`: Claude-specific skill sources. These are separate from Codex skills.
- `C:\Users\btf\.claude\skills`: Claude Code skill discovery root; active skills are junctions to `adapters/claude/skills`.
- `ai_memoryos`: shared restricted MCP server, configured in Claude user scope and allowed only to read/search Memory OS and write pending proposals.
