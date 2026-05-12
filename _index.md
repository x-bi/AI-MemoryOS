# Memory OS Index 记忆索引

## Read Budget 读取预算

默认不要读取本仓库。只有在用户明确要求以下模式时才读取：

- 复杂工程任务：先读本文件，最多再读 3 个直接相关页面。
- 记忆复盘：读本文件和少量相关 rules / workflows / domains / router 页面。
- 维护模式：可以审计、整理、晋升 proposal，但仍需保留变更记录。

普通复杂任务的 MemoryOS 读取预算默认不超过 2k tokens；该预算只统计 MemoryOS 自身内容，不包含业务项目代码、diff、报错日志、接口文档、终端输出、当前对话或 Codex 系统上下文。维护、weekly audit、proposal 晋升、skill 晋升等任务可临时放宽到 5k-8k tokens，但必须说明读取范围。

## Routing 路由

1. 先判断 task_type：explain / debug / implement / review / architecture / retrospective / maintenance。
2. 再判断 domain：frontend / testing / backend / scripting / devops / security。
3. 再选择 workflow / skill / markdown。
4. 低置信度时先问一个关键问题，不扩大读取。

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

## Domain Entry 领域入口

- 前端：`domains/frontend/README.md`
- 测试：`domains/testing/README.md`
- 后端：`domains/backend/README.md`
- 脚本：`domains/scripting/README.md`
- DevOps：`domains/devops/README.md`
- 安全：`domains/security/README.md`

## Adapter Files 适配器文件

- `adapters/codex/AGENTS.md`：Codex 接入说明。
- `adapters/codex/skills/`：Codex 专用 skills 源目录。
- `adapters/codex/config/recommended-config.toml`：全局 config 合并建议。
- `adapters/generic/SYSTEM.md`：通用模型接入说明。
- `adapters/mcp/`：受限 MCP 自动化入口，只允许读库和写 pending proposal。
