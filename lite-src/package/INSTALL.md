# Install AI Memory OS Lite

## Codex Only

```json
{
  "memoryos": {
    "root": ".",
    "language": "zh-CN"
  },
  "codex": {
    "enabled": true,
    "user_agents": "C:\\Users\\you\\.codex\\AGENTS.md",
    "skills_dir": "C:\\Users\\you\\.codex\\skills",
    "mode": "append"
  },
  "claude": {
    "enabled": false,
    "user_claude": "",
    "settings_json": "",
    "skills_dir": "",
    "install_hook": false,
    "mode": "append"
  }
}
```

## Claude Only

```json
{
  "memoryos": {
    "root": ".",
    "language": "zh-CN"
  },
  "codex": {
    "enabled": false,
    "user_agents": "",
    "skills_dir": "",
    "mode": "append"
  },
  "claude": {
    "enabled": true,
    "user_claude": "C:\\Users\\you\\.claude\\CLAUDE.md",
    "settings_json": "C:\\Users\\you\\.claude\\settings.json",
    "skills_dir": "C:\\Users\\you\\.claude\\skills",
    "install_hook": true,
    "mode": "append"
  }
}
```

## Commands

```powershell
.\install.ps1
.\install.ps1 -Check
.\install.ps1 -Uninstall
```

`-Check` 只检查配置、生成目标、入口托管块、hook、skill junction 和 manifest，不修改文件。

包目录移动后，先更新 `memoryos.config.json`，再运行：

```powershell
.\install.ps1 -Check
.\install.ps1
```

这样会按当前配置更新托管块、hook command、skill junction 和 manifest，不需要单独 repair 脚本。
