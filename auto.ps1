[CmdletBinding()]
param(
  [ValidateSet("content-quality", "router-cleanup", "skill-health", "proposal-review", "full")]
  [string]$Scope = "content-quality",

  [string]$ModelProfile = "claude",

  [switch]$Run,
  [switch]$Push,
  [switch]$AuditOnly,
  [int]$MaxRepairAttempts = 1
)

$ErrorActionPreference = "Stop"

$root = $PSScriptRoot
$startCycle = Join-Path $root "tools\auto\start-cycle.ps1"

$argsList = @(
  "-Root", $root,
  "-Scope", $Scope,
  "-ModelProfile", $ModelProfile,
  "-MaxRepairAttempts", $MaxRepairAttempts
)

if ($AuditOnly) {
  $argsList += "-AuditOnly"
}

if ($Push) {
  $argsList += "-Push"
}

if (-not $Run) {
  $argsList += "-WhatIf"
  Write-Host "Running auto cycle shortcut in dry-run mode. Use -Run for a real cycle."
} else {
  Write-Host "Running real auto cycle shortcut."
}

& powershell -NoProfile -ExecutionPolicy Bypass -File $startCycle @argsList
