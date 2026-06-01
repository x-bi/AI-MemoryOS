[CmdletBinding(SupportsShouldProcess=$true)]
param(
  [string]$Root = "C:\Users\btf\AI-MemoryOS",
  [string]$ModelProfile = "",
  [ValidateSet("content-quality", "router-cleanup", "skill-health", "proposal-review", "full")][string]$Scope = "full",
  [string]$RunOutputDir = "",
  [int]$MaxOpportunities = 8,
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
    Where-Object { $_.Name -notin @(".locks", "approval-sheets") } |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1).FullName
}

function Test-OpportunityProtectedPath {
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

function Invoke-OpportunityTextEdits {
  param(
    [string]$Root,
    [object[]]$Edits
  )

  $rootPath = Resolve-MemoryOsRoot -Root $Root
  $applied = New-Object System.Collections.Generic.List[object]
  foreach ($edit in @($Edits)) {
    $relativePath = [string]$edit.path
    if ([string]::IsNullOrWhiteSpace($relativePath)) { throw "Opportunity edit missing path." }
    if (Test-OpportunityProtectedPath -RelativePath $relativePath) {
      throw "Opportunity edit targets protected path that requires review: $relativePath"
    }
    $path = Resolve-MemoryOsRelativePath -Root $rootPath -RelativePath $relativePath
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Opportunity edit target file does not exist: $relativePath" }

    $oldText = [string]$edit.old_text
    $newText = [string]$edit.new_text
    if ([string]::IsNullOrEmpty($oldText)) { throw "Opportunity edit for '$relativePath' missing old_text." }

    $text = Get-Content -LiteralPath $path -Raw -Encoding UTF8
    $matches = [regex]::Matches($text, [regex]::Escape($oldText)).Count
    if ($matches -ne 1) {
      throw "Opportunity edit for '$relativePath' expected exactly one old_text match, found $matches."
    }
    $updated = $text.Replace($oldText, $newText)
    Assert-NoSensitiveContent -Text $updated
    Write-MemoryOsTextFile -Path $path -Content $updated
    $applied.Add((Get-MemoryOsRelativePath -Root $rootPath -Path $path))
  }

  & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $rootPath "tools\validate-memory-os.ps1") -Root $rootPath | Out-Null
  return @($applied.ToArray())
}

function Assert-OpportunityPayload {
  param(
    [string]$Root,
    [string]$JsonText
  )

  Assert-NoSensitiveContent -Text $JsonText
  $payload = $JsonText | ConvertFrom-Json
  if ($null -eq $payload.opportunities) { throw "Opportunity output missing required property: opportunities" }

  foreach ($item in @($payload.opportunities)) {
    foreach ($required in @("title", "scale", "tier", "category", "summary", "handling", "target")) {
      if ($null -eq $item.PSObject.Properties[$required] -or [string]::IsNullOrWhiteSpace([string]$item.$required)) {
        throw "Opportunity missing required property: $required"
      }
    }
    if ($item.scale -notin @("micro", "small", "medium", "large")) { throw "Invalid opportunity scale: $($item.scale)" }
    if ($item.tier -notin @("A", "B", "C")) { throw "Invalid opportunity tier: $($item.tier)" }
    if ($item.handling -notin @("apply-edits", "draft-proposal", "approval-sheet", "report-only")) {
      throw "Invalid opportunity handling: $($item.handling)"
    }
    if (-not [string]::IsNullOrWhiteSpace([string]$item.target)) {
      $target = [string]$item.target
      if ([System.IO.Path]::IsPathRooted($target)) {
        if (-not (Test-MemoryOsPathInside -ChildPath $target -ParentPath (Resolve-MemoryOsRoot -Root $Root))) {
          throw "Opportunity target escapes Memory OS root: $target"
        }
      } elseif ($target -notin @("repository", "multiple", "future-direction", "proposal")) {
        Resolve-MemoryOsRelativePath -Root $Root -RelativePath $target | Out-Null
      }
    }
  }
  return $payload
}

