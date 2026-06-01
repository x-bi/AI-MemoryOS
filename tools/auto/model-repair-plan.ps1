[CmdletBinding(SupportsShouldProcess=$true)]
param(
  [string]$Root = "C:\Users\btf\AI-MemoryOS",
  [string]$ModelProfile = "",
  [ValidateSet("content-quality", "router-cleanup", "skill-health", "proposal-review", "full")][string]$Scope = "full",
  [string]$RunOutputDir = "",
  [int]$MaxFindings = 12,
  [switch]$NoModel,
  [switch]$PlanOnly
)

$ErrorActionPreference = "Stop"
Import-Module (Join-Path $PSScriptRoot "_shared.psm1") -Force
$startedAt = Get-Date
Test-MemoryOsRepo -Root $Root | Out-Null
$rootPath = Resolve-MemoryOsRoot -Root $Root
$modelProfileObj = Get-ModelProfile -Root $rootPath -Name $ModelProfile

function Resolve-AutoRunDirectory {
  param(
    [string]$Root,
    [string]$Name
  )

  $logRoot = Join-Path $Root "logs\auto-runs"
  if (-not (Test-Path -LiteralPath $logRoot)) { return $null }

  if (-not [string]::IsNullOrWhiteSpace($Name)) {
    $candidate = if ([System.IO.Path]::IsPathRooted($Name)) { $Name } else { Join-Path $logRoot $Name }
    if (Test-Path -LiteralPath $candidate -PathType Container) { return $candidate }
    throw "Auto-run output directory does not exist: $Name"
  }

  if (-not [string]::IsNullOrWhiteSpace($env:AI_MEMORYOS_AUTO_RUN_OUTPUT_DIR)) {
    $candidate = Join-Path $logRoot $env:AI_MEMORYOS_AUTO_RUN_OUTPUT_DIR
    if (Test-Path -LiteralPath $candidate -PathType Container) { return $candidate }
  }

  return (Get-ChildItem -LiteralPath $logRoot -Directory |
    Where-Object { $_.Name -ne ".locks" } |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1).FullName
}

function Read-AutoRunPayloads {
  param([string]$Directory)

  if ([string]::IsNullOrWhiteSpace($Directory) -or -not (Test-Path -LiteralPath $Directory)) { return @() }
  $payloads = New-Object System.Collections.Generic.List[object]
  foreach ($file in Get-ChildItem -LiteralPath $Directory -Filter "*.md" -File -Recurse |
      Where-Object { $_.FullName -notmatch '\\approval-sheets\\' -and $_.FullName -notmatch '\\\.locks\\' } |
      Sort-Object LastWriteTime) {
    $text = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8
    $match = [regex]::Match($text, '(?s)(?:```|~~~)json\s*(\{.*?\})\s*(?:```|~~~)')
    if (-not $match.Success) { continue }
    $payload = $match.Groups[1].Value | ConvertFrom-Json
    $payload | Add-Member -NotePropertyName source_log -NotePropertyValue (Get-MemoryOsRelativePath -Root $rootPath -Path $file.FullName) -Force
    $payloads.Add($payload)
  }
  return @($payloads.ToArray())
}

function Test-AutoRepairProtectedPath {
  param([string]$RelativePath)

  $normalized = ($RelativePath -replace "\\", "/").TrimStart("/")
  if ([string]::IsNullOrWhiteSpace($normalized)) { return $true }
  foreach ($prefix in @("adapters/", "core/", "router/", "rules/", "skills/", "tools/", "logs/auto-runs/", "private/", "raw/", "proposals/accepted/", "proposals/rejected/")) {
    if ($normalized.StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase)) { return $true }
  }
  foreach ($file in @("_index.md", "GOVERNANCE.md", "INSTALL.md", "README.md", "ROADMAP.md", "STATUS.md")) {
    if ($normalized.Equals($file, [System.StringComparison]::OrdinalIgnoreCase)) { return $true }
  }
  return $false
}

