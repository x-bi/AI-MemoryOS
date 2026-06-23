param(
  [string]$ConfigPath = "",
  [switch]$Check,
  [switch]$Uninstall,
  [switch]$Prune,
  [string]$StateEventsPath = ""
)

$ErrorActionPreference = "Stop"

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

function ConvertTo-YamlDoubleQuoted {
  param([string]$Value)
  $builder = New-Object System.Text.StringBuilder
  foreach ($char in $Value.ToCharArray()) {
    $code = [int][char]$char
    switch ($char) {
      '\' { [void]$builder.Append('\\'); break }
      '"' { [void]$builder.Append('\"'); break }
      "`r" { [void]$builder.Append('\r'); break }
      "`n" { [void]$builder.Append('\n'); break }
      "`t" { [void]$builder.Append('\t'); break }
      default {
        if ($code -lt 32) {
          [void]$builder.Append(('\u{0:x4}' -f $code))
        } else {
          [void]$builder.Append($char)
        }
      }
    }
  }
  return '"' + $builder.ToString() + '"'
}

function Write-Utf8NoBom {
  param([string]$Path, [string]$Text)
  $directory = Split-Path -Parent $Path
  New-Item -ItemType Directory -Force -Path $directory | Out-Null
  $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($Path, $Text.TrimEnd("`r", "`n") + "`n", $utf8NoBom)
}