function Get-OpportunityRunContext {
  param(
    [string]$Root,
    [string]$Directory
  )

  $rootPath = Resolve-MemoryOsRoot -Root $Root
  $items = New-Object System.Collections.Generic.List[object]

  foreach ($relative in @("docs\auto-run-usage.md", "dashboard\auto-runs.md", "tools\auto\COMMANDS.md")) {
    $path = Join-Path $rootPath $relative
    if (Test-Path -LiteralPath $path -PathType Leaf) {
      $text = Get-Content -LiteralPath $path -Raw -Encoding UTF8
      $items.Add([pscustomobject]@{
        path = ($relative -replace "\\", "/")
        excerpt = $text.Substring(0, [Math]::Min($text.Length, 1800))
      })
    }
  }

  if (-not [string]::IsNullOrWhiteSpace($Directory) -and (Test-Path -LiteralPath $Directory)) {
    foreach ($file in Get-ChildItem -LiteralPath $Directory -Filter "*.md" -File | Sort-Object Name | Select-Object -First 8) {
      $text = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8
      $items.Add([pscustomobject]@{
        path = Get-MemoryOsRelativePath -Root $rootPath -Path $file.FullName
        excerpt = $text.Substring(0, [Math]::Min($text.Length, 1200))
      })
    }
  }

  return @($items.ToArray())
}

$actions = New-Object System.Collections.Generic.List[object]
$findings = New-Object System.Collections.Generic.List[object]
$runDir = Resolve-AutoRunDirectory -Root $rootPath -Name $RunOutputDir
$runDirRelative = if ($null -ne $runDir) { Get-MemoryOsRelativePath -Root $rootPath -Path $runDir } else { "" }
$modelInvocations = 0
$modelTokens = 0
$status = "ready"

$actions.Add((New-AutoAction -Tier "B" -Action "opportunity-radar" -Target $modelProfileObj.name -Status ($(if ($WhatIfPreference -or $NoModel) { "local synthesis" } else { "model synthesis" }))))

