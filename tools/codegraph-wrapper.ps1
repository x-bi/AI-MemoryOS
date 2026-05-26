param(
  [Parameter(Position = 0)]
  [ValidateSet("serve", "status")]
  [string]$Command = "serve"
)

$ErrorActionPreference = "Stop"

$memoryRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$configPath = Join-Path $memoryRoot "private\codegraph\registry.json"
$projectTool = Join-Path $memoryRoot "tools\codegraph-project.ps1"

function Get-CodeGraphConfig {
  if (-not (Test-Path -LiteralPath $configPath)) {
    return [pscustomobject]@{
      codegraph = [pscustomobject]@{
        enabled = $false
        reason = "registry_missing"
      }
    }
  }

  $raw = Get-Content -LiteralPath $configPath -Raw -Encoding UTF8
  if ([string]::IsNullOrWhiteSpace($raw)) {
    return [pscustomobject]@{
      codegraph = [pscustomobject]@{
        enabled = $false
        reason = "registry_empty"
      }
    }
  }

  return $raw | ConvertFrom-Json
}

function Get-CodeGraphCommand {
  $cmd = Get-Command codegraph -ErrorAction SilentlyContinue
  if (-not $cmd) {
    throw "CodeGraph executable not found on PATH. Install with: npm install -g @colbymchenry/codegraph@0.9.4"
  }
  return $cmd.Source
}

function Get-PreparePath {
  if (-not [string]::IsNullOrWhiteSpace($env:AI_MEMORYOS_CODEGRAPH_PROJECT_PATH)) {
    return $env:AI_MEMORYOS_CODEGRAPH_PROJECT_PATH
  }
  return (Get-Location).Path
}

$config = Get-CodeGraphConfig
$enabled = $false
if ($config.codegraph -and $null -ne $config.codegraph.enabled) {
  $enabled = [bool]$config.codegraph.enabled
}

if ($Command -eq "status") {
  [pscustomobject]@{
    enabled = $enabled
    registry = $configPath
    codegraph = (Get-Command codegraph -ErrorAction SilentlyContinue).Source
    launchPath = (Get-PreparePath)
  } | ConvertTo-Json -Depth 4
  exit 0
}

if (-not $enabled) {
  throw "CodeGraph is disabled by AI Memory OS policy. Enable private\codegraph\registry.json before starting the MCP server."
}

$preparePath = Get-PreparePath
$prepareJson = & powershell -NoProfile -ExecutionPolicy Bypass -File $projectTool prepare -SourcePath $preparePath
if ($LASTEXITCODE -ne 0) {
  throw "Unable to prepare CodeGraph private slot for path: $preparePath"
}

$prepared = $prepareJson | ConvertFrom-Json
if (-not $prepared.worktreePath) {
  throw "CodeGraph prepare did not return a private worktree path."
}

$codegraph = Get-CodeGraphCommand
& $codegraph serve --mcp --path $prepared.worktreePath
