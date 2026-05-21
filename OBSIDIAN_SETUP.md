# Obsidian Setup Report 配置报告

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
- Obsidian Git：已配置本地自动备份和自动 push，暂不开自动 pull

## Git 配置

已启用：

```text
Git / plugin id: obsidian-git
```

```text
Vault backup interval in minutes: 10 或 30
Auto Backup after file change: on
Pull updates on startup: off
Push on backup: on
Auto push interval: 60
Manual commit message: memory: manual vault sync {{date}}
Auto commit message: memory: obsidian auto backup {{date}}
```

当前本机 Git 用户信息已存在，可以 commit。

## 已清理

以下插件已不在当前 vault 启用列表中：

```text
GitHobs / plugin id: githobs
```

它是 GitHub issue editor，不是 vault 自动备份插件。当前只保留 `obsidian-git` 作为 Git 自动备份插件。

## 使用方式

按 `Ctrl + P`：

- `QuickAdd: Run QuickAdd`
- 选择 `New Pending Proposal` / `New Router Correction` / `New Weekly Audit`

Dashboard 入口：

- [[dashboard/home]]
- [[dashboard/pending-proposals]]
- [[dashboard/accepted-proposals]]
- [[dashboard/rejected-proposals]]
- [[dashboard/skills]]
- [[dashboard/router-evals]]
- [[dashboard/weekly-audit]]

## 验证命令

在 PowerShell 中运行：

```powershell
& C:\Users\btf\AI-MemoryOS\tools\validate-obsidian.ps1
```

通过后会输出：

```text
Obsidian validation passed.
```

## GitHub 远程

当前仓库 remote 已设置为个人 GitHub：

```text
https://github.com/x-bi/AI-MemoryOS.git
```

本仓库 local Git 身份：

```text
x-bi <924992512@qq.com>
```

Obsidian Git 当前已启用自动 push。建议先手动执行一次 `git push`，确认凭据可用；之后由 Obsidian Git 自动提交并推送。
