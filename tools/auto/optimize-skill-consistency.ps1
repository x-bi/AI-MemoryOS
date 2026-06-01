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
$actions = New-Object System.Collections.Generic.List[object]
$created = 0

foreach ($skill in Get-ActiveMemoryOsSkills -Root $rootPath) {
  if ($created -ge $MaxProposals) { break }
  $sourcePath = Resolve-MemoryOsRelativePath -Root $rootPath -RelativePath ([string]$skill.source)
  $sourceHash = Get-AutoFileSha256 -Path $sourcePath
  foreach ($adapterName in @("codex", "claude")) {
    $adapter = $skill.adapters.$adapterName
    if ($null -eq $adapter -or $adapter.enabled -ne $true) { continue }
    $outputPath = Resolve-MemoryOsRelativePath -Root $rootPath -RelativePath ([string]$adapter.output)
    $text = Get-Content -LiteralPath $outputPath -Raw -Encoding UTF8
    if ($text -notlike "*source-sha256: $sourceHash*") {
      $title = "Sync skill wrapper: $($skill.name) / $adapterName"
      $draft = "adapter wrapper hash does not match SKILL_SPEC. Run tools/sync-skills.ps1 and validate."
      $action = New-BTierProposal -Root $rootPath -Title $title -Summary "active skill wrapper appears out of sync with its shared SKILL_SPEC." -Trigger "optimize-skill-consistency" -RelatedTask ([string]$adapter.output) -Destination "skills" -Draft $draft -WhatIf:$WhatIfPreference
      $actions.Add($action)
      if ($action.status -eq "skipped global quota") { $created = $MaxProposals; break }
      if ($action.status -in @("created", "whatif", "skipped duplicate")) { $created++ }
    }
  }
}
if ($actions.Count -eq 0) { $actions.Add((New-AutoAction -Tier "B" -Action "proposal" -Target "skill-consistency" -Status "skipped no candidates")) }

Write-AutoRunLog -Root $rootPath -ScriptName "optimize-skill-consistency" -Actions $actions -Parameters @{ phase = "optimize"; root = $rootPath; max_proposals = $MaxProposals } -StartedAt $startedAt -WhatIf:$WhatIfPreference | Out-Null
Write-Host "optimize-skill-consistency actions: $($actions.Count)"
