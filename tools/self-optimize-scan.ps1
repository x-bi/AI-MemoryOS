<#
.SYNOPSIS
  Scan external GitHub/Web projects for ideas worth borrowing into AI Memory OS.

.DESCRIPTION
  1. Auto-detect or accept keywords describing this project.
  2. Search GitHub for candidate repos via REST API.
  3. Fetch top-N READMEs.
  4. Build a self-summary of this repo.
  5. Ask Claude CLI (headless) to evaluate borrow-worthiness + WebSearch.
  6. Optionally run adversarial verification pass.
  7. Render a Chinese markdown report under reports/.

.NOTES
  Requires: claude CLI on PATH (unless -DryRun).
  Optional: $env:GITHUB_TOKEN for higher GitHub rate limits.
#>

param(
  [string]$Root = "C:\Users\btf\AI-MemoryOS",
  [string]$Keywords = "",
  [int]$TopN = 10,
  [int]$BatchSize = 3,
  [int]$ReadmeBytes = 5120,
  [int]$MaxPromptBytes = 204800,
  [switch]$Verify,
  [switch]$DryRun,
  [string]$Model = ""
)

$ErrorActionPreference = "Stop"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

function Write-Status($msg) {
  Write-Host "[self-optimize-scan] $msg"
}

function Get-Utf8NoBom() {
  return New-Object System.Text.UTF8Encoding($false)
}

function Test-DirExists($path) {
  return (Test-Path -LiteralPath $path -PathType Container)
}

function Truncate-Bytes([string]$text, [int]$maxBytes) {
  $enc = [System.Text.Encoding]::UTF8
  $bytes = $enc.GetBytes($text)
  if ($bytes.Length -le $maxBytes) { return $text }
  # Walk back char-by-char until byte count fits
  $chars = $text.ToCharArray()
  $sb = New-Object System.Text.StringBuilder
  $len = 0
  foreach ($c in $chars) {
    $cBytes = $enc.GetByteCount(@($c))
    if ($len + $cBytes -gt $maxBytes) { break }
    [void]$sb.Append($c)
    $len += $cBytes
  }
  return $sb.ToString() + "`n[... truncated ...]"
}

function Read-FirstN($path, $n) {
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { return "" }
  $lines = Get-Content -LiteralPath $path -Encoding UTF8 -TotalCount $n -ErrorAction SilentlyContinue
  if ($null -eq $lines) { return "" }
  return ($lines -join "`n")
}

# ---------------------------------------------------------------------------
# Step 0: Preflight
# ---------------------------------------------------------------------------

Write-Status "Step 0: Preflight checks"

if (-not (Test-DirExists $Root)) {
  throw "Root directory not found: $Root"
}

$reportsDir = Join-Path $Root "reports"
if (-not (Test-DirExists $reportsDir)) {
  New-Item -ItemType Directory -Path $reportsDir -Force | Out-Null
}

if (-not $DryRun) {
  $claudeCmd = Get-Command claude -ErrorAction SilentlyContinue
  if (-not $claudeCmd) {
    throw "claude CLI not found on PATH. Install Claude Code, then retry. (Use -DryRun to skip the LLM step.)"
  }
  Write-Status "  claude CLI found: $($claudeCmd.Source)"
} else {
  Write-Status "  DryRun mode — skipping claude preflight"
}

# ---------------------------------------------------------------------------
# Step 1: Keyword derivation
# ---------------------------------------------------------------------------

Write-Status "Step 1: Keyword derivation"

$autoKeywordMap = @(
  @{ Test = "adapters\claude";           Term = "claude code skill" },
  @{ Test = "adapters\codex";            Term = "codex agent skill" },
  @{ Test = "skills\registry.json";      Term = "agent skill registry" },
  @{ Test = "proposals";                 Term = "agent proposal workflow" },
  @{ Test = "router\intent-map.md";      Term = "agent memory routing" },
  @{ Test = "router";                    Term = "LLM task router" },
  @{ Test = "adapters\mcp";              Term = "mcp server obsidian" },
  @{ Test = ".obsidian";                 Term = "obsidian agent memory" }
)

$anchorTerm = "personal AI memory OS"

