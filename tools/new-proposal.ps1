param(
  [Parameter(Mandatory=$true)][string]$Title,
  [string]$SourceEpisode = "",
  [string]$Root = "C:\Users\btf\AI-MemoryOS"
)

$ErrorActionPreference = "Stop"
$date = Get-Date -Format "yyyy-MM-dd"
$safe = $Title.ToLowerInvariant() -replace "[^a-z0-9\u4e00-\u9fa5]+", "-"
$safe = $safe.Trim("-")
if ([string]::IsNullOrWhiteSpace($safe)) { $safe = "proposal" }
$path = Join-Path $Root "proposals\pending\$date-$safe.md"
$template = Get-Content -LiteralPath (Join-Path $Root "templates\proposal.md") -Raw -Encoding UTF8
$content = $template.Replace("# Proposal: <title>", "# Proposal: $Title")
if (-not [string]::IsNullOrWhiteSpace($SourceEpisode)) {
  $content = $content.Replace('source_episode: ""', "source_episode: `"$SourceEpisode`"")
  $content = $content.Replace("- Source Episode \u6eaf\u6e90\uff1a", "- Source Episode \u6eaf\u6e90\uff1a$SourceEpisode")
}
$utf8 = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($path, $content, $utf8)
Write-Host $path