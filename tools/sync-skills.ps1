param(
  [string]$Root = "C:\Users\btf\AI-MemoryOS",
  [string]$Skill = ""
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
    throw "Absolute paths are not allowed in skill registry: $RelativePath"
  }

  $rootFull = [System.IO.Path]::GetFullPath((Resolve-Path -LiteralPath $RootPath).Path)
  $joined = Join-Path $rootFull ($RelativePath -replace '/', '\')
  $full = [System.IO.Path]::GetFullPath($joined)
  if (-not (Test-PathInside -ChildPath $full -ParentPath $rootFull)) {
    throw "Registry path escapes Memory OS root: $RelativePath"
  }
  return $full
}

function Assert-ExistingPathInside {
  param(
    [string]$Path,
    [string]$RootPath,
    [string]$Label
  )

  $rootReal = (Resolve-Path -LiteralPath $RootPath).Path
  $realPath = (Resolve-Path -LiteralPath $Path).Path
  if (-not (Test-PathInside -ChildPath $realPath -ParentPath $rootReal)) {
    throw "$Label escapes Memory OS root: $Path"
  }
  return $realPath
}

function Get-RelativePathText {
  param(
    [string]$Path
  )

  return $Path.Replace('\', '/')
}

function ConvertTo-YamlDoubleQuoted {
  param(
    [string]$Value
  )

  return '"' + $Value.Replace('\', '\\').Replace('"', '\"') + '"'
}

$registryPath = Join-MemoryOsPath -RootPath $Root -RelativePath "skills/registry.json"
if (-not (Test-Path -LiteralPath $registryPath)) {
  throw "skills/registry.json not found"
}

$registry = Get-Content -LiteralPath $registryPath -Raw -Encoding UTF8 | ConvertFrom-Json
$managedSkills = @($registry.skills | Where-Object {
  $_.managed -eq $true -and ([string]::IsNullOrWhiteSpace($Skill) -or $_.name -eq $Skill)
})

if ($managedSkills.Count -eq 0) {
  throw "No managed skills matched."
}

foreach ($skillConfig in $managedSkills) {
  $sourcePath = Join-MemoryOsPath -RootPath $Root -RelativePath $skillConfig.source
  if (-not (Test-Path -LiteralPath $sourcePath)) {
    throw "Missing shared skill spec: $($skillConfig.source)"
  }
  Assert-ExistingPathInside -Path $sourcePath -RootPath $Root -Label "Shared skill spec" | Out-Null

  $sourceHash = (Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash.ToLowerInvariant()
  $sourceBody = Get-Content -LiteralPath $sourcePath -Raw -Encoding UTF8

  foreach ($adapterName in @("codex", "claude")) {
    $adapter = $skillConfig.adapters.$adapterName
    if ($null -eq $adapter -or $adapter.enabled -ne $true) { continue }

    $outputPath = Join-MemoryOsPath -RootPath $Root -RelativePath $adapter.output
    $outputDir = Split-Path -Parent $outputPath
    New-Item -ItemType Directory -Force -Path $outputDir | Out-Null
    Assert-ExistingPathInside -Path $outputDir -RootPath $Root -Label "Generated skill output directory" | Out-Null

    $body = $sourceBody.Replace("{{AGENT_NAME}}", [string]$adapter.agentName).TrimEnd()
    $description = ConvertTo-YamlDoubleQuoted -Value ([string]$skillConfig.description)
    $content = @"
---
name: $($skillConfig.name)
description: $description
---
<!-- Generated from $($skillConfig.source); source-sha256: $sourceHash; adapter: $adapterName. Do not edit by hand; run tools/sync-skills.ps1. -->

$body
"@

    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    # Normalize to LF — script source is CRLF, here-strings inherit that; repo stores LF.
    $content = ($content -replace "`r`n", "`n").TrimEnd("`n") + "`n"
    [System.IO.File]::WriteAllText($outputPath, $content, $utf8NoBom)
    Write-Host "Synced $($skillConfig.name) -> $(Get-RelativePathText -Path $adapter.output)"
  }
}
