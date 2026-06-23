param(
  [string]$ConfigPath = ""
)

$ErrorActionPreference = "Stop"

$begin = "<!-- AI-MEMORYOS-LITE:BEGIN -->"
$end = "<!-- AI-MEMORYOS-LITE:END -->"

function Resolve-ConfigPath {
  param([string]$Path)
  if ([string]::IsNullOrWhiteSpace($Path)) {
    $liteRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    return Join-Path $liteRoot "memoryos.config.json"
  }
  return [System.IO.Path]::GetFullPath($Path)
}

function Resolve-LitePath {
  param([string]$ConfigFile, [string]$PathText)
  if ([string]::IsNullOrWhiteSpace($PathText)) {
    throw "Path is required"
  }
  if ([System.IO.Path]::IsPathRooted($PathText)) {
    return [System.IO.Path]::GetFullPath($PathText)
  }
  return [System.IO.Path]::GetFullPath((Join-Path (Split-Path -Parent $ConfigFile) $PathText))
}

function Test-PathInside {
  param([string]$ChildPath, [string]$ParentPath)
  $childFull = [System.IO.Path]::GetFullPath($ChildPath).TrimEnd("\", "/")
  $parentFull = [System.IO.Path]::GetFullPath($ParentPath).TrimEnd("\", "/")
  return $childFull.Equals($parentFull, [System.StringComparison]::OrdinalIgnoreCase) -or
    $childFull.StartsWith($parentFull + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase)
}

function Get-JunctionTarget {
  param([string]$Path)
  if (-not (Test-Path -LiteralPath $Path)) {
    return ""
  }
  $item = Get-Item -LiteralPath $Path -Force
  if (-not ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint)) {
    return ""
  }
  $target = $item.Target
  if ($target -is [array]) {
    return [string]$target[0]
  }
  return [string]$target
}

function Add-Problem {
  param([string]$Message)
  $script:problems += $Message
}

function Test-ManagedBlock {
  param(
    [string]$Path,
    [string]$BootstrapPath,
    [string]$GatePath,
    [string]$Adapter
  )

  if (-not (Test-Path -LiteralPath $Path)) {
    Add-Problem "MISSING $Adapter user entry: $Path"
    return
  }
  $text = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
  if ($text -notmatch [regex]::Escape($begin) -or $text -notmatch [regex]::Escape($end)) {
    Add-Problem "MISSING $Adapter Lite managed block: $Path"
    return
  }
  if ($text -notmatch [regex]::Escape($BootstrapPath) -or $text -notmatch [regex]::Escape($GatePath)) {
    Add-Problem "STALE $Adapter Lite managed block paths: $Path"
  }
}

function Test-PlaceholderFree {
  param([string[]]$Paths)
  foreach ($path in $Paths) {
    if ([string]::IsNullOrWhiteSpace($path) -or -not (Test-Path -LiteralPath $path)) {
      continue
    }
    $item = Get-Item -LiteralPath $path -Force
    if ($item.PSIsContainer) {
      Get-ChildItem -LiteralPath $path -Recurse -File | ForEach-Object {
        $text = Get-Content -LiteralPath $_.FullName -Raw -Encoding UTF8
        if ($text -match "\$\{[^}]+\}|<resolved-[^>]+>") {
          Add-Problem "UNRESOLVED placeholder in $($_.FullName)"
        }
      }
    } else {
      $text = Get-Content -LiteralPath $path -Raw -Encoding UTF8
      if ($text -match "\$\{[^}]+\}|<resolved-[^>]+>") {
        Add-Problem "UNRESOLVED placeholder in $path"
      }
    }
  }
}

function Resolve-RouterReference {
  param(
    [string]$LiteRoot,
    [string]$MemoryosRoot,
    [string]$Reference
  )

  $normalized = $Reference.Replace('/', '\')
  if ($normalized.StartsWith(".memoryos\", [System.StringComparison]::OrdinalIgnoreCase)) {
    return Join-Path $LiteRoot $normalized
  }
  if ($normalized.StartsWith("workflows\", [System.StringComparison]::OrdinalIgnoreCase) -or
      $normalized.StartsWith("domains\", [System.StringComparison]::OrdinalIgnoreCase) -or
      $normalized.StartsWith("router\", [System.StringComparison]::OrdinalIgnoreCase) -or
      $normalized.StartsWith("skills\", [System.StringComparison]::OrdinalIgnoreCase)) {
    return Join-Path $MemoryosRoot $normalized
  }
  return ""
}

function Test-RouterReferences {
  param(
    [string]$LiteRoot,
    [string]$MemoryosRoot,
    [string[]]$ActiveSkills
  )

  foreach ($routerFile in @("intent-map.md", "domain-map.md", "workflow-map.md", "skill-map.md")) {
    $path = Join-Path $MemoryosRoot "router/$routerFile"
    if (-not (Test-Path -LiteralPath $path)) {
      continue
    }
    $text = Get-Content -LiteralPath $path -Raw -Encoding UTF8
    foreach ($match in [regex]::Matches($text, '`([^`]+\.md)`')) {
      $reference = $match.Groups[1].Value
      $target = Resolve-RouterReference -LiteRoot $LiteRoot -MemoryosRoot $MemoryosRoot -Reference $reference
      if (-not [string]::IsNullOrWhiteSpace($target) -and -not (Test-Path -LiteralPath $target)) {
        Add-Problem "MISSING router reference: $routerFile -> $reference"
      }
    }
  }

  $skillMap = Join-Path $MemoryosRoot "router/skill-map.md"
  if (Test-Path -LiteralPath $skillMap) {
    Get-Content -LiteralPath $skillMap -Encoding UTF8 | ForEach-Object {
      if ($_ -match '^\|\s*([a-z0-9]+(?:-[a-z0-9]+)*)\s*\|') {
        $skillName = $matches[1]
        if ($skillName -eq "Skill") {
          return
        }
        if ($ActiveSkills -notcontains $skillName) {
          Add-Problem "STALE skill-map references inactive skill: $skillName"
        }
      }
    }
  }
}

$problems = @()
$items = @()

try {
  $configFull = Resolve-ConfigPath -Path $ConfigPath
  if (-not (Test-Path -LiteralPath $configFull)) {
    throw "Config not found: $configFull"
  }
  $config = Get-Content -LiteralPath $configFull -Raw -Encoding UTF8 | ConvertFrom-Json
  if ($null -eq $config.memoryos -or [string]::IsNullOrWhiteSpace([string]$config.memoryos.root)) {
    Add-Problem "memoryos.root is required"
  }
  $liteRoot = Resolve-LitePath -ConfigFile $configFull -PathText ([string]$config.memoryos.root)
  $memoryosRoot = Join-Path $liteRoot ".memoryos"
  if (-not (Test-Path -LiteralPath $memoryosRoot)) {
    Add-Problem ".memoryos missing: $memoryosRoot"
  }
  $indexPath = Join-Path $memoryosRoot "_index.md"
  if (-not (Test-Path -LiteralPath $indexPath)) {
    Add-Problem "MISSING Lite index: $indexPath"
  }

  $enabledAdapters = @()
  foreach ($adapter in @("codex", "claude")) {
    $adapterConfig = $config.$adapter
    if ($null -ne $adapterConfig -and $adapterConfig.enabled -eq $true) {
      $enabledAdapters += $adapter
    }
  }
  if ($enabledAdapters.Count -eq 0) {
    Add-Problem "At least one adapter must be enabled"
  }

  $activeSkills = @($config.skills.active)
  if ($activeSkills.Count -eq 0) {
    Add-Problem "skills.active must contain at least one skill"
  }

  foreach ($adapter in $enabledAdapters) {
    $adapterConfig = $config.$adapter
    $entryPath = if ($adapter -eq "codex") { [string]$adapterConfig.user_agents } else { [string]$adapterConfig.user_claude }
    if ([string]::IsNullOrWhiteSpace($entryPath)) {
      Add-Problem "$adapter user entry path is required"
      continue
    }
    if ([string]::IsNullOrWhiteSpace([string]$adapterConfig.skills_dir)) {
      Add-Problem "$adapter.skills_dir is required"
      continue
    }

    $entryFull = Resolve-LitePath -ConfigFile $configFull -PathText $entryPath
    $skillsDir = Resolve-LitePath -ConfigFile $configFull -PathText ([string]$adapterConfig.skills_dir)
    $bootstrap = Join-Path $liteRoot ".memoryos/adapters/$adapter/bootstrap.md"
    $gate = if ($adapter -eq "codex") {
      Join-Path $liteRoot ".memoryos/adapters/codex/gate.md"
    } else {
      Join-Path $liteRoot ".memoryos/adapters/claude/CLAUDE.md"
    }

    foreach ($required in @($bootstrap, $gate)) {
      if (-not (Test-Path -LiteralPath $required)) {
        Add-Problem "MISSING $adapter adapter file: $required"
      }
    }

    Test-ManagedBlock -Path $entryFull -BootstrapPath $bootstrap -GatePath $gate -Adapter $adapter

    foreach ($skillName in $activeSkills) {
      $adapterSkill = Join-Path $liteRoot ".memoryos/adapters/$adapter/skills/$skillName/SKILL.md"
      if (-not (Test-Path -LiteralPath $adapterSkill)) {
        Add-Problem "MISSING $adapter rendered skill: $adapterSkill"
      }
      $junctionPath = Join-Path $skillsDir $skillName
      $target = Get-JunctionTarget -Path $junctionPath
      if ([string]::IsNullOrWhiteSpace($target)) {
        Add-Problem "MISSING $adapter skill junction: $junctionPath"
      } elseif (-not ([System.IO.Path]::GetFullPath($target).TrimEnd("\", "/")).Equals(([System.IO.Path]::GetFullPath((Split-Path -Parent $adapterSkill))).TrimEnd("\", "/"), [System.StringComparison]::OrdinalIgnoreCase)) {
        Add-Problem "STALE $adapter skill junction: $junctionPath"
      }
    }
  }

  if ($config.claude.enabled -eq $true -and $config.claude.install_hook -eq $true) {
    if ([string]::IsNullOrWhiteSpace([string]$config.claude.settings_json)) {
      Add-Problem "claude.settings_json is required when claude.install_hook=true"
    } else {
      $settingsPath = Resolve-LitePath -ConfigFile $configFull -PathText ([string]$config.claude.settings_json)
      if (-not (Test-Path -LiteralPath $settingsPath)) {
        Add-Problem "MISSING Claude settings_json: $settingsPath"
      } else {
        $settingsText = Get-Content -LiteralPath $settingsPath -Raw -Encoding UTF8
        if ($settingsText -notmatch "AI-MEMORYOS-LITE" -or $settingsText -notmatch "inject-bootstrap-reminder\.ps1") {
          Add-Problem "MISSING Claude Lite hook: $settingsPath"
        }
      }
    }
  }

  $manifest = Join-Path $memoryosRoot "install-state.json"
  if (-not (Test-Path -LiteralPath $manifest)) {
    Add-Problem "MISSING install-state manifest: $manifest"
  } else {
    $state = Get-Content -LiteralPath $manifest -Raw -Encoding UTF8 | ConvertFrom-Json
    if (-not ([System.IO.Path]::GetFullPath([string]$state.memoryos_root).TrimEnd("\", "/")).Equals([System.IO.Path]::GetFullPath($liteRoot).TrimEnd("\", "/"), [System.StringComparison]::OrdinalIgnoreCase)) {
      Add-Problem "STALE install-state memoryos_root: $manifest"
    }
  }

  foreach ($routerFile in @("intent-map.md", "domain-map.md", "workflow-map.md", "skill-map.md")) {
    $path = Join-Path $memoryosRoot "router/$routerFile"
    if (-not (Test-Path -LiteralPath $path)) {
      Add-Problem "MISSING router file: $path"
    }
  }

  if (Test-Path -LiteralPath $indexPath) {
    $indexText = Get-Content -LiteralPath $indexPath -Raw -Encoding UTF8
    foreach ($requiredReference in @(
      "router/intent-map.md",
      "router/domain-map.md",
      "router/workflow-map.md",
      "router/skill-map.md",
      "skills/registry.json"
    )) {
      if ($indexText -notmatch [regex]::Escape($requiredReference)) {
        Add-Problem "STALE Lite index missing reference: $requiredReference"
      }
    }
  }

  foreach ($workflowFile in @("diff-review-lite.md", "pre-commit-self-check.md", "feature-development.md", "bugfix-with-regression-test.md", "frontend-prototype-driven-development.md")) {
    $path = Join-Path $memoryosRoot "workflows/$workflowFile"
    if (-not (Test-Path -LiteralPath $path)) {
      Add-Problem "MISSING workflow file: $path"
    }
  }

  Test-RouterReferences -LiteRoot $liteRoot -MemoryosRoot $memoryosRoot -ActiveSkills $activeSkills

  Test-PlaceholderFree -Paths @(
    (Join-Path $memoryosRoot "adapters"),
    (Join-Path $memoryosRoot "tools/inject-bootstrap-reminder.ps1")
  )
} catch {
  Add-Problem "ERROR $($_.Exception.Message)"
}

if ($problems.Count -gt 0) {
  $problems | ForEach-Object { Write-Host $_ }
  Write-Host "ERROR Lite validation completed with problems."
  exit 1
}

$items += "OK config"
$items += "OK adapters=$($enabledAdapters -join ',')"
$items += "OK skills=$($activeSkills -join ',')"
$items | ForEach-Object { Write-Host $_ }
Write-Host "OK Lite validation"
