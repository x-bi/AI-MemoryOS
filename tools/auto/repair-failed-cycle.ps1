[CmdletBinding(SupportsShouldProcess=$true)]
param(
  [string]$Root = "C:\Users\btf\AI-MemoryOS",
  [string]$Branch = "",
  [int]$MaxRepairAttempts = 1,
  [ValidateSet("frontmatter", "encoding", "runlog", "proposal-stem", "dashboard", "validate-missing-file", "all")][string]$RepairScope = "all"
)

$ErrorActionPreference = "Stop"
Import-Module (Join-Path $PSScriptRoot "_shared.psm1") -Force
$startedAt = Get-Date
Test-MemoryOsRepo -Root $Root | Out-Null
$rootPath = Resolve-MemoryOsRoot -Root $Root
$actions = New-Object System.Collections.Generic.List[object]
$logDir = Join-Path $rootPath "logs\auto-runs"

$failedLogs = @()
if (Test-Path -LiteralPath $logDir) {
  $failedLogs = @(Get-ChildItem -LiteralPath $logDir -Filter "*.md" -File | Where-Object {
      $text = Get-Content -LiteralPath $_.FullName -Raw -Encoding UTF8
      $text -match '(?m)^status:\s*"?(failed|partial)"?'
    })
}

if ($failedLogs.Count -eq 0) {
  $actions.Add((New-AutoAction -Tier "A" -Action "repair-cycle" -Target ($(if ($Branch) { $Branch } else { "current" })) -Status "skipped no candidates"))
} else {
  foreach ($log in $failedLogs | Select-Object -First $MaxRepairAttempts) {
    $relative = Get-MemoryOsRelativePath -Root $rootPath -Path $log.FullName
    $text = Get-Content -LiteralPath $log.FullName -Raw -Encoding UTF8
    $newText = $text
    foreach ($field in @("run_id", "script", "started_at", "status", "repair_attempts")) {
      if ($newText -notmatch "(?m)^${field}:") {
        $newText = $newText -replace '(?s)^---\r?\n', "---`n${field}: `"`"`n"
      }
    }
    $newText = $newText -replace "`r`n", "`n"
    if ($RepairScope -in @("frontmatter", "runlog", "all") -and $newText -ne $text) {
      if ($WhatIfPreference) {
        $actions.Add((New-AutoAction -Tier "A" -Action "repair-cycle" -Target $relative -Status "whatif"))
      } else {
        $utf8 = New-Object System.Text.UTF8Encoding($false)
        [System.IO.File]::WriteAllText($log.FullName, $newText, $utf8)
        $actions.Add((New-AutoAction -Tier "A" -Action "repair-cycle" -Target $relative -Status "updated"))
      }
    } else {
      $actions.Add((New-AutoAction -Tier "A" -Action "repair-cycle" -Target $relative -Status "review-required"))
    }
  }
}

Write-AutoRunLog -Root $rootPath -ScriptName "repair-failed-cycle" -Actions $actions -Parameters @{ phase = "repair"; root = $rootPath; branch = $Branch; max_repair_attempts = $MaxRepairAttempts; repair_scope = $RepairScope } -RepairAttempts $MaxRepairAttempts -StartedAt $startedAt -WhatIf:$WhatIfPreference | Out-Null
Write-Host "repair-failed-cycle actions: $($actions.Count)"
