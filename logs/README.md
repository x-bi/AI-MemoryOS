# Logs 日志说明

这个目录记录 Memory OS 的变更历史和审计记录，方便回溯“为什么改、改了哪里、是否验证”。

## 文件说明

- `memory-changelog.md`：长期记忆内容的新增、合并、废弃记录。
- `skill-changelog.md`：Skill 的新增、修改、暴露、下线记录。
- `router-changelog.md`：路由规则和 eval 样例的变更记录。
- `audit-log.md`：周/月审计记录。
- `audits/`：每次 weekly audit 的具体记录。

## 记录原则

- 用中文说明变更目的和影响。
- 保留英文术语、文件名、命令、字段名。
- 不记录敏感信息、token、客户数据、生产日志原文。
- 每条重要变更尽量关联 proposal 或 commit。