if ([string]::IsNullOrWhiteSpace($Keywords)) {
  $kwList = @()
  foreach ($entry in $autoKeywordMap) {
    $testPath = Join-Path $Root $entry.Test
    if ((Test-Path -LiteralPath $testPath)) {
      $kwList += $entry.Term
    }
    if ($kwList.Length -ge 8) { break }
  }
  # Always add anchor
  $kwList += $anchorTerm
  $Keywords = $kwList -join ","
}

$kwArray = $Keywords -split "," | ForEach-Object { $_.Trim() } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
Write-Status "  Keywords: $($kwArray -join ', ')"

# ---------------------------------------------------------------------------
# Step 2: GitHub Search
# ---------------------------------------------------------------------------

Write-Status "Step 2: GitHub Search (per keyword)"

$ghHeaders = @{
  "Accept"               = "application/vnd.github+json"
  "X-GitHub-Api-Version" = "2022-11-28"
  "User-Agent"           = "AI-MemoryOS-self-optimize-scan"
}
if ($env:GITHUB_TOKEN) {
  $ghHeaders["Authorization"] = "Bearer $env:GITHUB_TOKEN"
  Write-Status "  Using GITHUB_TOKEN (authenticated mode)"
} else {
  Write-Status "  No GITHUB_TOKEN — unauthenticated mode (60 req/hr limit)"
}

$allRepos = @()
$seenUrls = @{}

foreach ($kw in $kwArray) {
  $query = [uri]::EscapeDataString("$kw in:name,description,readme")
  $uri = "https://api.github.com/search/repositories?q=$query&sort=stars&order=desc&per_page=$TopN"
  try {
    $resp = Invoke-RestMethod -Uri $uri -Headers $ghHeaders -ErrorAction Stop
  } catch {
    if ($_.Exception.Response.StatusCode -eq 403) {
      Write-Warning "GitHub rate limit hit on keyword '$kw'. Stopping GitHub queries."
      break
    }
    Write-Warning "GitHub search failed for keyword '$kw': $($_.Exception.Message)"
    continue
  }
  if ($null -eq $resp.items) { continue }
  foreach ($item in $resp.items) {
    if ($seenUrls.ContainsKey($item.html_url)) { continue }
    $seenUrls[$item.html_url] = $true
    $allRepos += [ordered]@{
      full_name        = $item.full_name
      html_url         = $item.html_url
      description      = if ($item.description) { $item.description } else { "" }
      stargazers_count = $item.stargazers_count
      language         = if ($item.language) { $item.language } else { "" }
      updated_at       = $item.updated_at
      topics           = if ($item.topics) { $item.topics -join ", " } else { "" }
      default_branch   = if ($item.default_branch) { $item.default_branch } else { "main" }
    }
  }
}

# Dedupe already done by $seenUrls; sort by stars, keep top N
$allRepos = $allRepos | Sort-Object -Property stargazers_count -Descending | Select-Object -First $TopN
Write-Status "  Fetched $($allRepos.Count) unique candidates (top $TopN by stars)"

if ($allRepos.Count -eq 0) {
  throw "No GitHub candidates found. Check keywords or network connectivity."
}

# ---------------------------------------------------------------------------
# Step 3: README fetch
# ---------------------------------------------------------------------------

Write-Status "Step 3: README fetch"

$readmeFetchCount = 0
$readmeRateLimited = $false
foreach ($repo in $allRepos) {
  if ($readmeRateLimited) { $repo["readme"] = ""; continue }
  $readmeUri = "https://api.github.com/repos/$($repo.full_name)/readme"
  try {
    $readmeResp = Invoke-RestMethod -Uri $readmeUri -Headers $ghHeaders -ErrorAction Stop
    if ($readmeResp.content) {
      $cleanContent = ($readmeResp.content -replace '\s', '')
      $decoded = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($cleanContent))
      $repo["readme"] = (Truncate-Bytes $decoded $ReadmeBytes)
      $readmeFetchCount++
    } else {
      $repo["readme"] = ""
    }
  } catch {
    $repo["readme"] = ""
    if ($_.Exception.Response.StatusCode -eq 403) {
      Write-Warning "GitHub rate limit hit on README fetch ($($repo.full_name)). Remaining READMEs will be empty. Set `$env:GITHUB_TOKEN to lift the 60 req/hr ceiling."
      $readmeRateLimited = $true
    }
  }
}
Write-Status "  Fetched READMEs: $readmeFetchCount / $($allRepos.Count)"

