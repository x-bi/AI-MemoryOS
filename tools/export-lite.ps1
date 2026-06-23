param(
  [string]$Root = "",
  [string]$OutDir = "dist/lite",
  [switch]$Check,
  [switch]$Clean
)

$ErrorActionPreference = "Stop"

function Test-PathInside {
  param(
    [string]$ChildPath,
    [string]$ParentPath
  )

  $childFull = [System.IO.Path]::GetFullPath($ChildPath).TrimEnd("\", "/")
  $parentFull = [System.IO.Path]::GetFullPath($ParentPath).TrimEnd("\", "/")
  return $childFull.Equals($parentFull, [System.StringComparison]::OrdinalIgnoreCase) -or
    $childFull.StartsWith($parentFull + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase)
}

function Join-RootPath {
  param(
    [string]$RootPath,
    [string]$RelativePath
  )

  if ([string]::IsNullOrWhiteSpace($RelativePath)) {
    throw "Relative path is required"
  }
  if ([System.IO.Path]::IsPathRooted($RelativePath)) {
    throw "Relative path expected: $RelativePath"
  }

  $rootFull = [System.IO.Path]::GetFullPath((Resolve-Path -LiteralPath $RootPath).Path)
  $joined = Join-Path $rootFull ($RelativePath -replace '/', '\')
  $full = [System.IO.Path]::GetFullPath($joined)
  if (-not (Test-PathInside -ChildPath $full -ParentPath $rootFull)) {
    throw "Path escapes repo root: $RelativePath"
  }
  return $full
}

function Copy-LiteFile {
  param(
    [string]$Source,
    [string]$Destination
  )

  if (-not (Test-Path -LiteralPath $Source)) {
    throw "Missing Lite export source: $Source"
  }
  $directory = Split-Path -Parent $Destination
  New-Item -ItemType Directory -Force -Path $directory | Out-Null
  Copy-Item -LiteralPath $Source -Destination $Destination -Force
}

function Copy-LiteDirectory {
  param(
    [string]$Source,
    [string]$Destination
  )

  if (-not (Test-Path -LiteralPath $Source)) {
    return
  }
  New-Item -ItemType Directory -Force -Path $Destination | Out-Null
  Get-ChildItem -LiteralPath $Source -Recurse -File | ForEach-Object {
    $sourceFull = [System.IO.Path]::GetFullPath($_.FullName)
    $sourceRoot = [System.IO.Path]::GetFullPath((Resolve-Path -LiteralPath $Source).Path).TrimEnd("\", "/")
    $relative = $sourceFull.Substring($sourceRoot.Length).TrimStart("\", "/")
    $target = Join-Path $Destination $relative
    $targetDirectory = Split-Path -Parent $target
    New-Item -ItemType Directory -Force -Path $targetDirectory | Out-Null
    Copy-Item -LiteralPath $sourceFull -Destination $target -Force
  }
}

function Write-Utf8NoBom {
  param(
    [string]$Path,
    [string]$Text
  )

  $directory = Split-Path -Parent $Path
  New-Item -ItemType Directory -Force -Path $directory | Out-Null
  $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($Path, $Text.TrimEnd("`r", "`n") + "`n", $utf8NoBom)
}

$repoRoot = if ([string]::IsNullOrWhiteSpace($Root)) {
  [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot ".."))
} else {
  [System.IO.Path]::GetFullPath((Resolve-Path -LiteralPath $Root).Path)
}

$sourceRoot = Join-RootPath -RootPath $repoRoot -RelativePath "lite-src/package"
$outFull = Join-RootPath -RootPath $repoRoot -RelativePath $OutDir

$requiredFiles = @(
  "README.md",
  "INSTALL.md",
  "memoryos.config.json",
  "install.ps1",
  ".memoryos/_index.md",
  ".memoryos/core/usage-rules.md",
  ".memoryos/templates/codex-bootstrap.md.tmpl",
  ".memoryos/templates/codex-gate.md.tmpl",
  ".memoryos/templates/claude-bootstrap.md.tmpl",
  ".memoryos/templates/claude-gate.md.tmpl",
  ".memoryos/templates/skill.md.tmpl",
  ".memoryos/tools/install-core.ps1",
  ".memoryos/tools/render-adapters.ps1",
  ".memoryos/tools/sync-skills.ps1",
  ".memoryos/tools/patch-user-entry.ps1",
  ".memoryos/tools/patch-claude-hook.ps1",
  ".memoryos/tools/validate.ps1",
  ".memoryos/tools/inject-bootstrap-reminder.ps1"
)

$repoInputs = @(
  "core/safety-rules.md",
  "router/intent-map.md",
  "router/domain-map.md",
  "router/workflow-map.md",
  "router/skill-map.md",
  "domains/frontend/README.md",
  "workflows/diff-review-lite.md",
  "workflows/pre-commit-self-check.md",
  "workflows/feature-development.md",
  "workflows/frontend-prototype-driven-development.md",
  "workflows/frontend-regression-verification-strategy.md",
  "workflows/refactor-with-safety.md",
  "workflows/retrospective-lite.md",
  "workflows/script-automation.md",
  "workflows/test-strategy.md",
  "private.example/README.md"
)

$selectedSkills = @(
  "pr-review",
  "bugfix-with-regression-test",
  "frontend-component-review",
  "vue-change-self-check",
  "git-ops-guide"
)

$missing = @()
foreach ($file in $requiredFiles) {
  $path = Join-Path $sourceRoot ($file -replace '/', '\')
  if (-not (Test-Path -LiteralPath $path)) { $missing += "lite-src/package/$file" }
}
foreach ($file in $repoInputs) {
  $path = Join-RootPath -RootPath $repoRoot -RelativePath $file
  if (-not (Test-Path -LiteralPath $path)) { $missing += $file }
}
foreach ($skill in $selectedSkills) {
  $skillPath = Join-RootPath -RootPath $repoRoot -RelativePath "skills/$skill/SKILL_SPEC.md"
  if (-not (Test-Path -LiteralPath $skillPath)) { $missing += "skills/$skill/SKILL_SPEC.md" }
}

if ($missing.Count -gt 0) {
  $missing | ForEach-Object { Write-Host "ERROR missing $_" }
  exit 1
}

if ($Check) {
  Write-Host "OK Lite export inputs. out=$OutDir skills=$($selectedSkills.Count)"
  exit 0
}

if ((Test-Path -LiteralPath $outFull) -and $Clean) {
  if (-not (Test-PathInside -ChildPath $outFull -ParentPath (Join-RootPath -RootPath $repoRoot -RelativePath "dist"))) {
    throw "Clean is only allowed under dist/: $OutDir"
  }
  Remove-Item -LiteralPath $outFull -Recurse -Force
}

New-Item -ItemType Directory -Force -Path $outFull | Out-Null

Get-ChildItem -LiteralPath $sourceRoot -Recurse -File | ForEach-Object {
  $sourceFull = [System.IO.Path]::GetFullPath($_.FullName)
  $sourceBase = [System.IO.Path]::GetFullPath((Resolve-Path -LiteralPath $sourceRoot).Path).TrimEnd("\", "/")
  $relative = $sourceFull.Substring($sourceBase.Length).TrimStart("\", "/")
  $target = Join-Path $outFull $relative
  Copy-LiteFile -Source $sourceFull -Destination $target
}

$safetyOverride = Join-Path $sourceRoot ".memoryos/core/safety-rules.md"
if (Test-Path -LiteralPath $safetyOverride) {
  Copy-LiteFile -Source $safetyOverride -Destination (Join-Path $outFull ".memoryos/core/safety-rules.md")
} else {
  Copy-LiteFile -Source (Join-RootPath -RootPath $repoRoot -RelativePath "core/safety-rules.md") -Destination (Join-Path $outFull ".memoryos/core/safety-rules.md")
}

foreach ($routerFile in @("intent-map.md", "domain-map.md", "workflow-map.md", "skill-map.md")) {
  $routerOverride = Join-Path $sourceRoot ".memoryos/router/$routerFile"
  if (Test-Path -LiteralPath $routerOverride) {
    Copy-LiteFile -Source $routerOverride -Destination (Join-Path $outFull ".memoryos/router/$routerFile")
  } else {
    Copy-LiteFile -Source (Join-RootPath -RootPath $repoRoot -RelativePath "router/$routerFile") -Destination (Join-Path $outFull ".memoryos/router/$routerFile")
  }
}

Copy-LiteDirectory -Source (Join-RootPath -RootPath $repoRoot -RelativePath "domains") -Destination (Join-Path $outFull ".memoryos/domains")

foreach ($workflowFile in @("diff-review-lite.md", "pre-commit-self-check.md", "feature-development.md", "frontend-prototype-driven-development.md", "frontend-regression-verification-strategy.md", "refactor-with-safety.md", "retrospective-lite.md", "script-automation.md", "test-strategy.md")) {
  $workflowOverride = Join-Path $sourceRoot ".memoryos/workflows/$workflowFile"
  if (Test-Path -LiteralPath $workflowOverride) {
    Copy-LiteFile -Source $workflowOverride -Destination (Join-Path $outFull ".memoryos/workflows/$workflowFile")
  } else {
    Copy-LiteFile -Source (Join-RootPath -RootPath $repoRoot -RelativePath "workflows/$workflowFile") -Destination (Join-Path $outFull ".memoryos/workflows/$workflowFile")
  }
}

Copy-LiteFile -Source (Join-RootPath -RootPath $repoRoot -RelativePath "private.example/README.md") -Destination (Join-Path $outFull ".memoryos/private.example/README.md")

$registryPath = Join-RootPath -RootPath $repoRoot -RelativePath "skills/registry.json"
$registry = Get-Content -LiteralPath $registryPath -Raw -Encoding UTF8 | ConvertFrom-Json
$liteSkills = @()
foreach ($skillName in $selectedSkills) {
  $skill = @($registry.skills | Where-Object { $_.name -eq $skillName })[0]
  if ($null -eq $skill) {
    throw "Skill not found in registry: $skillName"
  }
  $liteSkills += [pscustomobject]@{
    name = [string]$skill.name
    status = [string]$skill.status
    source = "skills/$skillName/SKILL_SPEC.md"
    managed = $true
    description = [string]$skill.description
  }
  $skillOverride = Join-Path $sourceRoot ".memoryos/skills/$skillName/SKILL_SPEC.md"
  if (Test-Path -LiteralPath $skillOverride) {
    Copy-LiteFile -Source $skillOverride -Destination (Join-Path $outFull ".memoryos/skills/$skillName/SKILL_SPEC.md")
  } else {
    Copy-LiteFile -Source (Join-RootPath -RootPath $repoRoot -RelativePath "skills/$skillName/SKILL_SPEC.md") -Destination (Join-Path $outFull ".memoryos/skills/$skillName/SKILL_SPEC.md")
  }
  $referencesOverride = Join-Path $sourceRoot ".memoryos/skills/$skillName/references"
  if (Test-Path -LiteralPath $referencesOverride) {
    Copy-LiteDirectory -Source $referencesOverride -Destination (Join-Path $outFull ".memoryos/skills/$skillName/references")
  } else {
    Copy-LiteDirectory -Source (Join-RootPath -RootPath $repoRoot -RelativePath "skills/$skillName/references") -Destination (Join-Path $outFull ".memoryos/skills/$skillName/references")
  }
}

$liteRegistry = [pscustomobject]@{ skills = $liteSkills }
$registryJson = $liteRegistry | ConvertTo-Json -Depth 8
Write-Utf8NoBom -Path (Join-Path $outFull ".memoryos/skills/registry.json") -Text $registryJson

Write-Host "EXPORTED Lite package to $OutDir"
Write-Host "skills=$($selectedSkills -join ', ')"