function Invoke-ModelTextEdits {
  param(
    [string]$Root,
    [object[]]$Edits
  )

  $rootPath = Resolve-MemoryOsRoot -Root $Root
  $applied = New-Object System.Collections.Generic.List[object]
  foreach ($edit in @($Edits)) {
    $relativePath = [string]$edit.path
    if ([string]::IsNullOrWhiteSpace($relativePath)) { throw "Model edit missing path." }
    if (Test-AutoRepairProtectedPath -RelativePath $relativePath) {
      throw "Model edit targets protected path that requires review: $relativePath"
    }
    $path = Resolve-MemoryOsRelativePath -Root $rootPath -RelativePath $relativePath
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Model edit target file does not exist: $relativePath" }
    $oldText = [string]$edit.old_text
    $newText = [string]$edit.new_text
    if ([string]::IsNullOrEmpty($oldText)) { throw "Model edit for '$relativePath' missing old_text." }

    $text = Get-Content -LiteralPath $path -Raw -Encoding UTF8
    $matches = [regex]::Matches($text, [regex]::Escape($oldText)).Count
    if ($matches -ne 1) {
      throw "Model edit for '$relativePath' expected exactly one old_text match, found $matches."
    }
    $updated = $text.Replace($oldText, $newText)
    Assert-NoSensitiveContent -Text $updated
    Write-MemoryOsTextFile -Path $path -Content $updated
    $applied.Add((Get-MemoryOsRelativePath -Root $rootPath -Path $path))
  }

  & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $rootPath "tools\validate-memory-os.ps1") -Root $rootPath | Out-Null
  return @($applied.ToArray())
}

$actions = New-Object System.Collections.Generic.List[object]
$findings = New-Object System.Collections.Generic.List[object]
$runDir = Resolve-AutoRunDirectory -Root $rootPath -Name $RunOutputDir
$runDirRelative = if ($null -ne $runDir) { Get-MemoryOsRelativePath -Root $rootPath -Path $runDir } else { "" }

foreach ($payload in Read-AutoRunPayloads -Directory $runDir) {
  foreach ($finding in @($payload.findings)) {
    if ($findings.Count -ge $MaxFindings) { break }
    $severity = [string]$finding.severity
    $tier = [string]$finding.tier
    if ($severity -in @("critical", "warning") -or $tier -in @("B", "C")) {
      $data = @{
        source_log = [string]$payload.source_log
        source_category = [string]$finding.category
      }
      if ($null -ne $finding.data) { $data.source_data = $finding.data }
      $findings.Add((New-AutoFinding -Severity $severity -Category "repair-candidate" -Message ([string]$finding.message) -Path ([string]$finding.path) -Tier $tier -Data $data))
    }
  }
}

$modelInvocations = 0
$modelTokens = 0
$status = "ready"

