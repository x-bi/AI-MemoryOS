# AI Memory OS

AI Memory OS 是一个跨模型、跨项目的工程记忆系统。它以 Markdown + Git 为唯一事实源，通过分层 Gate、受限 MCP、Skills 工作流、Obsidian dashboard 和 proposal 审核流程，让工程经验可以长期沉淀、审核、回滚和复用。当前已接入 Codex Desktop 与 Claude Code 两个模型适配器。

## 核心原则

- **Markdown + Git = 唯一事实源**：所有记忆以 Markdown 文件存储，Git 版本控制，可审计可回滚。
- **分层 Gate**：每个输入先读轻量 Gate 判定 L0-L3，避免低级任务消耗记忆读取预算。
- **写入隔离**：新经验默认只写入 `proposals/pending/`，不直接修改正式规则；人工审核后才可晋升。
- **项目事实优先**：项目本地 CLAUDE.md / AGENTS.md / README / 代码事实优先于全局记忆。
- **安全边界**：token、密码、PII、生产日志原文、客户私有代码不进入仓库。
- **Obsidian 前台**：Obsidian 用于浏览、审核、dashboard 和 Git 同步；Codex / Claude / MCP 用于受控读写。

## 记忆分层 (L0-L3)

| 层级 | 触发场景 | Memory OS 读取 | 写入 |
|------|---------|---------------|------|
| L0 | 纯解释、问答、单点 debug | 不读取 | 不写入 |
| L1 | 轻量 workflow/skill、review 自检、路由检查 | 不读取 | 不写入 |
| L2 | 架构、跨模块重构、CI/CD、安全/权限、发布流程 | 读 `_index.md` + 最多 3 个相关页 | 不写入 |
| L3 | 用户明确要求捕获/复盘/更新 Memory OS | 按需读取 | 写入 `proposals/pending/` |

L2 读取预算默认不超过 2k tokens；维护/审计任务可临时放宽到 5k-8k tokens。Claude 当前启用临时 L2 Bias：borderline 任务偏好 L2（因可用预算更充足），不影响 Codex 与 L3 写入边界。

## 目录结构

```
AI-MemoryOS/
├── adapters/            # 多模型适配器
│   ├── gate-source/     #   Codex / Claude gate/bootstrap 共享源与 overlay
│   ├── codex/           #   Codex Desktop 适配（gate.md + skills + external-config.md）
│   ├── claude/          #   Claude Code 适配（CLAUDE.md + skills + external-config.md）
│   ├── mcp/             #   受限 MCP server，只允许读库 + 写 pending proposal
│   ├── generic/         #   通用模型适配
│   └── cursor/          #   Cursor 适配（待完善）
├── core/                # 核心规则（memory / safety）
├── router/              # 路由策略（intent-map / domain-map / skill-map）
├── skills/              # 共享 skill 定义
│   ├── registry.json    #   skill 注册表（adapter 外壳的生成源）
│   └── <skill>/SKILL_SPEC.md  # 模型无关的 skill 核心逻辑
├── workflows/           # 可复用执行流程
├── domains/             # 领域知识包（frontend / testing / backend / scripting / devops / security）
├── proposals/           # 经验提案
│   ├── pending/         #   唯一默认写入入口
│   ├── accepted/        #   已晋升（需审核原因）
│   ├── rejected/        #   已拒绝（需审核原因）
│   └── future-directions/  # 长期方向说明（非 pending 队列）
├── anti-patterns/       # 反模式记录
├── stacks/              # 技术栈特定规则
├── prompts/             # 提示词模板
├── templates/           # 文档模板
├── evals/               # 评估用例
├── logs/                # 审计与变更记录
├── wiki/                # 长期知识沉淀
├── dashboard/           # Obsidian dashboard（home.md）
├── tools/               # 维护脚本
├── private/             # 本地私有内容（CodeGraph 工作树等，不进 Git）
├── private.example/     # private 示例骨架
├── integrations/        # 第三方集成（含 Obsidian）
├── _index.md            # 记忆索引（L2 入口）
├── AGENTS.md            # 仓库级 Codex 规则
├── GOVERNANCE.md        # 治理与晋升规则
├── STATUS.md            # 当前状态
└── ROADMAP.md           # 路线图
```

## 维护脚本 (tools/)

| 脚本 | 用途 |
|------|------|
| `sync-skills.ps1` | 按 `skills/registry.json` 同步 SKILL_SPEC 到各 adapter 外壳 |
| `sync-adapter-gates.ps1` | 按 `adapters/gate-source/**` 和 adapter templates 同步 Codex / Claude gate/bootstrap |
| `validate-memory-os.ps1` | 仓库完整性校验 |
| `validate-obsidian.ps1` | Obsidian 配置校验 |
| `new-proposal.ps1` | 新建 proposal 模板 |
| `codegraph-project.ps1` | CodeGraph 项目管理 |
| `codegraph-wrapper.ps1` | CodeGraph 命令包装 |

## 架构

```text
AI-MemoryOS Markdown + Git           = 唯一事实源
adapters/{codex,claude,mcp,...}      = 多模型接入层
adapters/gate-source/**              = Codex / Claude gate/bootstrap 维护源
skills/<skill>/SKILL_SPEC.md         = 模型无关 skill 核心逻辑
adapters/{codex,claude}/{bootstrap,gate} = 由 sync-adapter-gates.ps1 生成的运行入口
adapters/<model>/skills/*/SKILL.md   = 由 sync-skills.ps1 生成的 adapter 外壳
Obsidian + dashboard/                = 人工审核、浏览、dashboard 前台
proposals/pending/                   = 默认写入入口，人工审核后才晋升
```

## 适配器接入

