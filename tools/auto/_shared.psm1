$ErrorActionPreference = "Stop"

function Resolve-MemoryOsRoot {
  param([string]$Root = "C:\Users\btf\AI-MemoryOS")

  $full = [System.IO.Path]::GetFullPath($Root)
  if (-not [System.IO.Directory]::Exists($full)) {
    throw "Memory OS root does not exist: $Root"
  }
  return $full
}

function Test-MemoryOsRepo {
  param([string]$Root = "C:\Users\btf\AI-MemoryOS")

  $rootPath = Resolve-MemoryOsRoot -Root $Root
  foreach ($required in @("_index.md", "GOVERNANCE.md", "skills\registry.json")) {
    if (-not (Test-Path -LiteralPath (Join-Path $rootPath $required))) {
      throw "Not a Memory OS repository; missing $required"
    }
  }
  $firstLine = Get-Content -LiteralPath (Join-Path $rootPath "_index.md") -Encoding UTF8 -TotalCount 1
  if ($firstLine -notmatch "Memory OS Index") {
    throw "Not a Memory OS repository; _index.md does not start with Memory OS Index"
  }
  return $true
}

function Get-MemoryOsRelativePath {
  param(
    [string]$Root,
    [string]$Path
  )

  $rootPath = (Resolve-MemoryOsRoot -Root $Root).TrimEnd("\", "/")
  $resolvedPath = [System.IO.Path]::GetFullPath($Path)
  if ($resolvedPath.StartsWith($rootPath, [System.StringComparison]::OrdinalIgnoreCase)) {
    return $resolvedPath.Substring($rootPath.Length).TrimStart("\", "/")
  }
  return $resolvedPath
}

function Test-MemoryOsPathInside {
  param(
    [string]$ChildPath,
    [string]$ParentPath
  )

  $childFull = [System.IO.Path]::GetFullPath($ChildPath).TrimEnd("\", "/")
  $parentFull = [System.IO.Path]::GetFullPath($ParentPath).TrimEnd("\", "/")
  return $childFull.Equals($parentFull, [System.StringComparison]::OrdinalIgnoreCase) -or
    $childFull.StartsWith($parentFull + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase)
}

function Resolve-MemoryOsRelativePath {
  param(
    [string]$Root,
    [string]$RelativePath
  )

  if ([string]::IsNullOrWhiteSpace($RelativePath)) {
    throw "Relative path is required"
  }
  if ([System.IO.Path]::IsPathRooted($RelativePath)) {
    throw "Absolute paths are not allowed: $RelativePath"
  }

  $rootPath = Resolve-MemoryOsRoot -Root $Root
  $full = [System.IO.Path]::GetFullPath((Join-Path $rootPath ($RelativePath -replace "/", "\")))
  if (-not (Test-MemoryOsPathInside -ChildPath $full -ParentPath $rootPath)) {
    throw "Path escapes Memory OS root: $RelativePath"
  }
  return $full
}

function Test-AutoExcludedPath {
  param([string]$RelativePath)

  $normalized = $RelativePath -replace "\\", "/"
  foreach ($prefix in @(".git", "node_modules", "private", ".obsidian/cache", "logs/auto-runs")) {
    if ($normalized -eq $prefix -or $normalized.StartsWith("$prefix/")) { return $true }
  }
  if ($normalized -match '^\.obsidian/workspace.*\.json$') { return $true }
  return $false
}

function Get-MemoryOsFiles {
  param(
    [string]$Root,
    [string[]]$Extensions = @(".md"),
    [switch]$IncludeAutoRuns
  )

  $rootPath = Resolve-MemoryOsRoot -Root $Root
  Get-ChildItem -LiteralPath $rootPath -Recurse -File -Force | Where-Object {
    $relative = Get-MemoryOsRelativePath -Root $rootPath -Path $_.FullName
    $includeByPath = $IncludeAutoRuns -or -not (Test-AutoExcludedPath -RelativePath $relative)
    $includeByPath -and ($Extensions.Count -eq 0 -or $Extensions -contains $_.Extension.ToLowerInvariant())
  }
}

function ConvertTo-SafeArray {
  param([object]$Value)

  if ($null -eq $Value) { return ,@() }
  $items = New-Object System.Collections.Generic.List[object]
  foreach ($item in $Value) { $items.Add($item) }
  if ($items.Count -eq 0) { return ,@() }
  return ,([object[]]$items.ToArray())
}

function Remove-MarkdownFrontMatter {
  param([string]$Text)

  if ($Text -match "(?s)^---\r?\n.*?\r?\n---\r?\n") {
    return [regex]::Replace($Text, "(?s)^---\r?\n.*?\r?\n---\r?\n", "", 1)
  }
  return $Text
}

function ConvertTo-AutoSlug {
  param([string]$Text)

  $safe = $Text.ToLowerInvariant() -replace "[^a-z0-9\u4e00-\u9fa5]+", "-"
  $safe = $safe.Trim("-")
  if ([string]::IsNullOrWhiteSpace($safe)) { return "proposal" }
  return $safe
}

function Get-AutoCurrentScriptName {
  param([string]$DefaultName = "run")

  foreach ($frame in Get-PSCallStack) {
    if ([string]::IsNullOrWhiteSpace($frame.ScriptName)) { continue }
    if ((Split-Path -Leaf $frame.ScriptName) -eq "_shared.psm1") { continue }
    return ([System.IO.Path]::GetFileNameWithoutExtension($frame.ScriptName))
  }
  return $DefaultName
}

function New-AutoRunOutputFolderName {
  param(
    [string]$ScriptName = "run",
    [string]$Detail = ""
  )

  $parts = @($ScriptName, $Detail) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
  $slug = ConvertTo-AutoSlug -Text ($parts -join "-")
  $runId = [guid]::NewGuid().ToString("N").Substring(0, 12)
  return "$(Get-Date -Format 'yyyy-MM-dd-HHmmss')-$slug-$runId"
}

function Enter-AutoRunOutputContext {
  param(
    [string]$ScriptName = "run",
    [string]$Detail = ""
  )

  $old = $env:AI_MEMORYOS_AUTO_RUN_OUTPUT_DIR
  $changed = $false
  if ([string]::IsNullOrWhiteSpace($env:AI_MEMORYOS_AUTO_RUN_OUTPUT_DIR)) {
    $env:AI_MEMORYOS_AUTO_RUN_OUTPUT_DIR = New-AutoRunOutputFolderName -ScriptName $ScriptName -Detail $Detail
    $changed = $true
  }
  return [pscustomobject]@{ old = $old; changed = $changed }
}

function Exit-AutoRunOutputContext {
  param([object]$Context)

  if ($null -eq $Context -or -not $Context.changed) { return }
  if ([string]::IsNullOrWhiteSpace($Context.old)) {
    $env:AI_MEMORYOS_AUTO_RUN_OUTPUT_DIR = $null
  } else {
    $env:AI_MEMORYOS_AUTO_RUN_OUTPUT_DIR = $Context.old
  }
}

function Get-AutoRunOutputDirectory {
  param(
    [string]$Root,
    [string]$RelativeDirectory,
    [string]$ScriptName = ""
  )

  $rootPath = Resolve-MemoryOsRoot -Root $Root
  if ([string]::IsNullOrWhiteSpace($env:AI_MEMORYOS_AUTO_RUN_OUTPUT_DIR)) {
    $name = if ([string]::IsNullOrWhiteSpace($ScriptName)) { Get-AutoCurrentScriptName } else { $ScriptName }
    $env:AI_MEMORYOS_AUTO_RUN_OUTPUT_DIR = New-AutoRunOutputFolderName -ScriptName $name
  }
  $parent = Join-Path $rootPath $RelativeDirectory
  $dir = Join-Path $parent $env:AI_MEMORYOS_AUTO_RUN_OUTPUT_DIR
  if (-not (Test-Path -LiteralPath $dir)) {
    New-Item -ItemType Directory -Path $dir | Out-Null
  }
  return $dir
}

function Assert-NoSensitiveContent {
  param([string]$Text)

  $patterns = @(
    '(?i)(api[_-]?key|token|password|secret)\s*[:=]\s*["'']?[a-z0-9_\-\.]{12,}',
    '(?i)-----BEGIN\s+(RSA\s+)?PRIVATE\s+KEY-----',
    '(?i)xox[baprs]-[a-z0-9-]{10,}'
  )
  foreach ($pattern in $patterns) {
    if ($Text -match $pattern) {
      throw "Sensitive-looking content blocked by pattern: $pattern"
    }
  }
}

function ConvertTo-AutoJson {
  param([object]$Value)

  return ($Value | ConvertTo-Json -Depth 12)
}

function Read-AutoJsonFile {
  param(
    [string]$Path,
    [object]$DefaultValue = $null
  )

  if (-not (Test-Path -LiteralPath $Path)) { return $DefaultValue }
  $text = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
  if ([string]::IsNullOrWhiteSpace($text)) { return $DefaultValue }
  return ($text | ConvertFrom-Json)
}

function Get-AutoConfig {
  param([string]$Root)

  $rootPath = Resolve-MemoryOsRoot -Root $Root
  $configPath = Join-Path $rootPath "tools\auto\config.json"
  $config = Read-AutoJsonFile -Path $configPath -DefaultValue ([pscustomobject]@{})
  $disabled = @()
  if ($null -ne $config.disabled_scripts) { $disabled += @($config.disabled_scripts | ForEach-Object { [string]$_ }) }
  if (-not [string]::IsNullOrWhiteSpace($env:AI_MEMORYOS_DISABLED_SCRIPTS)) {
    $disabled += @($env:AI_MEMORYOS_DISABLED_SCRIPTS -split "," | ForEach-Object { $_.Trim() } | Where-Object { $_ })
  }
  [pscustomobject]@{
    disabled_scripts = @($disabled | Select-Object -Unique)
  }
}

function Test-AutoScriptDisabled {
  param(
    [string]$Root,
    [string]$ScriptName
  )

  $config = Get-AutoConfig -Root $Root
  return @($config.disabled_scripts) -contains $ScriptName
}

function Get-ModelProfile {
  param(
    [string]$Root,
    [string]$Name = ""
  )

  $rootPath = Resolve-MemoryOsRoot -Root $Root
  $profilePath = Join-Path $rootPath "tools\auto\model-profiles.json"
  if (-not (Test-Path -LiteralPath $profilePath)) {
    $profilePath = Join-Path $rootPath "tools\auto\model-profiles.example.json"
  }
  $config = Read-AutoJsonFile -Path $profilePath
  if ($null -eq $config) { throw "Model profile config is missing or empty." }

  $selected = $Name
  if ([string]::IsNullOrWhiteSpace($selected)) { $selected = $env:AI_MEMORYOS_AUTO_MODEL_PROFILE }
  if ([string]::IsNullOrWhiteSpace($selected)) { $selected = [string]$config.default }
  if ([string]::IsNullOrWhiteSpace($selected)) { $selected = "codex" }

  $property = $config.profiles.PSObject.Properties[$selected]
  if ($null -eq $property) {
    throw "Unknown model profile '$selected'. Define it in tools\auto\model-profiles.json or model-profiles.example.json."
  }
  $profile = $property.Value
  $profile | Add-Member -NotePropertyName name -NotePropertyValue $selected -Force
  $profile | Add-Member -NotePropertyName source_path -NotePropertyValue (Get-MemoryOsRelativePath -Root $rootPath -Path $profilePath) -Force
  return $profile
}

function Get-AutoFileSha256 {
  param([string]$Path)

  $stream = [System.IO.File]::OpenRead([System.IO.Path]::GetFullPath($Path))
  try {
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
      $bytes = $sha.ComputeHash($stream)
      return ([System.BitConverter]::ToString($bytes) -replace "-", "").ToLowerInvariant()
    } finally {
      $sha.Dispose()
    }
  } finally {
    $stream.Dispose()
  }
}

function Assert-ModelActionBoundary {
  param(
    [string]$Root,
    [object]$Action
  )

  $forbidden = @("merge-main", "direct-git", "delete", "path-outside", "skip-validate", "force-push", "reset-hard")
  $actionName = [string]$Action.action
  if ($forbidden -contains $actionName) {
    throw "Forbidden model action: $actionName"
  }
  $target = [string]$Action.target
  if (-not [string]::IsNullOrWhiteSpace($target) -and -not [System.IO.Path]::IsPathRooted($target)) {
    Resolve-MemoryOsRelativePath -Root $Root -RelativePath $target | Out-Null
  }
  if (-not [string]::IsNullOrWhiteSpace($target) -and [System.IO.Path]::IsPathRooted($target)) {
    if (-not (Test-MemoryOsPathInside -ChildPath $target -ParentPath (Resolve-MemoryOsRoot -Root $Root))) {
      throw "Model action target escapes Memory OS root: $target"
    }
  }
}

function Assert-ModelOutputSchema {
  param(
    [string]$Root,
    [string]$JsonText,
    [ValidateSet("findings", "action")][string]$SchemaType = "findings"
  )

  Assert-NoSensitiveContent -Text $JsonText
  $payload = $JsonText | ConvertFrom-Json
  if ($SchemaType -eq "findings") {
    if ($null -eq $payload.findings) { throw "Model findings output missing required property: findings" }
    foreach ($finding in @($payload.findings)) {
      foreach ($required in @("severity", "category", "message", "tier")) {
        if ($null -eq $finding.PSObject.Properties[$required] -or [string]::IsNullOrWhiteSpace([string]$finding.$required)) {
          throw "Model finding missing required property: $required"
        }
      }
      if ($finding.severity -notin @("critical", "warning", "info")) { throw "Invalid finding severity: $($finding.severity)" }
      if ($finding.tier -notin @("A", "B", "C")) { throw "Invalid finding tier: $($finding.tier)" }
      if (-not [string]::IsNullOrWhiteSpace([string]$finding.path)) {
        $path = [string]$finding.path
        if ([System.IO.Path]::IsPathRooted($path)) {
          if (-not (Test-MemoryOsPathInside -ChildPath $path -ParentPath (Resolve-MemoryOsRoot -Root $Root))) {
            throw "Model finding path escapes Memory OS root: $path"
          }
        } else {
          Resolve-MemoryOsRelativePath -Root $Root -RelativePath $path | Out-Null
        }
      }
    }
  } else {
    foreach ($required in @("action", "tier", "target")) {
      if ($null -eq $payload.PSObject.Properties[$required] -or [string]::IsNullOrWhiteSpace([string]$payload.$required)) {
        throw "Model action output missing required property: $required"
      }
    }
    if ($payload.tier -notin @("A", "B", "C")) { throw "Invalid action tier: $($payload.tier)" }
    Assert-ModelActionBoundary -Root $Root -Action $payload
  }
  return $payload
}

function ConvertTo-AutoFindingsFromModel {
  param([object]$Payload)

  $items = New-Object System.Collections.Generic.List[object]
  foreach ($finding in @($Payload.findings)) {
    $data = @{}
    if ($null -ne $finding.evidence) { $data.evidence = @($finding.evidence) }
    $items.Add((New-AutoFinding -Severity $finding.severity -Category $finding.category -Message $finding.message -Path ([string]$finding.path) -Tier $finding.tier -Data $data))
  }
  return (ConvertTo-SafeArray -Value $items)
}

function Invoke-MemoryOsModel {
  param(
    [string]$Root,
    [object]$Profile,
    [string]$Task,
    [string]$Prompt,
    [switch]$WhatIf
  )

  if ($null -eq $Profile) { throw "Model profile is required." }
  if ($null -ne $Profile.allowed_tasks -and @($Profile.allowed_tasks) -notcontains $Task) {
    throw "Model profile '$($Profile.name)' does not allow task '$Task'."
  }
  if ($WhatIf) {
    return [pscustomobject]@{ text = ""; invocations = 0; tokens_estimate = 0; skipped = $true }
  }

  $provider = [string]$Profile.provider
  if ($provider -eq "openai-compatible") {
    $endpoint = [Environment]::GetEnvironmentVariable([string]$Profile.endpoint_env)
    $apiKey = [Environment]::GetEnvironmentVariable([string]$Profile.api_key_env)
    if ([string]::IsNullOrWhiteSpace($endpoint)) { throw "Missing endpoint env var for profile '$($Profile.name)': $($Profile.endpoint_env)" }
    if ([string]::IsNullOrWhiteSpace($apiKey)) { throw "Missing api key env var for profile '$($Profile.name)': $($Profile.api_key_env)" }
    $body = @{
      model = [string]$Profile.model
      messages = @(
        @{ role = "system"; content = "Return JSON only. Do not include secrets. Do not propose forbidden actions." },
        @{ role = "user"; content = $Prompt }
      )
    } | ConvertTo-Json -Depth 8
    $headers = @{ Authorization = "Bearer $apiKey"; "Content-Type" = "application/json" }
    $response = Invoke-RestMethod -Uri $endpoint -Method Post -Headers $headers -Body $body -TimeoutSec ([int]$Profile.timeout_seconds)
    $text = [string]$response.choices[0].message.content
    $text = Get-JsonFromModelOutput -Text $text
    return [pscustomobject]@{ text = $text; invocations = 1; tokens_estimate = [int]($Prompt.Length / 4 + $text.Length / 4); skipped = $false }
  }

  $command = [string]$Profile.command
  if ([string]::IsNullOrWhiteSpace($command)) { $command = $provider }
  if ([string]::IsNullOrWhiteSpace($command)) { throw "Model profile '$($Profile.name)' has no command/provider." }
  $arguments = @()
  if ($null -ne $Profile.arguments) { $arguments = @($Profile.arguments | ForEach-Object { [string]$_ }) }
  $output = $Prompt | & $command @arguments
  $text = ($output | Out-String).Trim()
  $text = Get-JsonFromModelOutput -Text $text
  return [pscustomobject]@{ text = $text; invocations = 1; tokens_estimate = [int]($Prompt.Length / 4 + $text.Length / 4); skipped = $false }
}

function Get-JsonFromModelOutput {
  param([string]$Text)

  if ([string]::IsNullOrWhiteSpace($Text)) { return $Text }
  $fenceMatch = [regex]::Match($Text, '(?s)```(?:json)?\s*(\{.*?\}|\[.*?\])\s*```')
  if ($fenceMatch.Success) { return $fenceMatch.Groups[1].Value.Trim() }
  $firstBrace = $Text.IndexOf('{')
  $firstBracket = $Text.IndexOf('[')
  $start = -1
  if ($firstBrace -ge 0 -and ($firstBracket -lt 0 -or $firstBrace -lt $firstBracket)) { $start = $firstBrace }
  elseif ($firstBracket -ge 0) { $start = $firstBracket }
  if ($start -lt 0) { return $Text }
  $lastBrace = $Text.LastIndexOf('}')
  $lastBracket = $Text.LastIndexOf(']')
  $end = [Math]::Max($lastBrace, $lastBracket)
  if ($end -le $start) { return $Text }
  return $Text.Substring($start, $end - $start + 1).Trim()
}

function Get-AutoFindingId {
  param(
    [string]$Category,
    [string]$Path,
    [string]$Message
  )

  $raw = "$Category|$Path|$Message"
  $bytes = [System.Text.Encoding]::UTF8.GetBytes($raw)
  $sha = [System.Security.Cryptography.SHA256]::Create()
  try {
    return ([System.BitConverter]::ToString($sha.ComputeHash($bytes)) -replace "-", "").ToLowerInvariant()
  } finally {
    $sha.Dispose()
  }
}

function Test-AutoFindingIgnored {
  param(
    [string]$Root,
    [object]$Finding
  )

  $rootPath = Resolve-MemoryOsRoot -Root $Root
  $path = Join-Path $rootPath "tools\auto\.ignored-findings.json"
  $config = Read-AutoJsonFile -Path $path -DefaultValue ([pscustomobject]@{ ignored_findings = @() })
  $findingId = Get-AutoFindingId -Category ([string]$Finding.category) -Path ([string]$Finding.path) -Message ([string]$Finding.message)
  foreach ($ignored in @($config.ignored_findings)) {
    if ([string]$ignored.id -eq $findingId) { return $true }
    if (-not [string]::IsNullOrWhiteSpace([string]$ignored.category) -and [string]$ignored.category -ne [string]$Finding.category) { continue }
    if (-not [string]::IsNullOrWhiteSpace([string]$ignored.path) -and [string]$ignored.path -ne [string]$Finding.path) { continue }
    if (-not [string]::IsNullOrWhiteSpace([string]$ignored.message) -and [string]$ignored.message -ne [string]$Finding.message) { continue }
    if ($null -ne $ignored.category -or $null -ne $ignored.path -or $null -ne $ignored.message) { return $true }
  }
  return $false
}

function New-AutoFinding {
  param(
    [ValidateSet("critical", "warning", "info")][string]$Severity,
    [string]$Category,
    [string]$Message,
    [string]$Path = "",
    [ValidateSet("A", "B", "C")][string]$Tier = "B",
    [hashtable]$Data = @{}
  )

  [pscustomobject]@{
    severity = $Severity
    category = $Category
    message = $Message
    path = $Path
    tier = $Tier
    data = $Data
  }
}

function New-AutoAction {
  param(
    [ValidateSet("A", "B", "C")][string]$Tier,
    [string]$Action,
    [string]$Target,
    [string]$Status
  )

  [pscustomobject]@{
    tier = $Tier
    action = $Action
    target = $Target
    status = $Status
  }
}

function Get-MaxSeverity {
  param([object[]]$Findings)

  if (@($Findings | Where-Object { $_.severity -eq "critical" }).Count -gt 0) { return "critical" }
  if (@($Findings | Where-Object { $_.severity -eq "warning" }).Count -gt 0) { return "warning" }
  if (@($Findings | Where-Object { $_.severity -eq "info" }).Count -gt 0) { return "info" }
  return ""
}

function ConvertTo-MarkdownTableCell {
  param([string]$Value)

  if ($null -eq $Value) { return "" }
  return (($Value -replace "\r?\n", " ") -replace "\|", "\|")
}

function Expand-AutoTemplate {
  param(
    [string]$Root,
    [string]$RelativePath,
    [hashtable]$Tokens
  )

  $templatePath = Resolve-MemoryOsRelativePath -Root $Root -RelativePath $RelativePath
  $content = Get-Content -LiteralPath $templatePath -Raw -Encoding UTF8
  foreach ($key in $Tokens.Keys) {
    $content = $content.Replace("{{${key}}}", [string]$Tokens[$key])
  }
  return $content
}

function Get-AutoLabels {
  param([string]$Root)

  $path = Resolve-MemoryOsRelativePath -Root $Root -RelativePath "templates\auto-labels.json"
  return (Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json)
}

function Get-AutoLabel {
  param(
    [object]$Labels,
    [string]$Group,
    [string]$Key
  )

  if ([string]::IsNullOrWhiteSpace($Key)) { return "" }
  $groupObject = $Labels.$Group
  if ($null -ne $groupObject) {
    $value = $groupObject.PSObject.Properties[$Key]
    if ($null -ne $value) { return [string]$value.Value }
  }
  return $Key
}

function Get-AutoFrontMatterValue {
  param(
    [string]$Text,
    [string]$Key
  )

  $pattern = '(?m)^{0}:\s*"?([^"\r\n]*)"?\s*$' -f [regex]::Escape($Key)
  $match = [regex]::Match($Text, $pattern)
  if ($match.Success) { return $match.Groups[1].Value.Trim() }
  return ""
}

function Write-AutoRunOverview {
  param(
    [string]$Root,
    [string]$OutputDirectoryName = ""
  )

  $rootPath = Resolve-MemoryOsRoot -Root $Root
  $logParent = Join-Path $rootPath "logs\auto-runs"
  if (-not (Test-Path -LiteralPath $logParent)) { return $null }

  $folderName = $OutputDirectoryName
  $logDir = $null
  if ([string]::IsNullOrWhiteSpace($folderName)) {
    $folderName = $env:AI_MEMORYOS_AUTO_RUN_OUTPUT_DIR
  }
  if ([string]::IsNullOrWhiteSpace($folderName)) {
    $latestDir = Get-ChildItem -LiteralPath $logParent -Directory |
      Where-Object { $_.Name -notin @("approval-sheets", ".locks") } |
      Sort-Object LastWriteTime -Descending |
      Select-Object -First 1
    if ($null -eq $latestDir) { return $null }
    $folderName = $latestDir.Name
    $logDir = $latestDir.FullName
  } elseif ([System.IO.Path]::IsPathRooted($folderName)) {
    $logDir = [System.IO.Path]::GetFullPath($folderName)
    if (-not (Test-MemoryOsPathInside -ChildPath $logDir -ParentPath $logParent)) {
      throw "Overview output directory escapes logs/auto-runs: $OutputDirectoryName"
    }
    $folderName = Split-Path -Leaf $logDir
  } else {
    $folderName = Split-Path -Leaf $folderName
    $logDir = Join-Path $logParent $folderName
  }

  if (-not (Test-Path -LiteralPath $logDir)) { return $null }

  $logs = @(Get-ChildItem -LiteralPath $logDir -Filter "*.md" -File |
    Where-Object { $_.Name -ne "000-overview.md" } |
    Sort-Object Name)
  if ($logs.Count -eq 0) { return $null }

  $rows = New-Object System.Collections.Generic.List[string]
  $totalFindings = 0
  $totalActions = 0
  $failedCount = 0
  $warningLikeCount = 0
  foreach ($log in $logs) {
    $text = Get-Content -LiteralPath $log.FullName -Raw -Encoding UTF8
    $script = Get-AutoFrontMatterValue -Text $text -Key "script"
    if ([string]::IsNullOrWhiteSpace($script)) { $script = $log.BaseName }
    $status = Get-AutoFrontMatterValue -Text $text -Key "status"
    $exitCode = Get-AutoFrontMatterValue -Text $text -Key "exit_code"
    $findingsCountText = Get-AutoFrontMatterValue -Text $text -Key "findings_count"
    $actionsCountText = Get-AutoFrontMatterValue -Text $text -Key "actions_count"
    $maxSeverity = Get-AutoFrontMatterValue -Text $text -Key "max_severity"
    $duration = Get-AutoFrontMatterValue -Text $text -Key "duration_seconds"
    $findingsCount = 0
    $actionsCount = 0
    [int]::TryParse($findingsCountText, [ref]$findingsCount) | Out-Null
    [int]::TryParse($actionsCountText, [ref]$actionsCount) | Out-Null
    $totalFindings += $findingsCount
    $totalActions += $actionsCount
    $hasExitCode = -not [string]::IsNullOrWhiteSpace($exitCode)
    if ($status -eq "failed" -or ($hasExitCode -and $exitCode -ne "0")) { $failedCount++ }
    if ($maxSeverity -in @("critical", "warning")) { $warningLikeCount++ }
    $relative = Get-MemoryOsRelativePath -Root $rootPath -Path $log.FullName
    $rows.Add("| $(ConvertTo-MarkdownTableCell $script) | $(ConvertTo-MarkdownTableCell $status) | $(ConvertTo-MarkdownTableCell $exitCode) | $findingsCount | $actionsCount | $(ConvertTo-MarkdownTableCell $maxSeverity) | $(ConvertTo-MarkdownTableCell $duration) | $(ConvertTo-MarkdownTableCell $relative) |")
  }

  $pendingDir = Join-Path $rootPath "proposals\pending\$folderName"
  $approvalDir = Join-Path $rootPath "logs\auto-runs\approval-sheets\$folderName"
  $pendingCount = if (Test-Path -LiteralPath $pendingDir) { @(Get-ChildItem -LiteralPath $pendingDir -Filter "*.md" -File -Recurse).Count } else { 0 }
  $approvalCount = if (Test-Path -LiteralPath $approvalDir) { @(Get-ChildItem -LiteralPath $approvalDir -Filter "*.md" -File -Recurse).Count } else { 0 }
  $generatedAt = (Get-Date).ToString("o")
  $logDirRelative = Get-MemoryOsRelativePath -Root $rootPath -Path $logDir
  $pendingRelative = if (Test-Path -LiteralPath $pendingDir) { Get-MemoryOsRelativePath -Root $rootPath -Path $pendingDir } else { "proposals\pending\$folderName" }
  $approvalRelative = if (Test-Path -LiteralPath $approvalDir) { Get-MemoryOsRelativePath -Root $rootPath -Path $approvalDir } else { "logs\auto-runs\approval-sheets\$folderName" }
  $nextStep = if ($failedCount -gt 0) {
    "Check logs with status=failed or non-zero exit_code first."
  } elseif ($warningLikeCount -gt 0) {
    "Check logs with max_severity=critical/warning, then review pending proposals or approval sheets."
  } elseif ($pendingCount -gt 0 -or $approvalCount -gt 0) {
    "This run has pending proposals or approval sheets that need human review."
  } else {
    "No failed logs or review outputs were detected."
  }

  $frontMatter = @"
---
type: auto-run-overview
run_output_dir: "$folderName"
generated_at: "$generatedAt"
log_count: $($logs.Count)
pending_count: $pendingCount
approval_sheet_count: $approvalCount
total_findings_count: $totalFindings
total_actions_count: $totalActions
failed_log_count: $failedCount
warning_or_critical_log_count: $warningLikeCount
---
"@
$content = @"
$frontMatter
# Auto Run Overview

- Run directory: $logDirRelative
- Generated at: $generatedAt
- Log count: $($logs.Count)
- Total findings: $totalFindings
- Total actions: $totalActions
- Pending proposals: $pendingCount ($pendingRelative)
- Approval sheets: $approvalCount ($approvalRelative)

## First Look

$nextStep

## Log Summary

| Script | Status | ExitCode | Findings | Actions | MaxSeverity | Seconds | Path |
| --- | --- | --- | ---: | ---: | --- | ---: | --- |
$($rows -join "`r`n")
"@

  Assert-NoSensitiveContent -Text $content
  $path = Join-Path $logDir "000-overview.md"
  $utf8 = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($path, $content, $utf8)
  return $path
}

function Write-AutoRunLog {
  param(
    [string]$Root,
    [string]$ScriptName,
    [object[]]$Findings = @(),
    [object[]]$Actions = @(),
    [hashtable]$Parameters = @{},
    [string]$Status = "ready",
    [int]$ExitCode = 0,
    [datetime]$StartedAt = (Get-Date),
    [string]$ModelProfile = "",
    [int]$ModelInvocationsCount = 0,
    [int]$ModelTokensEstimate = 0,
    [string]$Branch = "",
    [string]$LockId = "",
    [int]$RepairAttempts = 0,
    [switch]$WhatIf
  )

  $rootPath = Resolve-MemoryOsRoot -Root $Root
  if ($WhatIf) {
    Write-Host "WhatIf: would write run log for $ScriptName with $(@($Findings).Count) findings."
    return $null
  }

  $logDir = Get-AutoRunOutputDirectory -Root $rootPath -RelativeDirectory "logs\auto-runs" -ScriptName $ScriptName

  $runId = [guid]::NewGuid().ToString("N").Substring(0, 12)
  $duration = [int]((Get-Date) - $StartedAt).TotalSeconds
  $fileName = "$(Get-Date -Format 'yyyy-MM-dd-HHmmss')-$ScriptName-$runId.md"
  $path = Join-Path $logDir $fileName
  $maxSeverity = Get-MaxSeverity -Findings $Findings
  $labels = Get-AutoLabels -Root $rootPath
  if ([string]::IsNullOrWhiteSpace($ModelProfile) -and $Parameters.ContainsKey("model_profile")) { $ModelProfile = [string]$Parameters["model_profile"] }
  if ([string]::IsNullOrWhiteSpace($Branch) -and $Parameters.ContainsKey("branch")) { $Branch = [string]$Parameters["branch"] }
  if ([string]::IsNullOrWhiteSpace($LockId) -and $Parameters.ContainsKey("lock_id")) { $LockId = [string]$Parameters["lock_id"] }
  if ($RepairAttempts -eq 0 -and $Parameters.ContainsKey("repair_attempts")) { [int]::TryParse([string]$Parameters["repair_attempts"], [ref]$RepairAttempts) | Out-Null }
  $json = [pscustomobject]@{
    findings = ConvertTo-SafeArray -Value $Findings
    actions = ConvertTo-SafeArray -Value $Actions
    parameters = $Parameters
  } | ConvertTo-Json -Depth 12

  $findingRows = New-Object System.Collections.Generic.List[string]
  $i = 1
  foreach ($finding in @($Findings)) {
    $severityText = Get-AutoLabel -Labels $labels -Group "severity" -Key $finding.severity
    $categoryText = Get-AutoLabel -Labels $labels -Group "category" -Key $finding.category
    $messageText = Get-AutoLabel -Labels $labels -Group "message" -Key $finding.category
    $tierText = Get-AutoLabel -Labels $labels -Group "tier" -Key $finding.tier
    $findingRows.Add("| $i | $(ConvertTo-MarkdownTableCell $severityText) | $(ConvertTo-MarkdownTableCell $categoryText) | $(ConvertTo-MarkdownTableCell $messageText) | $(ConvertTo-MarkdownTableCell $finding.path) | $(ConvertTo-MarkdownTableCell $tierText) |")
    $i++
  }
  if ($findingRows.Count -eq 0) { $findingRows.Add("|  |  |  |  |  |  |") }

  $actionRows = New-Object System.Collections.Generic.List[string]
  $i = 1
  foreach ($action in @($Actions)) {
    $tierText = Get-AutoLabel -Labels $labels -Group "tier" -Key $action.tier
    $actionText = Get-AutoLabel -Labels $labels -Group "action" -Key $action.action
    $statusText = Get-AutoLabel -Labels $labels -Group "status" -Key $action.status
    $actionRows.Add("| $i | $(ConvertTo-MarkdownTableCell $tierText) | $(ConvertTo-MarkdownTableCell $actionText) | $(ConvertTo-MarkdownTableCell $action.target) | $(ConvertTo-MarkdownTableCell $statusText) |")
    $i++
  }
  if ($actionRows.Count -eq 0) { $actionRows.Add("|  |  |  |  |  |") }

  $parameterLines = New-Object System.Collections.Generic.List[string]
  foreach ($key in $Parameters.Keys) {
    $parameterLines.Add("- ${key}: $($Parameters[$key])")
  }
  if ($parameterLines.Count -eq 0) { $parameterLines.Add("- none") }

  $frontMatter = @"
---
run_id: "$runId"
script: "$ScriptName"
triggered_by: "manual"
model_profile: "$ModelProfile"
model_invocations_count: $ModelInvocationsCount
model_tokens_estimate: $ModelTokensEstimate
started_at: "$($StartedAt.ToString("o"))"
duration_seconds: $duration
exit_code: $ExitCode
findings_count: $(@($Findings).Count)
actions_count: $(@($Actions).Count)
pending_decisions_count: $(@($Findings | Where-Object { $_.tier -ne "A" }).Count)
max_severity: "$maxSeverity"
status: "$Status"
branch: "$Branch"
lock_id: "$LockId"
repair_attempts: $RepairAttempts
---
"@
  $decisionRows = New-Object System.Collections.Generic.List[string]
  $i = 1
  foreach ($finding in @($Findings | Where-Object { $_.tier -ne "A" })) {
    $messageText = Get-AutoLabel -Labels $labels -Group "message" -Key $finding.category
    $tierText = Get-AutoLabel -Labels $labels -Group "tier" -Key $finding.tier
    $decisionRows.Add("| $i | $(ConvertTo-MarkdownTableCell $messageText) | $(ConvertTo-MarkdownTableCell $tierText) | $(ConvertTo-MarkdownTableCell $finding.path) | pending |")
    $i++
  }
  if ($decisionRows.Count -eq 0) { $decisionRows.Add("|  |  |  |  |  |") }

  $body = Expand-AutoTemplate -Root $rootPath -RelativePath "templates\auto-run-log.md" -Tokens @{
    script = $ScriptName
    root = $rootPath
    phase = $Parameters["phase"]
    parameters = ($parameterLines -join "`r`n")
    finding_rows = ($findingRows -join "`r`n")
    action_rows = ($actionRows -join "`r`n")
    decision_rows = ($decisionRows -join "`r`n")
    structured_json = $json
    validation_status = "not run by this script"
    content_recheck_status = "not run by this script"
  }
  $body = [regex]::Replace($body, '(?s)^---\r?\n.*?\r?\n---\r?\n', '', 1)
  $content = $frontMatter + "`r`n" + $body

  Assert-NoSensitiveContent -Text $content
  $utf8 = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($path, $content, $utf8)
  Write-AutoRunOverview -Root $rootPath | Out-Null
  Write-Host "Wrote run log: $(Get-MemoryOsRelativePath -Root $rootPath -Path $path)"
  return $path
}

function Get-LatestAutoRunFindings {
  param(
    [string]$Root,
    [string]$ScriptName
  )

  $rootPath = Resolve-MemoryOsRoot -Root $Root
  $logDir = Join-Path $rootPath "logs\auto-runs"
  if (-not (Test-Path -LiteralPath $logDir)) { return @() }

  $latest = Get-ChildItem -LiteralPath $logDir -Filter "*-$ScriptName-*.md" -File -Recurse |
    Where-Object { $_.FullName -notmatch '\\approval-sheets\\' -and $_.FullName -notmatch '\\\.locks\\' } |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1
  if ($null -eq $latest) { return @() }

  $text = Get-Content -LiteralPath $latest.FullName -Raw -Encoding UTF8
  $match = [regex]::Match($text, '(?s)(?:```|~~~)json\s*(\{.*?\})\s*(?:```|~~~)')
  if (-not $match.Success) { return @() }

  $payload = $match.Groups[1].Value | ConvertFrom-Json
  return @($payload.findings)
}

function Get-ActiveMemoryOsSkills {
  param([string]$Root)

  $registryPath = Join-Path (Resolve-MemoryOsRoot -Root $Root) "skills\registry.json"
  $registry = Get-Content -LiteralPath $registryPath -Raw -Encoding UTF8 | ConvertFrom-Json
  return @($registry.skills | Where-Object { $_.status -eq "active" })
}

function Test-DuplicateProposal {
  param(
    [string]$Root,
    [string]$Title
  )

  $rootPath = Resolve-MemoryOsRoot -Root $Root
  $slug = ConvertTo-AutoSlug -Text $Title
  $proposalDirs = @("proposals\pending", "proposals\accepted", "proposals\rejected")
  foreach ($dir in $proposalDirs) {
    $fullDir = Join-Path $rootPath $dir
    if (-not (Test-Path -LiteralPath $fullDir)) { continue }
    foreach ($file in Get-ChildItem -LiteralPath $fullDir -Filter "*.md" -File -Recurse) {
      if ($file.BaseName -like "*$slug*") { return $true }
      $text = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8
      if ($text -match "(?m)^#\s+Proposal:\s*$([regex]::Escape($Title))\s*$") { return $true }
      if ($text -match "(?m)^title:\s*[""']?$([regex]::Escape($Title))[""']?\s*$") { return $true }
    }
  }
  return $false
}

function New-BTierProposal {
  param(
    [string]$Root,
    [string]$Title,
    [string]$Summary,
    [string]$Trigger,
    [string]$RelatedTask = "",
    [string]$Destination = "proposal",
    [string]$Draft,
    [switch]$WhatIf
  )

  $rootPath = Resolve-MemoryOsRoot -Root $Root
  $quota = 0
  $count = 0
  $hasQuota = [int]::TryParse($env:AI_MEMORYOS_AUTO_PROPOSAL_QUOTA, [ref]$quota)
  [int]::TryParse($env:AI_MEMORYOS_AUTO_PROPOSAL_COUNT, [ref]$count) | Out-Null
  if ($hasQuota -and $quota -ge 0 -and $count -ge $quota) {
    return [pscustomobject]@{ tier = "B"; action = "proposal"; target = $Title; status = "skipped global quota" }
  }

  if (Test-DuplicateProposal -Root $rootPath -Title $Title) {
    if ($hasQuota) { $env:AI_MEMORYOS_AUTO_PROPOSAL_COUNT = [string]($count + 1) }
    return [pscustomobject]@{ tier = "B"; action = "proposal"; target = $Title; status = "skipped duplicate" }
  }

  $date = Get-Date -Format "yyyy-MM-dd"
  $slug = ConvertTo-AutoSlug -Text $Title
  $pendingDir = Get-AutoRunOutputDirectory -Root $rootPath -RelativeDirectory "proposals\pending" -ScriptName (Get-AutoCurrentScriptName -DefaultName $Trigger)
  $path = Join-Path $pendingDir "$date-$slug.md"
  $titleYaml = $Title.Replace('"', "'")

  $content = Expand-AutoTemplate -Root $rootPath -RelativePath "templates\auto-b-tier-proposal.md" -Tokens @{
    title = $titleYaml
    created_at = $date
    destination = $Destination
    trigger = $Trigger
    related_task = $RelatedTask
    summary = $Summary
    draft = $Draft
  }

  Assert-NoSensitiveContent -Text $content
  if ($WhatIf) {
    Write-Host "WhatIf: would create proposal $Title"
    if ($hasQuota) { $env:AI_MEMORYOS_AUTO_PROPOSAL_COUNT = [string]($count + 1) }
    return [pscustomobject]@{ tier = "B"; action = "proposal"; target = $Title; status = "whatif" }
  }

  if (-not (Test-Path -LiteralPath $pendingDir)) {
    New-Item -ItemType Directory -Path $pendingDir | Out-Null
  }
  $utf8 = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($path, $content, $utf8)
  if ($hasQuota) { $env:AI_MEMORYOS_AUTO_PROPOSAL_COUNT = [string]($count + 1) }
  return [pscustomobject]@{ tier = "B"; action = "proposal"; target = (Get-MemoryOsRelativePath -Root $rootPath -Path $path); status = "created" }
}

function New-CTierApprovalSheet {
  param(
    [string]$Root,
    [string]$Title,
    [string]$Scope,
    [string[]]$Files,
    [string]$Reason,
    [string]$DiffPreview = "Pending.",
    [switch]$WhatIf
  )

  $rootPath = Resolve-MemoryOsRoot -Root $Root
  $sheetDir = Get-AutoRunOutputDirectory -Root $rootPath -RelativeDirectory "logs\auto-runs\approval-sheets" -ScriptName (Get-AutoCurrentScriptName -DefaultName "approval-sheet")
  $date = Get-Date -Format "yyyy-MM-dd-HHmmss"
  $slug = ConvertTo-AutoSlug -Text $Title
  $path = Join-Path $sheetDir "$date-$slug.md"
  $content = Expand-AutoTemplate -Root $rootPath -RelativePath "templates\approval-sheet.md" -Tokens @{
    title = $Title
    scope = $Scope
    files = (($Files | ForEach-Object { "- $_" }) -join "`r`n")
    reason = $Reason
    sensitive_check = "required before apply"
    path_check = "required before apply"
    validation_command = "powershell -NoProfile -ExecutionPolicy Bypass -File tools\validate-memory-os.ps1"
    diff_preview = $DiffPreview
  }

  Assert-NoSensitiveContent -Text $content
  if ($WhatIf) {
    Write-Host "WhatIf: would create C-tier approval sheet $Title"
    return New-AutoAction -Tier "C" -Action "approval-sheet" -Target $Title -Status "whatif"
  }

  if (-not (Test-Path -LiteralPath $sheetDir)) {
    New-Item -ItemType Directory -Path $sheetDir | Out-Null
  }
  $utf8 = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($path, $content, $utf8)
  return New-AutoAction -Tier "C" -Action "approval-sheet" -Target (Get-MemoryOsRelativePath -Root $rootPath -Path $path) -Status "created"
}

function Assert-CTierApprovalSheetApproved {
  param(
    [string]$Root,
    [string]$ApprovalSheet
  )

  if ([string]::IsNullOrWhiteSpace($ApprovalSheet)) {
    throw "ApprovalSheet is required when ApplyApproved is used."
  }
  $rootPath = Resolve-MemoryOsRoot -Root $Root
  $path = if ([System.IO.Path]::IsPathRooted($ApprovalSheet)) { $ApprovalSheet } else { Resolve-MemoryOsRelativePath -Root $rootPath -RelativePath $ApprovalSheet }
  if (-not (Test-Path -LiteralPath $path)) { throw "Approval sheet does not exist: $ApprovalSheet" }
  if (-not (Test-MemoryOsPathInside -ChildPath $path -ParentPath $rootPath)) { throw "Approval sheet escapes Memory OS root: $ApprovalSheet" }
  $text = Get-Content -LiteralPath $path -Raw -Encoding UTF8
  if ($text -notmatch '(?m)^\s*-?\s*Approved:\s*true\s*$') { throw "Approval sheet is not explicitly approved. Set 'Approved: true'." }
  if ($text -notmatch '(?m)^-\s*Approved by:\s*\S') { throw "Approval sheet missing Approved by." }
  if ($text -notmatch '(?m)^-\s*Decision reason:\s*\S') { throw "Approval sheet missing Decision reason." }
  return $path
}

function Get-CurrentGitBranch {
  param([string]$Root)

  try {
    $branch = & git -C $Root branch --show-current 2>$null
    return ([string]$branch).Trim()
  } catch {
    return ""
  }
}

function Get-AutoScopeScripts {
  param([string]$Scope)

  switch ($Scope) {
    "content-quality" { return @("iterate-stale-content.ps1", "iterate-duplicate-merge.ps1", "optimize-unused-pages.ps1", "optimize-frontmatter.ps1") }
    "router-cleanup" { return @("iterate-router-refinement.ps1", "optimize-adapter-gate-sync.ps1") }
    "skill-health" { return @("iterate-skill-gaps.ps1", "optimize-skill-consistency.ps1") }
    "proposal-review" { return @("iterate-promotion-candidates.ps1", "audit-proposal-health.ps1") }
    default { return @("run-all.ps1") }
  }
}

function New-AutoCycleLock {
  param(
    [string]$Root,
    [string]$Scope,
    [string]$Branch,
    [int]$StaleMinutes = 120,
    [switch]$WhatIf
  )

  $rootPath = Resolve-MemoryOsRoot -Root $Root
  $safeScope = ConvertTo-AutoSlug -Text $Scope
  $lockRoot = Join-Path $rootPath "logs\auto-runs\.locks"
  $lockDir = Join-Path $lockRoot "$safeScope.lock"
  $lockId = [guid]::NewGuid().ToString("N")
  if ($WhatIf) {
    Write-Host "WhatIf: would create cycle lock $safeScope"
    return [pscustomobject]@{ id = $lockId; path = $lockDir; scope = $Scope; branch = $Branch; whatif = $true }
  }

  if (-not (Test-Path -LiteralPath $lockRoot)) {
    New-Item -ItemType Directory -Path $lockRoot | Out-Null
  }
  if (Test-Path -LiteralPath $lockDir) {
    $age = ((Get-Date) - (Get-Item -LiteralPath $lockDir -Force).LastWriteTime).TotalMinutes
    if ($age -lt $StaleMinutes) {
      throw "Cycle lock already exists for scope '$Scope': $(Get-MemoryOsRelativePath -Root $rootPath -Path $lockDir)"
    }
    Remove-Item -LiteralPath $lockDir -Recurse -Force
  }
  New-Item -ItemType Directory -Path $lockDir | Out-Null
  $meta = [pscustomobject]@{
    id = $lockId
    scope = $Scope
    branch = $Branch
    started_at = (Get-Date).ToString("o")
    triggered_by = "manual"
    pid = $PID
  } | ConvertTo-Json -Depth 4
  $utf8 = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText((Join-Path $lockDir "lock.json"), $meta, $utf8)
  return [pscustomobject]@{ id = $lockId; path = $lockDir; scope = $Scope; branch = $Branch; whatif = $false }
}

function Remove-AutoCycleLock {
  param(
    [object]$Lock,
    [switch]$WhatIf
  )

  if ($null -eq $Lock -or [string]::IsNullOrWhiteSpace([string]$Lock.path)) { return }
  if ($WhatIf -or $Lock.whatif) {
    Write-Host "WhatIf: would remove cycle lock $($Lock.scope)"
    return
  }
  if (Test-Path -LiteralPath $Lock.path) {
    Remove-Item -LiteralPath $Lock.path -Recurse -Force
  }
}

function Assert-AutoBranch {
  param(
    [string]$Root,
    [string]$Branch = ""
  )

  $branchName = $Branch
  if ([string]::IsNullOrWhiteSpace($branchName)) { $branchName = Get-CurrentGitBranch -Root $Root }
  if ($branchName -notlike "auto/*") {
    throw "Auto git writes require an auto/* branch. Current branch: $branchName"
  }
  return $branchName
}

function Assert-MainReadyForAutoBranch {
  param([string]$Root)

  $rootPath = Resolve-MemoryOsRoot -Root $Root
  $branchName = Get-CurrentGitBranch -Root $rootPath
  if ($branchName -ne "main") {
    throw "Auto branch creation must start from main. Current branch: $branchName"
  }

  $status = & git -C $rootPath status --porcelain
  if (-not [string]::IsNullOrWhiteSpace(($status | Out-String))) {
    throw "Refusing to create auto branch because main has uncommitted or untracked changes. Commit and push main first, or move these changes out before running automation."
  }

  $upstream = (& git -C $rootPath rev-parse --abbrev-ref "main@{upstream}" 2>$null | Out-String).Trim()
  if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($upstream)) {
    throw "Refusing to create auto branch because main has no upstream tracking branch."
  }

  $sync = (& git -C $rootPath rev-list --left-right --count "$upstream...main" 2>$null | Out-String).Trim()
  if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($sync)) {
    throw "Unable to compare main with upstream tracking branch: $upstream"
  }
  $parts = @($sync -split "\s+")
  $behind = [int]$parts[0]
  $ahead = [int]$parts[1]
  if ($ahead -gt 0) {
    throw "Refusing to create auto branch because main has $ahead unpushed commit(s). Push main before running automation."
  }
  if ($behind -gt 0) {
    throw "Refusing to create auto branch because main is $behind commit(s) behind $upstream. Update main before running automation."
  }

  return [pscustomobject]@{
    branch = $branchName
    upstream = $upstream
    ahead = $ahead
    behind = $behind
  }
}

function New-AutoBranch {
  param(
    [string]$Root,
    [string]$Branch,
    [switch]$WhatIf
  )

  Test-MemoryOsRepo -Root $Root | Out-Null
  if ($Branch -notlike "auto/*") { throw "Auto branch must start with auto/: $Branch" }
  if ($WhatIf) {
    Write-Host "WhatIf: would create/switch auto branch $Branch"
    return $Branch
  }
  $current = Get-CurrentGitBranch -Root $Root
  if ($current -eq $Branch) { return $Branch }
  Assert-MainReadyForAutoBranch -Root $Root | Out-Null
  $existing = & git -C $Root branch --list $Branch
  if ([string]::IsNullOrWhiteSpace([string]$existing)) {
    & git -C $Root checkout -b $Branch | Out-Null
  } else {
    & git -C $Root checkout $Branch | Out-Null
  }
  return $Branch
}

function Invoke-AutoCommit {
  param(
    [string]$Root,
    [string]$Message,
    [string[]]$Paths = @(),
    [switch]$Push,
    [switch]$WhatIf
  )

  $rootPath = Resolve-MemoryOsRoot -Root $Root
  $branch = Assert-AutoBranch -Root $rootPath
  if ($WhatIf) {
    Write-Host "WhatIf: would commit on $branch with message: $Message"
    if ($Push) { Write-Host "WhatIf: would push $branch" }
    return ""
  }
  if ($Paths.Count -gt 0) {
    & git -C $rootPath add -- @($Paths)
  } else {
    & git -C $rootPath add -- logs/auto-runs proposals/pending dashboard templates tools/auto rules
  }
  $status = & git -C $rootPath status --porcelain
  if ([string]::IsNullOrWhiteSpace(($status | Out-String))) {
    if ($Push) {
      & git -C $rootPath push -u origin $branch | Out-Null
    }
    return ""
  }
  & git -C $rootPath commit -m $Message | Out-Null
  $commit = (& git -C $rootPath rev-parse HEAD).Trim()
  if ($Push) {
    & git -C $rootPath push -u origin $branch | Out-Null
  }
  return $commit
}

function Invoke-ATierAction {
  param(
    [string]$Root,
    [string]$Name,
    [string[]]$Paths,
    [scriptblock]$Action,
    [switch]$Commit,
    [switch]$Push,
    [switch]$WhatIf
  )

  $rootPath = Resolve-MemoryOsRoot -Root $Root
  $manifest = @()
  foreach ($relative in $Paths) {
    $full = Resolve-MemoryOsRelativePath -Root $rootPath -RelativePath $relative
    if (Test-Path -LiteralPath $full) {
      $manifest += [pscustomobject]@{ path = $relative; sha256 = (Get-AutoFileSha256 -Path $full) }
    } else {
      $manifest += [pscustomobject]@{ path = $relative; sha256 = "" }
    }
  }
  if ($WhatIf) {
    Write-Host "WhatIf: would run A-tier action $Name"
    return New-AutoAction -Tier "A" -Action $Name -Target ($Paths -join "; ") -Status "whatif"
  }
  & $Action
  & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $rootPath "tools\validate-memory-os.ps1") -Root $rootPath | Out-Null
  if ($Commit) {
    Invoke-AutoCommit -Root $rootPath -Message "auto: $Name" -Paths $Paths -Push:$Push | Out-Null
  }
  return New-AutoAction -Tier "A" -Action $Name -Target ($Paths -join "; ") -Status "updated"
}

function New-AutoCycleSummary {
  param(
    [string]$Root,
    [string]$Scope,
    [string]$Branch,
    [string]$Status,
    [string]$PhaseSummary,
    [string]$ManualItems,
    [string]$ReviewNotes,
    [datetime]$StartedAt,
    [switch]$WhatIf
  )

  $rootPath = Resolve-MemoryOsRoot -Root $Root
  $content = Expand-AutoTemplate -Root $rootPath -RelativePath "templates\auto-cycle-summary.md" -Tokens @{
    scope = $Scope
    branch = $Branch
    triggered_by = "manual"
    status = $Status
    started_at = $StartedAt.ToString("o")
    completed_at = (Get-Date).ToString("o")
    phase_summary = $PhaseSummary
    manual_items = $ManualItems
    review_notes = $ReviewNotes
  }
  if ($WhatIf) {
    Write-Host "WhatIf: would write cycle summary for $Scope"
    return $null
  }
  $dir = Get-AutoRunOutputDirectory -Root $rootPath -RelativeDirectory "logs\auto-runs" -ScriptName "cycle-summary"
  $path = Join-Path $dir "$(Get-Date -Format 'yyyy-MM-dd-HHmmss')-cycle-summary-$(ConvertTo-AutoSlug -Text $Scope).md"
  Assert-NoSensitiveContent -Text $content
  $utf8 = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($path, $content, $utf8)
  return $path
}

Export-ModuleMember -Function *
