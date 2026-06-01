[CmdletBinding(SupportsShouldProcess=$true)]
param(
  [string]$Root = "C:\Users\btf\AI-MemoryOS",
  [string]$RunOutputDir = ""
)

$ErrorActionPreference = "Stop"
Import-Module (Join-Path $PSScriptRoot "_shared.psm1") -Force
Test-MemoryOsRepo -Root $Root | Out-Null
$rootPath = Resolve-MemoryOsRoot -Root $Root

if ($WhatIfPreference) {
  $target = if ([string]::IsNullOrWhiteSpace($RunOutputDir)) { "latest auto-run output directory" } else { $RunOutputDir }
  Write-Host "WhatIf: would write auto-run overview for $target"
  return
}

$path = Write-AutoRunOverview -Root $rootPath -OutputDirectoryName $RunOutputDir
if ($null -eq $path) {
  Write-Host "No auto-run logs found for overview."
  return
}

Write-Host "Wrote auto-run overview: $(Get-MemoryOsRelativePath -Root $rootPath -Path $path)"
