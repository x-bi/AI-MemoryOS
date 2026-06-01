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

单独 dry run 发散型机会发现：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\auto\run-all.ps1 -Phase opportunity -ModelProfile claude -WhatIf
```

只生成机会计划和报告，不自动落地：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\auto\model-opportunity-radar.ps1 -Scope content-quality -ModelProfile claude -PlanOnly
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

完整 cycle 会在 `auto/*` 分支上执行确定性审计、语义审计、迭代、优化、repair plan，并追加 opportunity radar。Opportunity radar 会广泛发现优化机会，但只自动落地 micro/small A/B-tier 的安全路径改动；medium/large 或 C-tier 机会只报告、生成 proposal 或审批单。

完整 cycle 真实运行，并 push `auto/*` 分支：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\auto\start-cycle.ps1 -Scope content-quality -ModelProfile claude -Push
```

不在仓库根目录启动时，用绝对路径：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File C:\Users\btf\AI-MemoryOS\tools\auto\start-cycle.ps1 -Root C:\Users\btf\AI-MemoryOS -Scope content-quality -ModelProfile claude
```
