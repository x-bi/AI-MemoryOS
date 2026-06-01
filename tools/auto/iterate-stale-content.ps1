[CmdletBinding(SupportsShouldProcess=$true)]
param(
  [string]$Root = "C:\Users\btf\AI-MemoryOS",
  [int]$StaleDays = 30,
  [int]$MaxProposals = 10
)

$ErrorActionPreference = "Stop"
Import-Module (Join-Path $PSScriptRoot "_shared.psm1") -Force
$startedAt = Get-Date
Test-MemoryOsRepo -Root $Root | Out-Null

$rootPath = Resolve-MemoryOsRoot -Root $Root
$findings = @(Get-LatestAutoRunFindings -Root $rootPath -ScriptName "audit-content-quality" | Where-Object { $_.category -eq "hollow-content" })
$actions = New-Object System.Collections.Generic.List[object]
$created = 0

if ($findings.Count -eq 0) {
  $actions.Add([pscustomobject]@{ tier = "B"; action = "proposal"; target = "stale-content"; status = "skipped no audit findings" })
} else {
  foreach ($finding in $findings) {
    if ($created -ge $MaxProposals) {
      break
    }
    if (Test-AutoFindingIgnored -Root $rootPath -Finding $finding) {
      $actions.Add([pscustomobject]@{ tier = "B"; action = "proposal"; target = $finding.path; status = "skipped ignored finding" })
      continue
    }
    $title = "Archive stale content: $($finding.path)"
    $draft = @"
Review whether this page still has durable value.

- Finding category: $($finding.category)
- Evidence path: $($finding.path)
- Suggested action: If the content is confirmed as placeholder, stale, or not reusable, archive it or complete the body.
"@
    $action = New-BTierProposal -Root $rootPath -Title $title -Summary "Audit found content that appears hollow or placeholder-only and needs human review." -Trigger "audit-content-quality" -RelatedTask $finding.path -Destination "memory-cleanup" -Draft $draft -WhatIf:$WhatIfPreference
    $actions.Add($action)
    if ($action.status -eq "skipped global quota") { $created = $MaxProposals; break }
    if ($action.status -in @("created", "whatif", "skipped duplicate")) { $created++ }
  }
}

Write-AutoRunLog -Root $rootPath -ScriptName "iterate-stale-content" -Findings $findings -Actions $actions -Parameters @{ phase = "iterate"; root = $rootPath; max_proposals = $MaxProposals; stale_days = $StaleDays } -StartedAt $startedAt -WhatIf:$WhatIfPreference | Out-Null
Write-Host "iterate-stale-content actions: $($actions.Count)"
