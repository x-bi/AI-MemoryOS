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
$hashToFiles = @{}

foreach ($file in Get-MemoryOsFiles -Root $rootPath -Extensions @(".md")) {
  $relative = Get-MemoryOsRelativePath -Root $rootPath -Path $file.FullName
  $text = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8
  $body = Remove-MarkdownFrontMatter -Text $text
  $normalized = ($body -replace "\s+", " ").Trim()
  if (-not [string]::IsNullOrWhiteSpace($normalized)) {
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($normalized)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    $hash = [System.BitConverter]::ToString($sha.ComputeHash($bytes)).Replace("-", "").ToLowerInvariant()
    if (-not $hashToFiles.ContainsKey($hash)) { $hashToFiles[$hash] = New-Object System.Collections.Generic.List[string] }
    $hashToFiles[$hash].Add($relative)
  }

  $meaningfulLines = @($body -split "\r?\n" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
  $placeholderOnly = $false
  if ($meaningfulLines.Count -gt 0) {
    $joined = ($meaningfulLines -join " ").Trim()
    $placeholderOnly = $joined -match '(?i)^(todo|tbd|placeholder|coming soon)[\s\.\-:]*$'
  }
  if ($meaningfulLines.Count -lt 5 -or $placeholderOnly) {
    $findings.Add((New-AutoFinding -Severity "warning" -Category "hollow-content" -Message "Markdown body appears too short or placeholder-only." -Path $relative -Tier "B"))
  }
}

foreach ($entry in $hashToFiles.GetEnumerator()) {
  if ($entry.Value.Count -gt 1) {
    $paths = @($entry.Value)
    $findings.Add((New-AutoFinding -Severity "warning" -Category "duplicate-content" -Message "Multiple files have identical normalized body content." -Path ($paths -join "; ") -Tier "B" -Data @{ files = $paths }))
  }
}

Write-AutoRunLog -Root $rootPath -ScriptName "audit-content-quality" -Findings $findings -Parameters @{ phase = "audit"; root = $rootPath } -StartedAt $startedAt -WhatIf:$WhatIfPreference | Out-Null
Write-Host "audit-content-quality findings: $($findings.Count)"
