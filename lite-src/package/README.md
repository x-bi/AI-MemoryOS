# AI Memory OS Lite

这是 AI Memory OS 的轻量使用包，用来把 Codex 或 Claude 接到本地的 Lite 版规则、路由、工作流和 skills。

当前版本只支持 Windows PowerShell。

## 使用步骤

1. 打开 `memoryos.config.json`。
2. 至少配置一个工具：Codex 或 Claude。
3. 运行安装：

```powershell
.\install.ps1
```

4. 检查安装是否正确：

```powershell
.\install.ps1 -Check
```

## 必填配置

Codex 至少填写：

- `codex.enabled`: `true`
- `codex.user_agents`: 你的 `AGENTS.md` 路径
- `codex.skills_dir`: 你的 Codex skills 目录

Claude 至少填写：

- `claude.enabled`: `true`
- `claude.user_claude`: 你的 `CLAUDE.md` 路径
- `claude.skills_dir`: 你的 Claude skills 目录

如果要安装 Claude hook，再填写：

- `claude.install_hook`: `true`
- `claude.settings_json`: 你的 Claude `settings.json` 路径

更完整的配置示例见 `INSTALL.md`。

## 安装会修改什么

安装脚本只管理带 `AI-MEMORYOS-LITE` 标记的内容：

- 在 `AGENTS.md` 或 `CLAUDE.md` 顶部写入 Lite 托管块。
- 可选：在 Claude `settings.json` 中加入 Lite hook。
- 在 skills 目录中创建 Lite skill junction。
- 写入 `.memoryos/install-state.json` 记录安装状态。

已有用户内容会保留。写入前会创建 `.bak.<timestamp>` 备份。

## 卸载

```powershell
.\install.ps1 -Uninstall
```

卸载只移除 Lite 托管块、Lite hook 和 Lite 创建的 skill junction，不删除你的原文件、备份、配置文件或 `.memoryos/`。

## 注意

如果移动了 Lite 包目录，先更新 `memoryos.config.json`，再运行：

```powershell
.\install.ps1 -Check
.\install.ps1
```

安装脚本只能检查文件和路径配置，不能绕过 Codex 或 Claude 的运行时沙盒限制。如果模型读不到 Lite 文件，需要把 Lite 包放到工具可访问的位置，或按对应工具增加可读目录。