### Codex Desktop

- 全局 `C:\Users\btf\.codex\AGENTS.md` 仅保留 bootstrap，引导读取 `adapters/codex/bootstrap.md`。
- `adapters/codex/bootstrap.md` 和 `adapters/codex/gate.md` 是生成目标；维护源在 `adapters/gate-source/**` 和 `adapters/codex/templates/`。
- Skill 源目录 `adapters/codex/skills`，通过 junction 映射到 `C:\Users\btf\.codex\skills`。
- 可选 MCP：`adapters/mcp/server/`。
- 换机/重装步骤见 `adapters/codex/external-config.md`。

### Claude Code

- 用户级 `C:\Users\btf\.claude\CLAUDE.md` 引导读取 `adapters/claude/bootstrap.md`。
- `adapters/claude/bootstrap.md` 和 `adapters/claude/CLAUDE.md` 是生成目标；维护源在 `adapters/gate-source/**` 和 `adapters/claude/templates/`。
- Claude Gate 含临时 L2 Bias（仅 Claude 适用，不同步到 Codex）。
- Skill 源目录 `adapters/claude/skills`，通过 junction 映射到 `C:\Users\btf\.claude\skills`。
- `ai_memoryos` MCP：受限读取/搜索 Memory OS，只写 `proposals/pending/`。
- 换机/重装步骤见 `adapters/claude/external-config.md`。

> Claude 和 Codex 的 skill 源文件分开维护，共享 `skills/<skill>/SKILL_SPEC.md` 作为模型无关核心逻辑，通过 `tools/sync-skills.ps1` 生成各 adapter 外壳。
> Claude 和 Codex 的 gate/bootstrap 共享 `adapters/gate-source/**`，通过 `tools/sync-adapter-gates.ps1` 生成各 adapter 运行入口；不要手写生成目标。

## Active Skills

| Skill | 用途 |
|-------|------|
| `memory-curator` | 捕获工程经验、生成 pending proposal、记忆复盘 |
| `routing-auditor` | 审计路由、修正误分类、更新路由启发式 |
| `bugfix-with-regression-test` | 根因分析 + 回归保护的安全 bugfix |
| `frontend-component-review` | 前端组件、UI 交互、表单流程 review |
| `pr-review` | PR / diff / commit review，检查 bug 和回归风险 |
| `vue-change-self-check` | Vue / uni-app 变更自检，输出编号风险项 |
| `git-ops-guide` | Git 命令指导（不执行命令） |

## 治理流程

1. **写入**：新经验只进 `proposals/pending/`，不直接修改正式规则。
2. **晋升条件**：跨项目重复出现 / 减少明确重复错误 / 改善 review/debug 稳定性 / 降低路由误判。
3. **拒绝条件**：仅适用单项目 / 无真实案例 / 过度抽象 / 含敏感信息 / 与项目事实冲突。
4. **审计节奏**：不强制周审/月审。改为按需 + 触发条件审计（pending 堆积、重复路由误判、skill 误触发、冲突/过期、用户主动要求等），详见 `GOVERNANCE.md`。
5. **记录**：每次审计生成 `logs/audits/YYYY-MM-DD.md`。

## CodeGraph 可选集成

CodeGraph 是 OS 管理的代码图谱加速层（基于 `@colbymchenry/codegraph`）：

- 管理脚本：`tools/codegraph-project.ps1`、`tools/codegraph-wrapper.ps1`
- 图谱和私有 worktree 存放在 `private/codegraph/`，不在项目根目录创建 `.codegraph`
- 全局开关默认关闭，按项目注册启用
- 共享 module slot 名必须为业务特征名（如 `jd-brocade-gift`），不用 `feature`/`hot`/`module` 等通用名
- 不可用时回退到 `rg` 和直接源码读取

## Obsidian

- Dashboard 首页：`dashboard/home.md`
- 已配置插件：Obsidian Git、QuickAdd、Templater、Dataview、Advanced URI
- Obsidian Git 启用自动推送，同步已确认的本地 vault 变更
- 详细配置见 `integrations/obsidian.md`

## 远程仓库

- Origin：`https://github.com/x-bi/AI-MemoryOS.git`
- 分支：`main`
- 本仓库 Git 身份：`x-bi <924992512@qq.com>`
- 推送流程：本地变更 → `validate-memory-os.ps1` → `validate-obsidian.ps1` → review → commit → push
- 推送前做本地敏感信息扫描，无输出才推送

## 当前状态

详见 [STATUS.md](STATUS.md)。关键已完成项：

- 独立仓库已推送到个人 GitHub
- Codex Desktop + Claude Code 双 adapter 接入完成
- 7 个 active skills 由 SKILL_SPEC + registry.json 统一管理
- 受限 MCP 已接入 Codex / Claude
- Obsidian dashboard + 自动化已配置
- CodeGraph 可选集成已就绪
- L0-L3 分层路由策略已建立

## 入口索引

| 文档 | 说明 |
|------|------|
| [STATUS.md](STATUS.md) | 当前完成度和剩余工作 |
| [ROADMAP.md](ROADMAP.md) | 7 / 30 / 90 天推进路线 |
| [GOVERNANCE.md](GOVERNANCE.md) | 治理、晋升和审计规则 |
| [_index.md](_index.md) | 记忆索引（L2 入口） |
| [dashboard/home.md](dashboard/home.md) | Obsidian 首页 |
| [integrations/obsidian.md](integrations/obsidian.md) | Obsidian 集成说明 |
| [adapters/codex/external-config.md](adapters/codex/external-config.md) | Codex 接入恢复说明 |
| [adapters/claude/external-config.md](adapters/claude/external-config.md) | Claude 接入恢复说明 |