if ($WhatIfPreference -or $NoModel) {
  $findings.Add((New-AutoFinding -Severity "info" -Category "opportunity-radar-ready" -Message "Opportunity radar would discover broad improvement candidates, apply only safe micro/small edits, and report medium/large ideas without direct landing." -Path $runDirRelative -Tier "B" -Data @{ principle = "discover broadly, apply narrowly"; model_profile = $modelProfileObj.name; scope = $Scope }))
} else {
  $context = Get-OpportunityRunContext -Root $rootPath -Directory $runDir
  $promptPayload = [pscustomobject]@{
    task = "discover-opportunities"
    scope = $Scope
    max_opportunities = $MaxOpportunities
    run_output_dir = $runDirRelative
    context = $context
    instructions = @"
Return JSON only. No prose, no markdown fences.
Top-level must be one object with an opportunities array.
Each opportunity MUST have:
  - title: concise human-readable title
  - scale: one of "micro", "small", "medium", "large"
  - tier: one of "A", "B", "C"
  - category: short kebab-case string
  - summary: what was discovered
  - project_fit: why it fits or does not fit AI-MemoryOS
  - handling: one of "apply-edits", "draft-proposal", "approval-sheet", "report-only"
  - target: relative path, "multiple", "repository", "proposal", or "future-direction"
Optional:
  - implementation_plan: short concrete landing plan
  - validation_plan: validation command or check
  - edits: exact-match edits for safe direct landing, each with path, old_text, new_text, reason
  - proposal_title
  - approval_sheet_title
  - patch: markdown draft for proposal or approval sheet
Principle: discover broadly, apply narrowly.
Micro/small A/B opportunities may use apply-edits only for safe non-protected paths such as docs/, dashboard/, and proposals/pending/.
Medium/large opportunities may be reported or drafted as proposals, but must not be directly applied.
C-tier, protected paths, governance, security, adapters, router, rules, skills, tools, and release-process changes must use approval-sheet or report-only.
Do not include secrets. Do not request merge, push, force-push, reset, delete, path-outside, skip-validate, or direct git actions.
Protected paths: adapters/, core/, router/, rules/, skills/, tools/, logs/auto-runs/, private/, raw/, proposals/accepted/, proposals/rejected/, _index.md, GOVERNANCE.md, INSTALL.md, README.md, ROADMAP.md, STATUS.md.
Prefer practical details: what was found, what plan was chosen, what would change, and how it should be validated.
If no good candidates exist, return {"opportunities":[]}.
"@
  } | ConvertTo-Json -Depth 12

  $modelResult = Invoke-MemoryOsModel -Root $rootPath -Profile $modelProfileObj -Task "discover-opportunities" -Prompt $promptPayload
  $modelInvocations = $modelResult.invocations
  $modelTokens = $modelResult.tokens_estimate
  $payload = Assert-OpportunityPayload -Root $rootPath -JsonText $modelResult.text

  foreach ($item in @($payload.opportunities | Select-Object -First $MaxOpportunities)) {
    $scale = [string]$item.scale
    $tier = [string]$item.tier
    $handling = [string]$item.handling
    $title = [string]$item.title
    $target = [string]$item.target
    $summary = [string]$item.summary
    $projectFit = [string]$item.project_fit
    $message = "$title -- $summary Project fit: $projectFit"
    $severity = if ($tier -eq "C" -or $scale -in @("medium", "large")) { "warning" } else { "info" }
    $findings.Add((New-AutoFinding -Severity $severity -Category ([string]$item.category) -Message $message -Path $target -Tier $tier -Data @{ scale = $scale; handling = $handling; implementation_plan = [string]$item.implementation_plan; validation_plan = [string]$item.validation_plan } ))

    $edits = @()
    if ($null -ne $item.edits) { $edits = @($item.edits) }
    $canApply = $handling -eq "apply-edits" -and $scale -in @("micro", "small") -and $tier -in @("A", "B") -and $edits.Count -gt 0 -and -not $PlanOnly

    if ($canApply) {
      $appliedPaths = Invoke-OpportunityTextEdits -Root $rootPath -Edits $edits
      foreach ($appliedPath in @($appliedPaths)) {
        $actions.Add((New-AutoAction -Tier $tier -Action "apply-opportunity-edits" -Target $appliedPath -Status "updated and validated"))
      }
    } elseif ($handling -eq "approval-sheet" -or $tier -eq "C") {
      $approvalTitle = [string]$item.approval_sheet_title
      if ([string]::IsNullOrWhiteSpace($approvalTitle)) { $approvalTitle = "Opportunity approval: $title" }
      $draft = [string]$item.patch
      if ([string]::IsNullOrWhiteSpace($draft)) {
        $draft = "## Opportunity`n`n$summary`n`n## Project fit`n`n$projectFit`n`n## Validation`n`n$([string]$item.validation_plan)"
      }
      $actions.Add((New-CTierApprovalSheet -Root $rootPath -Title $approvalTitle -Scope $Scope -Files @($target) -Reason $summary -DiffPreview $draft -WhatIf:$WhatIfPreference))
    } elseif ($handling -eq "draft-proposal" -and $scale -ne "large") {
      $proposalTitle = [string]$item.proposal_title
      if ([string]::IsNullOrWhiteSpace($proposalTitle)) { $proposalTitle = "Opportunity proposal: $title" }
      $draft = [string]$item.patch
      if ([string]::IsNullOrWhiteSpace($draft)) {
        $draft = @"
## Opportunity

$summary

## Project fit

$projectFit

## Landing plan

$([string]$item.implementation_plan)

## Validation

$([string]$item.validation_plan)
"@
      }
      $actions.Add((New-BTierProposal -Root $rootPath -Title $proposalTitle -Summary $summary -Trigger "model-opportunity-radar" -RelatedTask $runDirRelative -Destination "proposal" -Draft $draft -WhatIf:$WhatIfPreference))
    } else {
      $statusText = if ($PlanOnly) { "reported plan-only" } elseif ($scale -eq "large") { "reported large opportunity only" } else { "reported only" }
      $actions.Add((New-AutoAction -Tier $tier -Action "report-opportunity" -Target $title -Status $statusText))
    }
  }

  if ($findings.Count -eq 0) {
    $findings.Add((New-AutoFinding -Severity "info" -Category "opportunity-radar-no-candidates" -Message "No useful micro, small, medium, or large opportunities were returned by the model." -Path $runDirRelative -Tier "B" -Data @{ model_profile = $modelProfileObj.name; scope = $Scope }))
  }
}

Write-AutoRunLog -Root $rootPath -ScriptName "model-opportunity-radar" -Findings $findings -Actions $actions -Parameters @{ phase = "opportunity"; root = $rootPath; model_profile = $modelProfileObj.name; scope = $Scope; run_output_dir = $runDirRelative; max_opportunities = $MaxOpportunities; plan_only = $PlanOnly.IsPresent; principle = "discover broadly, apply narrowly" } -StartedAt $startedAt -ModelProfile $modelProfileObj.name -ModelInvocationsCount $modelInvocations -ModelTokensEstimate $modelTokens -Status $status -WhatIf:$WhatIfPreference | Out-Null
Write-Host "model-opportunity-radar findings: $($findings.Count) actions: $($actions.Count)"
