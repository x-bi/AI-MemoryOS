[CmdletBinding(SupportsShouldProcess=$true)]
param(
  [string]$Root = "C:\Users\btf\AI-MemoryOS",
  [ValidateSet("audit", "iterate", "semantic-audit", "optimize", "opportunity", "all")][string]$Phase = "audit",
  [string]$ModelProfile = "",
  [int]$CycleTimeoutMinutes = 30,
  [int]$SingleScriptTimeoutMinutes = 5,
  [int]$MaxProposals = 10,
  [switch]$AutoCommit,
  [switch]$Push
)

$ErrorActionPreference = "Stop"
Import-Module (Join-Path $PSScriptRoot "_shared.psm1") -Force
Test-MemoryOsRepo -Root $Root | Out-Null
$rootPath = Resolve-MemoryOsRoot -Root $Root
$modelProfileObj = Get-ModelProfile -Root $rootPath -Name $ModelProfile
$outputContext = Enter-AutoRunOutputContext -ScriptName "run-all" -Detail $Phase

function Invoke-AutoScript {
  param(
    [string]$Script,
    [string]$PhaseName
  )

  $path = Join-Path $PSScriptRoot $Script
  if (Test-AutoScriptDisabled -Root $rootPath -ScriptName $Script) {
    Write-Host "Skipping disabled script $Script"
    return
  }
  Write-Host "Running $Script"
  if ($Script -in @("iterate-stale-content.ps1", "iterate-duplicate-merge.ps1", "iterate-skill-gaps.ps1", "iterate-router-refinement.ps1", "iterate-promotion-candidates.ps1", "optimize-unused-pages.ps1", "optimize-skill-consistency.ps1")) {
    & $path -Root $rootPath -MaxProposals $MaxProposals -WhatIf:$WhatIfPreference
  } elseif ($Script -eq "model-semantic-audit.ps1") {
    & $path -Root $rootPath -ModelProfile $modelProfileObj.name -WhatIf:$WhatIfPreference
  } elseif ($Script -eq "model-opportunity-radar.ps1") {
    & $path -Root $rootPath -ModelProfile $modelProfileObj.name -WhatIf:$WhatIfPreference
  } else {
    & $path -Root $rootPath -WhatIf:$WhatIfPreference
  }
}

$auditScripts = @(
    "audit-content-quality.ps1",
    "audit-link-integrity.ps1",
    "audit-skill-coverage.ps1",
    "audit-router-consistency.ps1",
    "audit-proposal-health.ps1"
)
$semanticScripts = @("model-semantic-audit.ps1")
$iterateScripts = @(
    "iterate-stale-content.ps1",
    "iterate-duplicate-merge.ps1",
    "iterate-skill-gaps.ps1",
    "iterate-router-refinement.ps1",
    "iterate-promotion-candidates.ps1"
)
$optimizeScripts = @(
  "optimize-frontmatter.ps1",
  "optimize-dashboard-sync.ps1",
  "optimize-skill-consistency.ps1",
  "optimize-unused-pages.ps1",
  "optimize-adapter-gate-sync.ps1",
  "optimize-core-rules.ps1"
)
$opportunityScripts = @("model-opportunity-radar.ps1")

$phaseMap = @{
  audit = $auditScripts
  "semantic-audit" = $semanticScripts
  iterate = $iterateScripts
  optimize = $optimizeScripts
  opportunity = $opportunityScripts
}
$scripts = if ($Phase -eq "all") { @($auditScripts + $semanticScripts + $iterateScripts + $optimizeScripts) } else { $phaseMap[$Phase] }

$oldQuota = $env:AI_MEMORYOS_AUTO_PROPOSAL_QUOTA
$oldCount = $env:AI_MEMORYOS_AUTO_PROPOSAL_COUNT
if ($Phase -eq "iterate") {
  $env:AI_MEMORYOS_AUTO_PROPOSAL_QUOTA = [string]$MaxProposals
  $env:AI_MEMORYOS_AUTO_PROPOSAL_COUNT = "0"
} elseif (@($scripts | Where-Object { $_ -like "iterate-*" }).Count -gt 0) {
  $env:AI_MEMORYOS_AUTO_PROPOSAL_QUOTA = [string]$MaxProposals
  $env:AI_MEMORYOS_AUTO_PROPOSAL_COUNT = "0"
}

$started = Get-Date
$passed = 0
$failed = 0
try {
  foreach ($script in $scripts) {
    if (((Get-Date) - $started).TotalMinutes -gt $CycleTimeoutMinutes) {
      throw "Cycle timeout after $CycleTimeoutMinutes minutes"
    }
    try {
      Invoke-AutoScript -Script $script -PhaseName $Phase
      if ($AutoCommit -and -not $WhatIfPreference) {
        Invoke-AutoCommit -Root $rootPath -Message "auto: $($script -replace '\.ps1$', '')" -Push:$Push | Out-Null
      }
      $passed++
    } catch {
      $failed++
      Write-Host "Failed ${script}: $($_.Exception.Message)"
      if ($script -like "iterate-*" -or $script -like "optimize-*") {
        throw "Stopping write-capable phase after script failure: $script"
      }
    }
  }
} finally {
  if ($null -eq $oldQuota) { $env:AI_MEMORYOS_AUTO_PROPOSAL_QUOTA = $null } else { $env:AI_MEMORYOS_AUTO_PROPOSAL_QUOTA = $oldQuota }
  if ($null -eq $oldCount) { $env:AI_MEMORYOS_AUTO_PROPOSAL_COUNT = $null } else { $env:AI_MEMORYOS_AUTO_PROPOSAL_COUNT = $oldCount }
  Exit-AutoRunOutputContext -Context $outputContext
}

if ($failed -gt 0) {
  throw "run-all phase '$Phase' completed with $failed failed script(s)."
}

Write-Host "run-all summary: phase=$Phase passed=$passed failed=$failed model_profile=$($modelProfileObj.name)"
