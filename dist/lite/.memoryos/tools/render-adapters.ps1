param(
  [string]$ConfigPath = "",
  [switch]$Check
)

$ErrorActionPreference = "Stop"

function Test-PathInside {
  param([string]$ChildPath, [string]$ParentPath)
  $childFull = [System.IO.Path]::GetFullPath($ChildPath).TrimEnd("\", "/")
  $parentFull = [System.IO.Path]::GetFullPath($ParentPath).TrimEnd("\", "/")
  return $childFull.Equals($parentFull, [System.StringComparison]::OrdinalIgnoreCase) -or
    $childFull.StartsWith($parentFull + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase)
}

function Resolve-ConfigPath {
  param([string]$Path)
  if ([string]::IsNullOrWhiteSpace($Path)) {
    $liteRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    return Join-Path $liteRoot "memoryos.config.json"
  }
  return [System.IO.Path]::GetFullPath($Path)
}

function Resolve-LitePath {
  param(
    [string]$ConfigFile,
    [string]$PathText
  )
  if ([string]::IsNullOrWhiteSpace($PathText)) {
    throw "Path is required"
  }
  if ([System.IO.Path]::IsPathRooted($PathText)) {
    return [System.IO.Path]::GetFullPath($PathText)
  }
  $configDir = Split-Path -Parent $ConfigFile
  return [System.IO.Path]::GetFullPath((Join-Path $configDir $PathText))
}

function Write-Utf8NoBom {
  param([string]$Path, [string]$Text)
  $directory = Split-Path -Parent $Path
  New-Item -ItemType Directory -Force -Path $directory | Out-Null
  $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($Path, $Text.TrimEnd("`r", "`n") + "`n", $utf8NoBom)
}

function Replace-TokenMap {
  param([string]$Text, [hashtable]$Tokens)
  $rendered = $Text
  foreach ($key in @($Tokens.Keys | Sort-Object { $_.Length } -Descending)) {
    $rendered = $rendered.Replace($key, [string]$Tokens[$key])
  }
  return $rendered.TrimEnd("`r", "`n") + "`n"
}

$items = @()
$problems = @()

try {
  $configFull = Resolve-ConfigPath -Path $ConfigPath
  if (-not (Test-Path -LiteralPath $configFull)) {
    throw "Config not found: $configFull"
  }
  $config = Get-Content -LiteralPath $configFull -Raw -Encoding UTF8 | ConvertFrom-Json
  $liteRoot = Resolve-LitePath -ConfigFile $configFull -PathText ([string]$config.memoryos.root)
  $memoryosRoot = Join-Path $liteRoot ".memoryos"
  if (-not (Test-Path -LiteralPath $memoryosRoot)) {
    throw ".memoryos directory not found: $memoryosRoot"
  }
  $language = if ($null -ne $config.memoryos.language -and -not [string]::IsNullOrWhiteSpace([string]$config.memoryos.language)) {
    [string]$config.memoryos.language
  } else {
    "zh-CN"
  }

  $targets = @(
    [pscustomobject]@{
      Adapter = "codex"
      AgentName = "Codex"
      Config = $config.codex
      Template = ".memoryos/templates/codex-bootstrap.md.tmpl"
      Output = ".memoryos/adapters/codex/bootstrap.md"
      FullGate = ".memoryos/adapters/codex/gate.md"
    },
    [pscustomobject]@{
      Adapter = "codex"
      AgentName = "Codex"
      Config = $config.codex
      Template = ".memoryos/templates/codex-gate.md.tmpl"
      Output = ".memoryos/adapters/codex/gate.md"
      FullGate = ".memoryos/adapters/codex/gate.md"
    },
    [pscustomobject]@{
      Adapter = "claude"
      AgentName = "Claude"
      Config = $config.claude
      Template = ".memoryos/templates/claude-bootstrap.md.tmpl"
      Output = ".memoryos/adapters/claude/bootstrap.md"
      FullGate = ".memoryos/adapters/claude/CLAUDE.md"
    },
    [pscustomobject]@{
      Adapter = "claude"
      AgentName = "Claude"
      Config = $config.claude
      Template = ".memoryos/templates/claude-gate.md.tmpl"
      Output = ".memoryos/adapters/claude/CLAUDE.md"
      FullGate = ".memoryos/adapters/claude/CLAUDE.md"
    }
  )

  foreach ($target in $targets) {
    if ($null -eq $target.Config -or $target.Config.enabled -ne $true) {
      continue
    }

    $templatePath = Join-Path $liteRoot ($target.Template -replace '/', '\')
    $outputPath = Join-Path $liteRoot ($target.Output -replace '/', '\')
    $fullGatePath = Join-Path $liteRoot ($target.FullGate -replace '/', '\')
    $bootstrapPath = Join-Path $liteRoot ".memoryos/adapters/$($target.Adapter)/bootstrap.md"
    $adapterSkillPath = Join-Path $liteRoot ".memoryos/adapters/$($target.Adapter)/skills"

    $templateText = Get-Content -LiteralPath $templatePath -Raw -Encoding UTF8
    $expected = Replace-TokenMap -Text $templateText -Tokens @{
      "{{memoryos_root}}" = $liteRoot
      "{{language}}" = $language
      "{{adapter_name}}" = $target.Adapter
      "{{agent_name}}" = $target.AgentName
      "{{bootstrap_path}}" = $bootstrapPath
      "{{full_gate_path}}" = $fullGatePath
      "{{adapter_skill_path}}" = $adapterSkillPath
    }

    if ($Check) {
      if (-not (Test-Path -LiteralPath $outputPath)) {
        $problems += "STALE $($target.Adapter) missing $($target.Output)"
      } else {
        $actual = Get-Content -LiteralPath $outputPath -Raw -Encoding UTF8
        if ($actual -ne $expected) {
          $problems += "STALE $($target.Adapter) $($target.Output)"
        } else {
          $items += "OK $($target.Adapter) $($target.Output)"
        }
      }
    } else {
      if (-not (Test-PathInside -ChildPath $outputPath -ParentPath $liteRoot)) {
        throw "Adapter output escapes Lite root: $outputPath"
      }
      Write-Utf8NoBom -Path $outputPath -Text $expected
      $items += "RENDERED $($target.Adapter) $($target.Output)"
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
Write-Host "OK render-adapters"
