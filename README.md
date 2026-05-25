# AI Memory OS

AI Memory OS 是一个跨模型、跨项目的工程记忆系统。它以 Markdown + Git 为事实源，通过 Codex Skills、受限 MCP、Obsidian dashboard 和 proposal 审核流程，让工程经验可以长期沉淀、审核、回滚和复用。

## 核心原则

- Codex 每个输入先读取轻量 `adapters/codex/gate.md`；L0/L1 不读取 Memory OS 正文，L2/L3 才按预算读取或写入。
- 新经验默认只写入 `proposals/pending/`，不直接污染正式规则。
- 项目本地事实优先于全局记忆。
- 敏感信息、token、客户数据、生产日志原文不进入仓库。
- Obsidian 用于浏览、审核、dashboard 和 Git 同步；Codex/MCP 用于受控读写。

## 目录入口

- [[docs/usage-manual]]：使用手册。
- [[dashboard/home]]：Obsidian 首页。
- [[STATUS]]：当前完成度和剩余工作。
- [[GOVERNANCE]]：治理和晋升规则。
- [[INSTALL]]：安装与接入说明。
- [[REMOTE]]：远程仓库与推送策略。

## 架构

```text
AI-MemoryOS Markdown + Git = 唯一事实源
Codex Skills = 高频任务工作流
MCP = 受限自动化工具层
Obsidian = 人工审核、dashboard、浏览前台
```

## 使用手册

- [[docs/usage-manual]]
- [Claude Code 接入恢复说明](adapters/claude/external-config.md)
