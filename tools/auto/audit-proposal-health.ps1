[CmdletBinding(SupportsShouldProcess=$true)]
param(
  [string]$Root = "C:\Users\btf\AI-MemoryOS",
  [int]$StaleDays = 30
)

$ErrorActionPreference = "Stop"
Import-Module (Join-Path $PSScriptRoot "_shared.psm1") -Force
$startedAt = Get-Date
Test-MemoryOsRepo -Root $Root | Out-Null

$rootPath = Resolve-MemoryOsRoot -Root $Root
$findings = New-Object System.Collections.Generic.List[object]
$pendingDir = Join-Path $rootPath "proposals\pending"
$titleMap = @{}

if (Test-Path -LiteralPath $pendingDir) {
  foreach ($file in Get-ChildItem -LiteralPath $pendingDir -Filter "*.md" -File -Recurse) {
    $relative = Get-MemoryOsRelativePath -Root $rootPath -Path $file.FullName
    $text = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8
    if (-not $text.StartsWith("---")) {
      $findings.Add((New-AutoFinding -Severity "critical" -Category "proposal-missing-frontmatter" -Message "Pending proposal is missing frontmatter." -Path $relative -Tier "B"))
      continue
    }
    foreach ($field in @("title", "type", "status", "created_at")) {
      if ($text -notmatch "(?m)^${field}:\s*\S") {
        $findings.Add((New-AutoFinding -Severity "critical" -Category "proposal-missing-frontmatter-field" -Message "Pending proposal missing frontmatter field: $field" -Path $relative -Tier "B" -Data @{ field = $field }))
      }
    }
    if ($text -notmatch "(?m)^status:\s*pending\s*$") {
      $findings.Add((New-AutoFinding -Severity "critical" -Category "proposal-status-mismatch" -Message "Pending proposal does not declare status: pending." -Path $relative -Tier "B"))
    }
    $created = [datetime]::MinValue
    $hasCreated = $false
    if ($text -match "(?m)^created_at:\s*[""']?([^""'\r\n]+)") {
      $hasCreated = [datetime]::TryParse($matches[1], [ref]$created)
    }
    if (-not $hasCreated -and $file.BaseName -match '^(\d{4}-\d{2}-\d{2})') {
      $hasCreated = [datetime]::TryParse($matches[1], [ref]$created)
    }
    if ($hasCreated) {
      $age = [int]((Get-Date) - $created).TotalDays
      if ($age -gt $StaleDays) {
        $findings.Add((New-AutoFinding -Severity "warning" -Category "stale-pending-proposal" -Message "Pending proposal is older than $StaleDays days." -Path $relative -Tier "B" -Data @{ age_days = $age }))
      }
      if ($age -ge 7) {
        $findings.Add((New-AutoFinding -Severity "info" -Category "promotion-candidate" -Message "Pending proposal is old enough for human promotion review." -Path $relative -Tier "B" -Data @{ age_days = $age }))
      }
    }
    $title = $file.BaseName
    if ($text -match "(?m)^#\s+Proposal:\s*(.+?)\s*$") { $title = $matches[1].Trim() }
    $normalizedTitle = ConvertTo-AutoSlug -Text $title
    if (-not $titleMap.ContainsKey($normalizedTitle)) { $titleMap[$normalizedTitle] = New-Object System.Collections.Generic.List[string] }
    $titleMap[$normalizedTitle].Add($relative)
  }
}

foreach ($entry in $titleMap.GetEnumerator()) {
  if ($entry.Value.Count -gt 1) {
    $paths = @($entry.Value)
    $findings.Add((New-AutoFinding -Severity "warning" -Category "duplicate-proposal-topic" -Message "Multiple pending proposals appear to share a topic." -Path ($paths -join "; ") -Tier "B" -Data @{ files = $paths }))
  }
}

foreach ($dirInfo in @(@{ path = "proposals\accepted"; status = "accepted" }, @{ path = "proposals\rejected"; status = "rejected" })) {
  $dir = Join-Path $rootPath $dirInfo.path
  if (-not (Test-Path -LiteralPath $dir)) { continue }
  foreach ($file in Get-ChildItem -LiteralPath $dir -Filter "*.md" -File) {
    $relative = Get-MemoryOsRelativePath -Root $rootPath -Path $file.FullName
    $text = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8
    if ($text -notmatch "(?m)^decision_reason:\s*\S" -and $text -notmatch "(?m)^##\s+(Reason|Decision Reason|Acceptance Reason|Rejection Reason)\s*$") {
      $findings.Add((New-AutoFinding -Severity "critical" -Category "proposal-missing-decision-reason" -Message "$($dirInfo.status) proposal is missing decision reason." -Path $relative -Tier "B"))
    }
  }
}

Write-AutoRunLog -Root $rootPath -ScriptName "audit-proposal-health" -Findings $findings -Parameters @{ phase = "audit"; root = $rootPath; stale_days = $StaleDays } -StartedAt $startedAt -WhatIf:$WhatIfPreference | Out-Null
Write-Host "audit-proposal-health findings: $($findings.Count)"
