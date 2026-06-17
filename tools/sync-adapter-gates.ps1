param(
  [string]$Root = "C:\Users\btf\AI-MemoryOS",
  [ValidateSet("", "codex", "claude")]
  [string]$Adapter = "",
  [switch]$Check,
  [string]$OutDir = ""
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

function Join-MemoryOsPath {
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
  $joined = Join-Path $rootFull ($RelativePath -replace '/', '\')
  $full = [System.IO.Path]::GetFullPath($joined)
  if (-not (Test-PathInside -ChildPath $full -ParentPath $rootFull)) {
    throw "Path escapes Memory OS root: $RelativePath"
  }
  return $full
}

function Get-RelativePathText {
  param([string]$Path)
  return $Path.Replace('\', '/')
}

function Read-MemoryOsText {
  param([string]$RelativePath)
  $path = Join-MemoryOsPath -RootPath $Root -RelativePath $RelativePath
  if (-not (Test-Path -LiteralPath $path)) {
    throw "Missing adapter gate source input: $RelativePath"
  }
  return Get-Content -LiteralPath $path -Raw -Encoding UTF8
}

function Normalize-RenderedText {
  param([string]$Text)
  return $Text.TrimEnd("`r", "`n") + "`n"
}

function Get-InputHash {
  param(
    [object[]]$Inputs
  )

  $manifest = ""
  foreach ($input in $Inputs) {
    $manifest += "path:$($input.Path)`n"
    $manifest += "length:$($input.Text.Length)`n"
    $manifest += $input.Text
    $manifest += "`n--memoryos-render-input--`n"
  }
  $bytes = [System.Text.Encoding]::UTF8.GetBytes($manifest)
  $sha = [System.Security.Cryptography.SHA256]::Create()
  try {
    return [System.BitConverter]::ToString($sha.ComputeHash($bytes)).Replace("-", "").ToLowerInvariant()
  } finally {
    $sha.Dispose()
  }
}

function Replace-TokenMap {
  param(
    [string]$Text,
    [hashtable]$Tokens
  )

  $rendered = $Text
  foreach ($key in @($Tokens.Keys | Sort-Object { $_.Length } -Descending)) {
    $rendered = $rendered.Replace($key, [string]$Tokens[$key])
  }
  return $rendered
}

function Get-RenderTargets {
  $sharedBootstrap = "adapters/gate-source/shared/bootstrap-core.md"
  $sharedGate = "adapters/gate-source/shared/gate-core.md"
  return @(
    [pscustomobject]@{
      Adapter = "codex"
      Kind = "adapter-bootstrap"
      TargetKind = "bootstrap"
      Template = "adapters/codex/templates/bootstrap.md.tmpl"
      Target = "adapters/codex/bootstrap.md"
      Shared = $sharedBootstrap
      Overlay = "adapters/gate-source/overlays/codex-bootstrap.md"
      AgentName = "Codex"
      FullGatePath = "C:\Users\btf\AI-MemoryOS\adapters\codex\gate.md"
      BootstrapPath = "C:\Users\btf\AI-MemoryOS\adapters\codex\bootstrap.md"
      UserEntryPath = "C:\Users\btf\.codex\AGENTS.md"
      FullGateFilename = "gate.md"
    },
    [pscustomobject]@{
      Adapter = "codex"
      Kind = "adapter-gate"
      TargetKind = "full-gate"
      Template = "adapters/codex/templates/gate.md.tmpl"
      Target = "adapters/codex/gate.md"
      Shared = $sharedGate
      Overlay = "adapters/gate-source/overlays/codex-gate.md"
      AgentName = "Codex"
      FullGatePath = "C:\Users\btf\AI-MemoryOS\adapters\codex\gate.md"
      BootstrapPath = "C:\Users\btf\AI-MemoryOS\adapters\codex\bootstrap.md"
      UserEntryPath = "C:\Users\btf\.codex\AGENTS.md"
      FullGateFilename = "gate.md"
    },
    [pscustomobject]@{
      Adapter = "claude"
      Kind = "adapter-bootstrap"
      TargetKind = "bootstrap"
      Template = "adapters/claude/templates/bootstrap.md.tmpl"
      Target = "adapters/claude/bootstrap.md"
      Shared = $sharedBootstrap
      Overlay = "adapters/gate-source/overlays/claude-bootstrap.md"
      AgentName = "Claude"
      FullGatePath = "C:\Users\btf\AI-MemoryOS\adapters\claude\CLAUDE.md"
      BootstrapPath = "C:\Users\btf\AI-MemoryOS\adapters\claude\bootstrap.md"
      UserEntryPath = "C:\Users\btf\.claude\CLAUDE.md"
      FullGateFilename = "CLAUDE.md"
    },
    [pscustomobject]@{
      Adapter = "claude"
      Kind = "adapter-gate"
      TargetKind = "full-gate"
      Template = "adapters/claude/templates/CLAUDE.md.tmpl"
      Target = "adapters/claude/CLAUDE.md"
      Shared = $sharedGate
      Overlay = "adapters/gate-source/overlays/claude-gate.md"
      AgentName = "Claude"
      FullGatePath = "C:\Users\btf\AI-MemoryOS\adapters\claude\CLAUDE.md"
      BootstrapPath = "C:\Users\btf\AI-MemoryOS\adapters\claude\bootstrap.md"
      UserEntryPath = "C:\Users\btf\.claude\CLAUDE.md"
      FullGateFilename = "CLAUDE.md"
    }
  ) | Where-Object { [string]::IsNullOrWhiteSpace($Adapter) -or $_.Adapter -eq $Adapter }
}

function Render-AdapterGate {
  param([object]$TargetConfig)

  $templateText = Read-MemoryOsText -RelativePath $TargetConfig.Template
  $sharedText = Read-MemoryOsText -RelativePath $TargetConfig.Shared
  $overlayText = Read-MemoryOsText -RelativePath $TargetConfig.Overlay

  $inputs = @(
    [pscustomobject]@{ Path = $TargetConfig.Template; Text = $templateText },
    [pscustomobject]@{ Path = $TargetConfig.Shared; Text = $sharedText },
    [pscustomobject]@{ Path = $TargetConfig.Overlay; Text = $overlayText }
  )
  $renderHash = Get-InputHash -Inputs $inputs
  $marker = "<!-- Generated from adapters/gate-source/** and adapter templates; render-sha256: $renderHash; adapter: $($TargetConfig.Adapter); target: $($TargetConfig.TargetKind). Do not edit by hand; update source/templates and run tools/sync-adapter-gates.ps1. -->"

  $tokens = @{
    "{{generated_marker}}" = $marker
    "{{adapter_name}}" = $TargetConfig.Adapter
    "{{agent_name}}" = $TargetConfig.AgentName
    "{{bootstrap_path}}" = $TargetConfig.BootstrapPath
    "{{full_gate_path}}" = $TargetConfig.FullGatePath
    "{{user_entry_path}}" = $TargetConfig.UserEntryPath
    "{{full_gate_filename}}" = $TargetConfig.FullGateFilename
    "{{shared_bootstrap_core}}" = $sharedText.TrimEnd("`r", "`n")
    "{{shared_gate_core}}" = $sharedText.TrimEnd("`r", "`n")
    "{{overlay_body}}" = $overlayText.TrimEnd("`r", "`n")
  }

  return Normalize-RenderedText -Text (Replace-TokenMap -Text $templateText -Tokens $tokens)
}

$items = @()
$problems = @()
$hadError = $false

try {
  $rootFull = [System.IO.Path]::GetFullPath((Resolve-Path -LiteralPath $Root).Path)
  $outDirFull = $null
  if (-not [string]::IsNullOrWhiteSpace($OutDir)) {
    if ([System.IO.Path]::IsPathRooted($OutDir)) {
      throw "OutDir must be a Memory OS relative path: $OutDir"
    }
    if ($OutDir -match '(^|[\\/])\.\.([\\/]|$)') {
      throw "OutDir must not contain path traversal: $OutDir"
    }
    $outDirFull = Join-MemoryOsPath -RootPath $Root -RelativePath $OutDir
    $formalRoots = @(
      (Join-MemoryOsPath -RootPath $Root -RelativePath "adapters/codex"),
      (Join-MemoryOsPath -RootPath $Root -RelativePath "adapters/claude")
    )
    foreach ($formalRoot in $formalRoots) {
      if (Test-PathInside -ChildPath $outDirFull -ParentPath $formalRoot) {
        throw "OutDir must not be inside formal adapter target directories: $OutDir"
      }
    }
  }

  foreach ($targetConfig in Get-RenderTargets) {
    $expectedContent = Render-AdapterGate -TargetConfig $targetConfig
    $targetPath = Join-MemoryOsPath -RootPath $Root -RelativePath $targetConfig.Target
    $relativeTarget = Get-RelativePathText -Path $targetConfig.Target

    if ($Check) {
      if (-not (Test-Path -LiteralPath $targetPath)) {
        $problems += "STALE $($targetConfig.Kind) $($targetConfig.Adapter) missing $relativeTarget"
      } else {
        $actualContent = Get-Content -LiteralPath $targetPath -Raw -Encoding UTF8
        if ($actualContent -ne $expectedContent) {
          $problems += "STALE $($targetConfig.Kind) $($targetConfig.Adapter) $relativeTarget"
        } else {
          $items += "OK $($targetConfig.Kind) $($targetConfig.Adapter) $relativeTarget"
        }
      }
    } elseif ([string]::IsNullOrWhiteSpace($OutDir)) {
      $targetDirectory = Split-Path -Parent $targetPath
      New-Item -ItemType Directory -Force -Path $targetDirectory | Out-Null
      if (-not (Test-PathInside -ChildPath (Resolve-Path -LiteralPath $targetDirectory).Path -ParentPath $rootFull)) {
        throw "Generated adapter gate output escapes Memory OS root: $relativeTarget"
      }
      $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
      [System.IO.File]::WriteAllText($targetPath, $expectedContent, $utf8NoBom)
      $items += "SYNCED $($targetConfig.Kind) $($targetConfig.Adapter) $relativeTarget"
    }

    if (-not [string]::IsNullOrWhiteSpace($OutDir)) {
      $renderPath = Join-Path $outDirFull ($targetConfig.Target -replace '/', '\')
      $renderPathFull = [System.IO.Path]::GetFullPath($renderPath)
      if (-not (Test-PathInside -ChildPath $renderPathFull -ParentPath $outDirFull)) {
        throw "Rendered output escapes OutDir: $($targetConfig.Target)"
      }
      $renderDirectory = Split-Path -Parent $renderPathFull
      New-Item -ItemType Directory -Force -Path $renderDirectory | Out-Null
      $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
      [System.IO.File]::WriteAllText($renderPathFull, $expectedContent, $utf8NoBom)
      $items += "RENDERED $($targetConfig.Kind) $($targetConfig.Adapter) $($OutDir.TrimEnd('/', '\'))/$relativeTarget"
    }
  }
} catch {
  $problems += "ERROR $($_.Exception.Message)"
  $hadError = $true
}

if ($problems.Count -gt 0) {
  $problems | ForEach-Object { Write-Host $_ }
  if ($hadError -or (@($problems | Where-Object { $_ -like "ERROR *" }).Count -gt 0)) {
    Write-Host "ERROR adapter-gates completed with problems."
  } else {
    Write-Host "STALE adapter-gates completed with problems."
  }
  exit 1
}

if ($Check) {
  Write-Host "OK adapter-gates"
} elseif (-not [string]::IsNullOrWhiteSpace($OutDir)) {
  Write-Host "RENDERED adapter-gates items=$($items.Count)"
} else {
  Write-Host "SYNCED adapter-gates items=$($items.Count)"
}
