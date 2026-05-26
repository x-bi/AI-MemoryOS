param(
  [Parameter(Mandatory = $true, Position = 0)]
  [ValidateSet("status", "register", "enable", "disable", "prepare", "add-module-slot")]
  [string]$Command,

  [string]$ProjectId,
  [string]$SourcePath,
  [string]$SlotName,
  [string[]]$Branches
)

$ErrorActionPreference = "Stop"

$memoryRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$root = Join-Path $memoryRoot "private\codegraph"
$registryPath = Join-Path $root "registry.json"

function Ensure-PrivateRoot {
  New-Item -ItemType Directory -Force -Path $root | Out-Null
}

function ConvertTo-Hashtable($value) {
  if ($null -eq $value) {
    return $null
  }

  if ($value -is [System.Collections.IDictionary]) {
    $hash = [ordered]@{}
    foreach ($key in $value.Keys) {
      $hash[$key] = ConvertTo-Hashtable $value[$key]
    }
    return $hash
  }

  if ($value -is [pscustomobject]) {
    $hash = [ordered]@{}
    foreach ($prop in $value.PSObject.Properties) {
      $hash[$prop.Name] = ConvertTo-Hashtable $prop.Value
    }
    return $hash
  }

  if (($value -is [System.Collections.IEnumerable]) -and -not ($value -is [string])) {
    $items = @()
    foreach ($item in $value) {
      $items += ,(ConvertTo-Hashtable $item)
    }
    return $items
  }

  return $value
}

function New-DefaultRegistry {
  [ordered]@{
    codegraph = [ordered]@{
      enabled = $false
      defaultMode = "hybrid-slots"
      projects = [ordered]@{}
    }
  }
}

function Read-Registry {
  Ensure-PrivateRoot
  if (-not (Test-Path -LiteralPath $registryPath)) {
    return New-DefaultRegistry
  }

  $raw = Get-Content -LiteralPath $registryPath -Raw -Encoding UTF8
  if ([string]::IsNullOrWhiteSpace($raw)) {
    return New-DefaultRegistry
  }

  $json = ConvertTo-Hashtable ($raw | ConvertFrom-Json)
  if (-not $json.Contains("codegraph")) {
    return New-DefaultRegistry
  }
  if (-not $json.codegraph.Contains("projects")) {
    $json.codegraph.projects = [ordered]@{}
  }
  return $json
}

function Write-Registry($registry) {
  Ensure-PrivateRoot
  $registry | ConvertTo-Json -Depth 30 | Set-Content -LiteralPath $registryPath -Encoding UTF8
}

function Require-ProjectId {
  if ([string]::IsNullOrWhiteSpace($ProjectId)) {
    throw "ProjectId is required for this command."
  }
}

function Get-CodeGraphCommand {
  $cmd = Get-Command codegraph -ErrorAction SilentlyContinue
  if (-not $cmd) {
    throw "CodeGraph executable not found on PATH. Install with: npm install -g @colbymchenry/codegraph@0.9.4"
  }
  return $cmd.Source
}

function Invoke-Checked($file, [string[]]$arguments) {
  $previousErrorActionPreference = $ErrorActionPreference
  $ErrorActionPreference = "Continue"
  try {
    & $file @arguments > $null 2> $null
    $exitCode = $LASTEXITCODE
  }
  finally {
    $ErrorActionPreference = $previousErrorActionPreference
  }

  if ($exitCode -ne 0) {
    throw "Command failed: $file $($arguments -join ' ')"
  }
}

function Sanitize-SlotName([string]$name) {
  if ([string]::IsNullOrWhiteSpace($name)) {
    return "default"
  }
  return ($name -replace "[^A-Za-z0-9._-]", "_")
}

function Assert-ModuleSlotName([string]$name) {
  $slot = Sanitize-SlotName $name
  $genericNames = @(
    "active",
    "branch",
    "claude",
    "codegraph",
    "codex",
    "current",
    "default",
    "dev",
    "feature",
    "graph",
    "hot",
    "index",
    "module",
    "slot",
    "temp"
  )

  if ($genericNames -contains $slot.ToLowerInvariant()) {
    throw "Module slot name '$slot' is too generic. Use the business feature group name, for example 'jd-brocade-gift'."
  }
}

function Get-BranchNames($items) {
  $names = @()
  foreach ($item in @($items)) {
    if ($null -eq $item) {
      continue
    }
    if ($item -is [string]) {
      $names += $item
    } elseif ($item.Contains("name")) {
      $names += $item.name
    }
  }
  return $names
}

