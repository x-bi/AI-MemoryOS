# Obsidian Setup Report

## 当前已配置

- Vault：`C:\Users\btf\AI-MemoryOS`
- Templater：模板目录已设为 `templates`
- QuickAdd：已配置 3 个 Template Choice
  - New Pending Proposal -> `templates/proposal.md` -> `proposals/pending/`
  - New Router Correction -> `templates/router-correction-proposal.md` -> `proposals/pending/`
  - New Weekly Audit -> `templates/weekly-audit.md` -> `logs/audits/`
- Dataview：已写入安全基线配置，JS 查询关闭
- Dashboard：已创建 `dashboard/` 文件
- Advanced URI：已安装，默认配置即可
- Obsidian Git：已配置本地自动备份，暂不开 push / pull

## Git 配置

已启用：

```text
Git / plugin id: obsidian-git
```

```text
Vault backup interval in minutes: 10 或 30
Auto Backup after file change: on
Pull updates on startup: off
Push on backup: off
Commit message: memory: auto backup {{date}}
```

当前本机 Git 用户信息已存在，可以 commit。

## 可选清理

你仍然启用了：

```text
GitHobs / plugin id: githobs
```

它是 GitHub issue editor，不是 vault 自动备份插件。如果你不用它，建议在 Community Plugins 中禁用，减少无关 GitHub token 配置面。

## 使用方式

按 `Ctrl + P`：

- `QuickAdd: Run QuickAdd`
- 选择 `New Pending Proposal` / `New Router Correction` / `New Weekly Audit`

Dashboard 入口：

- [[dashboard/pending-proposals]]
- [[dashboard/accepted-proposals]]
- [[dashboard/rejected-proposals]]
- [[dashboard/skills]]
- [[dashboard/router-evals]]
- [[dashboard/weekly-audit]]
