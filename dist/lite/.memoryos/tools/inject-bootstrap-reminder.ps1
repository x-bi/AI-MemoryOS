param(
  [string]$LiteMarker = ""
)

$ErrorActionPreference = "SilentlyContinue"

$memoryosRoot = Split-Path -Parent $PSScriptRoot
$liteRoot = Split-Path -Parent $memoryosRoot
$bootstrap = Join-Path $liteRoot ".memoryos/adapters/claude/bootstrap.md"

Write-Output "[强制] 本轮第一个工具调用必须先 Read $bootstrap，再按 bootstrap 判断是否读取 full gate。"
