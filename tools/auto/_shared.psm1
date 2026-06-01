$ErrorActionPreference = "Stop"

function Write-MemoryOsTextFile {
  # Single chokepoint for writing text files in the auto pipeline.
  # Normalizes CRLF -> LF and ensures exactly one trailing LF so reruns are
  # idempotent and don't produce noisy diffs on Windows (where .ps1 here-strings
  # carry CRLF but the repo stores .md/.json as LF per .gitattributes).
  param(
    [Parameter(Mandatory = $true)][string]$Path,
    [Parameter(Mandatory = $true)][string]$Content,
    [switch]$NoTrailingNewline
  )

  if ($null -eq $Content) { $Content = "" }
  $normalized = $Content -replace "`r`n", "`n"
  if (-not $NoTrailingNewline) {
    $normalized = $normalized.TrimEnd("`n") + "`n"
  }
  $utf8 = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($Path, $normalized, $utf8)
}

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

  $zh = @{
    passed = [regex]::Unescape('\u901a\u8fc7')
    failed = [regex]::Unescape('\u5931\u8d25')
    partial = [regex]::Unescape('\u90e8\u5206\u5b8c\u6210')
    whatif = [regex]::Unescape('\u6f14\u7ec3')
    unknown = [regex]::Unescape('\u672a\u77e5')
    none = [regex]::Unescape('\u65e0')
    critical = [regex]::Unescape('\u4e25\u91cd')
    warning = [regex]::Unescape('\u8b66\u544a')
    info = [regex]::Unescape('\u63d0\u793a')
    overviewTitle = [regex]::Unescape('\u81ea\u52a8\u5316\u8fd0\u884c\u603b\u89c8')
    runDirectory = [regex]::Unescape('\u65e5\u5fd7\u76ee\u5f55')
    generatedAt = [regex]::Unescape('\u751f\u6210\u65f6\u95f4')
    logCount = [regex]::Unescape('\u65e5\u5fd7\u6570\u91cf')
    findingsCount = [regex]::Unescape('\u53d1\u73b0\u6570\u91cf')
    actionsCount = [regex]::Unescape('\u52a8\u4f5c\u6570\u91cf')
    pendingProposals = [regex]::Unescape('\u5f85\u5ba1\u6838 proposal')
    approvalSheets = [regex]::Unescape('\u5ba1\u6279\u5355')
    firstLook = [regex]::Unescape('\u5148\u770b\u8fd9\u91cc')
    logDetails = [regex]::Unescape('\u65e5\u5fd7\u660e\u7ec6')
    tableHeader = [regex]::Unescape('| \u811a\u672c | \u72b6\u6001 | \u9000\u51fa\u7801 | \u53d1\u73b0 | \u52a8\u4f5c | \u6700\u9ad8\u7ea7\u522b | \u8017\u65f6\u79d2 | \u65e5\u5fd7\u8def\u5f84 |')
    failedNext = [regex]::Unescape('\u672c\u6b21\u8fd0\u884c\u5b58\u5728\u5931\u8d25\u65e5\u5fd7\u3002\u8bf7\u5148\u67e5\u770b\u4e0b\u65b9\u8868\u683c\u4e2d\u72b6\u6001\u4e3a\u201c\u5931\u8d25\u201d\u6216\u9000\u51fa\u7801\u975e 0 \u7684\u811a\u672c\uff0c\u518d\u51b3\u5b9a\u4fee\u590d\u3001\u4fdd\u7559\u73b0\u573a\uff0c\u6216\u4e22\u5f03 auto \u5206\u652f\u540e\u91cd\u8dd1\u3002')
    warningNext = [regex]::Unescape('\u672c\u6b21\u8fd0\u884c\u6ca1\u6709\u5931\u8d25\u811a\u672c\uff0c\u4f46\u5b58\u5728\u4e25\u91cd\u6216\u8b66\u544a\u7ea7\u522b\u53d1\u73b0\u3002\u8bf7\u4f18\u5148\u67e5\u770b\u8fd9\u4e9b\u65e5\u5fd7\uff0c\u518d\u5ba1\u6838\u5f85\u5904\u7406 proposal \u6216\u5ba1\u6279\u5355\u3002')
    reviewNext = [regex]::Unescape('\u672c\u6b21\u8fd0\u884c\u751f\u6210\u4e86\u5f85\u5ba1\u6838 proposal \u6216\u5ba1\u6279\u5355\u3002\u8bf7\u4eba\u5de5\u786e\u8ba4\u540e\u518d\u51b3\u5b9a\u662f\u5426\u5408\u5e76 auto \u5206\u652f\u3002')
    cleanNext = [regex]::Unescape('\u672a\u53d1\u73b0\u5931\u8d25\u65e5\u5fd7\uff0c\u4e5f\u6ca1\u6709\u9700\u8981\u7acb\u5373\u5904\u7406\u7684\u5ba1\u6838\u4ea7\u7269\u3002\u4ecd\u5efa\u8bae\u5feb\u901f\u67e5\u770b\u65e5\u5fd7\u8868\u683c\u540e\u518d\u5408\u5e76\u3002')
  }

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
    $statusLabel = switch ($status) {
      "passed" { $zh.passed }
      "failed" { $zh.failed }
      "partial" { $zh.partial }
      "whatif" { $zh.whatif }
      default { if ([string]::IsNullOrWhiteSpace($status)) { $zh.unknown } else { $status } }
    }
    $severityLabel = switch ($maxSeverity) {
      "critical" { $zh.critical }
      "warning" { $zh.warning }
      "info" { $zh.info }
      default { if ([string]::IsNullOrWhiteSpace($maxSeverity)) { $zh.none } else { $maxSeverity } }
    }
    $exitCodeLabel = if ([string]::IsNullOrWhiteSpace($exitCode)) { $zh.none } else { $exitCode }
    $durationLabel = if ([string]::IsNullOrWhiteSpace($duration)) { $zh.none } else { $duration }
    $relative = Get-MemoryOsRelativePath -Root $rootPath -Path $log.FullName
    $rows.Add("| $(ConvertTo-MarkdownTableCell $script) | $(ConvertTo-MarkdownTableCell $statusLabel) | $(ConvertTo-MarkdownTableCell $exitCodeLabel) | $findingsCount | $actionsCount | $(ConvertTo-MarkdownTableCell $severityLabel) | $(ConvertTo-MarkdownTableCell $durationLabel) | $(ConvertTo-MarkdownTableCell $relative) |")
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
    $zh.failedNext
  } elseif ($warningLikeCount -gt 0) {
    $zh.warningNext
  } elseif ($pendingCount -gt 0 -or $approvalCount -gt 0) {
    $zh.reviewNext
  } else {
    $zh.cleanNext
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
# $($zh.overviewTitle)

- $($zh.runDirectory): $logDirRelative
- $($zh.generatedAt): $generatedAt
- $($zh.logCount): $($logs.Count)
- $($zh.findingsCount): $totalFindings
- $($zh.actionsCount): $totalActions
- $($zh.pendingProposals): $pendingCount ($pendingRelative)
- $($zh.approvalSheets): $approvalCount ($approvalRelative)

## $($zh.firstLook)

$nextStep

## $($zh.logDetails)

$($zh.tableHeader)
| --- | --- | --- | ---: | ---: | --- | ---: | --- |
$($rows -join "`r`n")
"@

  Assert-NoSensitiveContent -Text $content
  $path = Join-Path $logDir "000-overview.md"
  Write-MemoryOsTextFile -Path $path -Content $content
  return $path
}

