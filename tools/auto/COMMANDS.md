# Auto Commands

AI Memory OS 自动化的终端命令速查。

先进入仓库根目录：

```powershell
cd C:\Users\btf\AI-MemoryOS
```

## 快捷入口

默认 dry run，会自动加 `-WhatIf`：

```powershell
.\auto.ps1
```

真实完整 cycle，不 push：

```powershell
.\auto.ps1 -Run
```

真实完整 cycle，并 push `auto/*` 分支：

```powershell
.\auto.ps1 -Run -Push
```

切换范围或模型：

```powershell
.\auto.ps1 -Scope proposal-review -ModelProfile claude
```

运行全量维护范围：

```powershell
.\auto.ps1 -Scope full
```

## 原始命令

完整 cycle dry run：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\auto\start-cycle.ps1 -Scope content-quality -ModelProfile claude -WhatIf
```

完整 cycle 真实运行，不 push：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\auto\start-cycle.ps1 -Scope content-quality -ModelProfile claude
```

完整 cycle 真实运行，并 push `auto/*` 分支：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\auto\start-cycle.ps1 -Scope content-quality -ModelProfile claude -Push
```

不在仓库根目录启动时，用绝对路径：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File C:\Users\btf\AI-MemoryOS\tools\auto\start-cycle.ps1 -Root C:\Users\btf\AI-MemoryOS -Scope content-quality -ModelProfile claude
```
