# Codex External Config Snapshot

本文件记录 AI Memory OS 之外、但接入 Codex 时需要配置的本机内容。它是可公开提交的配置副本，不保存 token、密码、密钥、账号 cookie、私有日志或机器专属敏感信息。

## Paths

| Purpose | Path |
|---|---|
| Memory OS repo | `C:\Users\btf\AI-MemoryOS` |
| Codex global instructions | `C:\Users\btf\.codex\AGENTS.md` |
| Codex config | `C:\Users\btf\.codex\config.toml` |
| Codex skill discovery root | `C:\Users\btf\.codex\skills` |
| Memory OS active skill source | `C:\Users\btf\AI-MemoryOS\adapters\codex\skills` |
| Codex bootstrap generated target | `C:\Users\btf\AI-MemoryOS\adapters\codex\bootstrap.md` |
| Codex gate generated target | `C:\Users\btf\AI-MemoryOS\adapters\codex\gate.md` |
| Adapter gate source | `C:\Users\btf\AI-MemoryOS\adapters\gate-source` |

## Global AGENTS Bootstrap

`C:\Users\btf\.codex\AGENTS.md` should contain only this bootstrap:

```md
# Codex Bootstrap

每个用户输入先读取：

`C:\Users\btf\AI-MemoryOS\adapters\codex\bootstrap.md`

该文件是 Codex 接入 AI Memory OS 的唯一加载入口，负责判断是否需要读取完整 gate。

完整 gate 位于：

`C:\Users\btf\AI-MemoryOS\adapters\codex\gate.md`

读取完整 gate 只用于加载 Codex 运行策略，不等于读取 Memory OS 正文。

如果 `bootstrap.md` 读取失败：

- 使用简洁、直接、工程化的中文回答。
- 普通 explain / 单点 debug / small implement 直接处理。
- 涉及架构、跨模块、安全/权限、发布流程、Memory OS 维护、长期规范时，先询问用户是否读取 Memory OS。
- 不自动写入 Memory OS；只有用户明确要求或确认后，才写入 `C:\Users\btf\AI-MemoryOS\proposals\pending\`。

项目本地 `AGENTS.md`、README、代码事实优先于 AI Memory OS。
```

Keep this file UTF-8 no BOM.

`adapters/codex/bootstrap.md` and `adapters/codex/gate.md` are generated targets. Do not edit them by hand. Update `adapters/gate-source/**` or `adapters/codex/templates/`, then run `tools/sync-adapter-gates.ps1` and `tools/validate-memory-os.ps1`.

## Codex Config Snippet

Merge into `C:\Users\btf\.codex\config.toml`:

```toml
[features]
memories = true

[projects.'c:\users\btf\ai-memoryos']
trust_level = "trusted"
```

Optional user-level Codex preferences observed on this machine, not required for Memory OS restore:

```toml
model = "gpt-5.5"
model_reasoning_effort = "medium"
personality = "pragmatic"

[windows]
sandbox = "elevated"
```

Do not blindly copy unrelated trusted projects, marketplace cache paths, or unrelated MCP servers from an existing `config.toml`.

## Optional MCP Config

MCP is optional. It is useful when Codex should access the restricted AI Memory OS MCP tools instead of only reading files directly.

Merge this snippet into `C:\Users\btf\.codex\config.toml` only after validating local paths:

```toml
[mcp_servers.ai_memoryos]
command = "C:\\Users\\btf\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\node\\bin\\node.exe"
args = [
  "C:\\Users\\btf\\AI-MemoryOS\\adapters\\mcp\\server\\obsidian-memory-os-mcp.mjs"
]
enabled = true
startup_timeout_sec = 10
tool_timeout_sec = 60
```

Source snapshot:

```text
adapters/mcp/config/codex-mcp.example.toml
```

Optional CodeGraph MCP snapshot:

```text
adapters/codex/config/codegraph-mcp.example.toml
```

CodeGraph is an optional project-code graph acceleration layer. Its runtime policy, wrapper, and restore notes are documented under `integrations/codegraph.md` and `adapters/codegraph/external-config.md`.

Validate the server path:

```powershell
& "C:\Users\btf\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe" `
  "C:\Users\btf\AI-MemoryOS\adapters\mcp\server\obsidian-memory-os-mcp.mjs"
