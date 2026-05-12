# Audit Log 审计日志

## 2026-05-11 初始审计

- Active Codex skills 控制在 4 个。
- Candidate skills 保留在 `skills/`，不进入 Codex 自动发现目录。
- 初始化 pending / accepted / rejected proposal 目录。
- Obsidian dashboard、QuickAdd、Templater、Dataview、Obsidian Git 已配置。
- MCP adapter 已限制为读库和写 pending proposal。

## 审计重点

- pending proposal 是否堆积。
- 是否有重复、冲突、过期内容。
- 是否有项目私有内容误入全局记忆。
- router 是否臃肿。
- skill description 是否重叠或误触发。
