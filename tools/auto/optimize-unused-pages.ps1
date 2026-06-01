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
$allMd = @(Get-MemoryOsFiles -Root $rootPath -Extensions @(".md") | ForEach-Object { Get-MemoryOsRelativePath -Root $rootPath -Path $_.FullName })
$allText = ($allMd | ForEach-Object { Get-Content -LiteralPath (Join-Path $rootPath $_) -Raw -Encoding UTF8 }) -join "`n"
$required = @("_index.md", "README.md", "STATUS.md", "ROADMAP.md", "GOVERNANCE.md", "dashboard/home.md")
$created = 0

foreach ($relative in $allMd) {
  if ($created -ge $MaxProposals) { break }
  $normalized = $relative -replace "\\", "/"
  if ($required -contains $relative -or $normalized.StartsWith("proposals/pending/") -or $normalized.StartsWith("logs/")) { continue }
  $stem = [System.IO.Path]::GetFileNameWithoutExtension($relative)
  if ($allText -notmatch [regex]::Escape($relative) -and $allText -notmatch "\[\[[^\]]*$([regex]::Escape($stem))[^\]]*\]\]") {
    $title = "Review orphan page: $relative"
    $draft = "No inbound reference was detected by the simple Round 2 link scan. Human review should decide whether to index, merge, or archive the page."
    $action = New-BTierProposal -Root $rootPath -Title $title -Summary "Automatic scan found a page that may have no inbound links and needs human review." -Trigger "optimize-unused-pages" -RelatedTask $relative -Destination "memory-cleanup" -Draft $draft -WhatIf:$WhatIfPreference
    $actions.Add($action)
    if ($action.status -eq "skipped global quota") { $created = $MaxProposals; break }
    if ($action.status -in @("created", "whatif", "skipped duplicate")) { $created++ }
  }
}
if ($actions.Count -eq 0) { $actions.Add((New-AutoAction -Tier "B" -Action "proposal" -Target "unused-pages" -Status "skipped no candidates")) }

Write-AutoRunLog -Root $rootPath -ScriptName "optimize-unused-pages" -Actions $actions -Parameters @{ phase = "optimize"; root = $rootPath; max_proposals = $MaxProposals } -StartedAt $startedAt -WhatIf:$WhatIfPreference | Out-Null
Write-Host "optimize-unused-pages actions: $($actions.Count)"
