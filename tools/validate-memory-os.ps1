param(
  [string]$Root = "C:\Users\btf\AI-MemoryOS"
)

$ErrorActionPreference = "Stop"
$required = @(
  "_index.md",
  "STATUS.md",
  "GOVERNANCE.md",
  "adapters\codex\skills\memory-curator\SKILL.md",
  "adapters\codex\skills\routing-auditor\SKILL.md",
  "adapters\codex\skills\bugfix-with-regression-test\SKILL.md",
  "adapters\codex\skills\frontend-component-review\SKILL.md",
  "router\intent-map.md",
  "router\domain-map.md",
  "router\skill-map.md",
  "evals\router-test-cases.md",
  "evals\skill-trigger-test-cases.md",
  "dashboard\home.md",
  "templates\proposal.md",
  "templates\router-correction-proposal.md",
  "templates\weekly-audit.md",
  "tools\sync-codex-skills.ps1",
  "adapters\mcp\README.md",
  "adapters\mcp\tool-policy.md",
  "adapters\mcp\server\obsidian-memory-os-mcp.mjs"
)

$missing = @()
foreach ($item in $required) {
  $path = Join-Path $Root $item
  if (-not (Test-Path -LiteralPath $path)) { $missing += $item }
}

$codexSkillRoot = Join-Path $env:USERPROFILE ".codex\skills"
$activeSkills = @("memory-curator", "routing-auditor", "bugfix-with-regression-test", "frontend-component-review")
$missingCodexSkills = @()
$junctionCodexSkills = @()
foreach ($skill in $activeSkills) {
  $codexPath = Join-Path $codexSkillRoot $skill
  $codexSkillFile = Join-Path $codexPath "SKILL.md"
  if (-not (Test-Path -LiteralPath $codexSkillFile)) {
    $missingCodexSkills += $skill
    continue
  }

  $codexItem = Get-Item -LiteralPath $codexPath -Force
  if ($codexItem.LinkType -in @("Junction", "SymbolicLink")) {
    $junctionCodexSkills += $skill
  }
}

$templateChecks = @(
  "templates\proposal.md",
  "templates\router-correction-proposal.md",
  "templates\weekly-audit.md"
)
$badTemplates = @()
foreach ($item in $templateChecks) {
  $path = Join-Path $Root $item
  $text = Get-Content -LiteralPath $path -Raw -Encoding UTF8
  if (-not $text.StartsWith("---")) { $badTemplates += $item }
}

if ($missing.Count -gt 0 -or $missingCodexSkills.Count -gt 0 -or $junctionCodexSkills.Count -gt 0 -or $badTemplates.Count -gt 0) {
  Write-Host "Memory OS validation failed."
  if ($missing.Count -gt 0) { Write-Host "Missing files:"; $missing | ForEach-Object { Write-Host "- $_" } }
  if ($missingCodexSkills.Count -gt 0) { Write-Host "Missing .codex synced skills:"; $missingCodexSkills | ForEach-Object { Write-Host "- $_" } }
  if ($junctionCodexSkills.Count -gt 0) { Write-Host ".codex skills should be real copied directories, not junctions:"; $junctionCodexSkills | ForEach-Object { Write-Host "- $_" } }
  if ($badTemplates.Count -gt 0) { Write-Host "Templates missing frontmatter:"; $badTemplates | ForEach-Object { Write-Host "- $_" } }
  exit 1
}

Write-Host "Memory OS validation passed."