function ConvertFrom-AutoUnicode {
  param([string]$Text)
  return [regex]::Unescape($Text)
}

function Get-AutoScriptPurpose {
  param([string]$ScriptName, [hashtable]$Parameters = @{})

  $scope = if ($Parameters.ContainsKey("scope")) { [string]$Parameters["scope"] } else { "" }
  switch ($ScriptName) {
    "audit-content-quality" { return ConvertFrom-AutoUnicode "\u68c0\u67e5 Memory OS \u5185\u5bb9\u8d28\u91cf\uff0c\u91cd\u70b9\u770b\u7a7a\u6d1e\u5185\u5bb9\u3001\u8fc7\u671f\u5185\u5bb9\u548c\u53ef\u6e05\u7406\u9879\u3002" }
    "audit-link-integrity" { return ConvertFrom-AutoUnicode "\u68c0\u67e5\u6587\u6863\u94fe\u63a5\u3001wiki-link \u548c\u5f15\u7528\u76ee\u6807\u662f\u5426\u6709\u6548\u3002" }
    "audit-skill-coverage" { return ConvertFrom-AutoUnicode "\u68c0\u67e5 active skills \u7684\u8986\u76d6\u3001\u5165\u53e3\u548c\u6ce8\u518c\u4e00\u81f4\u6027\u3002" }
    "audit-router-consistency" { return ConvertFrom-AutoUnicode "\u68c0\u67e5 gate\u3001router\u3001domain\u3001skill \u8def\u7531\u89c4\u5219\u662f\u5426\u4e00\u81f4\u3002" }
    "audit-proposal-health" { return ConvertFrom-AutoUnicode "\u68c0\u67e5 pending proposals \u7684\u5065\u5eb7\u5ea6\u3001\u91cd\u590d\u9879\u548c\u53ef\u664b\u5347\u5019\u9009\u3002" }
    "model-semantic-audit" { return ConvertFrom-AutoUnicode "\u628a\u786e\u5b9a\u6027\u5ba1\u8ba1\u53d1\u73b0\u4ea4\u7ed9\u6a21\u578b\u505a\u8bed\u4e49\u590d\u6838\uff0c\u7b5b\u51fa\u9700\u8981\u8fdb\u4e00\u6b65\u5904\u7406\u7684\u95ee\u9898\u3002" }
    "model-repair-plan" { return ConvertFrom-AutoUnicode "\u8bfb\u53d6\u672c\u8f6e\u8fd0\u884c\u65e5\u5fd7\uff0c\u8c03\u7528\u6a21\u578b\u751f\u6210\u6216\u5e94\u7528\u540e\u7eed\u4fee\u590d\u52a8\u4f5c\u3002" }
    "run-all" { return ConvertFrom-AutoUnicode "\u6309 phase \u7f16\u6392\u591a\u4e2a\u81ea\u52a8\u5316\u811a\u672c\u5e76\u6c47\u603b\u6267\u884c\u7ed3\u679c\u3002" }
    "start-cycle" { return ConvertFrom-AutoUnicode "\u521b\u5efa auto \u5206\u652f\uff0c\u8fd0\u884c\u5b8c\u6574\u81ea\u52a8\u5316 cycle\uff0c\u5e76\u5728\u901a\u8fc7\u540e\u63d0\u4ea4\u53ef\u5ba1\u6838\u7ed3\u679c\u3002" }
    "review-cycle" { return ConvertFrom-AutoUnicode "\u6c47\u603b\u81ea\u52a8\u5316\u5206\u652f\u3001\u65e5\u5fd7\u3001proposal \u548c\u5ba1\u6279\u5355\uff0c\u8f85\u52a9\u4eba\u5de5\u5ba1\u6838\u3002" }
    "repair-failed-cycle" { return ConvertFrom-AutoUnicode "\u4fee\u590d\u5931\u8d25\u6216\u90e8\u5206\u5b8c\u6210 cycle \u7684\u65e5\u5fd7/frontmatter \u7b49\u673a\u68b0\u95ee\u9898\u3002" }
    default {
      if (-not [string]::IsNullOrWhiteSpace($scope)) { return "$(ConvertFrom-AutoUnicode '\u6267\u884c ')$ScriptName$(ConvertFrom-AutoUnicode '\uff0c\u8303\u56f4\u662f ')$scope$(ConvertFrom-AutoUnicode '\u3002')" }
      return "$(ConvertFrom-AutoUnicode '\u6267\u884c ')$ScriptName$(ConvertFrom-AutoUnicode '\u3002')"
    }
  }
}

