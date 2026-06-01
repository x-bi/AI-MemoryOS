[CmdletBinding(SupportsShouldProcess=$true)]
param(
  [string]$Root = "C:\Users\btf\AI-MemoryOS",
  [int]$MaxProposals = 10
)

$ErrorActionPreference = "Stop"
Import-Module (Join-Path $PSScriptRoot "_shared.psm1") -Force
$startedAt = Get-Date
Test-MemoryOsRepo -Root $Root | Out-Null

$rootPath = Resolve-MemoryOsRoot -Root $Root
$findings = @(Get-LatestAutoRunFindings -Root $rootPath -ScriptName "audit-content-quality" | Where-Object { $_.category -eq "duplicate-content" })
$actions = New-Object System.Collections.Generic.List[object]
$created = 0

if ($findings.Count -eq 0) {
  $actions.Add([pscustomobject]@{ tier = "B"; action = "proposal"; target = "duplicate-content"; status = "skipped no audit findings" })
} else {
  foreach ($finding in $findings) {
    if ($created -ge $MaxProposals) {
      break
    }
    if (Test-AutoFindingIgnored -Root $rootPath -Finding $finding) {
      $actions.Add([pscustomobject]@{ tier = "B"; action = "proposal"; target = $finding.path; status = "skipped ignored finding" })
      continue
    }
    $files = @()
    if ($null -ne $finding.data.files) { $files = @($finding.data.files) }
    if ($files.Count -eq 0) { $files = @(([string]$finding.path) -split ";\s*") }
    $topic = if ($files.Count -gt 0) { Split-Path -Leaf $files[0] } else { "unknown" }
    $title = "Merge duplicate content: $topic"
    $fileLines = ($files | ForEach-Object { "- $_" }) -join "`r`n"
    $draft = @"
Review the duplicate content below and choose one canonical page to keep:

$fileLines

Suggested action: Confirm the source of truth before promotion. Do not delete files automatically.
"@
    $action = New-BTierProposal -Root $rootPath -Title $title -Summary "Audit found multiple pages with identical normalized body content." -Trigger "audit-content-quality" -RelatedTask ($files -join "; ") -Destination "memory-cleanup" -Draft $draft -WhatIf:$WhatIfPreference
    $actions.Add($action)
    if ($action.status -eq "skipped global quota") { $created = $MaxProposals; break }
    if ($action.status -in @("created", "whatif", "skipped duplicate")) { $created++ }
  }
}

Write-AutoRunLog -Root $rootPath -ScriptName "iterate-duplicate-merge" -Findings $findings -Actions $actions -Parameters @{ phase = "iterate"; root = $rootPath; max_proposals = $MaxProposals } -StartedAt $startedAt -WhatIf:$WhatIfPreference | Out-Null
Write-Host "iterate-duplicate-merge actions: $($actions.Count)"
