param(
  [string]$Root = "C:\Users\btf\AI-MemoryOS"
)

$ErrorActionPreference = "Stop"

$jsonFiles = @(
  ".obsidian\community-plugins.json",
  ".obsidian\plugins\quickadd\data.json",
  ".obsidian\plugins\templater-obsidian\data.json",
  ".obsidian\plugins\dataview\data.json",
  ".obsidian\plugins\obsidian-git\data.json"
)

foreach ($item in $jsonFiles) {
  $path = Join-Path $Root $item
  if (-not (Test-Path -LiteralPath $path)) {
    throw "Missing Obsidian config: $item"
  }
  Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json | Out-Null
}

$plugins = Get-Content -LiteralPath (Join-Path $Root ".obsidian\community-plugins.json") -Raw -Encoding UTF8 | ConvertFrom-Json
$requiredPlugins = @(
  "dataview",
  "templater-obsidian",
  "quickadd",
  "obsidian-advanced-uri",
  "obsidian-git"
)

$missingPlugins = @()
foreach ($plugin in $requiredPlugins) {
  if ($plugins -notcontains $plugin) { $missingPlugins += $plugin }
}
if ($missingPlugins.Count -gt 0) {
  throw "Missing enabled plugins: $($missingPlugins -join ', ')"
}

$qa = Get-Content -LiteralPath (Join-Path $Root ".obsidian\plugins\quickadd\data.json") -Raw -Encoding UTF8 | ConvertFrom-Json
$expectedChoices = @{
  "New Pending Proposal" = @{
    template = "templates/proposal.md"
    folder = "proposals/pending"
  }
  "New Router Correction" = @{
    template = "templates/router-correction-proposal.md"
    folder = "proposals/pending"
  }
  "New Weekly Audit" = @{
    template = "templates/weekly-audit.md"
    folder = "logs/audits"
  }
}

foreach ($name in $expectedChoices.Keys) {
  $choice = $qa.choices | Where-Object { $_.name -eq $name } | Select-Object -First 1
  if (-not $choice) { throw "Missing QuickAdd choice: $name" }
  if ($choice.templatePath -ne $expectedChoices[$name].template) {
    throw "Wrong template for $name"
  }
  if (($choice.folder.folders -notcontains $expectedChoices[$name].folder) -or -not $choice.folder.enabled) {
    throw "Wrong output folder for $name"
  }
  if (-not $choice.openFile) {
    throw "QuickAdd choice should open created file: $name"
  }
}

$tpl = Get-Content -LiteralPath (Join-Path $Root ".obsidian\plugins\templater-obsidian\data.json") -Raw -Encoding UTF8 | ConvertFrom-Json
if ($tpl.templates_folder -ne "templates") {
  throw "Templater template folder must be templates"
}
if ($tpl.enable_system_commands) {
  throw "Templater system commands should stay disabled"
}

$git = Get-Content -LiteralPath (Join-Path $Root ".obsidian\plugins\obsidian-git\data.json") -Raw -Encoding UTF8 | ConvertFrom-Json
if ($git.disablePush) {
  throw "Obsidian Git push should be enabled for this vault"
}
if ($git.autoPushInterval -lt 1) {
  throw "Obsidian Git autoPushInterval should be enabled"
}
if ($git.autoSaveInterval -lt 1) {
  throw "Obsidian Git autoSaveInterval should be enabled"
}

$dashboards = @(
  "dashboard\home.md",
  "dashboard\pending-proposals.md",
  "dashboard\accepted-proposals.md",
  "dashboard\rejected-proposals.md",
  "dashboard\skills.md",
  "dashboard\router-evals.md",
  "dashboard\weekly-audit.md"
)
foreach ($item in $dashboards) {
  if (-not (Test-Path -LiteralPath (Join-Path $Root $item))) {
    throw "Missing dashboard: $item"
  }
}

Write-Host "Obsidian validation passed."