```

If the Codex bundled Node path changes, update only the `command` path in local `config.toml`; do not commit machine-specific runtime discovery output.

MCP safety boundary:

- Read/search Memory OS text files, including `proposals/future-directions/` as read-only long-term direction notes.
- Create or append only `proposals/pending/`.
- Do not use MCP to directly modify formal rules, router, skills, evals, future direction notes, accepted proposals, or rejected proposals.
- Do not store tokens, passwords, secrets, cookies, account data, private logs, or PII in MCP config.

## Optional Figma MCP And Official Skills

Figma is an optional external design capability used by `workflows/frontend-prototype-to-figma-design.md`. Memory OS stores only restoration and verification guidance; OAuth state, account data, private Figma file content, and plugin cache contents remain outside this repository.

Preferred Codex App setup:

- Install the official Figma integration through Codex Plugins.
- Complete Figma OAuth interactively.
- Confirm the integration exposes the official Skills required by the workflow: `figma-create-new-file`, `figma-use`, `figma-generate-design`, `figma-generate-library`, and `figma-design-to-code`.

Manual remote MCP fallback:

```powershell
codex mcp add figma --url https://mcp.figma.com/mcp
```

When using the manual MCP path, install the official Figma Skills separately through Figma's supported distribution. Do not copy their bodies into `AI-MemoryOS\skills`, add them to `skills/registry.json`, or create Memory OS junctions for plugin-managed Skills.

Validation:

- Restart Codex after installation or connection changes.
- Confirm the `figma` MCP server is connected and OAuth succeeds.
- Confirm the workflow's official Skill names are discoverable before attempting a canvas write.
- Do not record versioned plugin-cache paths such as `...\figma\<version>\skills`; plugin updates may replace them.

## Active Skill Junctions

Codex Desktop discovers skills from `C:\Users\btf\.codex\skills`. Each active skill should be a junction to the Memory OS source directory.

Active `SKILL.md` files are generated from shared specs:

```text
skills/registry.json
skills/<skill>/SKILL_SPEC.md
tools/sync-skills.ps1
```

Do not edit generated adapter `SKILL.md` files by hand — they will be overwritten on the next sync. Update the shared spec (`skills/<skill>/SKILL_SPEC.md`) or registry adapter description instead, then run `tools/sync-skills.ps1` followed by `tools/validate-memory-os.ps1`. The shared spec is the single source of truth.

Active skills:

- `memory-curator`
- `routing-auditor`
- `bugfix-with-regression-test`
- `frontend-component-review`
- `git-ops-guide`
- `pr-review`
- `vue-change-self-check`

PowerShell setup:

```powershell
$src = "C:\Users\btf\AI-MemoryOS\adapters\codex\skills"
$dst = "C:\Users\btf\.codex\skills"
New-Item -ItemType Directory -Force -Path $dst | Out-Null

foreach ($skill in @(
  "memory-curator",
  "routing-auditor",
  "bugfix-with-regression-test",
  "frontend-component-review",
  "git-ops-guide",
  "pr-review",
  "vue-change-self-check"
)) {
  $link = Join-Path $dst $skill
  $target = Join-Path $src $skill
  if (-not (Test-Path -LiteralPath $link)) {
    New-Item -ItemType Junction -Path $link -Target $target | Out-Null
  }
}
```

Do not map every candidate skill. Only map active skills with stable trigger boundaries.

## Git Local Config

The repository local Git config is outside tracked files. Recreate it on a new machine if this repository should commit and push directly.

Current expected local config:

```powershell
git -C C:\Users\btf\AI-MemoryOS config user.name "x-bi"
git -C C:\Users\btf\AI-MemoryOS config user.email "924992512@qq.com"
git -C C:\Users\btf\AI-MemoryOS remote add origin https://github.com/x-bi/AI-MemoryOS.git
git -C C:\Users\btf\AI-MemoryOS branch --set-upstream-to=origin/main main
```

If `origin` already exists, update it instead:

```powershell
git -C C:\Users\btf\AI-MemoryOS remote set-url origin https://github.com/x-bi/AI-MemoryOS.git
```

Validate:

```powershell
git -C C:\Users\btf\AI-MemoryOS config --local --list
git -C C:\Users\btf\AI-MemoryOS remote -v
git -C C:\Users\btf\AI-MemoryOS status -sb
```

Authentication tokens or credential helpers must not be stored in this repository.

## Obsidian Config

Obsidian vault configuration is already inside this repository under `.obsidian/`, including:

- community plugin list,
- QuickAdd choices,
- Templater settings,
- Dataview settings,
- Obsidian Git settings,
- Advanced URI plugin files.

No separate OS-external copy is needed for Obsidian as long as `.obsidian/` remains tracked. Do not store Obsidian account data, sync secrets, private plugin tokens, or workspace-local sensitive state in the repository.

Current tracked Obsidian plugins:

- `dataview`
- `templater-obsidian`
- `quickadd`
- `obsidian-advanced-uri`
- `obsidian-git`

## Observed Local Codex Config Outside Memory OS Scope

The current local `C:\Users\btf\.codex\config.toml` may also contain entries unrelated to AI Memory OS, such as:

- trusted business/project workspaces,
- `lanhu` MCP server,
- bundled browser/document/spreadsheet/presentation plugins,
- marketplace cache paths,
- disabled or unrelated local skills.

Do not copy these as part of Memory OS setup unless that specific integration is needed.

## Validation

Run after setup:

```powershell
& C:\Users\btf\AI-MemoryOS\tools\validate-memory-os.ps1
& C:\Users\btf\AI-MemoryOS\tools\sync-adapter-gates.ps1 -Check
```

Manual checks:

```powershell
Get-Content C:\Users\btf\.codex\AGENTS.md -Encoding utf8
Get-ChildItem C:\Users\btf\.codex\skills | Select-Object Name,LinkType,Target
```

Expected result:

- `AGENTS.md` is the bootstrap above.
- `adapters/codex/bootstrap.md` and `adapters/codex/gate.md` contain generated markers and match `tools/sync-adapter-gates.ps1 -Check`.
- Seven active skills appear under `.codex\skills`.
- Active skills are junctions or symbolic links to `AI-MemoryOS\adapters\codex\skills`.
- `SKILL.md` files are UTF-8 no BOM.
- Managed skill source hashes match `skills/<skill>/SKILL_SPEC.md`.
- Optional MCP config points to an existing Node runtime and `adapters\mcp\server\obsidian-memory-os-mcp.mjs`.
- Git local config has the intended `user.name`, `user.email`, `origin`, and `main` upstream.
- Obsidian config is restored by tracked `.obsidian/` files, not by this external config snapshot.

## Read Boundary

This file is a setup snapshot. Normal Codex tasks should not read it.

Read this file only when:

- setting up Codex on a new machine,
- changing Codex installation/runtime,
- repairing `.codex` config,
- auditing external Codex configuration,
- updating active skill junctions,
- enabling or debugging the optional MCP server.
- restoring repository-local Git config.