function Get-AutoReadableFindingMessage {
  param(
    [object]$Labels,
    [object]$Finding
  )

  $message = [string]$Finding.message
  if (-not [string]::IsNullOrWhiteSpace($message)) { return $message }
  $categoryLabel = Get-AutoLabel -Labels $Labels -Group "message" -Key $Finding.category
  if (-not [string]::IsNullOrWhiteSpace($categoryLabel)) { return $categoryLabel }
  return [string]$Finding.category
}

function ConvertTo-AutoReadableFindingLine {
  param(
    [object]$Labels,
    [object]$Finding
  )

  $severityText = Get-AutoLabel -Labels $Labels -Group "severity" -Key $Finding.severity
  $tierText = Get-AutoLabel -Labels $Labels -Group "tier" -Key $Finding.tier
  $messageText = Get-AutoReadableFindingMessage -Labels $Labels -Finding $Finding
  $pathText = [string]$Finding.path
  if ([string]::IsNullOrWhiteSpace($pathText)) { $pathText = ConvertFrom-AutoUnicode "\u672a\u7ed1\u5b9a\u5230\u5355\u4e2a\u6587\u4ef6" }
  return "- [$severityText / $tierText] ${pathText}: $messageText"
}

function ConvertTo-AutoReadableActionLine {
  param(
    [object]$Labels,
    [object]$Action
  )

  $tierText = Get-AutoLabel -Labels $Labels -Group "tier" -Key $Action.tier
  $actionText = Get-AutoLabel -Labels $Labels -Group "action" -Key $Action.action
  if ([string]::IsNullOrWhiteSpace($actionText)) { $actionText = [string]$Action.action }
  $statusText = Get-AutoLabel -Labels $Labels -Group "status" -Key $Action.status
  if ([string]::IsNullOrWhiteSpace($statusText)) { $statusText = [string]$Action.status }
  $targetText = [string]$Action.target
  if ([string]::IsNullOrWhiteSpace($targetText)) { $targetText = ConvertFrom-AutoUnicode "\u672a\u6307\u5b9a\u76ee\u6807" }
  return "- [$tierText] ${actionText}: $targetText ($statusText)"
}