# ---------------------------------------------------------------------------
# Step 4: Self-summary assembly
# ---------------------------------------------------------------------------

Write-Status "Step 4: Self-summary assembly"

$selfSummary = @()

# Top-level dir listing
$dirNames = @("adapters", "skills", "tools", "router", "workflows", "proposals", "templates")
$selfSummary += "## 顶层目录"
foreach ($d in $dirNames) {
  $dp = Join-Path $Root $d
  if (Test-DirExists $dp) {
    $children = (Get-ChildItem -LiteralPath $dp -Directory -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name) -join ", "
    if ([string]::IsNullOrWhiteSpace($children)) {
      $selfSummary += "- $d/ (empty or files only)"
    } else {
      $selfSummary += "- $d/: $children"
    }
  }
}

# README head
$selfSummary += ""
$selfSummary += "## README.md (前 60 行)"
$selfSummary += (Read-FirstN (Join-Path $Root "README.md") 60)

# _index.md head
$selfSummary += ""
$selfSummary += "## _index.md (前 60 行)"
$selfSummary += (Read-FirstN (Join-Path $Root "_index.md") 60)

# Keywords
$selfSummary += ""
$selfSummary += "## 当前搜索关键词"
$selfSummary += ($kwArray -join ", ")

$selfSummaryText = $selfSummary -join "`n"
$selfSummaryText = Truncate-Bytes $selfSummaryText 8192

# ---------------------------------------------------------------------------
# Step 5: Prompt assembly
# ---------------------------------------------------------------------------

Write-Status "Step 5: Prompt assembly"

function Build-Prompt($repos, $summary, $readmeCap, [bool]$IncludeWebSearch = $true, [int]$BatchIndex = 0, [int]$BatchTotal = 1) {
  $sb = New-Object System.Text.StringBuilder

  [void]$sb.AppendLine("# 角色")
  [void]$sb.AppendLine("你是外部项目借鉴评估师。评估以下 GitHub 候选项目对本仓库的借鉴价值。输出中文。")
  if ($BatchTotal -gt 1) {
    [void]$sb.AppendLine()
    [void]$sb.AppendLine("（本次为第 $($BatchIndex + 1) / $BatchTotal 批，仅评估本批 $($repos.Count) 个候选；其它候选另行评估。）")
  }
  [void]$sb.AppendLine()

  [void]$sb.AppendLine("# 本仓库描述")
  [void]$sb.AppendLine($summary)
  [void]$sb.AppendLine()

  [void]$sb.AppendLine("# 候选项目 (GitHub Search)")
  foreach ($repo in $repos) {
    [void]$sb.AppendLine("## $($repo.full_name)  (★$($repo.stargazers_count), $($repo.language), updated $($repo.updated_at))")
    [void]$sb.AppendLine("- url: $($repo.html_url)")
    [void]$sb.AppendLine("- topics: $($repo.topics)")
    [void]$sb.AppendLine("- description: $($repo.description)")
    if (-not [string]::IsNullOrWhiteSpace($repo["readme"])) {
      [void]$sb.AppendLine("- README (truncated):")
      [void]$sb.AppendLine('```')
      [void]$sb.AppendLine($repo["readme"])
      [void]$sb.AppendLine('```')
    }
    [void]$sb.AppendLine()
  }

  [void]$sb.AppendLine("# 任务")
  $taskIdx = 1
  if ($IncludeWebSearch) {
    [void]$sb.AppendLine("$taskIdx. 也请使用 WebSearch 搜索 2-3 个补充查询，合并结果。")
    $taskIdx++
  }
  [void]$sb.AppendLine("$taskIdx. 对每个候选判断是否有具体可借鉴的想法/模式/工作流。")
  $taskIdx++
  [void]$sb.AppendLine("$taskIdx. 仅输出一个 ```json 块，schema 如下：")
  [void]$sb.AppendLine()
  [void]$sb.AppendLine('```json')
  [void]$sb.AppendLine('{')
  [void]$sb.AppendLine('  "borrow_candidates": [{')
  [void]$sb.AppendLine('    "source_url": "",')
  [void]$sb.AppendLine('    "source_name": "owner/repo or site title",')
  [void]$sb.AppendLine('    "channel": "github" | "web",')
  [void]$sb.AppendLine('    "idea_title": "中文短句",')
  [void]$sb.AppendLine('    "why_relevant": "1-2 句中文",')
  [void]$sb.AppendLine('    "fit_with_this_repo": "指明可能目录/文件",')
  [void]$sb.AppendLine('    "estimated_effort": "S" | "M" | "L",')
  [void]$sb.AppendLine('    "estimated_value": "low" | "med" | "high",')
  [void]$sb.AppendLine('    "risks": "1 句中文"')
  [void]$sb.AppendLine('  }],')
  [void]$sb.AppendLine('  "web_queries_used": [],')
  [void]$sb.AppendLine('  "overview": "3-5 句中文概览"')
  [void]$sb.AppendLine('}')
  [void]$sb.AppendLine('```')
  [void]$sb.AppendLine()
  [void]$sb.AppendLine("4. 硬约束：不提议修改 proposals/；只提想法不提代码；跳过仅「用了 LLM」的重叠。")

  return $sb.ToString()
}

