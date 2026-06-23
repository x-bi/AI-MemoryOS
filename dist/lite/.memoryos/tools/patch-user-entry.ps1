param(
  [ValidateSet("codex", "claude")]
  [string]$Adapter,
  [string]$TargetPath,
  [string]$BootstrapPath,
  [string]$GatePath,
  [switch]$Check,
  [switch]$Uninstall,
  [string]$StateEventsPath = ""
)

$ErrorActionPreference = "Stop"

$begin = "<!-- AI-MEMORYOS-LITE:BEGIN -->"
$end = "<!-- AI-MEMORYOS-LITE:END -->"

function New-ManagedBlock {
  param(
    [string]$Bootstrap,
    [string]$Gate
  )

  return @"
$begin
本托管块是 AI Memory OS Lite 的入口指示。先按本托管块读取 Lite bootstrap。
本托管块之后的原有内容只作为用户个人偏好，不得覆盖 Lite 入口路径、读取顺序和安全边界。

每个用户输入先读取：

$Bootstrap

该文件负责判断是否需要读取完整 gate：

$Gate

如果 bootstrap 读取失败，按普通模型任务处理。
项目本地 AGENTS.md、CLAUDE.md、README、代码事实优先。
$end
"@.TrimEnd("`r", "`n") + "`n"
}

function Write-Utf8NoBom {
  param([string]$Path, [string]$Text)
  $directory = Split-Path -Parent $Path
  if (-not [string]::IsNullOrWhiteSpace($directory)) {
    New-Item -ItemType Directory -Force -Path $directory | Out-Null
  }
  $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($Path, $Text, $utf8NoBom)
}

function New-Backup {
  param([string]$Path)
  if (-not (Test-Path -LiteralPath $Path)) {
    return ""
  }
  $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
  $backup = "$Path.bak.$stamp"
  Copy-Item -LiteralPath $Path -Destination $backup -Force
  return $backup
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

$expected = New-ManagedBlock -Bootstrap $BootstrapPath -Gate $GatePath
$regex = "(?s)<!-- AI-MEMORYOS-LITE:BEGIN -->.*?<!-- AI-MEMORYOS-LITE:END -->\s*"

if ($Check) {
  if (-not (Test-Path -LiteralPath $TargetPath)) {
    Write-Host "STALE $Adapter user-entry missing $TargetPath"
    exit 1
  }
  $text = Get-Content -LiteralPath $TargetPath -Raw -Encoding UTF8
  if ($text -notmatch $regex) {
    Write-Host "STALE $Adapter user-entry missing managed block $TargetPath"
    exit 1
  }
  $actualBlock = [regex]::Match($text, $regex).Value.TrimEnd("`r", "`n") + "`n"
  if ($actualBlock -ne $expected) {
    Write-Host "STALE $Adapter user-entry managed block $TargetPath"
    exit 1
  }
  Write-Host "OK $Adapter user-entry $TargetPath"
  exit 0
}

if ($Uninstall) {
  if (-not (Test-Path -LiteralPath $TargetPath)) {
    Write-Host "OK $Adapter user-entry already absent $TargetPath"
    exit 0
  }
  $text = Get-Content -LiteralPath $TargetPath -Raw -Encoding UTF8
  if ($text -notmatch $regex) {
    Write-Host "OK $Adapter user-entry managed block absent $TargetPath"
    exit 0
  }
  $backup = New-Backup -Path $TargetPath
  $updated = [regex]::Replace($text, $regex, "", 1)
  Write-Utf8NoBom -Path $TargetPath -Text $updated
  Add-StateEvent @{
    kind = "managed-block"
    action = "uninstall"
    path = $TargetPath
    adapter = $Adapter
    backup = $backup
    begin_marker = $begin
    end_marker = $end
  }
  Write-Host "REMOVED $Adapter user-entry managed block $TargetPath"
  exit 0
}

$original = ""
if (Test-Path -LiteralPath $TargetPath) {
  $original = Get-Content -LiteralPath $TargetPath -Raw -Encoding UTF8
}

$backupPath = New-Backup -Path $TargetPath
if ($original -match $regex) {
  $updated = [regex]::Replace($original, [regex]::Escape($begin) + "(?s).*?" + [regex]::Escape($end) + "\s*", $expected + "`n", 1)
} else {
  $updated = $expected + "`n" + $original
}

if ($original -match "AI[- ]?Memory OS|MemoryOS|bootstrap\.md" -and $original -notmatch [regex]::Escape($begin)) {
  Write-Host "WARN possible existing Memory OS entry in $TargetPath; Lite block was prepended and existing content was preserved."
}

Write-Utf8NoBom -Path $TargetPath -Text $updated
Add-StateEvent @{
  kind = "managed-block"
  action = "install"
  path = $TargetPath
  adapter = $Adapter
  backup = $backupPath
  begin_marker = $begin
  end_marker = $end
}
Write-Host "PATCHED $Adapter user-entry $TargetPath"