function New-AutoReadableRunSummary {
  param(
    [string]$ScriptName,
    [object[]]$Findings = @(),
    [object[]]$Actions = @(),
    [hashtable]$Parameters = @{},
    [string]$Status = "ready",
    [int]$ModelInvocationsCount = 0,
    [object]$Labels
  )

  $checked = Get-AutoScriptPurpose -ScriptName $ScriptName -Parameters $Parameters
  $modelLine = if ($ModelInvocationsCount -gt 0) { "$(ConvertFrom-AutoUnicode '\u672c\u811a\u672c\u8c03\u7528\u4e86\u6a21\u578b ')$ModelInvocationsCount$(ConvertFrom-AutoUnicode ' \u6b21\u3002')" } else { ConvertFrom-AutoUnicode "\u672c\u811a\u672c\u6ca1\u6709\u771f\u5b9e\u8c03\u7528\u6a21\u578b\uff0c\u6216\u672c\u6b21\u53ea\u4f7f\u7528\u672c\u5730/\u786e\u5b9a\u6027\u903b\u8f91\u3002" }

  $findingLines = New-Object System.Collections.Generic.List[string]
  foreach ($finding in @($Findings | Select-Object -First 8)) {
    $findingLines.Add((ConvertTo-AutoReadableFindingLine -Labels $Labels -Finding $finding))
  }
  if ($findingLines.Count -eq 0) { $findingLines.Add("- $(ConvertFrom-AutoUnicode '\u672a\u53d1\u73b0\u9700\u8981\u5904\u7406\u7684\u95ee\u9898\u3002')") }
  if (@($Findings).Count -gt 8) { $findingLines.Add("- $(ConvertFrom-AutoUnicode '\u53e6\u6709 ')$(@($Findings).Count - 8)$(ConvertFrom-AutoUnicode ' \u6761\u53d1\u73b0\uff0c\u89c1\u4e0b\u65b9\u660e\u7ec6\u8868\u3002')") }

  $actionLines = New-Object System.Collections.Generic.List[string]
  foreach ($action in @($Actions | Select-Object -First 8)) {
    $actionLines.Add((ConvertTo-AutoReadableActionLine -Labels $Labels -Action $action))
  }
  if ($actionLines.Count -eq 0) { $actionLines.Add("- $(ConvertFrom-AutoUnicode '\u672c\u811a\u672c\u6ca1\u6709\u6267\u884c\u4fee\u590d\u3001\u751f\u6210 proposal \u6216\u751f\u6210\u5ba1\u6279\u5355\u3002')") }
  if (@($Actions).Count -gt 8) { $actionLines.Add("- $(@($Actions).Count - 8)$(ConvertFrom-AutoUnicode ' \u4e2a\u52a8\u4f5c\uff0c\u89c1\u4e0b\u65b9\u660e\u7ec6\u8868\u3002')") }

  $remainingLines = New-Object System.Collections.Generic.List[string]
  foreach ($finding in @($Findings | Where-Object { $_.tier -ne "A" } | Select-Object -First 6)) {
    $remainingLines.Add((ConvertTo-AutoReadableFindingLine -Labels $Labels -Finding $finding))
  }
  if ($remainingLines.Count -eq 0) {
    $remainingLines.Add("- $(ConvertFrom-AutoUnicode '\u6682\u65e0\u5fc5\u987b\u4eba\u5de5\u5904\u7406\u7684 B/C-tier \u5269\u4f59\u4e8b\u9879\u3002')")
  } elseif (@($Findings | Where-Object { $_.tier -ne "A" }).Count -gt 6) {
    $remainingLines.Add("- $(ConvertFrom-AutoUnicode '\u8fd8\u6709\u66f4\u591a B/C-tier \u4e8b\u9879\uff0c\u89c1\u5f85\u4eba\u5de5\u51b3\u7b56\u8868\u3002')")
  }

  $hStatus = ConvertFrom-AutoUnicode "\u8fd0\u884c\u72b6\u6001"
  $hChecked = ConvertFrom-AutoUnicode "\u68c0\u67e5\u4e86\u4ec0\u4e48"
  $hModel = ConvertFrom-AutoUnicode "\u6a21\u578b\u53c2\u4e0e"
  $hFindings = ConvertFrom-AutoUnicode "\u53d1\u73b0\u4e86\u4ec0\u4e48"
  $hActions = ConvertFrom-AutoUnicode "\u5df2\u7ecf\u5904\u7406\u4e86\u4ec0\u4e48"
  $hRemaining = ConvertFrom-AutoUnicode "\u5269\u4f59\u9700\u8981\u770b\u4ec0\u4e48"
  return @"
- **$hStatus**: $Status
- **$hChecked**: $checked
- **$hModel**: $modelLine

### $hFindings
$($findingLines -join "`n")

### $hActions
$($actionLines -join "`n")

### $hRemaining
$($remainingLines -join "`n")
"@
}

