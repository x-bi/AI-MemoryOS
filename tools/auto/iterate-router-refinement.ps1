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
$findings = @(Get-LatestAutoRunFindings -Root $rootPath -ScriptName "audit-router-consistency")
$actions = New-Object System.Collections.Generic.List[object]
$created = 0

foreach ($finding in $findings) {
  if ($created -ge $MaxProposals) {
    break
  }
  if (Test-AutoFindingIgnored -Root $rootPath -Finding $finding) {
    $actions.Add([pscustomobject]@{ tier = "B"; action = "proposal"; target = $finding.path; status = "skipped ignored finding" })
    continue
  }
  $title = "Fix router consistency: $($finding.category)"
  $draft = @"
Router consistency audit found an issue that needs human review.

- Category: $($finding.category)
- Message: $($finding.message)
- Path: $($finding.path)
- Suggested action: Confirm whether router maps, registry, and evals need synchronized updates.
"@
  $action = New-BTierProposal -Root $rootPath -Title $title -Summary "Router consistency audit found a synchronization issue that needs human review." -Trigger "audit-router-consistency" -RelatedTask $finding.path -Destination "router" -Draft $draft -WhatIf:$WhatIfPreference
  $actions.Add($action)
  if ($action.status -eq "skipped global quota") { $created = $MaxProposals; break }
  if ($action.status -in @("created", "whatif", "skipped duplicate")) { $created++ }
}

$casesPath = Join-Path $rootPath "evals\router-correction-cases.md"
if (Test-Path -LiteralPath $casesPath) {
  foreach ($line in Get-Content -LiteralPath $casesPath -Encoding UTF8) {
    if ($created -ge $MaxProposals) { break }
    if ($line -notmatch '^\|' -or $line -match '^\|\s*(-+|Date)\s*\|') { continue }
    $columns = @($line.Trim("|") -split "\|" | ForEach-Object { $_.Trim() })
    if ($columns.Count -lt 5) { continue }
    $inputText = $columns[1]
    $fix = $columns[4]
    if ([string]::IsNullOrWhiteSpace($inputText) -or [string]::IsNullOrWhiteSpace($fix)) { continue }
    $caseFinding = [pscustomobject]@{ category = "router-correction-case"; path = "evals\router-correction-cases.md"; message = $inputText }
    if (Test-AutoFindingIgnored -Root $rootPath -Finding $caseFinding) {
      $actions.Add([pscustomobject]@{ tier = "B"; action = "proposal"; target = $inputText; status = "skipped ignored finding" })
      continue
    }
    $title = "Router correction: $inputText"
    $draft = @"
Router correction case:

- Original input: $inputText
- Wrong routing: $($columns[2])
- Correct routing: $($columns[3])
- Proposed fix: $fix
"@
    $action = New-BTierProposal -Root $rootPath -Title $title -Summary "router-correction-cases.md contains a correction case that still needs implementation review." -Trigger "router-correction-cases" -RelatedTask $inputText -Destination "router" -Draft $draft -WhatIf:$WhatIfPreference
    $actions.Add($action)
    if ($action.status -eq "skipped global quota") { $created = $MaxProposals; break }
    if ($action.status -in @("created", "whatif", "skipped duplicate")) { $created++ }
  }
}

if ($actions.Count -eq 0) {
  $actions.Add([pscustomobject]@{ tier = "B"; action = "proposal"; target = "router-refinement"; status = "skipped no candidates" })
}

Write-AutoRunLog -Root $rootPath -ScriptName "iterate-router-refinement" -Findings $findings -Actions $actions -Parameters @{ phase = "iterate"; root = $rootPath; max_proposals = $MaxProposals } -StartedAt $startedAt -WhatIf:$WhatIfPreference | Out-Null
Write-Host "iterate-router-refinement actions: $($actions.Count)"