# ---------------------------------------------------------------------------
# Helper: build prompt for ONE batch + auto-shrink if oversized
# ---------------------------------------------------------------------------
function Build-BatchPrompt($batchRepos, $summary, $readmeCap, $maxBytes, $batchIdx, $batchTotal, $includeWeb) {
  $enc = [System.Text.Encoding]::UTF8
  $promptText = Build-Prompt -repos $batchRepos -summary $summary -readmeCap $readmeCap -IncludeWebSearch $includeWeb -BatchIndex $batchIdx -BatchTotal $batchTotal

  $shrinkPass = 0
  $currentCap = $readmeCap
  while ($enc.GetByteCount($promptText) -gt $maxBytes -and $shrinkPass -lt 3) {
    $shrinkPass++
    $currentCap = [math]::Max([math]::Floor($currentCap / 2), 512)
    Write-Warning "  Batch $($batchIdx + 1): prompt too large, shrinking README cap to $currentCap (pass $shrinkPass)"
    foreach ($repo in $batchRepos) {
      if (-not [string]::IsNullOrWhiteSpace($repo["readme"])) {
        $repo["readme"] = Truncate-Bytes $repo["readme"] $currentCap
      }
    }
    $promptText = Build-Prompt -repos $batchRepos -summary $summary -readmeCap $currentCap -IncludeWebSearch $includeWeb -BatchIndex $batchIdx -BatchTotal $batchTotal
  }
  return $promptText
}

# ---------------------------------------------------------------------------
# Helper: invoke claude on a single prompt file, return parsed inner JSON or $null
# ---------------------------------------------------------------------------
function Invoke-ClaudeOnPrompt($promptPath, $claudeArgs, $reportsDir, $batchLabel) {
  $rawOutput = Get-Content -LiteralPath $promptPath -Raw -Encoding UTF8 | claude @claudeArgs 2>&1
  $exit = $LASTEXITCODE

  if ($exit -ne 0) {
    $errorPath = Join-Path $reportsDir ".last-claude-error.txt"
    [System.IO.File]::WriteAllText($errorPath, "[batch=$batchLabel]`n$rawOutput", (Get-Utf8NoBom))
    throw "Claude CLI exited with code $exit on batch $batchLabel. Error output saved to $errorPath"
  }

  # Envelope parse
  $envelope = $null
  try { $envelope = $rawOutput | ConvertFrom-Json -ErrorAction Stop }
  catch { throw "Failed to parse Claude envelope on batch ${batchLabel}: $($_.Exception.Message)" }

  $assistantText = ""
  if ($envelope.PSObject.Properties["result"]) { $assistantText = $envelope.result }
  elseif ($envelope.PSObject.Properties["content"]) { $assistantText = $envelope.content }
  else { $assistantText = $rawOutput }

  # Extract inner JSON block with truncation repair + undefined sanitization
  $inner = $null
  $m = [regex]::Match($assistantText, '```json\s*([\s\S]*?)\s*```')
  if ($m.Success) {
    try {
      $jt = $m.Groups[1].Value -replace '\bundefined\b', '"unclear"'
      $inner = $jt | ConvertFrom-Json -ErrorAction Stop
    } catch {
      Write-Warning "  Batch ${batchLabel}: inner JSON parse failed: $($_.Exception.Message). Attempting truncation-repair..."
      try {
        $jt = $m.Groups[1].Value -replace '\bundefined\b', '"unclear"'
        $lastComplete = $jt.LastIndexOf("},")
        if ($lastComplete -gt 0) {
          $repaired = $jt.Substring(0, $lastComplete + 1) + "`n  ]`n}"
          $inner = $repaired | ConvertFrom-Json -ErrorAction Stop
          Write-Warning "    Repair succeeded (some trailing candidates may be missing)."
        }
      } catch {
        Write-Warning "    Repair also failed: $($_.Exception.Message)."
      }
    }
  }
  if ($null -eq $inner) {
    try {
      $fb = $assistantText -replace '\bundefined\b', '"unclear"'
      $inner = $fb | ConvertFrom-Json -ErrorAction Stop
    } catch {
      Write-Warning "  Batch ${batchLabel}: could not extract structured JSON. Skipping this batch."
    }
  }
  return ,@{ inner = $inner; rawText = $assistantText }
}

