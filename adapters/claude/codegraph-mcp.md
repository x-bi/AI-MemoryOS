# Claude CodeGraph MCP Restore

Use this only when CodeGraph is enabled for Claude Code.

## Add MCP Server

```powershell
& C:\Users\btf\.local\bin\claude.exe mcp add --transport stdio --scope user codegraph -- `
  powershell `
  -NoProfile `
  -ExecutionPolicy Bypass `
  -File C:\Users\btf\AI-MemoryOS\tools\codegraph-wrapper.ps1 `
  serve
```

## Validate

```powershell
& C:\Users\btf\.local\bin\claude.exe mcp list
& C:\Users\btf\.local\bin\claude.exe mcp get codegraph
```

Expected result: `codegraph` is connected.

## Remove

```powershell
& C:\Users\btf\.local\bin\claude.exe mcp remove codegraph
```

Do not copy Claude auth, session, cache, history, or project state files as part of this restore.
