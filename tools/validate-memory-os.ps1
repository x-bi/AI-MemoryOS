param(
  [string]$Root = "C:\Users\btf\AI-MemoryOS"
)

$ErrorActionPreference = "Stop"
$required = @(
  "_index.md",
  "STATUS.md",
  "GOVERNANCE.md",
  "adapters\codex\gate.md",
  "adapters\codex\external-config.md",
  "adapters\codex\skills\memory-curator\SKILL.md",
  "adapters\codex\skills\routing-auditor\SKILL.md",
  "adapters\codex\skills\bugfix-with-regression-test\SKILL.md",
  "adapters\codex\skills\frontend-component-review\SKILL.md",
  "adapters\codex\skills\pr-review\SKILL.md",
  "adapters\codex\skills\vue-change-self-check\SKILL.md",
  "skills\vue-change-self-check\SKILL_SPEC.md",
  "router\intent-map.md",
  "router\domain-map.md",
  "router\skill-map.md",
  "evals\router-test-cases.md",
  "evals\skill-trigger-test-cases.md",
  "dashboard\home.md",
  "templates\proposal.md",
  "templates\router-correction-proposal.md",
  "templates\weekly-audit.md",
  "adapters\mcp\README.md",
  "adapters\mcp\tool-policy.md",
  "adapters\mcp\server\obsidian-memory-os-mcp.mjs"
)

$missing = @()
foreach ($item in $required) {
  $path = Join-Path $Root $item
  if (-not (Test-Path -LiteralPath $path)) { $missing += $item }
}

$bomFiles = @()
$skillFilesToCheck = @()
$activeSkills = @("memory-curator", "routing-auditor", "bugfix-with-regression-test", "frontend-component-review", "pr-review", "vue-change-self-check")
foreach ($skill in $activeSkills) {
  $skillFilesToCheck += (Join-Path $Root "adapters\codex\skills\$skill\SKILL.md")
  $skillFilesToCheck += (Join-Path $env:USERPROFILE ".codex\skills\$skill\SKILL.md")
}
foreach ($path in $skillFilesToCheck) {
  if (-not (Test-Path -LiteralPath $path)) { continue }
  $bytes = [System.IO.File]::ReadAllBytes($path)
  if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
    $bomFiles += $path
  }
}

$codexSkillRoot = Join-Path $env:USERPROFILE ".codex\skills"
$missingCodexSkills = @()
$nonJunctionCodexSkills = @()
$wrongTargetCodexSkills = @()
foreach ($skill in $activeSkills) {
  $codexPath = Join-Path $codexSkillRoot $skill
  $codexSkillFile = Join-Path $codexPath "SKILL.md"
  if (-not (Test-Path -LiteralPath $codexSkillFile)) {
    $missingCodexSkills += $skill
    continue
  }

  $codexItem = Get-Item -LiteralPath $codexPath -Force
  if ($codexItem.LinkType -notin @("Junction", "SymbolicLink")) {
    $nonJunctionCodexSkills += $skill
    continue
  }

  $expectedTarget = Join-Path $Root "adapters\codex\skills\$skill"
  $actualTarget = @($codexItem.Target)[0]
  if ([string]::IsNullOrWhiteSpace($actualTarget) -or ((Resolve-Path -LiteralPath $actualTarget).Path -ne (Resolve-Path -LiteralPath $expectedTarget).Path)) {
    $wrongTargetCodexSkills += $skill
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

if ($missing.Count -gt 0 -or $missingCodexSkills.Count -gt 0 -or $nonJunctionCodexSkills.Count -gt 0 -or $wrongTargetCodexSkills.Count -gt 0 -or $badTemplates.Count -gt 0 -or $bomFiles.Count -gt 0) {
  Write-Host "Memory OS validation failed."
  if ($missing.Count -gt 0) { Write-Host "Missing files:"; $missing | ForEach-Object { Write-Host "- $_" } }
  if ($missingCodexSkills.Count -gt 0) { Write-Host "Missing .codex skill junctions:"; $missingCodexSkills | ForEach-Object { Write-Host "- $_" } }
  if ($nonJunctionCodexSkills.Count -gt 0) { Write-Host ".codex skills should be junctions to MemoryOS source:"; $nonJunctionCodexSkills | ForEach-Object { Write-Host "- $_" } }
  if ($wrongTargetCodexSkills.Count -gt 0) { Write-Host ".codex skill junctions point to wrong targets:"; $wrongTargetCodexSkills | ForEach-Object { Write-Host "- $_" } }
  if ($badTemplates.Count -gt 0) { Write-Host "Templates missing frontmatter:"; $badTemplates | ForEach-Object { Write-Host "- $_" } }
  if ($bomFiles.Count -gt 0) { Write-Host "SKILL.md files must be UTF-8 without BOM:"; $bomFiles | ForEach-Object { Write-Host "- $_" } }
  exit 1
}

Write-Host "Memory OS validation passed."
