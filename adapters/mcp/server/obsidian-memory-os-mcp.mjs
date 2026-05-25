#!/usr/bin/env node

import fs from "node:fs/promises";
import path from "node:path";
import readline from "node:readline";

const ROOT = process.env.AI_MEMORYOS_ROOT || "C:\\Users\\btf\\AI-MemoryOS";
const MAX_READ_BYTES = Number(process.env.AI_MEMORYOS_MAX_READ_BYTES || 60000);
const PENDING_DIR = path.join(ROOT, "proposals", "pending");

function send(message) {
  process.stdout.write(`${JSON.stringify(message)}\n`);
}

function result(id, value) {
  send({ jsonrpc: "2.0", id, result: value });
}

function error(id, code, message) {
  send({ jsonrpc: "2.0", id, error: { code, message } });
}

function normalizeRelative(input) {
  if (!input || typeof input !== "string") {
    throw new Error("path is required");
  }
  if (path.isAbsolute(input)) {
    throw new Error("absolute paths are not allowed");
  }
  const normalized = path.normalize(input);
  const resolved = path.resolve(ROOT, normalized);
  const rootResolved = path.resolve(ROOT);
  if (!resolved.toLowerCase().startsWith(rootResolved.toLowerCase() + path.sep)) {
    throw new Error("path escapes Memory OS root");
  }
  if (resolved.includes(`${path.sep}.git${path.sep}`)) {
    throw new Error(".git is not readable through MCP");
  }
  const relNormalized = normalized.replaceAll("\\", "/");
  const restrictedReadPaths = [
    "proposals/accepted/",
    "proposals/rejected/",
  ];
  if (restrictedReadPaths.some((p) => relNormalized.startsWith(p))) {
    throw new Error(`${relNormalized} is not readable through MCP`);
  }
  return { relative: normalized, absolute: resolved };
}

function safePendingFilename(title) {
  const date = new Date().toISOString().slice(0, 10);
  const stem = String(title || "proposal")
    .trim()
    .toLowerCase()
    .replace(/[^\p{L}\p{N}]+/gu, "-")
    .replace(/^-+|-+$/g, "")
    .slice(0, 80) || "proposal";
  return `${date}-${stem}.md`;
}

async function fileExists(file) {
  try {
    await fs.access(file);
    return true;
  } catch {
    return false;
  }
}

const RESTRICTED_DIRS = new Set([".git", "node_modules", ".obsidian"]);

async function walk(dir, out = []) {
  const entries = await fs.readdir(dir, { withFileTypes: true });
  for (const entry of entries) {
    if (RESTRICTED_DIRS.has(entry.name)) continue;
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      await walk(full, out);
    } else {
      out.push(full);
    }
  }
  return out;
}

async function readTextFile(relativePath) {
  const { relative, absolute } = normalizeRelative(relativePath);
  const stat = await fs.stat(absolute);
  if (!stat.isFile()) throw new Error("target is not a file");
  if (stat.size > MAX_READ_BYTES) {
    throw new Error(`file exceeds read limit: ${stat.size} bytes`);
  }
  const text = await fs.readFile(absolute, "utf8");
  return { path: relative.replaceAll(path.sep, "/"), text };
}

async function memorySearch(args) {
  const query = String(args?.query || "").trim();
  const maxResults = Math.min(Number(args?.maxResults || 20), 50);
  if (!query) throw new Error("query is required");

  const files = await walk(ROOT);
  const allowedExt = new Set([".md", ".txt", ".toml", ".json", ".ps1"]);
  const lowerQuery = query.toLowerCase();
  const restrictedPrefixes = [
    `proposals${path.sep}accepted${path.sep}`,
    `proposals${path.sep}rejected${path.sep}`,
    `raw${path.sep}videos${path.sep}`,
    `raw${path.sep}sessions${path.sep}`,
  ];
  const matches = [];

  for (const file of files) {
    if (!allowedExt.has(path.extname(file).toLowerCase())) continue;
    const rel = path.relative(ROOT, file);
    if (restrictedPrefixes.some((p) => rel.startsWith(p))) continue;
    const stat = await fs.stat(file);
    if (stat.size > MAX_READ_BYTES) continue;
    const text = await fs.readFile(file, "utf8");
    const index = text.toLowerCase().indexOf(lowerQuery);
    if (index === -1) continue;
    const start = Math.max(0, index - 120);
    const end = Math.min(text.length, index + query.length + 180);
    matches.push({
      path: rel.replaceAll(path.sep, "/"),
      snippet: text.slice(start, end).replace(/\s+/g, " ").trim(),
    });
    if (matches.length >= maxResults) break;
  }

  return matches;
}

async function listPending() {
  await fs.mkdir(PENDING_DIR, { recursive: true });
  const entries = await fs.readdir(PENDING_DIR, { withFileTypes: true });
  const proposals = [];
  for (const entry of entries) {
    if (!entry.isFile() || !entry.name.endsWith(".md")) continue;
    const full = path.join(PENDING_DIR, entry.name);
    const stat = await fs.stat(full);
    proposals.push({
      name: entry.name,
      path: path.relative(ROOT, full).replaceAll(path.sep, "/"),
      updatedAt: stat.mtime.toISOString(),
      bytes: stat.size,
    });
  }
  proposals.sort((a, b) => b.updatedAt.localeCompare(a.updatedAt));
  return proposals;
}

