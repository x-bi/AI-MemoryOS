param(
  [string]$SettingsJson,
  [string]$HookScriptPath,
  [switch]$Check,
  [switch]$Uninstall,
  [string]$StateEventsPath = ""
)

$ErrorActionPreference = "Stop"

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

function Write-JsonFile {
  param(
    [string]$Path,
    [object]$Value
  )
  $directory = Split-Path -Parent $Path
  New-Item -ItemType Directory -Force -Path $directory | Out-Null
  $tmp = "$Path.tmp"
  $json = $Value | ConvertTo-Json -Depth 30
  $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($tmp, $json.TrimEnd("`r", "`n") + "`n", $utf8NoBom)
  Move-Item -LiteralPath $tmp -Destination $Path -Force
}

function Get-SettingsObject {
  param([string]$Path)
  if (-not (Test-Path -LiteralPath $Path)) {
    return [pscustomobject]@{}
  }
  $text = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
  if ([string]::IsNullOrWhiteSpace($text)) {
    return [pscustomobject]@{}
  }
  return $text | ConvertFrom-Json
}

function Ensure-Property {
  param(
    [object]$Object,
    [string]$Name,
    [object]$Value
  )
  if ($null -eq $Object.PSObject.Properties[$Name]) {
    $Object | Add-Member -NotePropertyName $Name -NotePropertyValue $Value
  }
}

function Get-LiteCommand {
  param([string]$ScriptPath)
  return 'powershell.exe -NoProfile -ExecutionPolicy Bypass -File "' + $ScriptPath + '" -LiteMarker "AI-MEMORYOS-LITE"'
}

function Remove-LiteHooks {
  param([object[]]$PromptHooks)

  $result = @()
  foreach ($entry in @($PromptHooks)) {
    if ($null -eq $entry) { continue }
    $hooks = @()
    foreach ($hook in @($entry.hooks)) {
      $command = [string]$hook.command
      if ($command -match "AI-MEMORYOS-LITE" -or $command -match "inject-bootstrap-reminder\.ps1") {
        continue
      }
      $hooks += $hook
    }
    $entry.hooks = @($hooks)
    $result += $entry
  }
  return @($result)
}

function Has-LiteHook {
  param([object[]]$PromptHooks, [string]$ExpectedCommand)
  foreach ($entry in @($PromptHooks)) {
    foreach ($hook in @($entry.hooks)) {
      if ([string]$hook.command -eq $ExpectedCommand) {
        return $true
      }
    }
  }
  return $false
}

$expectedCommand = Get-LiteCommand -ScriptPath ([System.IO.Path]::GetFullPath($HookScriptPath))

try {
  if ($Check) {
    if (-not (Test-Path -LiteralPath $SettingsJson)) {
      Write-Host "STALE claude hook settings_json missing $SettingsJson"
      exit 1
    }
    $settings = Get-SettingsObject -Path $SettingsJson
    $promptHooks = @($settings.hooks.UserPromptSubmit)
    if (-not (Has-LiteHook -PromptHooks $promptHooks -ExpectedCommand $expectedCommand)) {
      Write-Host "STALE claude hook missing or stale $SettingsJson"
      exit 1
    }
    Write-Host "OK claude hook $SettingsJson"
    exit 0
  }

  $settings = Get-SettingsObject -Path $SettingsJson
  Ensure-Property -Object $settings -Name "hooks" -Value ([pscustomobject]@{})
  Ensure-Property -Object $settings.hooks -Name "UserPromptSubmit" -Value @()

  $promptHooks = Remove-LiteHooks -PromptHooks @($settings.hooks.UserPromptSubmit)

  if ($Uninstall) {
    if (Test-Path -LiteralPath $SettingsJson) {
      $backup = New-Backup -Path $SettingsJson
      $settings.hooks.UserPromptSubmit = @($promptHooks)
      Write-JsonFile -Path $SettingsJson -Value $settings
      Add-StateEvent @{
        kind = "claude-hook"
        action = "uninstall"
        settings_json = $SettingsJson
        id = "AI-MEMORYOS-LITE"
        backup = $backup
      }
    }
    Write-Host "REMOVED claude hook $SettingsJson"
    exit 0
  }

  $backupPath = New-Backup -Path $SettingsJson
  $liteEntry = [pscustomobject]@{
    matcher = ""
    hooks = @(
      [pscustomobject]@{
        type = "command"
        command = $expectedCommand
      }
    )
  }
  $settings.hooks.UserPromptSubmit = @($promptHooks + $liteEntry)
  Write-JsonFile -Path $SettingsJson -Value $settings
  Add-StateEvent @{
    kind = "claude-hook"
    action = "install"
    settings_json = $SettingsJson
    id = "AI-MEMORYOS-LITE"
    command_contains = "inject-bootstrap-reminder.ps1"
    backup = $backupPath
  }
  Write-Host "PATCHED claude hook $SettingsJson"
} catch {
  Write-Host "ERROR claude hook $($_.Exception.Message)"
  exit 1
}