# ---------------------------------------------------------------------------
# Step 5+6: Batched prompt assembly + Claude evaluation
# ---------------------------------------------------------------------------

# Slice candidates into batches
$batches = @()
for ($i = 0; $i -lt $allRepos.Count; $i += $BatchSize) {
  $end = [math]::Min($i + $BatchSize, $allRepos.Count)
  $batches += ,@($allRepos[$i..($end - 1)])
}
$batchTotal = $batches.Count
Write-Status "  Splitting $($allRepos.Count) candidates into $batchTotal batch(es) of up to $BatchSize"

# Build claude args once
$claudeArgs = @("-p", "--output-format", "json", "--allowed-tools", "WebSearch,WebFetch", "--effort", "high")
if (-not [string]::IsNullOrWhiteSpace($Model)) {
  $claudeArgs += @("--model", $Model)
}

# DryRun: just preview the FIRST batch's prompt
if ($DryRun) {
  $previewPrompt = Build-BatchPrompt -batchRepos $batches[0] -summary $selfSummaryText -readmeCap $ReadmeBytes -maxBytes $MaxPromptBytes -batchIdx 0 -batchTotal $batchTotal -includeWeb $true
  $ts = Get-Date -Format "yyyy-MM-dd-HHmm"
  $previewPath = Join-Path $reportsDir "self-optimize-prompt-preview-$ts.md"
  [System.IO.File]::WriteAllText($previewPath, $previewPrompt, (Get-Utf8NoBom))
  $previewBytes = [System.Text.Encoding]::UTF8.GetByteCount($previewPrompt)
  Write-Status "  Batch 1 prompt size: $([math]::Round($previewBytes / 1024, 1)) KB"
  Write-Status "DryRun: first-batch prompt preview saved to $previewPath"
  return
}

Write-Status "Step 6: Pass 1 — Claude CLI calls (batched)"