function New-AutoOperatorSummaryFromLogs {
  param(
    [string]$Root,
    [string]$OutputDirectoryName = ""
  )

  $noLogs = ConvertFrom-AutoUnicode "\u8fd8\u6ca1\u6709\u53ef\u6c47\u603b\u7684\u81ea\u52a8\u5316\u65e5\u5fd7\u3002"
  $rootPath = Resolve-MemoryOsRoot -Root $Root
  $logParent = Join-Path $rootPath "logs\auto-runs"
  if (-not (Test-Path -LiteralPath $logParent)) { return $noLogs }

  $folderName = $OutputDirectoryName
  if ([string]::IsNullOrWhiteSpace($folderName)) { $folderName = $env:AI_MEMORYOS_AUTO_RUN_OUTPUT_DIR }
  if ([string]::IsNullOrWhiteSpace($folderName)) {
    $latestDir = Get-ChildItem -LiteralPath $logParent -Directory |
      Where-Object { $_.Name -notin @("approval-sheets", ".locks") } |
      Sort-Object LastWriteTime -Descending |
      Select-Object -First 1
    if ($null -eq $latestDir) { return $noLogs }
    $logDir = $latestDir.FullName
  } else {
    $folderName = Split-Path -Leaf $folderName
    $logDir = Join-Path $logParent $folderName
  }
  if (-not (Test-Path -LiteralPath $logDir)) { return $noLogs }

  $labels = Get-AutoLabels -Root $rootPath
  $logs = @(Get-ChildItem -LiteralPath $logDir -Filter "*.md" -File |
    Where-Object { $_.Name -ne "000-overview.md" } |
    Sort-Object Name)
  if ($logs.Count -eq 0) { return $noLogs }

  $checked = New-Object System.Collections.Generic.List[string]
  $problemLines = New-Object System.Collections.Generic.List[string]
  $fixedLines = New-Object System.Collections.Generic.List[string]
  $remainingLines = New-Object System.Collections.Generic.List[string]
  $failedScripts = New-Object System.Collections.Generic.List[string]
  $modelInvocations = 0

  foreach ($log in $logs) {
    $text = Get-Content -LiteralPath $log.FullName -Raw -Encoding UTF8
    $script = Get-AutoFrontMatterValue -Text $text -Key "script"
    if ([string]::IsNullOrWhiteSpace($script)) { $script = $log.BaseName }
    $status = Get-AutoFrontMatterValue -Text $text -Key "status"
    $exitCode = Get-AutoFrontMatterValue -Text $text -Key "exit_code"
    $modelText = Get-AutoFrontMatterValue -Text $text -Key "model_invocations_count"
    $modelCount = 0
    [int]::TryParse($modelText, [ref]$modelCount) | Out-Null
    $modelInvocations += $modelCount
    $checked.Add("- ${script}: $(Get-AutoScriptPurpose -ScriptName $script)")
    if ($status -eq "failed" -or ((-not [string]::IsNullOrWhiteSpace($exitCode)) -and $exitCode -ne "0")) {
      $failedScripts.Add("- ${script}: $(ConvertFrom-AutoUnicode '\u72b6\u6001 ')$status$(ConvertFrom-AutoUnicode '\uff0cexit_code=')$exitCode")
    }

    $match = [regex]::Match($text, '(?s)(?:```|~~~)json\s*(\{.*?\})\s*(?:```|~~~)')
    if (-not $match.Success) { continue }
    $payload = $match.Groups[1].Value | ConvertFrom-Json
    foreach ($finding in @($payload.findings | Select-Object -First 3)) {
      if (@($problemLines).Count -lt 12) {
        $problemLines.Add((ConvertTo-AutoReadableFindingLine -Labels $labels -Finding $finding))
      }
      if ($finding.tier -ne "A" -and @($remainingLines).Count -lt 10) {
        $remainingLines.Add((ConvertTo-AutoReadableFindingLine -Labels $labels -Finding $finding))
      }
    }
    foreach ($action in @($payload.actions | Select-Object -First 3)) {
      if (@($fixedLines).Count -lt 12) {
        $fixedLines.Add((ConvertTo-AutoReadableActionLine -Labels $labels -Action $action))
      }
    }
  }

  if ($problemLines.Count -eq 0) { $problemLines.Add("- $(ConvertFrom-AutoUnicode '\u6ca1\u6709\u53d1\u73b0\u9700\u8981\u91cd\u70b9\u5904\u7406\u7684\u95ee\u9898\u3002')") }
  if ($fixedLines.Count -eq 0) { $fixedLines.Add("- $(ConvertFrom-AutoUnicode '\u672c\u8f6e\u6ca1\u6709\u81ea\u52a8\u5e94\u7528\u4fee\u590d\uff0c\u4e5f\u6ca1\u6709\u751f\u6210\u65b0\u7684\u5904\u7406\u4ea7\u7269\u3002')") }
  if ($remainingLines.Count -eq 0) { $remainingLines.Add("- $(ConvertFrom-AutoUnicode '\u6682\u65e0\u5fc5\u987b\u4eba\u5de5\u5904\u7406\u7684 B/C-tier \u5269\u4f59\u4e8b\u9879\u3002')") }
  if ($failedScripts.Count -eq 0) { $failedScripts.Add("- $(ConvertFrom-AutoUnicode '\u6ca1\u6709\u811a\u672c\u5931\u8d25\u3002')") }

  $hChecked = ConvertFrom-AutoUnicode "\u68c0\u67e5\u4e86\u4ec0\u4e48"
  $hFindings = ConvertFrom-AutoUnicode "\u53d1\u73b0\u4e86\u4ec0\u4e48"
  $hFixed = ConvertFrom-AutoUnicode "\u5df2\u7ecf\u81ea\u52a8\u5904\u7406\u4e86\u4ec0\u4e48"
  $hRemaining = ConvertFrom-AutoUnicode "\u5269\u4f59\u9700\u8981\u4eba\u5de5\u770b\u7684\u4e8b\u9879"
  $hFailures = ConvertFrom-AutoUnicode "\u8fd0\u884c\u5f02\u5e38"
  $hModel = ConvertFrom-AutoUnicode "\u6a21\u578b\u53c2\u4e0e"
  $modelCountLabel = ConvertFrom-AutoUnicode "\u672c\u8f6e\u6a21\u578b\u8c03\u7528\u6b21\u6570\uff1a"
  return @"
### $hChecked
$($checked -join "`n")

### $hFindings
$($problemLines -join "`n")

### $hFixed
$($fixedLines -join "`n")

### $hRemaining
$($remainingLines -join "`n")

### $hFailures
$($failedScripts -join "`n")

### $hModel
- $modelCountLabel$modelInvocations
"@
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
    $messageText = Get-AutoReadableFindingMessage -Labels $labels -Finding $finding
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
    $messageText = Get-AutoReadableFindingMessage -Labels $labels -Finding $finding
    $tierText = Get-AutoLabel -Labels $labels -Group "tier" -Key $finding.tier
    $decisionRows.Add("| $i | $(ConvertTo-MarkdownTableCell $messageText) | $(ConvertTo-MarkdownTableCell $tierText) | $(ConvertTo-MarkdownTableCell $finding.path) | pending |")
    $i++
  }
  if ($decisionRows.Count -eq 0) { $decisionRows.Add("|  |  |  |  |  |") }

  $body = Expand-AutoTemplate -Root $rootPath -RelativePath "templates\auto-run-log.md" -Tokens @{
    script = $ScriptName
    readable_summary = (New-AutoReadableRunSummary -ScriptName $ScriptName -Findings $Findings -Actions $Actions -Parameters $Parameters -Status $Status -ModelInvocationsCount $ModelInvocationsCount -Labels $labels)
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
  Write-MemoryOsTextFile -Path $path -Content $content
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
  Write-MemoryOsTextFile -Path $path -Content $content
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
  Write-MemoryOsTextFile -Path $path -Content $content
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
    # If the owning process is dead, treat the lock as stale regardless of age
    $lockJsonPath = Join-Path $lockDir "lock.json"
    if (Test-Path -LiteralPath $lockJsonPath) {
      try {
        $lockMeta = Get-Content -LiteralPath $lockJsonPath -Raw | ConvertFrom-Json
        if ($lockMeta.pid -and $lockMeta.pid -ne $PID) {
          $ownerProcess = Get-Process -Id ([int]$lockMeta.pid) -ErrorAction SilentlyContinue
          if ($null -eq $ownerProcess) {
            Write-Host "Auto: removing stale lock for scope '$Scope' — owning process $($lockMeta.pid) is no longer running"
            Remove-Item -LiteralPath $lockDir -Recurse -Force
            # Skip to creating a fresh lock below
            New-Item -ItemType Directory -Path $lockDir | Out-Null
            $lockMeta2 = [pscustomobject]@{
              id       = $lockId
              scope    = $Scope
              branch   = $Branch
              started_at = (Get-Date).ToString("o")
              triggered_by = "manual"
              pid      = $PID
            } | ConvertTo-Json -Depth 4
            $utf8 = New-Object System.Text.UTF8Encoding($false)
            [System.IO.File]::WriteAllText((Join-Path $lockDir "lock.json"), $lockMeta2, $utf8)
            return [pscustomobject]@{ id = $lockId; path = $lockDir; scope = $Scope; branch = $Branch; whatif = $false }
          }
        }
      } catch {
        # Malformed lock.json — fall through to age-based stale check
      }
    }
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
  $operatorSummary = New-AutoOperatorSummaryFromLogs -Root $rootPath
  $content = Expand-AutoTemplate -Root $rootPath -RelativePath "templates\auto-cycle-summary.md" -Tokens @{
    scope = $Scope
    branch = $Branch
    triggered_by = "manual"
    status = $Status
    started_at = $StartedAt.ToString("o")
    completed_at = (Get-Date).ToString("o")
    phase_summary = $PhaseSummary
    operator_summary = $operatorSummary
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
  Write-MemoryOsTextFile -Path $path -Content $content
  return $path
}

Export-ModuleMember -Function *
