param(
  [string]$Root = "C:\Users\btf\AI-MemoryOS",
  [string]$Skill = "",
  [ValidateSet("", "codex", "claude")]
  [string]$Adapter = "",
  [switch]$Check
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

  $builder = New-Object System.Text.StringBuilder
  foreach ($char in $Value.ToCharArray()) {
    $code = [int][char]$char
    switch ($char) {
      '\' { [void]$builder.Append('\\'); break }
      '"' { [void]$builder.Append('\"'); break }
      "`r" { [void]$builder.Append('\r'); break }
      "`n" { [void]$builder.Append('\n'); break }
      "`t" { [void]$builder.Append('\t'); break }
      default {
        if ($code -lt 32) {
          [void]$builder.Append(('\u{0:x4}' -f $code))
        } else {
          [void]$builder.Append($char)
        }
      }
    }
  }

  return '"' + $builder.ToString() + '"'
}

function Assert-RegistryText {
  param(
    [object]$Value,
    [string]$Label
  )

  if ($null -eq $Value -or [string]::IsNullOrWhiteSpace([string]$Value)) {
    throw "Invalid registry: $Label is required"
  }
}

function Get-TemplateRelativePath {
  param(
    [object]$AdapterConfig,
    [string]$AdapterName
  )

  if ($null -ne $AdapterConfig.template -and -not [string]::IsNullOrWhiteSpace([string]$AdapterConfig.template)) {
    return [string]$AdapterConfig.template
  }
  return "adapters/$AdapterName/templates/skill.md.tmpl"
}

function Render-Skill {
  param(
    [string]$TemplateText,
    [object]$SkillConfig,
    [object]$AdapterConfig,
    [string]$AdapterName,
    [string]$SourceHash,
    [string]$SourceBody
  )

  $body = $SourceBody.Replace("{{AGENT_NAME}}", [string]$AdapterConfig.agentName).TrimEnd()
  $bodyToken = "{{body}}"
  $bodyMarker = "__MEMORYOS_SKILL_BODY_$([guid]::NewGuid().ToString('N'))__"
  $tokens = @{
    "{{name}}" = [string]$SkillConfig.name
    "{{description}}" = ConvertTo-YamlDoubleQuoted -Value ([string]$SkillConfig.description)
    "{{source}}" = [string]$SkillConfig.source
    "{{source_sha256}}" = $SourceHash
    "{{adapter}}" = $AdapterName
    "{{agent_name}}" = [string]$AdapterConfig.agentName
  }

  $rendered = $TemplateText.Replace($bodyToken, $bodyMarker)
  foreach ($key in $tokens.Keys) {
    $rendered = $rendered.Replace($key, $tokens[$key])
  }
  $rendered = $rendered.Replace($bodyMarker, $body)
  return $rendered.TrimEnd("`r", "`n") + "`n"
}

function Test-BasicFrontmatter {
  param(
    [string]$Text,
    [string]$SkillName
  )

  return $Text -match "(?s)^---\s*name:\s*$([regex]::Escape($SkillName))\s*description:\s*.+?\s*---"
}

$hadProblem = $false
$items = @()