# Loop batches; merge results
$mergedCandidates = @()
$mergedOverview = @()
$mergedWebQueries = @()
$batchIdx = 0
foreach ($batchRepos in $batches) {
  $batchIdx++
  $batchLabel = "$batchIdx/$batchTotal"
  $includeWeb = ($batchIdx -eq 1)  # only first batch runs WebSearch to avoid redundant cost
  Write-Status "  Batch ${batchLabel}: $($batchRepos.Count) candidate(s), WebSearch=$includeWeb"

  $bpText = Build-BatchPrompt -batchRepos $batchRepos -summary $selfSummaryText -readmeCap $ReadmeBytes -maxBytes $MaxPromptBytes -batchIdx ($batchIdx - 1) -batchTotal $batchTotal -includeWeb $includeWeb
  $bpBytes = [System.Text.Encoding]::UTF8.GetByteCount($bpText)
  Write-Status "    Prompt size: $([math]::Round($bpBytes / 1024, 1)) KB"

  $bpPath = Join-Path $env:TEMP "self-optimize-prompt-batch-$batchIdx-$([guid]::NewGuid()).md"
  [System.IO.File]::WriteAllText($bpPath, $bpText, (Get-Utf8NoBom))

  try {
    $result = Invoke-ClaudeOnPrompt -promptPath $bpPath -claudeArgs $claudeArgs -reportsDir $reportsDir -batchLabel $batchLabel
    $bInner = $result.inner
    if ($null -ne $bInner -and $bInner.borrow_candidates) {
      $mergedCandidates += $bInner.borrow_candidates
      if ($bInner.PSObject.Properties["overview"] -and $bInner.overview) {
        $mergedOverview += "[批 $batchLabel] " + $bInner.overview
      }
      if ($bInner.PSObject.Properties["web_queries_used"] -and $bInner.web_queries_used) {
        $mergedWebQueries += $bInner.web_queries_used
      }
      Write-Status "    OK: $($bInner.borrow_candidates.Count) candidate(s) from this batch"
    } else {
      Write-Warning "  Batch ${batchLabel}: no structured candidates returned."
    }
  } finally {
    if (Test-Path -LiteralPath $bpPath -PathType Leaf) {
      try { Remove-Item -LiteralPath $bpPath -Force -ErrorAction Stop } catch { }
    }
  }
}

# Build the unified $innerJson the downstream code expects
$innerJson = $null
if ($mergedCandidates.Count -gt 0) {
  $innerJson = [pscustomobject]@{
    borrow_candidates = $mergedCandidates
    overview = ($mergedOverview -join "`n`n")
    web_queries_used = ($mergedWebQueries | Select-Object -Unique)
  }
  Write-Status "  Merged: $($mergedCandidates.Count) total candidates across $batchTotal batch(es)"
}

# Dummy $promptPath so the outer finally{} below doesn't crash on undefined var
# (kept for compatibility with the legacy try/finally cleanup block below).
$promptPath = Join-Path $env:TEMP "self-optimize-noop-$([guid]::NewGuid()).txt"

