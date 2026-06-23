param(
  [string]$ConfigPath = "",
  [switch]$Check,
  [switch]$Uninstall,
  [switch]$Prune
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

function Invoke-Step {
  param(
    [string]$Name,
    [scriptblock]$Script
  )
  Write-Host "== $Name =="
  $global:LASTEXITCODE = 0
  & $Script
  $succeeded = $?
  $exitCode = $global:LASTEXITCODE
  if (-not $succeeded -or $exitCode -ne 0) {
    throw "$Name failed with exit code $exitCode"
  }
}

function Add-ArrayProperty {
  param(
    [hashtable]$Table,
    [string]$Name,
    [object]$Value
  )
  if (-not $Table.ContainsKey($Name)) {
    $Table[$Name] = @()
  }
  if ($null -ne $Value) {
    $Table[$Name] += $Value
  }
}

function Write-Utf8NoBom {
  param([string]$Path, [string]$Text)
  $directory = Split-Path -Parent $Path
  New-Item -ItemType Directory -Force -Path $directory | Out-Null
  $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($Path, $Text.TrimEnd("`r", "`n") + "`n", $utf8NoBom)
}

function Assert-InstallConfig {
  param([object]$Config)

  if ($null -eq $Config.memoryos -or [string]::IsNullOrWhiteSpace([string]$Config.memoryos.root)) {
    throw "memoryos.root is required"
  }
  if ($null -eq $Config.skills -or @($Config.skills.active).Count -eq 0) {
    throw "skills.active must contain at least one skill"
  }

  $enabled = @()
  foreach ($adapter in @("codex", "claude")) {
    $adapterConfig = $Config.$adapter
    if ($null -eq $adapterConfig -or $adapterConfig.enabled -ne $true) {
      continue
    }
    $enabled += $adapter
    $entryPath = if ($adapter -eq "codex") { [string]$adapterConfig.user_agents } else { [string]$adapterConfig.user_claude }
    if ([string]::IsNullOrWhiteSpace($entryPath)) {
      throw "$adapter user entry path is required"
    }
    if ([string]::IsNullOrWhiteSpace([string]$adapterConfig.skills_dir)) {
      throw "$adapter.skills_dir is required"
    }
  }
  if ($enabled.Count -eq 0) {
    throw "At least one adapter must be enabled"
  }
  if ($Config.claude.enabled -eq $true -and $Config.claude.install_hook -eq $true -and [string]::IsNullOrWhiteSpace([string]$Config.claude.settings_json)) {
    throw "claude.settings_json is required when claude.install_hook=true"
  }
}

function Write-Manifest {
  param(
    [string]$ManifestPath,
    [string]$LiteRoot,
    [string]$ConfigFull,
    [string]$EventsPath
  )

  $managedFiles = @()
  $managedHooks = @()
  $managedJunctions = @()
  $backups = @()

  if (Test-Path -LiteralPath $EventsPath) {
    Get-Content -LiteralPath $EventsPath -Encoding UTF8 | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | ForEach-Object {
      $event = $_ | ConvertFrom-Json
      if ($event.backup -and -not [string]::IsNullOrWhiteSpace([string]$event.backup)) {
        $backups += [string]$event.backup
      }
      switch ([string]$event.kind) {
        "managed-block" {
          if ([string]$event.action -eq "install") {
            $managedFiles += [pscustomobject]@{
              path = [string]$event.path
              kind = "managed-block"
              adapter = [string]$event.adapter
              begin_marker = [string]$event.begin_marker
              end_marker = [string]$event.end_marker
              backup = [string]$event.backup
            }
          }
        }
        "claude-hook" {
          if ([string]$event.action -eq "install") {
            $managedHooks += [pscustomobject]@{
              settings_json = [string]$event.settings_json
              id = "AI-MEMORYOS-LITE"
              command_contains = "inject-bootstrap-reminder.ps1"
              backup = [string]$event.backup
            }
          }
        }
        "skill-junction" {
          if ([string]$event.action -eq "install") {
            $managedJunctions += [pscustomobject]@{
              path = [string]$event.path
              target = [string]$event.target
              adapter = [string]$event.adapter
            }
          }
        }
      }
    }
  }

  $manifest = [pscustomobject]@{
    schema = 1
    installed_at = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    memoryos_root = $LiteRoot
    config_path = $ConfigFull
    managed_files = $managedFiles
    managed_hooks = $managedHooks
    managed_junctions = $managedJunctions
    backups = @($backups | Select-Object -Unique)
  }
  Write-Utf8NoBom -Path $ManifestPath -Text ($manifest | ConvertTo-Json -Depth 20)
}

$configFull = Resolve-ConfigPath -Path $ConfigPath
if (-not (Test-Path -LiteralPath $configFull)) {
  throw "Config not found: $configFull"
}
$config = Get-Content -LiteralPath $configFull -Raw -Encoding UTF8 | ConvertFrom-Json
if (-not $Uninstall) {
  Assert-InstallConfig -Config $config
}
$liteRoot = Resolve-LitePath -ConfigFile $configFull -PathText ([string]$config.memoryos.root)
$memoryosRoot = Join-Path $liteRoot ".memoryos"
$eventsPath = Join-Path $memoryosRoot "install-events.jsonl"
$manifestPath = Join-Path $memoryosRoot "install-state.json"

if ($Check) {
  Invoke-Step -Name "render-adapters -Check" -Script { & (Join-Path $PSScriptRoot "render-adapters.ps1") -ConfigPath $configFull -Check }
  Invoke-Step -Name "sync-skills -Check" -Script { & (Join-Path $PSScriptRoot "sync-skills.ps1") -ConfigPath $configFull -Check }
  foreach ($adapter in @("codex", "claude")) {
    $adapterConfig = $config.$adapter
    if ($null -eq $adapterConfig -or $adapterConfig.enabled -ne $true) { continue }
    $entryPath = if ($adapter -eq "codex") { [string]$adapterConfig.user_agents } else { [string]$adapterConfig.user_claude }
    if ([string]::IsNullOrWhiteSpace($entryPath)) { continue }
    $entryFull = Resolve-LitePath -ConfigFile $configFull -PathText $entryPath
    $bootstrapPath = Join-Path $liteRoot ".memoryos/adapters/$adapter/bootstrap.md"
    $gatePath = if ($adapter -eq "codex") { Join-Path $liteRoot ".memoryos/adapters/codex/gate.md" } else { Join-Path $liteRoot ".memoryos/adapters/claude/CLAUDE.md" }
    Invoke-Step -Name "$adapter user-entry -Check" -Script { & (Join-Path $PSScriptRoot "patch-user-entry.ps1") -Adapter $adapter -TargetPath $entryFull -BootstrapPath $bootstrapPath -GatePath $gatePath -Check }
  }
  if ($config.claude.enabled -eq $true -and $config.claude.install_hook -eq $true -and -not [string]::IsNullOrWhiteSpace([string]$config.claude.settings_json)) {
    Invoke-Step -Name "claude hook -Check" -Script {
      & (Join-Path $PSScriptRoot "patch-claude-hook.ps1") -SettingsJson (Resolve-LitePath -ConfigFile $configFull -PathText ([string]$config.claude.settings_json)) -HookScriptPath (Join-Path $memoryosRoot "tools/inject-bootstrap-reminder.ps1") -Check
    }
  }
  Invoke-Step -Name "validate" -Script { & (Join-Path $PSScriptRoot "validate.ps1") -ConfigPath $configFull }
  exit 0
}

if (Test-Path -LiteralPath $eventsPath) {
  Remove-Item -LiteralPath $eventsPath -Force
}

if ($Uninstall) {
  foreach ($adapter in @("codex", "claude")) {
    $adapterConfig = $config.$adapter
    if ($null -eq $adapterConfig) { continue }
    $entryPath = if ($adapter -eq "codex") { [string]$adapterConfig.user_agents } else { [string]$adapterConfig.user_claude }
    if ([string]::IsNullOrWhiteSpace($entryPath)) { continue }
    $entryFull = Resolve-LitePath -ConfigFile $configFull -PathText $entryPath
    $bootstrapPath = Join-Path $liteRoot ".memoryos/adapters/$adapter/bootstrap.md"
    $gatePath = if ($adapter -eq "codex") { Join-Path $liteRoot ".memoryos/adapters/codex/gate.md" } else { Join-Path $liteRoot ".memoryos/adapters/claude/CLAUDE.md" }
    Invoke-Step -Name "$adapter user-entry uninstall" -Script { & (Join-Path $PSScriptRoot "patch-user-entry.ps1") -Adapter $adapter -TargetPath $entryFull -BootstrapPath $bootstrapPath -GatePath $gatePath -Uninstall -StateEventsPath $eventsPath }
  }
  if (-not [string]::IsNullOrWhiteSpace([string]$config.claude.settings_json)) {
    Invoke-Step -Name "claude hook uninstall" -Script {
      & (Join-Path $PSScriptRoot "patch-claude-hook.ps1") -SettingsJson (Resolve-LitePath -ConfigFile $configFull -PathText ([string]$config.claude.settings_json)) -HookScriptPath (Join-Path $memoryosRoot "tools/inject-bootstrap-reminder.ps1") -Uninstall -StateEventsPath $eventsPath
    }
  }
  Invoke-Step -Name "sync-skills uninstall" -Script { & (Join-Path $PSScriptRoot "sync-skills.ps1") -ConfigPath $configFull -Uninstall }
  Write-Host "OK Lite uninstall"
  exit 0
}

if ($null -ne $config.local -and -not [string]::IsNullOrWhiteSpace([string]$config.local.private_dir)) {
  $privateDir = Resolve-LitePath -ConfigFile $configFull -PathText ([string]$config.local.private_dir)
  New-Item -ItemType Directory -Force -Path $privateDir | Out-Null
}

Invoke-Step -Name "render-adapters" -Script { & (Join-Path $PSScriptRoot "render-adapters.ps1") -ConfigPath $configFull }
Invoke-Step -Name "sync-skills" -Script { & (Join-Path $PSScriptRoot "sync-skills.ps1") -ConfigPath $configFull -Prune:$Prune -StateEventsPath $eventsPath }

foreach ($adapter in @("codex", "claude")) {
  $adapterConfig = $config.$adapter
  if ($null -eq $adapterConfig -or $adapterConfig.enabled -ne $true) { continue }
  $entryPath = if ($adapter -eq "codex") { [string]$adapterConfig.user_agents } else { [string]$adapterConfig.user_claude }
  if ([string]::IsNullOrWhiteSpace($entryPath)) {
    throw "$adapter user entry path is required"
  }
  $entryFull = Resolve-LitePath -ConfigFile $configFull -PathText $entryPath
  $bootstrapPath = Join-Path $liteRoot ".memoryos/adapters/$adapter/bootstrap.md"
  $gatePath = if ($adapter -eq "codex") { Join-Path $liteRoot ".memoryos/adapters/codex/gate.md" } else { Join-Path $liteRoot ".memoryos/adapters/claude/CLAUDE.md" }
  Invoke-Step -Name "$adapter user-entry patch" -Script { & (Join-Path $PSScriptRoot "patch-user-entry.ps1") -Adapter $adapter -TargetPath $entryFull -BootstrapPath $bootstrapPath -GatePath $gatePath -StateEventsPath $eventsPath }
}

if ($config.claude.enabled -eq $true -and $config.claude.install_hook -eq $true) {
  if ([string]::IsNullOrWhiteSpace([string]$config.claude.settings_json)) {
    Write-Host "WARN Claude hook skipped: claude.settings_json is empty."
  } else {
    Invoke-Step -Name "claude hook patch" -Script {
      & (Join-Path $PSScriptRoot "patch-claude-hook.ps1") -SettingsJson (Resolve-LitePath -ConfigFile $configFull -PathText ([string]$config.claude.settings_json)) -HookScriptPath (Join-Path $memoryosRoot "tools/inject-bootstrap-reminder.ps1") -StateEventsPath $eventsPath
    }
  }
}

Write-Manifest -ManifestPath $manifestPath -LiteRoot $liteRoot -ConfigFull $configFull -EventsPath $eventsPath
Invoke-Step -Name "validate" -Script { & (Join-Path $PSScriptRoot "validate.ps1") -ConfigPath $configFull }
Write-Host "OK Lite install"
