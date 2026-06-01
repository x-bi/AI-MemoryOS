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

$codexGate = Get-Content -LiteralPath (Join-Path $rootPath "adapters\codex\gate.md") -Raw -Encoding UTF8
$claudeGate = Get-Content -LiteralPath (Join-Path $rootPath "adapters\claude\CLAUDE.md") -Raw -Encoding UTF8
$actions = New-Object System.Collections.Generic.List[object]
if ($ApplyApproved) {
  Assert-CTierApprovalSheetApproved -Root $rootPath -ApprovalSheet $ApprovalSheet | Out-Null
  $traceMatch = [regex]::Match($codexGate, "(?ms)^## Final Trace\r?\n.*?(?=^## |\z)")
  if ($traceMatch.Success -and ($claudeGate -notmatch "Final Trace")) {
    $traceSection = $traceMatch.Value.Trim()
    $claudePath = Join-Path $rootPath "adapters\claude\CLAUDE.md"
    $newText = $claudeGate.TrimEnd() + "`r`n`r`n" + $traceSection + "`r`n"
    if ($WhatIfPreference) {
      $actions.Add((New-AutoAction -Tier "C" -Action "apply-approved" -Target "adapters/claude/CLAUDE.md" -Status "whatif"))
    } else {
      Assert-NoSensitiveContent -Text $newText
      $utf8 = New-Object System.Text.UTF8Encoding($false)
      [System.IO.File]::WriteAllText($claudePath, $newText, $utf8)
      $actions.Add((New-AutoAction -Tier "C" -Action "apply-approved" -Target "adapters/claude/CLAUDE.md" -Status "updated"))
    }
  } else {
    $actions.Add((New-AutoAction -Tier "C" -Action "apply-approved" -Target "adapter-gate-sync" -Status "skipped no candidates"))
  }
  Write-AutoRunLog -Root $rootPath -ScriptName "optimize-adapter-gate-sync" -Actions $actions -Parameters @{ phase = "optimize"; root = $rootPath; apply_approved = $ApplyApproved.IsPresent; approval_sheet = $ApprovalSheet } -StartedAt $startedAt -WhatIf:$WhatIfPreference | Out-Null
  Write-Host "optimize-adapter-gate-sync actions: $($actions.Count)"
  return
}
if (($codexGate -match "Final Trace") -and ($claudeGate -notmatch "Final Trace")) {
  $actions.Add((New-CTierApprovalSheet -Root $rootPath -Title "Sync adapter gate trace rules" -Scope "adapter gates" -Files @("adapters/codex/gate.md", "adapters/claude/CLAUDE.md") -Reason "Codex gate and Claude gate trace sections appear drifted." -DiffPreview "Human review required." -WhatIf:$WhatIfPreference))
}
if ($actions.Count -eq 0) { $actions.Add((New-AutoAction -Tier "C" -Action "approval-sheet" -Target "adapter-gate-sync" -Status "skipped no candidates")) }

Write-AutoRunLog -Root $rootPath -ScriptName "optimize-adapter-gate-sync" -Actions $actions -Parameters @{ phase = "optimize"; root = $rootPath; apply_approved = $ApplyApproved.IsPresent } -StartedAt $startedAt -WhatIf:$WhatIfPreference | Out-Null
Write-Host "optimize-adapter-gate-sync actions: $($actions.Count)"
