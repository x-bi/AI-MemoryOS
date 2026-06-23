param(
  [switch]$Check,
  [switch]$Uninstall,
  [switch]$Prune,
  [string]$ConfigPath = ""
)

$ErrorActionPreference = "Stop"

$packageRoot = [System.IO.Path]::GetFullPath($PSScriptRoot)
if ([string]::IsNullOrWhiteSpace($ConfigPath)) {
  $ConfigPath = Join-Path $packageRoot "memoryos.config.json"
}

$coreScript = Join-Path $packageRoot ".memoryos/tools/install-core.ps1"
if (-not (Test-Path -LiteralPath $coreScript)) {
  throw "Missing Lite installer core: $coreScript"
}

& $coreScript -ConfigPath $ConfigPath -Check:$Check -Uninstall:$Uninstall -Prune:$Prune
exit $LASTEXITCODE