function Add-StateEvent {
  param([hashtable]$Event)
  if ([string]::IsNullOrWhiteSpace($StateEventsPath)) {
    return
  }
  $directory = Split-Path -Parent $StateEventsPath
  New-Item -ItemType Directory -Force -Path $directory | Out-Null
  ($Event | ConvertTo-Json -Depth 8 -Compress) | Add-Content -LiteralPath $StateEventsPath -Encoding UTF8
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

function Render-Skill {
  param(
    [string]$TemplateText,
    [object]$Skill,
    [string]$SourceHash,
    [string]$SourceBody,
    [string]$Adapter
  )
  $body = $SourceBody.Replace("{{AGENT_NAME}}", $(if ($Adapter -eq "codex") { "Codex" } else { "Claude" })).TrimEnd("`r", "`n")
  $rendered = $TemplateText.Replace("{{body}}", "__LITE_SKILL_BODY__")
  $tokens = @{
    "{{name}}" = [string]$Skill.name
    "{{description}}" = ConvertTo-YamlDoubleQuoted -Value ([string]$Skill.description)
    "{{source}}" = [string]$Skill.source
    "{{source_sha256}}" = $SourceHash
    "{{adapter}}" = $Adapter
  }
  foreach ($key in $tokens.Keys) {
    $rendered = $rendered.Replace($key, [string]$tokens[$key])
  }
  return $rendered.Replace("__LITE_SKILL_BODY__", $body)
}

function Copy-References {
  param([string]$SourceDir, [string]$TargetDir, [bool]$CheckOnly)
  if (-not (Test-Path -LiteralPath $SourceDir)) {
    return @()
  }
  $messages = @()
  $sourceRoot = [System.IO.Path]::GetFullPath((Resolve-Path -LiteralPath $SourceDir).Path).TrimEnd("\", "/")
  Get-ChildItem -LiteralPath $SourceDir -Recurse -File | ForEach-Object {
    $relative = ([System.IO.Path]::GetFullPath($_.FullName)).Substring($sourceRoot.Length).TrimStart("\", "/")
    $target = Join-Path $TargetDir $relative
    if ($CheckOnly) {
      if (-not (Test-Path -LiteralPath $target)) {
        $messages += "STALE reference missing $target"
      } else {
        $sourceHash = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash
        $targetHash = (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash
        if ($sourceHash -ne $targetHash) {
          $messages += "STALE reference $target"
        }
      }
    } else {
      New-Item -ItemType Directory -Force -Path (Split-Path -Parent $target) | Out-Null
      Copy-Item -LiteralPath $_.FullName -Destination $target -Force
    }
  }
  return $messages
}

function Remove-LiteJunctions {
  param(
    [string]$SkillsDir,
    [string]$LiteRoot,
    [string[]]$KeepNames = @()
  )
  if (-not (Test-Path -LiteralPath $SkillsDir)) {
    return
  }
  Get-ChildItem -LiteralPath $SkillsDir -Force | ForEach-Object {
    if ($KeepNames -contains $_.Name) {
      return
    }
    $target = Get-JunctionTarget -Path $_.FullName
    if (-not [string]::IsNullOrWhiteSpace($target) -and (Test-PathInside -ChildPath $target -ParentPath $LiteRoot)) {
      Remove-Item -LiteralPath $_.FullName -Force
      Write-Host "REMOVED skill junction $($_.FullName)"
    }
  }
}

$items = @()
$problems = @()

try {
  $configFull = Resolve-ConfigPath -Path $ConfigPath
  $config = Get-Content -LiteralPath $configFull -Raw -Encoding UTF8 | ConvertFrom-Json
  $liteRoot = Resolve-LitePath -ConfigFile $configFull -PathText ([string]$config.memoryos.root)
  $memoryosRoot = Join-Path $liteRoot ".memoryos"

  if ($Uninstall) {
    foreach ($adapter in @("codex", "claude")) {
      $adapterConfig = $config.$adapter
      if ($null -ne $adapterConfig -and -not [string]::IsNullOrWhiteSpace([string]$adapterConfig.skills_dir)) {
        $skillsDir = Resolve-LitePath -ConfigFile $configFull -PathText ([string]$adapterConfig.skills_dir)
        Remove-LiteJunctions -SkillsDir $skillsDir -LiteRoot $liteRoot
      }
    }
    Write-Host "OK sync-skills uninstall"
    exit 0
  }

  $activeSkills = @($config.skills.active)
  if ($activeSkills.Count -eq 0) {
    throw "skills.active must contain at least one skill"
  }

  $registryPath = Join-Path $memoryosRoot "skills/registry.json"
  $registry = Get-Content -LiteralPath $registryPath -Raw -Encoding UTF8 | ConvertFrom-Json
  $template = Get-Content -LiteralPath (Join-Path $memoryosRoot "templates/skill.md.tmpl") -Raw -Encoding UTF8

  foreach ($skillName in $activeSkills) {
    $skill = @($registry.skills | Where-Object { $_.name -eq $skillName })[0]
    if ($null -eq $skill) {
      $problems += "ERROR active skill not in registry: $skillName"
      continue
    }
    $sourcePath = Join-Path $memoryosRoot ($skill.source -replace '/', '\')
    if (-not (Test-Path -LiteralPath $sourcePath)) {
      $problems += "ERROR missing skill source: $($skill.source)"
      continue
    }
    $sourceHash = (Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash.ToLowerInvariant()
    $sourceBody = Get-Content -LiteralPath $sourcePath -Raw -Encoding UTF8

    foreach ($adapter in @("codex", "claude")) {
      $adapterConfig = $config.$adapter
      if ($null -eq $adapterConfig -or $adapterConfig.enabled -ne $true) {
        continue
      }
      if ([string]::IsNullOrWhiteSpace([string]$adapterConfig.skills_dir)) {
        $problems += "ERROR $adapter.skills_dir is required"
        continue
      }

      $adapterSkillDir = Join-Path $memoryosRoot "adapters/$adapter/skills/$skillName"
      $adapterSkillPath = Join-Path $adapterSkillDir "SKILL.md"
      $expected = Render-Skill -TemplateText $template -Skill $skill -SourceHash $sourceHash -SourceBody $sourceBody -Adapter $adapter
      $referenceMessages = Copy-References -SourceDir (Join-Path (Split-Path -Parent $sourcePath) "references") -TargetDir (Join-Path $adapterSkillDir "references") -CheckOnly ([bool]$Check)
      $problems += $referenceMessages

      if ($Check) {
        if (-not (Test-Path -LiteralPath $adapterSkillPath)) {
          $problems += "STALE $adapter skill missing $adapterSkillPath"
        } else {
          $actual = Get-Content -LiteralPath $adapterSkillPath -Raw -Encoding UTF8
          if ($actual -ne ($expected.TrimEnd("`r", "`n") + "`n")) {
            $problems += "STALE $adapter skill $adapterSkillPath"
          } else {
            $items += "OK $adapter skill $skillName"
          }
        }
      } else {
        Write-Utf8NoBom -Path $adapterSkillPath -Text $expected
        Copy-References -SourceDir (Join-Path (Split-Path -Parent $sourcePath) "references") -TargetDir (Join-Path $adapterSkillDir "references") -CheckOnly $false | Out-Null
        $items += "RENDERED $adapter skill $skillName"
      }

      $skillsDir = Resolve-LitePath -ConfigFile $configFull -PathText ([string]$adapterConfig.skills_dir)
      $junctionPath = Join-Path $skillsDir $skillName
      $expectedTarget = [System.IO.Path]::GetFullPath($adapterSkillDir)
      $actualTarget = Get-JunctionTarget -Path $junctionPath

      if ($Check) {
        if ([string]::IsNullOrWhiteSpace($actualTarget)) {
          $problems += "STALE $adapter skill junction missing $junctionPath"
        } elseif (-not ([System.IO.Path]::GetFullPath($actualTarget).TrimEnd("\", "/")).Equals($expectedTarget.TrimEnd("\", "/"), [System.StringComparison]::OrdinalIgnoreCase)) {
          $problems += "STALE $adapter skill junction target $junctionPath"
        } else {
          $items += "OK $adapter junction $skillName"
        }
      } else {
        New-Item -ItemType Directory -Force -Path $skillsDir | Out-Null
        if (Test-Path -LiteralPath $junctionPath) {
          if ([string]::IsNullOrWhiteSpace($actualTarget)) {
            $problems += "ERROR $adapter skill path exists and is not a junction: $junctionPath"
            continue
          }
          if (-not (Test-PathInside -ChildPath $actualTarget -ParentPath $liteRoot)) {
            $problems += "ERROR existing junction is not Lite-managed: $junctionPath -> $actualTarget"
            continue
          }
          if (-not ([System.IO.Path]::GetFullPath($actualTarget).TrimEnd("\", "/")).Equals($expectedTarget.TrimEnd("\", "/"), [System.StringComparison]::OrdinalIgnoreCase)) {
            Remove-Item -LiteralPath $junctionPath -Force
          }
        }
        if (-not (Test-Path -LiteralPath $junctionPath)) {
          New-Item -ItemType Junction -Path $junctionPath -Target $expectedTarget | Out-Null
        }
        Add-StateEvent @{
          kind = "skill-junction"
          action = "install"
          adapter = $adapter
          path = $junctionPath
          target = $expectedTarget
        }
        $items += "LINKED $adapter skill $skillName"
      }
    }
  }

  if ($Prune -and -not $Check) {
    foreach ($adapter in @("codex", "claude")) {
      $adapterConfig = $config.$adapter
      if ($null -ne $adapterConfig -and $adapterConfig.enabled -eq $true -and -not [string]::IsNullOrWhiteSpace([string]$adapterConfig.skills_dir)) {
        Remove-LiteJunctions -SkillsDir (Resolve-LitePath -ConfigFile $configFull -PathText ([string]$adapterConfig.skills_dir)) -LiteRoot $liteRoot -KeepNames $activeSkills
      }
    }
  }
} catch {
  $problems += "ERROR $($_.Exception.Message)"
}

if ($problems.Count -gt 0) {
  $problems | ForEach-Object { Write-Host $_ }
  exit 1
}

if ($items.Count -gt 0) {
  $items | ForEach-Object { Write-Host $_ }
}
Write-Host "OK sync-skills"
