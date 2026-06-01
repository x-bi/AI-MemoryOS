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
$activeSkillNames = @((Get-ActiveMemoryOsSkills -Root $rootPath) | ForEach-Object { [string]$_.name })
$skillMapPath = Join-Path $rootPath "router\skill-map.md"
$domainMapPath = Join-Path $rootPath "router\domain-map.md"

if (Test-Path -LiteralPath $skillMapPath) {
  $skillMapText = Get-Content -LiteralPath $skillMapPath -Raw -Encoding UTF8
  foreach ($skillName in $activeSkillNames) {
    if ($skillMapText -notmatch "(?m)^\|\s*$([regex]::Escape($skillName))\s*\|") {
      $findings.Add((New-AutoFinding -Severity "critical" -Category "active-skill-missing-from-skill-map" -Message "Active skill is missing from router/skill-map.md: $skillName" -Path "router/skill-map.md" -Tier "B" -Data @{ skill = $skillName }))
    }
  }
  foreach ($match in [regex]::Matches($skillMapText, '(?m)^\|\s*([a-z0-9][a-z0-9_-]+)\s*\|')) {
    $skillName = $match.Groups[1].Value
    if ($skillName -in @("Skill")) { continue }
    if ($activeSkillNames -notcontains $skillName) {
      $findings.Add((New-AutoFinding -Severity "warning" -Category "skill-map-non-active-skill" -Message "Skill map references a non-active skill: $skillName" -Path "router/skill-map.md" -Tier "B" -Data @{ skill = $skillName }))
    }
  }
}

if (Test-Path -LiteralPath $domainMapPath) {
  $domainMapText = Get-Content -LiteralPath $domainMapPath -Raw -Encoding UTF8
  foreach ($match in [regex]::Matches($domainMapText, '`([^`]+\.md)`')) {
    $relative = $match.Groups[1].Value
    $full = Resolve-MemoryOsRelativePath -Root $rootPath -RelativePath $relative
    if (-not (Test-Path -LiteralPath $full)) {
      $findings.Add((New-AutoFinding -Severity "critical" -Category "domain-map-missing-read-target" -Message "Domain map read target does not exist: $relative" -Path "router/domain-map.md" -Tier "B" -Data @{ target = $relative }))
    }
  }
}

Write-AutoRunLog -Root $rootPath -ScriptName "audit-router-consistency" -Findings $findings -Parameters @{ phase = "audit"; root = $rootPath } -StartedAt $startedAt -WhatIf:$WhatIfPreference | Out-Null
Write-Host "audit-router-consistency findings: $($findings.Count)"
