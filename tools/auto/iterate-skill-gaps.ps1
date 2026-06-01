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
$findings = @(Get-LatestAutoRunFindings -Root $rootPath -ScriptName "audit-skill-coverage" | Where-Object { $_.category -like "skill-missing-*" })
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
  $skillName = if ($null -ne $finding.data.skill) { [string]$finding.data.skill } else { "unknown-skill" }
  $title = "Add eval coverage: $skillName"
  $draft = @"
Add trigger-boundary eval coverage for the active skill.

- Skill: $skillName
- Finding: $($finding.message)
- Target file: evals/skill-trigger-test-cases.md
- Suggested action: Add at least one positive and one negative case to reduce false triggers and misses.
"@
  $action = New-BTierProposal -Root $rootPath -Title $title -Summary "Audit found insufficient trigger eval coverage for an active skill." -Trigger "audit-skill-coverage" -RelatedTask $skillName -Destination "evals" -Draft $draft -WhatIf:$WhatIfPreference
  $actions.Add($action)
  if ($action.status -eq "skipped global quota") { $created = $MaxProposals; break }
  if ($action.status -in @("created", "whatif", "skipped duplicate")) { $created++ }
}

$statusPath = Join-Path $rootPath "STATUS.md"
if (Test-Path -LiteralPath $statusPath) {
  $statusText = Get-Content -LiteralPath $statusPath -Raw -Encoding UTF8
  $active = @((Get-ActiveMemoryOsSkills -Root $rootPath) | ForEach-Object { [string]$_.name })
  foreach ($match in [regex]::Matches($statusText, '[a-z][a-z0-9]+(?:-[a-z0-9]+)+')) {
    if ($created -ge $MaxProposals) { break }
    $candidate = $match.Value
    if ($candidate -notmatch '(skill|review|planning|auditor|automation|strategy|pipeline|backend|playwright|prompt|refactor)' ) { continue }
    if ($active -contains $candidate) { continue }
    $candidateFinding = [pscustomobject]@{ category = "status-skill-candidate"; path = "STATUS.md"; message = $candidate }
    if (Test-AutoFindingIgnored -Root $rootPath -Finding $candidateFinding) {
      $actions.Add([pscustomobject]@{ tier = "B"; action = "proposal"; target = $candidate; status = "skipped ignored finding" })
      continue
    }
    $title = "Evaluate candidate skill: $candidate"
    $draft = @"
STATUS.md mentions this candidate skill, but it is not active.

- Candidate: $candidate
- Suggested action: Decide whether it should enter `skills/registry.json`, then add SKILL_SPEC, adapter sync, and eval coverage.
"@
    $action = New-BTierProposal -Root $rootPath -Title $title -Summary "STATUS.md contains a candidate skill that is not active yet." -Trigger "STATUS.md skill candidate scan" -RelatedTask $candidate -Destination "skills" -Draft $draft -WhatIf:$WhatIfPreference
    $actions.Add($action)
    if ($action.status -eq "skipped global quota") { $created = $MaxProposals; break }
    if ($action.status -in @("created", "whatif", "skipped duplicate")) { $created++ }
  }
}

if ($actions.Count -eq 0) {
  $actions.Add([pscustomobject]@{ tier = "B"; action = "proposal"; target = "skill-gaps"; status = "skipped no candidates" })
}

Write-AutoRunLog -Root $rootPath -ScriptName "iterate-skill-gaps" -Findings $findings -Actions $actions -Parameters @{ phase = "iterate"; root = $rootPath; max_proposals = $MaxProposals } -StartedAt $startedAt -WhatIf:$WhatIfPreference | Out-Null
Write-Host "iterate-skill-gaps actions: $($actions.Count)"