if ($findings.Count -eq 0) {
  $findings.Add((New-AutoFinding -Severity "info" -Category "repair-plan-no-candidates" -Message "No critical, warning, B-tier, or C-tier findings were available for model repair planning." -Path $runDirRelative -Tier "B" -Data @{ model_profile = $modelProfileObj.name; scope = $Scope } ))
  $actions.Add((New-AutoAction -Tier "B" -Action "model-repair-plan" -Target $runDirRelative -Status "skipped no candidates"))
} elseif ($WhatIfPreference -or $NoModel) {
  $actions.Add((New-AutoAction -Tier "B" -Action "model-repair-plan" -Target $runDirRelative -Status ($(if ($WhatIfPreference) { "whatif" } else { "local synthesis" }))))
} else {
  $sourceFindings = ConvertTo-SafeArray -Value $findings
  $promptPayload = [pscustomobject]@{
    task = "suggest-repair"
    scope = $Scope
    run_output_dir = $runDirRelative
    source_findings = $sourceFindings
    instructions = @"
Return JSON only. No prose, no markdown fences.
Top-level must be one object with these required fields:
  - action: use "apply-edits" for direct A/B-tier safe-path fixes, "draft-proposal" when a direct fix is not reliable, or "approval-sheet" for C-tier/core-rule/gate/router changes.
  - tier: one of "A", "B", or "C". Use C only for core rules, adapter gates, routing policy, security, permissions, release process, or protected paths.
  - target: relative file path or area inside Memory OS. Use "proposals/pending" for proposal drafts when no single file is enough.
Recommended optional fields:
  - edits: array of objects with path, old_text, new_text, and optional reason. Use only for direct safe-path fixes.
  - proposal_title: short title for B-tier proposal
  - approval_sheet_title: short title for C-tier approval sheet
  - summary: concise repair intent
  - patch: markdown draft with concrete steps, acceptance checks, and validation command.
Do not include secrets. Do not request merge, push, force-push, reset, delete, path-outside, skip-validate, or direct git actions.
Protected paths require approval-sheet: adapters/, core/, router/, rules/, skills/, tools/, logs/auto-runs/, private/, raw/, proposals/accepted/, proposals/rejected/, _index.md, GOVERNANCE.md, INSTALL.md, README.md, ROADMAP.md, STATUS.md.
Prefer apply-edits for docs/, dashboard/, proposals/pending/, and other non-protected Markdown content when the old_text is exact and the repair is clear.
"@
  } | ConvertTo-Json -Depth 12

  $modelResult = Invoke-MemoryOsModel -Root $rootPath -Profile $modelProfileObj -Task "suggest-repair" -Prompt $promptPayload
  $modelInvocations = $modelResult.invocations
  $modelTokens = $modelResult.tokens_estimate
  $actionPayload = Assert-ModelOutputSchema -Root $rootPath -JsonText $modelResult.text -SchemaType action

  $tier = [string]$actionPayload.tier
  $summary = [string]$actionPayload.summary
  if ([string]::IsNullOrWhiteSpace($summary)) { $summary = "Model-suggested repair plan for auto-run findings." }
  $draft = [string]$actionPayload.patch
  if ([string]::IsNullOrWhiteSpace($draft)) {
    $draft = @"
## Model Repair Plan

$summary

## Source

- Scope: $Scope
- Run output: $runDirRelative
- Model profile: $($modelProfileObj.name)

## Acceptance

- Relevant findings are addressed or explicitly deferred.
- `powershell -NoProfile -ExecutionPolicy Bypass -File tools\validate-memory-os.ps1` passes.
"@
  }

  $edits = @()
  if ($null -ne $actionPayload.edits) { $edits = @($actionPayload.edits) }

  if ($tier -eq "C") {
    $title = [string]$actionPayload.approval_sheet_title
    if ([string]::IsNullOrWhiteSpace($title)) { $title = "Model repair approval: $Scope" }
    $target = [string]$actionPayload.target
    if ([string]::IsNullOrWhiteSpace($target)) { $target = $runDirRelative }
    $actions.Add((New-CTierApprovalSheet -Root $rootPath -Title $title -Scope $Scope -Files @($target) -Reason $summary -DiffPreview $draft -WhatIf:$WhatIfPreference))
  } elseif ([string]$actionPayload.action -eq "apply-edits" -and $edits.Count -gt 0 -and -not $PlanOnly) {
    $appliedPaths = Invoke-ModelTextEdits -Root $rootPath -Edits $edits
    foreach ($appliedPath in @($appliedPaths)) {
      $actions.Add((New-AutoAction -Tier $tier -Action "apply-edits" -Target $appliedPath -Status "updated"))
    }
  } else {
    $title = [string]$actionPayload.proposal_title
    if ([string]::IsNullOrWhiteSpace($title)) { $title = "Model repair proposal: $Scope" }
    $actions.Add((New-BTierProposal -Root $rootPath -Title $title -Summary $summary -Trigger "model-repair-plan" -RelatedTask $runDirRelative -Destination "proposal" -Draft $draft -WhatIf:$WhatIfPreference))
  }
}

Write-AutoRunLog -Root $rootPath -ScriptName "model-repair-plan" -Findings $findings -Actions $actions -Parameters @{ phase = "repair-plan"; root = $rootPath; model_profile = $modelProfileObj.name; scope = $Scope; run_output_dir = $runDirRelative; max_findings = $MaxFindings; plan_only = $PlanOnly.IsPresent } -StartedAt $startedAt -ModelProfile $modelProfileObj.name -ModelInvocationsCount $modelInvocations -ModelTokensEstimate $modelTokens -Status $status -WhatIf:$WhatIfPreference | Out-Null
Write-Host "model-repair-plan findings: $($findings.Count) actions: $($actions.Count)"
