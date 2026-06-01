[CmdletBinding(SupportsShouldProcess=$true)]
param(
  [string]$Root = "C:\Users\btf\AI-MemoryOS",
  [string]$Branch = "",
  [switch]$ApproveAOnly
)

$ErrorActionPreference = "Stop"
Import-Module (Join-Path $PSScriptRoot "_shared.psm1") -Force
$startedAt = Get-Date
Test-MemoryOsRepo -Root $Root | Out-Null
$rootPath = Resolve-MemoryOsRoot -Root $Root
$actions = New-Object System.Collections.Generic.List[object]
$logDir = Join-Path $rootPath "logs\auto-runs"
$pendingDir = Join-Path $rootPath "proposals\pending"

$runCount = 0
if (Test-Path -LiteralPath $logDir) {
  $runCount = @(Get-ChildItem -LiteralPath $logDir -Filter "*.md" -File -Recurse |
    Where-Object { $_.Name -ne "000-overview.md" -and $_.FullName -notmatch '\\approval-sheets\\' -and $_.FullName -notmatch '\\\.locks\\' }).Count
}

$pendingCount = 0
if (Test-Path -LiteralPath $pendingDir) {
  $pendingCount = @(Get-ChildItem -LiteralPath $pendingDir -Filter "*.md" -File -Recurse).Count
}

$currentBranch = if ($Branch) { $Branch } else { Get-CurrentGitBranch -Root $rootPath }
$commitList = ""
try {
  if (-not [string]::IsNullOrWhiteSpace($currentBranch)) {
    $commitList = (& git -C $rootPath log --oneline -n 10 $currentBranch 2>$null | Out-String).Trim()
  }
} catch {
  $commitList = ""
}
$suggested = "Review logs in dashboard/auto-runs.md; inspect pending proposals; merge or cherry-pick manually only after validation."

$actions.Add((New-AutoAction -Tier "A" -Action "review-cycle" -Target "auto-run-logs:$runCount" -Status ($(if ($WhatIfPreference) { "whatif" } else { "reviewed" }))))
$actions.Add((New-AutoAction -Tier "B" -Action "review-cycle" -Target "pending-proposals:$pendingCount" -Status "pending human review"))
if (-not [string]::IsNullOrWhiteSpace($commitList)) {
  $actions.Add((New-AutoAction -Tier "A" -Action "review-cycle" -Target "commits:$currentBranch" -Status "summarized"))
}
if ($ApproveAOnly) {
  $actions.Add((New-AutoAction -Tier "A" -Action "review-cycle" -Target ($(if ($Branch) { $Branch } else { "current" })) -Status "a-only-approved"))
}

Write-AutoRunLog -Root $rootPath -ScriptName "review-cycle" -Actions $actions -Parameters @{ phase = "review"; root = $rootPath; branch = $currentBranch; approve_a_only = $ApproveAOnly.IsPresent; suggested_commands = $suggested; commits = $commitList } -Branch $currentBranch -StartedAt $startedAt -WhatIf:$WhatIfPreference | Out-Null
Write-Host "review-cycle actions: $($actions.Count)"