function Get-ModuleSlotName($project, [string]$branch) {
  if ([string]::IsNullOrWhiteSpace($branch)) {
    return $null
  }

  if ($project.Contains("activeModuleSlots")) {
    foreach ($moduleSlot in @($project.activeModuleSlots)) {
      if ($null -eq $moduleSlot) {
        continue
      }

      $status = $moduleSlot.status
      if ($status -in @("inactive", "cold", "disabled")) {
        continue
      }

      $branches = Get-BranchNames $moduleSlot.branches
      if ($branches -contains $branch) {
        if (-not [string]::IsNullOrWhiteSpace($moduleSlot.slot)) {
          return (Sanitize-SlotName $moduleSlot.slot)
        }
        if (-not [string]::IsNullOrWhiteSpace($moduleSlot.module)) {
          return (Sanitize-SlotName $moduleSlot.module)
        }
        return (Sanitize-SlotName $branch)
      }
    }
  }

  # Backward compatibility with the earlier one-branch-one-active-slot shape.
  $legacyActive = Get-BranchNames $project.activeModuleBranches
  if ($legacyActive -contains $branch) {
    return (Sanitize-SlotName $branch)
  }

  return $null
}

function Find-Project($registry, [string]$path) {
  $resolvedPath = (Resolve-Path -LiteralPath $path).Path.TrimEnd("\")
  foreach ($key in $registry.codegraph.projects.Keys) {
    $project = $registry.codegraph.projects[$key]
    if (-not $project.Contains("sourcePath")) {
      continue
    }
    $source = $project.sourcePath.TrimEnd("\")
    if ($resolvedPath.Equals($source, [System.StringComparison]::OrdinalIgnoreCase) -or
        $resolvedPath.StartsWith($source + "\", [System.StringComparison]::OrdinalIgnoreCase)) {
      return [pscustomobject]@{
        id = $key
        project = $project
      }
    }
  }
  return $null
}

function Prepare-ProjectSlot($registry, [string]$id, $project) {
  if (-not [bool]$registry.codegraph.enabled) {
    throw "CodeGraph global switch is disabled."
  }
  if ($project.Contains("enabled") -and -not [bool]$project.enabled) {
    throw "CodeGraph is disabled for project '$id'."
  }

  $sourcePath = (Resolve-Path -LiteralPath $project.sourcePath).Path
  $git = "git"
  $codegraph = Get-CodeGraphCommand

  $branch = (& $git -C $sourcePath branch --show-current).Trim()
  if ([string]::IsNullOrWhiteSpace($branch)) {
    $branch = "detached"
  }
  $commit = (& $git -C $sourcePath rev-parse HEAD).Trim()
  if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($commit)) {
    throw "Unable to resolve current Git commit for $sourcePath"
  }

  $pinned = Get-BranchNames $project.pinnedBranches
  $slot = "default"
  $slotKind = "fallback"
  $moduleSlot = Get-ModuleSlotName $project $branch
  if ($pinned -contains $branch) {
    $slot = Sanitize-SlotName $branch
    $slotKind = "pinned"
  } elseif (-not [string]::IsNullOrWhiteSpace($moduleSlot)) {
    $slot = $moduleSlot
    $slotKind = "shared-hot"
  }

  if (-not $project.Contains("slots")) {
    $project.slots = [ordered]@{}
  }

  $projectRoot = Join-Path $root "projects\$id"
  $slotRoot = Join-Path $projectRoot "slots\$slot"
  $worktreePath = Join-Path $slotRoot "worktree"
  $statePath = Join-Path $slotRoot "state.json"
  $lockPath = Join-Path $slotRoot "sync.lock"

  New-Item -ItemType Directory -Force -Path $slotRoot | Out-Null
  $lockStream = [System.IO.File]::Open($lockPath, [System.IO.FileMode]::OpenOrCreate, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)
  try {
    if (-not (Test-Path -LiteralPath (Join-Path $worktreePath ".git"))) {
      New-Item -ItemType Directory -Force -Path (Split-Path -Parent $worktreePath) | Out-Null
      Invoke-Checked $git @("-C", $sourcePath, "worktree", "add", "--detach", $worktreePath, $commit)
    } else {
      Invoke-Checked $git @("-C", $worktreePath, "checkout", "--detach", "--force", $commit)
    }

    $graphPath = Join-Path $worktreePath ".codegraph"
    if (-not (Test-Path -LiteralPath $graphPath)) {
      Invoke-Checked $codegraph @("init", "-i", $worktreePath)
    } else {
      Invoke-Checked $codegraph @("sync", $worktreePath)
    }

    $state = [ordered]@{
      status = "ready"
      projectId = $id
      slot = $slot
      slotKind = $slotKind
      branch = $branch
      commit = $commit
      sourcePath = $sourcePath
      worktreePath = $worktreePath
      updatedAt = (Get-Date).ToString("o")
    }
    $state | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $statePath -Encoding UTF8

    $project.slots[$slot] = [ordered]@{
      enabled = $true
      kind = $slotKind
      branch = $branch
      lastIndexedCommit = $commit
      worktreePath = $worktreePath
      statePath = $statePath
    }

    Write-Registry $registry
    $state | ConvertTo-Json -Depth 10 -Compress
  }
  finally {
    $lockStream.Close()
  }
}

$registry = Read-Registry

switch ($Command) {
  "status" {
    $registry | ConvertTo-Json -Depth 30
  }
  "enable" {
    $registry.codegraph.enabled = $true
    Write-Registry $registry
    "CodeGraph global switch enabled."
  }
  "disable" {
    $registry.codegraph.enabled = $false
    Write-Registry $registry
    "CodeGraph global switch disabled."
  }
  "register" {
    Require-ProjectId
    if ([string]::IsNullOrWhiteSpace($SourcePath)) {
      throw "SourcePath is required for register."
    }

    $resolved = Resolve-Path -LiteralPath $SourcePath
    $projectRoot = Join-Path $root "projects\$ProjectId"

    $registry.codegraph.projects[$ProjectId] = [ordered]@{
      enabled = $true
      sourcePath = $resolved.Path
      mode = "hybrid-slots"
      slots = [ordered]@{
        default = [ordered]@{
          enabled = $true
          kind = "fallback"
          worktreePath = (Join-Path $projectRoot "slots\default\worktree")
        }
      }
      pinnedBranches = @("main", "master", "dev")
      activeModuleBranches = @()
      activeModuleSlots = @()
    }

    Write-Registry $registry
    "Registered project '$ProjectId'."
  }
  "add-module-slot" {
    Require-ProjectId
    if (-not $registry.codegraph.projects.Contains($ProjectId)) {
      throw "Project '$ProjectId' is not registered."
    }
    if ([string]::IsNullOrWhiteSpace($SlotName)) {
      throw "SlotName is required for add-module-slot."
    }
    if ($null -eq $Branches -or $Branches.Count -eq 0) {
      throw "At least one branch is required for add-module-slot."
    }
    Assert-ModuleSlotName $SlotName

    $project = $registry.codegraph.projects[$ProjectId]
    if (-not $project.Contains("activeModuleSlots") -or $null -eq $project.activeModuleSlots) {
      $project.activeModuleSlots = @()
    }

    $slot = Sanitize-SlotName $SlotName
    $newBranches = Get-BranchNames @($Branches)
    $existing = @()
    foreach ($moduleSlot in @($project.activeModuleSlots)) {
      if ($null -eq $moduleSlot) {
        continue
      }
      $existingBranches = Get-BranchNames $moduleSlot.branches
      $hasSameBranch = $false
      foreach ($branch in $newBranches) {
        if ($existingBranches -contains $branch) {
          $hasSameBranch = $true
          break
        }
      }
      if ($moduleSlot.slot -ne $slot -and -not $hasSameBranch) {
        $existing += ,$moduleSlot
      }
    }

    $existing += ,[ordered]@{
      slot = $slot
      module = $SlotName
      branches = @($Branches)
      status = "active"
      mode = "shared-hot-slot"
      updatedAt = (Get-Date).ToString("o")
    }

    $project.activeModuleSlots = $existing
    Write-Registry $registry
    "Added module slot '$slot' for branches: $($Branches -join ', ')."
  }
  "prepare" {
    if ([string]::IsNullOrWhiteSpace($ProjectId)) {
      $path = if ([string]::IsNullOrWhiteSpace($SourcePath)) { (Get-Location).Path } else { $SourcePath }
      $found = Find-Project $registry $path
      if (-not $found) {
        throw "No registered CodeGraph project matches path: $path"
      }
      Prepare-ProjectSlot $registry $found.id $found.project
    } else {
      if (-not $registry.codegraph.projects.Contains($ProjectId)) {
        throw "Project '$ProjectId' is not registered."
      }
      Prepare-ProjectSlot $registry $ProjectId $registry.codegraph.projects[$ProjectId]
    }
  }
}
