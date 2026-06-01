[CmdletBinding(SupportsShouldProcess=$true)]
param(
  [string]$Root = "C:\Users\btf\AI-MemoryOS"
)

$ErrorActionPreference = "Stop"
Import-Module (Join-Path $PSScriptRoot "_shared.psm1") -Force
$startedAt = Get-Date
Test-MemoryOsRepo -Root $Root | Out-Null
$rootPath = Resolve-MemoryOsRoot -Root $Root
$actions = New-Object System.Collections.Generic.List[object]

foreach ($file in Get-MemoryOsFiles -Root $rootPath -Extensions @(".md")) {
  $text = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8
  if ($null -eq $text) { $text = "" }
  # Normalize to LF and ensure exactly one trailing LF — idempotent across reruns
  # and avoids fighting git's autocrlf on Windows checkouts.
  $newText = $text -replace "`r`n", "`n"
  $newText = $newText.TrimEnd("`n") + "`n"
  if ($newText -ne $text) {
    $relative = Get-MemoryOsRelativePath -Root $rootPath -Path $file.FullName
    if ($WhatIfPreference) {
      $actions.Add((New-AutoAction -Tier "A" -Action "normalize-trailing-newline" -Target $relative -Status "whatif"))
    } else {
      Write-MemoryOsTextFile -Path $file.FullName -Content $newText
      $actions.Add((New-AutoAction -Tier "A" -Action "normalize-trailing-newline" -Target $relative -Status "updated"))
    }
  }
}
if ($actions.Count -eq 0) { $actions.Add((New-AutoAction -Tier "A" -Action "normalize-frontmatter" -Target "markdown files" -Status "skipped no changes")) }

Write-AutoRunLog -Root $rootPath -ScriptName "optimize-frontmatter" -Actions $actions -Parameters @{ phase = "optimize"; root = $rootPath } -StartedAt $startedAt -WhatIf:$WhatIfPreference | Out-Null
Write-Host "optimize-frontmatter actions: $($actions.Count)"
