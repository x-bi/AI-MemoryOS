# Obsidian Integration

Obsidian 适合作为人类侧前台：浏览、双链、审核、整理和 dashboard。

## Recommended Use

- 打开 AI Memory OS 仓库根目录作为 vault。
- 用 `dashboard/home.md` 作为首页入口。
- 用 `proposals/` 做审核面板。
- 用 `templates/weekly-audit.md` 做周审计。
- 用 Obsidian Git 同步已确认的本地 vault 变更。

## Current Plugin Shape

- Templater：模板目录为 `templates`。
- QuickAdd：用于创建 pending proposal、router correction 和 weekly audit。
- Dataview：用于 dashboard 查询；JS 查询保持关闭。
- Advanced URI：保持默认配置即可。
- Obsidian Git：用于本地自动备份和可选自动 push，不作为 Memory OS 路由器。

## Dashboard Entries

- `dashboard/home.md`
- `dashboard/pending-proposals.md`
- `dashboard/future-directions.md`
- `dashboard/weekly-audit.md`
- `dashboard/skills.md`
- `dashboard/router-evals.md`

## Validation

```powershell
tools/validate-obsidian.ps1
```

## Boundaries

- 不把 Obsidian 当自动路由器。
- 不把 raw 内容自动晋升为正式规则。
- 不在仓库文档里保存本机 Git 身份、账号、token、cookie 或其他敏感配置。
- 具体 Git remote 和本机凭据属于本地环境状态，不作为 Memory OS 正式规则。