try {
  # (Pass 1 already completed above; this try{} only exists so Pass 2 / Step 8 / finally still flow.)
  $assistantText = $mergedCandidates | ConvertTo-Json -Depth 5  # used as fallback in report-render


  # ---------------------------------------------------------------------------
  # Step 7: Pass 2 — Adversarial verification (optional)
  # ---------------------------------------------------------------------------

  if ($Verify -and $null -ne $innerJson -and $innerJson.borrow_candidates) {
    Write-Status "Step 7: Pass 2 — Adversarial verification"

    $verifySb = New-Object System.Text.StringBuilder
    [void]$verifySb.AppendLine("# 对抗验证任务")
    [void]$verifySb.AppendLine("以下是从外部项目扫描中得出的借鉴候选列表。请对每个候选判断它是否真正适合一个「个人 AI Memory OS for AI agents」仓库。")
    [void]$verifySb.AppendLine()
    [void]$verifySb.AppendLine("## 本仓库关键词")
    [void]$verifySb.AppendLine(($kwArray -join ", "))
    [void]$verifySb.AppendLine()
    [void]$verifySb.AppendLine("## 候选列表")
    [void]$verifySb.AppendLine('```json')
    [void]$verifySb.AppendLine(($innerJson.borrow_candidates | ConvertTo-Json -Depth 5))
    [void]$verifySb.AppendLine('```')
    [void]$verifySb.AppendLine()
    [void]$verifySb.AppendLine("## 输出格式")
    [void]$verifySb.AppendLine('仅输出一个 ```json 块：')
    [void]$verifySb.AppendLine('```json')
    [void]$verifySb.AppendLine('{ "verifications": [{ "idea_title": "...", "fits": true|false|unclear, "reason": "一句中文" }] }')
    [void]$verifySb.AppendLine('```')

    $verifyPromptPath = Join-Path $env:TEMP "self-optimize-verify-$([guid]::NewGuid()).md"
    [System.IO.File]::WriteAllText($verifyPromptPath, $verifySb.ToString(), (Get-Utf8NoBom))

    try {
      $verifyRaw = Get-Content -LiteralPath $verifyPromptPath -Raw -Encoding UTF8 | claude @claudeArgs 2>&1
      $verifyExit = $LASTEXITCODE

      if ($verifyExit -eq 0) {
        $verifyJson = $null
        try {
          $verifyEnvelope = $verifyRaw | ConvertFrom-Json -ErrorAction Stop
          $verifyText = ""
          if ($verifyEnvelope.PSObject.Properties["result"]) {
            $verifyText = $verifyEnvelope.result
          } else {
            $verifyText = $verifyRaw
          }
          $verifyJsonMatch = [regex]::Match($verifyText, '```json\s*([\s\S]*?)\s*```')
          $verifyJsonText = ""
          if ($verifyJsonMatch.Success) {
            $verifyJsonText = $verifyJsonMatch.Groups[1].Value
          } else {
            $verifyJsonText = $verifyText
          }
          # Sanitize: replace JS undefined with "unclear" (PowerShell ConvertFrom-Json cannot parse undefined)
          $verifyJsonText = $verifyJsonText -replace '\bundefined\b', '"unclear"'
          $verifyJson = $verifyJsonText | ConvertFrom-Json -ErrorAction Stop

          # Merge verification results into candidates
          if ($verifyJson -and $verifyJson.verifications) {
            foreach ($v in $verifyJson.verifications) {
              $match = $innerJson.borrow_candidates | Where-Object { $_.idea_title -eq $v.idea_title } | Select-Object -First 1
              if ($match) {
                $match | Add-Member -NotePropertyName "fits" -NotePropertyValue $v.fits -Force
                $match | Add-Member -NotePropertyName "verify_reason" -NotePropertyValue $v.reason -Force
              }
            }
          }
          Write-Status "  Verification complete: $($verifyJson.verifications.Count) items checked"
        } catch {
          Write-Warning "Verification JSON parse failed: $($_.Exception.Message). Skipping verification merge."
        }
      } else {
        Write-Warning "Verification Claude call failed (exit $verifyExit). Skipping verification."
      }
    } finally {
      if (Test-Path -LiteralPath $verifyPromptPath -PathType Leaf) {
        try { Remove-Item -LiteralPath $verifyPromptPath -Force -ErrorAction Stop } catch { }
      }
    }
  }

  # ---------------------------------------------------------------------------
  # Step 8: Render report
  # ---------------------------------------------------------------------------

  Write-Status "Step 8: Render report"

  $timestamp = Get-Date -Format "yyyy-MM-dd-HHmm"
  $reportPath = Join-Path $reportsDir "self-optimize-$timestamp.md"
  $isoTs = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"

  $report = New-Object System.Text.StringBuilder

  [void]$report.AppendLine("# Self-Optimize 扫描报告")
  [void]$report.AppendLine()
  [void]$report.AppendLine("- 生成时间: $isoTs")
  [void]$report.AppendLine("- 关键词: $($kwArray -join ', ')")
  [void]$report.AppendLine("- GitHub 候选数: $($allRepos.Count) (去重后 top $TopN)")
  [void]$report.AppendLine("- Verify 通道: $(if ($Verify) { '启用' } else { '未启用' })")
  [void]$report.AppendLine("- 模型: $(if ([string]::IsNullOrWhiteSpace($Model)) { 'default' } else { $Model })")
  [void]$report.AppendLine()

  # Overview
  $overview = ""
  if ($null -ne $innerJson -and $innerJson.PSObject.Properties["overview"]) {
    $overview = $innerJson.overview
  } elseif ($null -eq $innerJson) {
    $overview = "（Claude 未返回结构化结果，详见下方原始输出）"
  }
  [void]$report.AppendLine("## 概览")
  [void]$report.AppendLine()
  [void]$report.AppendLine($overview)
  [void]$report.AppendLine()

  if ($null -ne $innerJson -and $innerJson.borrow_candidates) {
    # Summary table
    [void]$report.AppendLine("## 候选清单")
    [void]$report.AppendLine()
    [void]$report.AppendLine("| # | 来源 | 项目 | ★ | 价值 | 工作量 | 标题 |")
    [void]$report.AppendLine("|---|------|------|---|------|--------|------|")

    $idx = 0
    foreach ($c in $innerJson.borrow_candidates) {
      $idx++
      $channel = if ($c.PSObject.Properties["channel"]) { $c.channel } else { "github" }
      $stars = if ($channel -eq "github") {
        $matchRepo = $allRepos | Where-Object { $_.html_url -eq $c.source_url -or $_.full_name -eq $c.source_name } | Select-Object -First 1
        if ($matchRepo) { $matchRepo.stargazers_count } else { "-" }
      } else { "-" }
      $value = if ($c.PSObject.Properties["estimated_value"]) { $c.estimated_value } else { "-" }
      $effort = if ($c.PSObject.Properties["estimated_effort"]) { $c.estimated_effort } else { "-" }
      [void]$report.AppendLine("| $idx | $channel | $($c.source_name) | $stars | $value | $effort | $($c.idea_title) |")
    }
    [void]$report.AppendLine()

    # Detailed section
    [void]$report.AppendLine("## 详细借鉴点")
    [void]$report.AppendLine()

    $idx = 0
    foreach ($c in $innerJson.borrow_candidates) {
      $idx++
      [void]$report.AppendLine("### $idx. $($c.idea_title)")
      [void]$report.AppendLine("- 来源: [$($c.source_name)]($($c.source_url)) (channel: $(if ($c.PSObject.Properties["channel"]) { $c.channel } else { "unknown" }))")
      [void]$report.AppendLine("- 相关性: $($c.why_relevant)")
      [void]$report.AppendLine("- 接入设想: $($c.fit_with_this_repo)")
      [void]$report.AppendLine("- 工作量 / 价值: $($c.estimated_effort) / $($c.estimated_value)")
      [void]$report.AppendLine("- 风险: $($c.risks)")
      if ($c.PSObject.Properties["fits"]) {
        [void]$report.AppendLine("- 验证: fits=$($c.fits), $($c.verify_reason)")
      }
      [void]$report.AppendLine()
    }
  } else {
    # Fallback: raw output
    [void]$report.AppendLine("## 原始输出")
    [void]$report.AppendLine()
    [void]$report.AppendLine("Claude 未能返回结构化 JSON，以下是原始输出：")
    [void]$report.AppendLine()
    [void]$report.AppendLine('```')
    [void]$report.AppendLine($assistantText)
    [void]$report.AppendLine('```')
    [void]$report.AppendLine()
  }

  # Next steps
  [void]$report.AppendLine("## 下一步建议")
  [void]$report.AppendLine()
  [void]$report.AppendLine("- 不会自动创建 proposal。若要采纳，请基于以上 idea 手工运行:")
  [void]$report.AppendLine('  ```powershell')
  [void]$report.AppendLine('  pwsh tools/new-proposal.ps1 -Title "<中文标题>"')
  [void]$report.AppendLine('  ```')
  [void]$report.AppendLine("- 推荐优先级: 先看 value=high & effort=S/M 的条目。")
  [void]$report.AppendLine()

  # Web queries appendix
  [void]$report.AppendLine("## 附录: 本次使用的 Web 查询")
  [void]$report.AppendLine()
  if ($null -ne $innerJson -and $innerJson.PSObject.Properties["web_queries_used"]) {
    foreach ($q in $innerJson.web_queries_used) {
      [void]$report.AppendLine("- $q")
    }
  } else {
    [void]$report.AppendLine("- （无）")
  }
  [void]$report.AppendLine()

  # Raw JSON appendix
  [void]$report.AppendLine("---")
  [void]$report.AppendLine()
  [void]$report.AppendLine("原始 JSON (备查):")
  [void]$report.AppendLine('```json')
  if ($null -ne $innerJson) {
    [void]$report.AppendLine(($innerJson | ConvertTo-Json -Depth 5))
  } else {
    [void]$report.AppendLine("(无结构化 JSON)")
  }
  [void]$report.AppendLine('```')

  # Write report
  $utf8NoBom = Get-Utf8NoBom
  [System.IO.File]::WriteAllText($reportPath, $report.ToString(), $utf8NoBom)
  Write-Status "Report saved: $reportPath"
  Write-Host $reportPath

} finally {
  # Always clean up temp prompt file (best-effort; ignore lock contention on Windows)
  if (Test-Path -LiteralPath $promptPath -PathType Leaf) {
    try { Remove-Item -LiteralPath $promptPath -Force -ErrorAction Stop } catch { }
  }
}
