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
$findings = @(Get-LatestAutoRunFindings -Root $rootPath -ScriptName "audit-proposal-health" | Where-Object { $_.category -eq "promotion-candidate" })
$actions = New-Object System.Collections.Generic.List[object]
$updated = 0

foreach ($finding in $findings) {
  if ($updated -ge $MaxProposals) {
    $actions.Add([pscustomobject]@{ tier = "B"; action = "mark-promotion-candidate"; target = $finding.path; status = "skipped max proposals" })
    continue
  }
  $proposalPath = Resolve-MemoryOsRelativePath -Root $rootPath -RelativePath ([string]$finding.path)
  if (-not (Test-Path -LiteralPath $proposalPath)) {
    $actions.Add([pscustomobject]@{ tier = "B"; action = "mark-promotion-candidate"; target = $finding.path; status = "skipped missing file" })
    continue
  }
  $text = Get-Content -LiteralPath $proposalPath -Raw -Encoding UTF8
  if ($text -match '## Auto-detected promotion candidate') {
    $actions.Add([pscustomobject]@{ tier = "B"; action = "mark-promotion-candidate"; target = $finding.path; status = "skipped duplicate marker" })
    continue
  }
  $append = @"

## Auto-detected promotion candidate

- Detected at: $(Get-Date -Format "yyyy-MM-dd")
- Source: audit-proposal-health
- Reason: $($finding.message)
- Note: This marker does not promote the proposal. Human review is still required.
"@
  if ($WhatIfPreference) {
    Write-Host "WhatIf: would append promotion marker to $($finding.path)"
    $actions.Add([pscustomobject]@{ tier = "B"; action = "mark-promotion-candidate"; target = $finding.path; status = "whatif" })
    $updated++
    continue
  }
  Assert-NoSensitiveContent -Text $append
  # Add-Content on Windows writes CRLF and may add a BOM; the repo stores .md
  # as LF without BOM. Read-modify-write through Write-MemoryOsTextFile keeps
  # it idempotent.
  $existing = Get-Content -LiteralPath $proposalPath -Raw -Encoding UTF8
  if ($null -eq $existing) { $existing = "" }
  Write-MemoryOsTextFile -Path $proposalPath -Content ($existing.TrimEnd("`n") + "`n" + $append)
  $actions.Add([pscustomobject]@{ tier = "B"; action = "mark-promotion-candidate"; target = $finding.path; status = "updated" })
  $updated++
}

if ($actions.Count -eq 0) {
  $actions.Add([pscustomobject]@{ tier = "B"; action = "mark-promotion-candidate"; target = "proposal-health"; status = "skipped no candidates" })
}

Write-AutoRunLog -Root $rootPath -ScriptName "iterate-promotion-candidates" -Findings $findings -Actions $actions -Parameters @{ phase = "iterate"; root = $rootPath; max_proposals = $MaxProposals } -StartedAt $startedAt -WhatIf:$WhatIfPreference | Out-Null
Write-Host "iterate-promotion-candidates actions: $($actions.Count)"