try {
  $registryPath = Join-MemoryOsPath -RootPath $Root -RelativePath "skills/registry.json"
  if (-not (Test-Path -LiteralPath $registryPath)) {
    throw "skills/registry.json not found"
  }

  $registry = Get-Content -LiteralPath $registryPath -Raw -Encoding UTF8 | ConvertFrom-Json
  if ($null -eq $registry.skills) {
    throw "Invalid registry: skills is required"
  }

  $managedSkills = @($registry.skills | Where-Object {
    $_.managed -eq $true -and ([string]::IsNullOrWhiteSpace($Skill) -or $_.name -eq $Skill)
  })

  if ($managedSkills.Count -eq 0) {
    throw "No managed skills matched."
  }

  $adapterNames = if ([string]::IsNullOrWhiteSpace($Adapter)) { @("codex", "claude") } else { @($Adapter) }

  foreach ($skillConfig in $managedSkills) {
    Assert-RegistryText -Value $skillConfig.name -Label "skill.name"
    Assert-RegistryText -Value $skillConfig.status -Label "$($skillConfig.name).status"
    Assert-RegistryText -Value $skillConfig.source -Label "$($skillConfig.name).source"
    Assert-RegistryText -Value $skillConfig.description -Label "$($skillConfig.name).description"
    if ([string]$skillConfig.name -notmatch '^[a-z0-9]+(-[a-z0-9]+)*$') {
      throw "Invalid registry: skill name must be kebab-case: $($skillConfig.name)"
    }
    if (([string]$skillConfig.source) -ne "skills/$($skillConfig.name)/SKILL_SPEC.md") {
      throw "Invalid registry: $($skillConfig.name).source should be skills/$($skillConfig.name)/SKILL_SPEC.md"
    }
    if ($null -eq $skillConfig.adapters) {
      throw "Invalid registry: $($skillConfig.name).adapters is required"
    }

    $enabledCount = 0
    foreach ($adapterName in @("codex", "claude")) {
      $adapterConfig = $skillConfig.adapters.$adapterName
      if ($null -ne $adapterConfig -and $adapterConfig.enabled -eq $true) { $enabledCount++ }
    }
    if ([string]$skillConfig.status -eq "active" -and $enabledCount -eq 0) {
      throw "Invalid registry: active managed skill needs at least one enabled adapter: $($skillConfig.name)"
    }

    $sourcePath = Join-MemoryOsPath -RootPath $Root -RelativePath $skillConfig.source
    if (-not (Test-Path -LiteralPath $sourcePath)) {
      throw "Missing shared skill spec: $($skillConfig.source)"
    }

    $sourceHash = (Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash.ToLowerInvariant()
    $sourceBody = Get-Content -LiteralPath $sourcePath -Raw -Encoding UTF8

    foreach ($adapterName in $adapterNames) {
      $adapterConfig = $skillConfig.adapters.$adapterName
      if ($null -eq $adapterConfig -or $adapterConfig.enabled -ne $true) { continue }

      Assert-RegistryText -Value $adapterConfig.output -Label "$($skillConfig.name).adapters.$adapterName.output"
      Assert-RegistryText -Value $adapterConfig.agentName -Label "$($skillConfig.name).adapters.$adapterName.agentName"
      $expectedOutput = "adapters/$adapterName/skills/$($skillConfig.name)/SKILL.md"
      if ((Get-RelativePathText -Path ([string]$adapterConfig.output)) -ne $expectedOutput) {
        throw "Invalid registry: $($skillConfig.name).adapters.$adapterName.output should be $expectedOutput"
      }

      $templateRelativePath = Get-TemplateRelativePath -AdapterConfig $adapterConfig -AdapterName $adapterName
      $templatePath = Join-MemoryOsPath -RootPath $Root -RelativePath $templateRelativePath
      if (-not (Test-Path -LiteralPath $templatePath)) {
        throw "Missing adapter skill template: $templateRelativePath"
      }
      $templateText = Get-Content -LiteralPath $templatePath -Raw -Encoding UTF8

      $outputPath = Join-MemoryOsPath -RootPath $Root -RelativePath $adapterConfig.output
      $expectedContent = Render-Skill -TemplateText $templateText -SkillConfig $skillConfig -AdapterConfig $adapterConfig -AdapterName $adapterName -SourceHash $sourceHash -SourceBody $sourceBody
      if (-not (Test-BasicFrontmatter -Text $expectedContent -SkillName ([string]$skillConfig.name))) {
        throw "Rendered skill is missing usable frontmatter: $($skillConfig.name) ($adapterName)"
      }

      if ($Check) {
        if (-not (Test-Path -LiteralPath $outputPath)) {
          $items += "STALE $($skillConfig.name) $adapterName missing $(Get-RelativePathText -Path $adapterConfig.output)"
          $hadProblem = $true
          continue
        }

        $actualContent = Get-Content -LiteralPath $outputPath -Raw -Encoding UTF8
        if ($actualContent -ne $expectedContent) {
          $items += "STALE $($skillConfig.name) $adapterName $(Get-RelativePathText -Path $adapterConfig.output)"
          $hadProblem = $true
          continue
        }

        $items += "OK $($skillConfig.name) $adapterName $(Get-RelativePathText -Path $adapterConfig.output)"
      } else {
        $outputDir = Split-Path -Parent $outputPath
        New-Item -ItemType Directory -Force -Path $outputDir | Out-Null
        if (-not (Test-PathInside -ChildPath (Resolve-Path -LiteralPath $outputDir).Path -ParentPath (Resolve-Path -LiteralPath $Root).Path)) {
          throw "Generated skill output directory escapes Memory OS root: $($adapterConfig.output)"
        }

        $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
        [System.IO.File]::WriteAllText($outputPath, $expectedContent, $utf8NoBom)
        $items += "SYNCED $($skillConfig.name) $adapterName $(Get-RelativePathText -Path $adapterConfig.output)"
      }
    }
  }
} catch {
  $items += "ERROR $($_.Exception.Message)"
  $hadProblem = $true
}

if ($items.Count -gt 0) {
  $items | ForEach-Object { Write-Host $_ }
}

if ($hadProblem) {
  $hasErrors = @($items | Where-Object { $_ -like "ERROR *" }).Count -gt 0
  $summary = if ($Check -and -not $hasErrors) { "STALE" } else { "ERROR" }
  Write-Host "$summary managed skill sync completed with problems."
  exit 1
}

$summaryStatus = if ($Check) { "OK" } else { "SYNCED" }
Write-Host "$summaryStatus managed skill sync completed. items=$($items.Count)"
