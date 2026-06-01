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

foreach ($file in Get-MemoryOsFiles -Root $rootPath -Extensions @(".md")) {
  $relative = Get-MemoryOsRelativePath -Root $rootPath -Path $file.FullName
  $text = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8
  $scanText = [regex]::Replace($text, '(?s)(```|~~~).*?\1', '')
  $scanText = [regex]::Replace($scanText, '`[^`]*`', '')

  foreach ($match in [regex]::Matches($scanText, '\[\[([^\]|#]+)(?:[#|][^\]]*)?\]\]')) {
    $target = $match.Groups[1].Value.Trim()
    if ([string]::IsNullOrWhiteSpace($target)) { continue }
    $targetPath = Join-Path $rootPath $target
    $targetMdPath = Join-Path $rootPath "$target.md"
    if (-not (Test-Path -LiteralPath $targetPath) -and -not (Test-Path -LiteralPath $targetMdPath)) {
      $findings.Add((New-AutoFinding -Severity "critical" -Category "broken-wiki-link" -Message "Wiki link target does not exist: $target" -Path $relative -Tier "B" -Data @{ target = $target }))
    }
  }

  foreach ($match in [regex]::Matches($scanText, '(?<!\!)\[[^\]]+\]\(([^)]+)\)')) {
    $target = $match.Groups[1].Value.Trim()
    if ([string]::IsNullOrWhiteSpace($target)) { continue }
    if ($target -match '^(?i)(https?|mailto|obsidian|file):' -or $target.StartsWith("#")) { continue }
    if ([System.IO.Path]::IsPathRooted($target)) { continue }
    $cleanTarget = ($target -split "#")[0].Trim()
    if ([string]::IsNullOrWhiteSpace($cleanTarget)) { continue }
    $baseDir = Split-Path -Parent $file.FullName
    $fullTarget = [System.IO.Path]::GetFullPath((Join-Path $baseDir ($cleanTarget -replace "/", "\")))
    if (-not (Test-MemoryOsPathInside -ChildPath $fullTarget -ParentPath $rootPath)) { continue }
    if (-not (Test-Path -LiteralPath $fullTarget)) {
      $findings.Add((New-AutoFinding -Severity "warning" -Category "broken-markdown-link" -Message "Markdown link target does not exist: $target" -Path $relative -Tier "B" -Data @{ target = $target }))
    }
  }
}

Write-AutoRunLog -Root $rootPath -ScriptName "audit-link-integrity" -Findings $findings -Parameters @{ phase = "audit"; root = $rootPath } -StartedAt $startedAt -WhatIf:$WhatIfPreference | Out-Null
Write-Host "audit-link-integrity findings: $($findings.Count)"
