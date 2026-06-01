[CmdletBinding(SupportsShouldProcess=$true)]
param(
  [string]$Root = "C:\Users\btf\AI-MemoryOS",
  [string]$ModelProfile = "",
  [ValidateSet("content-quality", "router-cleanup", "skill-health", "proposal-review", "full")][string]$Scope = "full",
  [int]$MaxFindings = 20,
  [switch]$NoModel
)

$ErrorActionPreference = "Stop"
Import-Module (Join-Path $PSScriptRoot "_shared.psm1") -Force
$startedAt = Get-Date
Test-MemoryOsRepo -Root $Root | Out-Null
$rootPath = Resolve-MemoryOsRoot -Root $Root
$modelProfileObj = Get-ModelProfile -Root $rootPath -Name $ModelProfile

$findings = New-Object System.Collections.Generic.List[object]
$sourceScripts = @("audit-content-quality", "audit-skill-coverage", "audit-router-consistency", "audit-proposal-health")
foreach ($script in $sourceScripts) {
  foreach ($finding in Get-LatestAutoRunFindings -Root $rootPath -ScriptName $script) {
    if ($findings.Count -ge $MaxFindings) { break }
    if ($finding.severity -in @("critical", "warning")) {
      $findings.Add((New-AutoFinding -Severity $finding.severity -Category "semantic-review-candidate" -Message "Deterministic audit finding selected for model semantic review." -Path $finding.path -Tier $finding.tier -Data @{ source_script = $script; source_category = $finding.category }))
    }
  }
}

$modelInvocations = 0
$modelTokens = 0
$status = "ready"
$actions = New-Object System.Collections.Generic.List[object]
$actions.Add((New-AutoAction -Tier "B" -Action "semantic-audit" -Target $modelProfileObj.name -Status ($(if ($WhatIfPreference -or $NoModel) { "local synthesis" } else { "model synthesis" }))))

if (-not $WhatIfPreference -and -not $NoModel) {
  $sourceFindings = ConvertTo-SafeArray -Value $findings
  $promptPayload = [pscustomobject]@{
    task = "semantic-audit"
    scope = $Scope
    source_findings = $sourceFindings
    instructions = @"
Return JSON only. No prose, no markdown fences. Top-level must be an object with a 'findings' array.
Each finding object MUST have ALL of these fields:
  - severity: one of "critical", "warning", "info"
  - category: short kebab-case string describing the issue type
  - message: human-readable description of the finding
  - tier: one of "A", "B", "C"
  - path: relative file path inside Memory OS, or empty string if not file-specific
Optional: evidence (array of strings).
Do not include secrets. Do not request forbidden actions.
If no findings, return {"findings": []}.
"@
  } | ConvertTo-Json -Depth 12
  $modelResult = Invoke-MemoryOsModel -Root $rootPath -Profile $modelProfileObj -Task "semantic-audit" -Prompt $promptPayload
  $modelInvocations = $modelResult.invocations
  $modelTokens = $modelResult.tokens_estimate
  if (-not [string]::IsNullOrWhiteSpace($modelResult.text)) {
    $payload = Assert-ModelOutputSchema -Root $rootPath -JsonText $modelResult.text -SchemaType findings
    $findings.Clear()
    foreach ($item in ConvertTo-AutoFindingsFromModel -Payload $payload) { $findings.Add($item) }
  }
}

if ($findings.Count -eq 0) {
  $findings.Add((New-AutoFinding -Severity "info" -Category "semantic-audit-no-candidates" -Message "No deterministic or model findings were available for semantic synthesis." -Path "" -Tier "B" -Data @{ model_profile = $modelProfileObj.name; scope = $Scope }))
}

Write-AutoRunLog -Root $rootPath -ScriptName "model-semantic-audit" -Findings $findings -Actions $actions -Parameters @{ phase = "semantic-audit"; root = $rootPath; model_profile = $modelProfileObj.name; scope = $Scope; max_findings = $MaxFindings } -StartedAt $startedAt -ModelProfile $modelProfileObj.name -ModelInvocationsCount $modelInvocations -ModelTokensEstimate $modelTokens -Status $status -WhatIf:$WhatIfPreference | Out-Null
Write-Host "model-semantic-audit findings: $($findings.Count)"
