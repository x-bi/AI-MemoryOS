[CmdletBinding(SupportsShouldProcess=$true)]
param(
  [string]$Root = "C:\Users\btf\AI-MemoryOS",
  [ValidateSet("content-quality", "router-cleanup", "skill-health", "proposal-review", "full")][string]$Scope = "full",
  [string]$ModelProfile = "",
  [switch]$AuditOnly,
  [int]$MaxRepairAttempts = 1,
  [switch]$Push
)

$ErrorActionPreference = "Stop"
Import-Module (Join-Path $PSScriptRoot "_shared.psm1") -Force
$startedAt = Get-Date
Test-MemoryOsRepo -Root $Root | Out-Null
$rootPath = Resolve-MemoryOsRoot -Root $Root
$modelProfileObj = Get-ModelProfile -Root $rootPath -Name $ModelProfile
$outputContext = Enter-AutoRunOutputContext -ScriptName "start-cycle" -Detail $Scope
$actions = New-Object System.Collections.Generic.List[object]
$scripts = Get-AutoScopeScripts -Scope $Scope
$branchName = "auto/$(Get-Date -Format 'yyyyMMdd-HHmmss')-$Scope"
$lock = $null

if ($Push -and $WhatIfPreference) {
  Write-Host "WhatIf: push requested but no git command will run."
}

foreach ($script in $scripts) {
  $actions.Add((New-AutoAction -Tier "A" -Action "cycle-plan" -Target $script -Status ($(if ($WhatIfPreference) { "whatif" } else { "ready" }))))
}

if ($WhatIfPreference) {
  New-AutoCycleLock -Root $rootPath -Scope $Scope -Branch $branchName -WhatIf | Out-Null
  Write-Host "WhatIf: would start cycle scope=$Scope model=$($modelProfileObj.name) branch=$branchName audit_only=$($AuditOnly.IsPresent) max_repair_attempts=$MaxRepairAttempts push=$($Push.IsPresent)"
  Write-AutoRunLog -Root $rootPath -ScriptName "start-cycle" -Actions $actions -Parameters @{ phase = "cycle"; root = $rootPath; scope = $Scope; model_profile = $modelProfileObj.name; audit_only = $AuditOnly.IsPresent; max_repair_attempts = $MaxRepairAttempts; push = $Push.IsPresent; branch = $branchName } -StartedAt $startedAt -ModelProfile $modelProfileObj.name -Branch $branchName -WhatIf:$true | Out-Null
  New-AutoCycleSummary -Root $rootPath -Scope $Scope -Branch $branchName -Status "whatif" -PhaseSummary "WhatIf cycle plan only." -ManualItems "Review planned scripts before running without -WhatIf." -ReviewNotes "No branch, commit, push, or model call was executed." -StartedAt $startedAt -WhatIf | Out-Null
  Exit-AutoRunOutputContext -Context $outputContext
  return
}

try {
  $lock = New-AutoCycleLock -Root $rootPath -Scope $Scope -Branch $branchName
  if ($AuditOnly) {
    & (Join-Path $PSScriptRoot "run-all.ps1") -Root $rootPath -Phase audit -ModelProfile $modelProfileObj.name
    & (Join-Path $PSScriptRoot "model-semantic-audit.ps1") -Root $rootPath -ModelProfile $modelProfileObj.name -Scope $Scope
  } else {
    New-AutoBranch -Root $rootPath -Branch $branchName | Out-Null
    & (Join-Path $PSScriptRoot "run-all.ps1") -Root $rootPath -Phase all -ModelProfile $modelProfileObj.name
    & (Join-Path $PSScriptRoot "model-repair-plan.ps1") -Root $rootPath -ModelProfile $modelProfileObj.name -Scope $Scope
    & (Join-Path $PSScriptRoot "model-opportunity-radar.ps1") -Root $rootPath -ModelProfile $modelProfileObj.name -Scope $Scope
    New-AutoCycleSummary -Root $rootPath -Scope $Scope -Branch $branchName -Status "ready" -PhaseSummary "run-all phase=all completed; model-repair-plan consumed run findings; model-opportunity-radar discovered improvement opportunities, applied only safe micro/small edits, and reported larger ideas for human review." -ManualItems "Review B-tier proposals, C-tier approval sheets, large opportunity reports, and any applied opportunity edits before merging." -ReviewNotes "Use review-cycle.ps1 for a summary. Main merge remains manual." -StartedAt $startedAt | Out-Null
    Write-AutoRunLog -Root $rootPath -ScriptName "start-cycle" -Actions $actions -Parameters @{ phase = "cycle"; root = $rootPath; scope = $Scope; model_profile = $modelProfileObj.name; audit_only = $AuditOnly.IsPresent; max_repair_attempts = $MaxRepairAttempts; push = $Push.IsPresent; branch = $branchName; lock_id = $lock.id } -StartedAt $startedAt -ModelProfile $modelProfileObj.name -Branch $branchName -LockId $lock.id | Out-Null
    Invoke-AutoCommit -Root $rootPath -Message "auto: start-cycle - $Scope" -Push:$Push | Out-Null
  }
  Write-Host "start-cycle completed: scope=$Scope audit_only=$($AuditOnly.IsPresent)"
} catch {
  Write-AutoRunLog -Root $rootPath -ScriptName "start-cycle" -Actions $actions -Parameters @{ phase = "cycle"; root = $rootPath; scope = $Scope; model_profile = $modelProfileObj.name; audit_only = $AuditOnly.IsPresent; max_repair_attempts = $MaxRepairAttempts; push = $Push.IsPresent; branch = $branchName; lock_id = $(if ($null -ne $lock) { $lock.id } else { "" }) } -StartedAt $startedAt -ModelProfile $modelProfileObj.name -Branch $branchName -LockId $(if ($null -ne $lock) { $lock.id } else { "" }) -Status "failed" -ExitCode 1 | Out-Null
  throw
} finally {
  Remove-AutoCycleLock -Lock $lock
  Exit-AutoRunOutputContext -Context $outputContext
}
