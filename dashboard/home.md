# AI Memory OS Home 首页

这是 Obsidian 中的 Memory OS 总入口。

## Daily Entry 日常入口

- [[dashboard/pending-proposals]]：查看待审核经验。
- [[dashboard/future-directions]]：查看重大方向说明。
- [[dashboard/weekly-audit]]：每周审计入口。
- [[dashboard/skills]]：查看技能状态。
- [[dashboard/router-evals]]：查看路由测试样例。

## Core 核心文档

- [[STATUS]]：当前完成度。
- [[ROADMAP]]：路线图。
- [[GOVERNANCE]]：治理规则。
- [[integrations/obsidian]]：Obsidian 集成说明。

## Workflows 工作流

- [[workflows/memory-retrospective]]：记忆复盘。
- [[workflows/proposal-promotion]]：proposal 晋升。
- [[workflows/weekly-audit]]：每周审计。

## Pending Queue 待审核队列

```dataview
TABLE file.mtime AS updated, status, source, destination
FROM "proposals/pending"
SORT file.mtime DESC
```

## Future Directions 重大方向

```dataview
TABLE file.mtime AS updated, type, status
FROM "proposals/future-directions"
SORT file.mtime DESC
```
