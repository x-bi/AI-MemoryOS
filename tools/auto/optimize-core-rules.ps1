[CmdletBinding(SupportsShouldProcess=$true)]
param(
  [string]$Root = "C:\Users\btf\AI-MemoryOS",
  [switch]$ApplyApproved,
  [string]$ApprovalSheet
)

$ErrorActionPreference = "Stop"
Import-Module (Join-Path $PSScriptRoot "_shared.psm1") -Force
$startedAt = Get-Date
Test-MemoryOsRepo -Root $Root | Out-Null
$rootPath = Resolve-MemoryOsRoot -Root $Root

$indexText = Get-Content -LiteralPath (Join-Path $rootPath "_index.md") -Raw -Encoding UTF8
$actions = New-Object System.Collections.Generic.List[object]
$missingRefs = New-Object System.Collections.Generic.List[string]
foreach ($dir in @("core", "rules", "router")) {
  foreach ($file in Get-ChildItem -LiteralPath (Join-Path $rootPath $dir) -Filter "*.md" -File) {
    $relative = Get-MemoryOsRelativePath -Root $rootPath -Path $file.FullName
    if ($indexText -notmatch [regex]::Escape($relative) -and $indexText -notmatch [regex]::Escape(($relative -replace "\\", "/"))) {
      $missingRefs.Add($relative)
      if (-not $ApplyApproved) {
        $actions.Add((New-CTierApprovalSheet -Root $rootPath -Title "Review core index reference: $relative" -Scope "core/rules/router index coverage" -Files @($relative, "_index.md") -Reason "Core/rules/router file is not directly referenced from _index.md." -DiffPreview "Human review required." -WhatIf:$WhatIfPreference))
      }
      break
    }
  }
}
if ($ApplyApproved) {
  Assert-CTierApprovalSheetApproved -Root $rootPath -ApprovalSheet $ApprovalSheet | Out-Null
  $actions.Clear()
  if ($missingRefs.Count -gt 0) {
    $indexPath = Join-Path $rootPath "_index.md"
    $lines = New-Object System.Collections.Generic.List[string]
    foreach ($relative in $missingRefs) {
      $lines.Add("- `$relative`: C-tier approved index reference.")
    }
    $newIndexText = $indexText.TrimEnd() + "`n`n## Auto Indexed References`n`n" + ($lines -join "`n") + "`n"
    $newIndexText = $newIndexText -replace "`r`n", "`n"
    if ($WhatIfPreference) {
      $actions.Add((New-AutoAction -Tier "C" -Action "apply-approved" -Target "_index.md" -Status "whatif"))
    } else {
      Assert-NoSensitiveContent -Text $newIndexText
      $utf8 = New-Object System.Text.UTF8Encoding($false)
      [System.IO.File]::WriteAllText($indexPath, $newIndexText, $utf8)
      $actions.Add((New-AutoAction -Tier "C" -Action "apply-approved" -Target "_index.md" -Status "updated"))
    }
  } else {
    $actions.Add((New-AutoAction -Tier "C" -Action "apply-approved" -Target "core-rules" -Status "skipped no candidates"))
  }
  Write-AutoRunLog -Root $rootPath -ScriptName "optimize-core-rules" -Actions $actions -Parameters @{ phase = "optimize"; root = $rootPath; apply_approved = $ApplyApproved.IsPresent; approval_sheet = $ApprovalSheet } -StartedAt $startedAt -WhatIf:$WhatIfPreference | Out-Null
  Write-Host "optimize-core-rules actions: $($actions.Count)"
  return
}
if ($actions.Count -eq 0) { $actions.Add((New-AutoAction -Tier "C" -Action "approval-sheet" -Target "core-rules" -Status "skipped no candidates")) }

Write-AutoRunLog -Root $rootPath -ScriptName "optimize-core-rules" -Actions $actions -Parameters @{ phase = "optimize"; root = $rootPath; apply_approved = $ApplyApproved.IsPresent } -StartedAt $startedAt -WhatIf:$WhatIfPreference | Out-Null
Write-Host "optimize-core-rules actions: $($actions.Count)"
