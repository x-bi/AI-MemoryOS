[CmdletBinding(SupportsShouldProcess=$true)]
param(
  [string]$Root = "C:\Users\btf\AI-MemoryOS"
)

$ErrorActionPreference = "Stop"
Import-Module (Join-Path $PSScriptRoot "_shared.psm1") -Force
$startedAt = Get-Date
Test-MemoryOsRepo -Root $Root | Out-Null
$rootPath = Resolve-MemoryOsRoot -Root $Root
$actions = New-Object System.Collections.Generic.List[object]

$autoRunsPath = Join-Path $rootPath "dashboard\auto-runs.md"
$autoRunsContent = Expand-AutoTemplate -Root $rootPath -RelativePath "templates\auto-runs-dashboard.md" -Tokens @{}

if ($WhatIfPreference) {
  $actions.Add((New-AutoAction -Tier "A" -Action "sync-dashboard" -Target "dashboard/auto-runs.md" -Status "whatif"))
} else {
  $utf8 = New-Object System.Text.UTF8Encoding($false)
  $autoRunsContent = ($autoRunsContent -replace "`r`n", "`n").TrimEnd("`n") + "`n"
  [System.IO.File]::WriteAllText($autoRunsPath, $autoRunsContent, $utf8)
  $actions.Add((New-AutoAction -Tier "A" -Action "sync-dashboard" -Target "dashboard/auto-runs.md" -Status "updated"))
}

$homePath = Join-Path $rootPath "dashboard\home.md"
$homeText = Get-Content -LiteralPath $homePath -Raw -Encoding UTF8
if ($homeText -notmatch '\[\[dashboard/auto-runs\]\]') {
  $homeLink = (Expand-AutoTemplate -Root $rootPath -RelativePath "templates\auto-dashboard-home-link.md" -Tokens @{}).Trim()
  $newHomeText = $homeText -replace '(- \[\[dashboard/weekly-audit\]\].*\r?\n)', "`$1$homeLink`n"
  $newHomeText = $newHomeText -replace "`r`n", "`n"
  if ($WhatIfPreference) {
    $actions.Add((New-AutoAction -Tier "A" -Action "sync-dashboard-link" -Target "dashboard/home.md" -Status "whatif"))
  } else {
    $utf8 = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($homePath, $newHomeText, $utf8)
    $actions.Add((New-AutoAction -Tier "A" -Action "sync-dashboard-link" -Target "dashboard/home.md" -Status "updated"))
  }
}

Write-AutoRunLog -Root $rootPath -ScriptName "optimize-dashboard-sync" -Actions $actions -Parameters @{ phase = "optimize"; root = $rootPath } -StartedAt $startedAt -WhatIf:$WhatIfPreference | Out-Null
Write-Host "optimize-dashboard-sync actions: $($actions.Count)"
