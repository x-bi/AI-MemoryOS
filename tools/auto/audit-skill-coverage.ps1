[CmdletBinding(SupportsShouldProcess=$true)]
param(
  [string]$Root = "C:\Users\btf\AI-MemoryOS"
)

$ErrorActionPreference = "Stop"
Import-Module (Join-Path $PSScriptRoot "_shared.psm1") -Force
$startedAt = Get-Date
Test-MemoryOsRepo -Root $Root | Out-Null

$rootPath = Resolve-MemoryOsRoot -Root $Root
$findings = New-Object System.Collections.Generic.List[object]
$skills = Get-ActiveMemoryOsSkills -Root $rootPath
$evalPath = Join-Path $rootPath "evals\skill-trigger-test-cases.md"
$evalLines = @()
if (Test-Path -LiteralPath $evalPath) {
  $evalLines = Get-Content -LiteralPath $evalPath -Encoding UTF8
}

foreach ($skill in $skills) {
  $name = [string]$skill.name
  $positive = 0
  $negative = 0
  foreach ($line in $evalLines) {
    if ($line -notmatch '^\|') { continue }
    $columns = @($line.Trim("|") -split "\|" | ForEach-Object { $_.Trim() })
    if ($columns.Count -lt 3 -or $columns[0] -eq "Input" -or $columns[0] -match '^-+$') { continue }
    $expected = $columns[1]
    $shouldTrigger = $columns[2].ToLowerInvariant()
    if ($expected -match "(^|[^a-z0-9_-])$([regex]::Escape($name))([^a-z0-9_-]|$)") {
      if ($shouldTrigger -eq "yes") { $positive++ }
      if ($shouldTrigger -eq "no") { $negative++ }
    }
  }
  if ($positive -eq 0) {
    $findings.Add((New-AutoFinding -Severity "critical" -Category "skill-missing-positive-eval" -Message "Active skill has no positive trigger eval case: $name" -Path "evals/skill-trigger-test-cases.md" -Tier "B" -Data @{ skill = $name }))
  }
  if ($negative -eq 0) {
    $findings.Add((New-AutoFinding -Severity "warning" -Category "skill-missing-negative-eval" -Message "Active skill has no explicit negative trigger eval case: $name" -Path "evals/skill-trigger-test-cases.md" -Tier "B" -Data @{ skill = $name }))
  }
}

Write-AutoRunLog -Root $rootPath -ScriptName "audit-skill-coverage" -Findings $findings -Parameters @{ phase = "audit"; root = $rootPath } -StartedAt $startedAt -WhatIf:$WhatIfPreference | Out-Null
Write-Host "audit-skill-coverage findings: $($findings.Count)"
