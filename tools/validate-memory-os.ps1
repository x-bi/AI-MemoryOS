param(
  [string]$Root = "C:\Users\btf\AI-MemoryOS"
)

$ErrorActionPreference = "Stop"

function Get-MemoryOsRelativePath {
  param(
    [string]$RootPath,
    [string]$Path
  )

  $resolvedRoot = (Resolve-Path -LiteralPath $RootPath).Path.TrimEnd("\", "/")
  $resolvedPath = (Resolve-Path -LiteralPath $Path).Path
  if ($resolvedPath.StartsWith($resolvedRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
    return $resolvedPath.Substring($resolvedRoot.Length).TrimStart("\", "/")
  }
  return $resolvedPath
}

function Test-MemoryOsPathInside {
  param(
    [string]$ChildPath,
    [string]$ParentPath
  )

  $childFull = [System.IO.Path]::GetFullPath($ChildPath).TrimEnd("\", "/")
  $parentFull = [System.IO.Path]::GetFullPath($ParentPath).TrimEnd("\", "/")
  return $childFull.Equals($parentFull, [System.StringComparison]::OrdinalIgnoreCase) -or
    $childFull.StartsWith($parentFull + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase)
}

function Resolve-MemoryOsRelativePath {
  param(
    [string]$RootPath,
    [string]$RelativePath
  )

  if ([string]::IsNullOrWhiteSpace($RelativePath)) {
    throw "Relative path is required"
  }
  if ([System.IO.Path]::IsPathRooted($RelativePath)) {
    throw "Absolute paths are not allowed: $RelativePath"
  }

  $rootFull = [System.IO.Path]::GetFullPath((Resolve-Path -LiteralPath $RootPath).Path)
  $full = [System.IO.Path]::GetFullPath((Join-Path $rootFull ($RelativePath -replace '/', '\')))
  if (-not (Test-MemoryOsPathInside -ChildPath $full -ParentPath $rootFull)) {
    throw "Path escapes Memory OS root: $RelativePath"
  }
  return $full
}

function Test-ExcludedRepositoryScanPath {
  param(
    [string]$RelativePath
  )

  $normalized = $RelativePath -replace '\\', '/'
  if ($normalized -eq ".git" -or $normalized.StartsWith(".git/")) { return $true }
  if ($normalized -eq "node_modules" -or $normalized.StartsWith("node_modules/")) { return $true }
  if ($normalized -eq "private" -or $normalized.StartsWith("private/")) { return $true }
  if ($normalized -eq ".obsidian/cache" -or $normalized.StartsWith(".obsidian/cache/")) { return $true }
  if ($normalized -match '^\.obsidian/workspace.*\.json$') { return $true }
  return $false
}

$skillRegistryPath = Join-Path $Root "skills\registry.json"

$required = @(
  "_index.md",
  "STATUS.md",
  "GOVERNANCE.md",
  "skills\registry.json",
  "adapters\codex\templates\skill.md.tmpl",
  "adapters\claude\templates\skill.md.tmpl",
  "adapters\codex\gate.md",
  "adapters\codex\external-config.md",
  "adapters\claude\CLAUDE.md",
  "adapters\claude\external-config.md",
  "router\intent-map.md",
  "router\domain-map.md",
  "router\skill-map.md",
  "workflows\skill-maintenance.md",
  "evals\router-test-cases.md",
  "evals\skill-trigger-test-cases.md",
  "dashboard\home.md",
  "dashboard\skills.md",
  "dashboard\future-directions.md",
  "templates\proposal.md",
  "templates\router-correction-proposal.md",
  "templates\weekly-audit.md",
  "tools\sync-skills.ps1",
  "adapters\mcp\README.md",
  "adapters\mcp\tool-policy.md",
  "adapters\mcp\server\obsidian-memory-os-mcp.mjs"
)

if (Test-Path -LiteralPath $skillRegistryPath) {
  $skillRegistryForRequired = Get-Content -LiteralPath $skillRegistryPath -Raw -Encoding UTF8 | ConvertFrom-Json
  foreach ($skillConfig in @($skillRegistryForRequired.skills | Where-Object { $_.managed -eq $true })) {
    if (-not [string]::IsNullOrWhiteSpace([string]$skillConfig.source)) {
      $required += ([string]$skillConfig.source -replace '/', '\')
    }
    foreach ($adapterName in @("codex", "claude")) {
      $adapter = $skillConfig.adapters.$adapterName
      if ($null -ne $adapter -and $adapter.enabled -eq $true -and -not [string]::IsNullOrWhiteSpace([string]$adapter.output)) {
        $required += ([string]$adapter.output -replace '/', '\')
      }
    }
  }
}

$missing = @()
foreach ($item in $required) {
  $path = Join-Path $Root $item
  if (-not (Test-Path -LiteralPath $path)) { $missing += $item }
}

$bomFiles = @()
$skillFilesToCheck = @()
$activeSkills = @("memory-curator", "routing-auditor", "bugfix-with-regression-test", "frontend-component-review", "pr-review", "vue-change-self-check", "git-ops-guide")
if (Test-Path -LiteralPath $skillRegistryPath) {
  $skillRegistryForActiveList = Get-Content -LiteralPath $skillRegistryPath -Raw -Encoding UTF8 | ConvertFrom-Json
  $activeSkills = @($skillRegistryForActiveList.skills | Where-Object { $_.status -eq "active" } | ForEach-Object { [string]$_.name })
}
foreach ($skill in $activeSkills) {
  $skillFilesToCheck += (Join-Path $Root "adapters\codex\skills\$skill\SKILL.md")
  $skillFilesToCheck += (Join-Path $env:USERPROFILE ".codex\skills\$skill\SKILL.md")
  $skillFilesToCheck += (Join-Path $Root "adapters\claude\skills\$skill\SKILL.md")
  $skillFilesToCheck += (Join-Path $env:USERPROFILE ".claude\skills\$skill\SKILL.md")
}
foreach ($path in $skillFilesToCheck) {
  if (-not (Test-Path -LiteralPath $path)) { continue }
  $bytes = [System.IO.File]::ReadAllBytes($path)
  if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
    $bomFiles += $path
  }
}

$codexSkillRoot = Join-Path $env:USERPROFILE ".codex\skills"
$missingCodexSkills = @()
$nonJunctionCodexSkills = @()
$wrongTargetCodexSkills = @()
foreach ($skill in $activeSkills) {
  $codexPath = Join-Path $codexSkillRoot $skill
  $codexSkillFile = Join-Path $codexPath "SKILL.md"
  if (-not (Test-Path -LiteralPath $codexSkillFile)) {
    $missingCodexSkills += $skill
    continue
  }

  $codexItem = Get-Item -LiteralPath $codexPath -Force
  if ($codexItem.LinkType -notin @("Junction", "SymbolicLink")) {
    $nonJunctionCodexSkills += $skill
    continue
  }

  $expectedTarget = Join-Path $Root "adapters\codex\skills\$skill"
  $actualTarget = @($codexItem.Target)[0]
  if ([string]::IsNullOrWhiteSpace($actualTarget) -or ((Resolve-Path -LiteralPath $actualTarget).Path -ne (Resolve-Path -LiteralPath $expectedTarget).Path)) {
    $wrongTargetCodexSkills += $skill
  }
}

$claudeSkillRoot = Join-Path $env:USERPROFILE ".claude\skills"
$missingClaudeSkills = @()
$nonJunctionClaudeSkills = @()
$wrongTargetClaudeSkills = @()
$claudeGateSyncProblems = @()
foreach ($skill in $activeSkills) {
  $claudePath = Join-Path $claudeSkillRoot $skill
  $claudeSkillFile = Join-Path $claudePath "SKILL.md"
  if (-not (Test-Path -LiteralPath $claudeSkillFile)) {
    $missingClaudeSkills += $skill
    continue
  }

  $claudeItem = Get-Item -LiteralPath $claudePath -Force
  if ($claudeItem.LinkType -notin @("Junction", "SymbolicLink")) {
    $nonJunctionClaudeSkills += $skill
    continue
  }

  $expectedTarget = Join-Path $Root "adapters\claude\skills\$skill"
  $actualTarget = @($claudeItem.Target)[0]
  if ([string]::IsNullOrWhiteSpace($actualTarget) -or ((Resolve-Path -LiteralPath $actualTarget).Path -ne (Resolve-Path -LiteralPath $expectedTarget).Path)) {
    $wrongTargetClaudeSkills += $skill
  }
}

$claudeAdapterGate = Join-Path $Root "adapters\claude\CLAUDE.md"
$claudeUserGate = Join-Path $env:USERPROFILE ".claude\CLAUDE.md"
if (Test-Path -LiteralPath $claudeAdapterGate) {
  if (-not (Test-Path -LiteralPath $claudeUserGate)) {
    $claudeGateSyncProblems += "Missing user Claude gate: $claudeUserGate"
  } else {
    $userGateText = Get-Content -LiteralPath $claudeUserGate -Raw -Encoding UTF8
    if ($userGateText -notmatch 'AI-MemoryOS\\adapters\\claude\\CLAUDE\.md') {
      $claudeGateSyncProblems += "User Claude gate is not a bootstrap redirect to adapters\claude\CLAUDE.md"
    }
  }
}

$templateChecks = @(
  "templates\proposal.md",
  "templates\router-correction-proposal.md",
  "templates\weekly-audit.md"
)
$badTemplates = @()
foreach ($item in $templateChecks) {
  $path = Join-Path $Root $item
  $text = Get-Content -LiteralPath $path -Raw -Encoding UTF8
  if (-not $text.StartsWith("---")) { $badTemplates += $item }
}

$skillSyncProblems = @()
$syncSkillsScript = Join-Path $Root "tools\sync-skills.ps1"
if (Test-Path -LiteralPath $syncSkillsScript) {
  $pwshCommand = Get-Command pwsh -ErrorAction SilentlyContinue
  if ($null -eq $pwshCommand) {
    $skillSyncProblems += "pwsh not found; cannot run tools\sync-skills.ps1 -Check"
  } else {
    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    $skillSyncOutput = & $pwshCommand.Source -NoProfile -ExecutionPolicy Bypass -File $syncSkillsScript -Root $Root -Check 2>&1
    $skillSyncExitCode = $LASTEXITCODE
    $ErrorActionPreference = $previousErrorActionPreference
    if ($skillSyncExitCode -ne 0) {
      if ($skillSyncOutput.Count -eq 0) {
        $skillSyncProblems += "tools\sync-skills.ps1 -Check failed with exit code $skillSyncExitCode"
      } else {
        $skillSyncOutput | ForEach-Object { $skillSyncProblems += [string]$_ }
      }
    }
  }
}

$skillTriggerEvalProblems = @()
$skillTriggerEvalPath = Join-Path $Root "evals\skill-trigger-test-cases.md"
if (Test-Path -LiteralPath $skillTriggerEvalPath) {
  $skillTriggerEvalText = Get-Content -LiteralPath $skillTriggerEvalPath -Raw -Encoding UTF8
  foreach ($skill in $activeSkills) {
    $skillPattern = "\|\s*[^|]+\|\s*$([regex]::Escape($skill))\s*\|\s*yes\s*\|"
    if ($skillTriggerEvalText -notmatch $skillPattern) {
      $skillTriggerEvalProblems += "$skill has no positive trigger eval case"
    }
  }
}

$allFiles = Get-ChildItem -LiteralPath $Root -Recurse -File -Force | Where-Object {
  $relative = Get-MemoryOsRelativePath -RootPath $Root -Path $_.FullName
  -not (Test-ExcludedRepositoryScanPath -RelativePath $relative)
}

$sensitiveNameFiles = @()
foreach ($file in $allFiles) {
  $name = $file.Name
  $extension = $file.Extension.ToLowerInvariant()
  if ($name -match '^\.env($|\.)' -or $extension -in @(".pem", ".key", ".pfx", ".p12", ".kdbx", ".sqlite", ".db")) {
    $sensitiveNameFiles += Get-MemoryOsRelativePath -RootPath $Root -Path $file.FullName
  }
}

$proposalStatusProblems = @()
$proposalDirs = @(
  @{ Path = "proposals\pending"; Status = "pending" },
  @{ Path = "proposals\accepted"; Status = "accepted" },
  @{ Path = "proposals\rejected"; Status = "rejected" }
)
foreach ($proposalDir in $proposalDirs) {
  $fullDir = Join-Path $Root $proposalDir.Path
  if (-not (Test-Path -LiteralPath $fullDir)) { continue }
  Get-ChildItem -LiteralPath $fullDir -Filter "*.md" -File | ForEach-Object {
    $relative = Get-MemoryOsRelativePath -RootPath $Root -Path $_.FullName
    $text = Get-Content -LiteralPath $_.FullName -Raw -Encoding UTF8
    if (-not $text.StartsWith("---")) {
      $proposalStatusProblems += "$relative missing frontmatter"
      return
    }
    $expectedStatus = [regex]::Escape($proposalDir.Status)
    if ($text -notmatch "(?m)^status:\s*$expectedStatus\s*$") {
      $proposalStatusProblems += "$relative missing status: $($proposalDir.Status)"
    }
    if ($proposalDir.Status -in @("accepted", "rejected") -and
      $text -notmatch "(?m)^decision_reason:\s*\S" -and
      $text -notmatch "(?m)^##\s+(Reason|Decision Reason|Acceptance Reason|Rejection Reason|原因|接受原因|拒绝原因)\s*$") {
      $proposalStatusProblems += "$relative missing decision reason"
    }
    # source_episode preservation check for accepted proposals
    if ($proposalDir.Status -eq "accepted" -and
      $text -notmatch "(?m)^source_episode:\s*\S" -and
      $text -notmatch "(?m)^##\s+Source Episode 溯源\s*$") {
      $proposalStatusProblems += "$relative missing source_episode (use 'exempt' if emergency)"
    }
  }
}

$futureDirectionProblems = @()
$futureDirectionsDir = Join-Path $Root "proposals\future-directions"
if (Test-Path -LiteralPath $futureDirectionsDir) {
  Get-ChildItem -LiteralPath $futureDirectionsDir -Filter "*.md" -File | Where-Object { $_.Name -ne "README.md" } | ForEach-Object {
    $relative = Get-MemoryOsRelativePath -RootPath $Root -Path $_.FullName
    $text = Get-Content -LiteralPath $_.FullName -Raw -Encoding UTF8
    if (-not $text.StartsWith("---")) {
      $futureDirectionProblems += "$relative missing frontmatter"
      return
    }
    if ($text -notmatch "(?m)^type:\s*future-direction-note\s*$") {
      $futureDirectionProblems += "$relative missing type: future-direction-note"
    }
    if ($text -notmatch "(?m)^not_directly_promotable:\s*true\s*$") {
      $futureDirectionProblems += "$relative missing not_directly_promotable: true"
    }
  }
}

$brokenWikiLinks = @()
foreach ($file in $allFiles | Where-Object { $_.Extension -eq ".md" }) {
  $relative = Get-MemoryOsRelativePath -RootPath $Root -Path $file.FullName
  $text = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8
  $matches = [regex]::Matches($text, '\[\[([^\]|#]+)(?:[#|][^\]]*)?\]\]')
  foreach ($match in $matches) {
    $target = $match.Groups[1].Value.Trim()
    if ([string]::IsNullOrWhiteSpace($target)) { continue }
    $targetPath = Join-Path $Root $target
    $targetMdPath = Join-Path $Root "$target.md"
    if (-not (Test-Path -LiteralPath $targetPath) -and -not (Test-Path -LiteralPath $targetMdPath)) {
      $brokenWikiLinks += "$relative -> [[$target]]"
    }
  }
}

if ($missing.Count -gt 0 -or $missingCodexSkills.Count -gt 0 -or $nonJunctionCodexSkills.Count -gt 0 -or $wrongTargetCodexSkills.Count -gt 0 -or $missingClaudeSkills.Count -gt 0 -or $nonJunctionClaudeSkills.Count -gt 0 -or $wrongTargetClaudeSkills.Count -gt 0 -or $claudeGateSyncProblems.Count -gt 0 -or $badTemplates.Count -gt 0 -or $skillSyncProblems.Count -gt 0 -or $skillTriggerEvalProblems.Count -gt 0 -or $bomFiles.Count -gt 0 -or $sensitiveNameFiles.Count -gt 0 -or $proposalStatusProblems.Count -gt 0 -or $futureDirectionProblems.Count -gt 0 -or $brokenWikiLinks.Count -gt 0) {
  Write-Host "Memory OS validation failed."
  if ($missing.Count -gt 0) { Write-Host "Missing files:"; $missing | ForEach-Object { Write-Host "- $_" } }
  if ($missingCodexSkills.Count -gt 0) { Write-Host "Missing .codex skill junctions:"; $missingCodexSkills | ForEach-Object { Write-Host "- $_" } }
  if ($nonJunctionCodexSkills.Count -gt 0) { Write-Host ".codex skills should be junctions to MemoryOS source:"; $nonJunctionCodexSkills | ForEach-Object { Write-Host "- $_" } }
  if ($wrongTargetCodexSkills.Count -gt 0) { Write-Host ".codex skill junctions point to wrong targets:"; $wrongTargetCodexSkills | ForEach-Object { Write-Host "- $_" } }
  if ($missingClaudeSkills.Count -gt 0) { Write-Host "Missing .claude skill junctions:"; $missingClaudeSkills | ForEach-Object { Write-Host "- $_" } }
  if ($nonJunctionClaudeSkills.Count -gt 0) { Write-Host ".claude skills should be junctions to MemoryOS source:"; $nonJunctionClaudeSkills | ForEach-Object { Write-Host "- $_" } }
  if ($wrongTargetClaudeSkills.Count -gt 0) { Write-Host ".claude skill junctions point to wrong targets:"; $wrongTargetClaudeSkills | ForEach-Object { Write-Host "- $_" } }
  if ($claudeGateSyncProblems.Count -gt 0) { Write-Host "Claude gate sync problems:"; $claudeGateSyncProblems | ForEach-Object { Write-Host "- $_" } }
  if ($badTemplates.Count -gt 0) { Write-Host "Templates missing frontmatter:"; $badTemplates | ForEach-Object { Write-Host "- $_" } }
  if ($skillSyncProblems.Count -gt 0) { Write-Host "Managed skill sync problems:"; $skillSyncProblems | ForEach-Object { Write-Host "- $_" } }
  if ($skillTriggerEvalProblems.Count -gt 0) { Write-Host "Skill trigger eval problems:"; $skillTriggerEvalProblems | ForEach-Object { Write-Host "- $_" } }
  if ($bomFiles.Count -gt 0) { Write-Host "SKILL.md files must be UTF-8 without BOM:"; $bomFiles | ForEach-Object { Write-Host "- $_" } }
  if ($sensitiveNameFiles.Count -gt 0) { Write-Host "Sensitive-looking files must stay out of Memory OS:"; $sensitiveNameFiles | ForEach-Object { Write-Host "- $_" } }
  if ($proposalStatusProblems.Count -gt 0) { Write-Host "Proposal status/frontmatter problems:"; $proposalStatusProblems | ForEach-Object { Write-Host "- $_" } }
  if ($futureDirectionProblems.Count -gt 0) { Write-Host "Future direction frontmatter problems:"; $futureDirectionProblems | ForEach-Object { Write-Host "- $_" } }
  if ($brokenWikiLinks.Count -gt 0) { Write-Host "Broken wiki links:"; $brokenWikiLinks | ForEach-Object { Write-Host "- $_" } }
  exit 1
}

Write-Host "Memory OS validation passed."