async function createPendingProposal(args) {
  const title = String(args?.title || "").trim();
  if (!title) throw new Error("title is required");
  const summary = String(args?.summary || "").trim();
  const body = String(args?.body || "").trim();
  await fs.mkdir(PENDING_DIR, { recursive: true });

  let filename = safePendingFilename(title);
  let full = path.join(PENDING_DIR, filename);
  let counter = 2;
  while (await fileExists(full)) {
    filename = filename.replace(/(?:-\d+)?\.md$/, `-${counter}.md`);
    full = path.join(PENDING_DIR, filename);
    counter += 1;
  }

  const now = new Date().toISOString();
  const content = `---\ntitle: ${JSON.stringify(title)}\nstatus: pending\ncreated_at: ${now}\nsource: mcp\n---\n\n# Proposal: ${title}\n\n## Summary\n\n${summary || "TODO"}\n\n## Scope\n\n- Global / domain / stack / project-specific:\n- Applies to:\n- Does not apply to:\n\n## Proposed Destination\n\n- rules:\n- workflow:\n- domain:\n- stack:\n- skill:\n- router:\n- eval:\n\n## Rationale\n\n${body || "TODO"}\n\n## Risks\n\n- 是否过度泛化：\n- 是否包含敏感信息：\n- 是否与现有规则冲突：\n\n## Draft\n\nTODO\n`;
  await fs.writeFile(full, content, "utf8");
  return { path: path.relative(ROOT, full).replaceAll(path.sep, "/") };
}

async function appendPendingProposal(args) {
  const filename = String(args?.filename || "").trim();
  const note = String(args?.note || "").trim();
  if (!filename || !filename.endsWith(".md")) throw new Error("filename must be a pending .md file");
  if (!note) throw new Error("note is required");

  const full = path.resolve(PENDING_DIR, filename);
  const pendingResolved = path.resolve(PENDING_DIR);
  if (!full.toLowerCase().startsWith(pendingResolved.toLowerCase() + path.sep)) {
    throw new Error("path escapes pending directory");
  }
  if (!(await fileExists(full))) throw new Error("pending proposal not found");
  const stamp = new Date().toISOString();
  await fs.appendFile(full, `\n\n## MCP Update ${stamp}\n\n${note}\n`, "utf8");
  return { path: path.relative(ROOT, full).replaceAll(path.sep, "/") };
}

const tools = [
  {
    name: "memory_search",
    description: "Search AI Memory OS text files. Read-only.",
    inputSchema: {
      type: "object",
      properties: {
        query: { type: "string" },
        maxResults: { type: "number" },
      },
      required: ["query"],
    },
  },
  {
    name: "memory_read",
    description: "Read a file by relative path inside AI Memory OS. Read-only.",
    inputSchema: {
      type: "object",
      properties: {
        path: { type: "string" },
      },
      required: ["path"],
    },
  },
  {
    name: "list_pending_proposals",
    description: "List proposals/pending/*.md. Read-only.",
    inputSchema: { type: "object", properties: {} },
  },
  {
    name: "create_pending_proposal",
    description: "Create a new pending proposal. Writes only to proposals/pending.",
    inputSchema: {
      type: "object",
      properties: {
        title: { type: "string" },
        summary: { type: "string" },
        body: { type: "string" },
      },
      required: ["title"],
    },
  },
  {
    name: "append_pending_proposal",
    description: "Append a note to an existing pending proposal. Writes only to proposals/pending.",
    inputSchema: {
      type: "object",
      properties: {
        filename: { type: "string" },
        note: { type: "string" },
      },
      required: ["filename", "note"],
    },
  },
];

async function callTool(name, args) {
  if (name === "memory_search") return memorySearch(args);
  if (name === "memory_read") return readTextFile(args?.path);
  if (name === "list_pending_proposals") return listPending();
  if (name === "create_pending_proposal") return createPendingProposal(args);
  if (name === "append_pending_proposal") return appendPendingProposal(args);
  throw new Error(`unknown tool: ${name}`);
}

async function handle(message) {
  const { id, method, params } = message;
  try {
    if (method === "initialize") {
      return result(id, {
        protocolVersion: "2024-11-05",
        capabilities: { tools: {} },
        serverInfo: { name: "ai-memoryos", version: "0.1.0" },
      });
    }
    if (method === "notifications/initialized") return;
    if (method === "tools/list") return result(id, { tools });
    if (method === "tools/call") {
      const value = await callTool(params?.name, params?.arguments || {});
      return result(id, {
        content: [{ type: "text", text: JSON.stringify(value, null, 2) }],
        isError: false,
      });
    }
    if (id !== undefined) return error(id, -32601, `method not found: ${method}`);
  } catch (err) {
    if (id !== undefined) {
      return result(id, {
        content: [{ type: "text", text: err instanceof Error ? err.message : String(err) }],
        isError: true,
      });
    }
  }
}

const rl = readline.createInterface({ input: process.stdin });
rl.on("line", async (line) => {
  const trimmed = line.trim();
  if (!trimmed) return;
  try {
    await handle(JSON.parse(trimmed));
  } catch (err) {
    error(null, -32700, err instanceof Error ? err.message : String(err));
  }
});
