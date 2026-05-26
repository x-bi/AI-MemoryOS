#!/usr/bin/env node

import fs from "node:fs/promises";
import path from "node:path";
import readline from "node:readline";

const ROOT = process.env.AI_MEMORYOS_ROOT || "C:\\Users\\btf\\AI-MemoryOS";
const MAX_READ_BYTES = Number(process.env.AI_MEMORYOS_MAX_READ_BYTES || 60000);
const PENDING_DIR = path.join(ROOT, "proposals", "pending");
const ROOT_REAL = await fs.realpath(ROOT);
const ALLOWED_SEARCH_EXTENSIONS = new Set([".md", ".txt", ".toml", ".json", ".ps1"]);
const ACTIVE_SEARCH_PATHS = [
  "README.md",
  "_index.md",
  "STATUS.md",
  "GOVERNANCE.md",
  "core",
  "router",
  "workflows",
  "domains",
  "stacks",
  "rules",
  "skills",
  "evals",
  "templates",
  "logs",
  "proposals/pending",
];
const HISTORY_SEARCH_PATHS = [
  "proposals/accepted",
  "proposals/rejected",
];
const SENSITIVE_PATTERNS = [
  { label: "private key block", pattern: /-----BEGIN [A-Z ]*PRIVATE KEY-----/i },
  { label: "authorization header", pattern: /\bauthorization\s*[:=]\s*bearer\s+[A-Za-z0-9._~+/=-]{16,}/i },
  { label: "cookie header", pattern: /\bcookie\s*[:=]\s*[^;\n]+=[^;\n]{16,}/i },
  { label: "dotenv secret", pattern: /(?:^|\n)\s*[A-Z0-9_]*(?:TOKEN|SECRET|PASSWORD|API[_-]?KEY|PRIVATE[_-]?KEY)[A-Z0-9_]*\s*=\s*["']?[^"'\s]{12,}/i },
  { label: "github token", pattern: /\bgh[pousr]_[A-Za-z0-9_]{30,}\b/i },
  { label: "openai api key", pattern: /\bsk-(?:proj-)?[A-Za-z0-9_-]{20,}\b/i },
  { label: "aws access key", pattern: /\bAKIA[0-9A-Z]{16}\b/ },
  { label: "long token-like value", pattern: /\b[A-Za-z0-9_./+=-]{80,}\b/ },
];

function send(message) {
  process.stdout.write(`${JSON.stringify(message)}\n`);
}

function result(id, value) {
  send({ jsonrpc: "2.0", id, result: value });
}

function error(id, code, message) {
  send({ jsonrpc: "2.0", id, error: { code, message } });
}

function pathInside(child, parent) {
  const childResolved = path.resolve(child).toLowerCase();
  const parentResolved = path.resolve(parent).toLowerCase();
  return childResolved === parentResolved || childResolved.startsWith(parentResolved + path.sep);
}

async function assertRealPathInside(absolute, realRoot, label) {
  const real = await fs.realpath(absolute);
  if (!pathInside(real, realRoot)) {
    throw new Error(`${label} escapes allowed directory`);
  }
  return real;
}

async function assertPendingTargetPath(absolute, options = {}) {
  const mustExist = Boolean(options.mustExist);
  await fs.mkdir(PENDING_DIR, { recursive: true });
  const pendingReal = await fs.realpath(PENDING_DIR);
  if (!pathInside(absolute, PENDING_DIR)) {
    throw new Error("path escapes pending directory");
  }
  if (mustExist) {
    return assertRealPathInside(absolute, pendingReal, "path");
  }
  const parentReal = await fs.realpath(path.dirname(absolute));
  if (!pathInside(parentReal, pendingReal)) {
    throw new Error("path escapes pending directory");
  }
  return path.join(parentReal, path.basename(absolute));
}

function assertNoSensitiveContent(text, label) {
  for (const entry of SENSITIVE_PATTERNS) {
    if (entry.pattern.test(text)) {
      throw new Error(`${label} appears to contain sensitive content: ${entry.label}`);
    }
  }
}

function normalizeRelative(input) {
  if (!input || typeof input !== "string") {
    throw new Error("path is required");
  }
  if (path.isAbsolute(input)) {
    throw new Error("absolute paths are not allowed");
  }
  const normalized = path.normalize(input);
  const relNormalized = normalized.replaceAll("\\", "/");
  if (relNormalized === ".git" || relNormalized.startsWith(".git/")) {
    throw new Error(".git is not readable through MCP");
  }
  if (relNormalized === "private" || relNormalized.startsWith("private/")) {
    throw new Error("private overlays are not readable through MCP");
  }
  const resolved = path.resolve(ROOT, normalized);
  const rootResolved = path.resolve(ROOT);
  if (!resolved.toLowerCase().startsWith(rootResolved.toLowerCase() + path.sep)) {
    throw new Error("path escapes Memory OS root");
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

const RESTRICTED_DIRS = new Set([".git", "node_modules", ".obsidian", "private"]);

async function walk(dir, out = []) {
  await assertRealPathInside(dir, ROOT_REAL, "search path");
  const entries = await fs.readdir(dir, { withFileTypes: true });
  for (const entry of entries) {
    if (RESTRICTED_DIRS.has(entry.name)) continue;
    const full = path.join(dir, entry.name);
    await assertRealPathInside(full, ROOT_REAL, "search path");
    if (entry.isDirectory()) {
      await walk(full, out);
    } else {
      out.push(full);
    }
  }
  return out;
}

function searchPathsForScope(scope) {
  if (scope === "active") return ACTIVE_SEARCH_PATHS;
  if (scope === "history") return HISTORY_SEARCH_PATHS;
  if (scope === "all") return [...ACTIVE_SEARCH_PATHS, ...HISTORY_SEARCH_PATHS];
  throw new Error("scope must be active, history, or all");
}

async function collectSearchFiles(relativePaths) {
  const files = [];
  const seen = new Set();
  for (const relativePath of relativePaths) {
    const full = path.resolve(ROOT, relativePath);
    if (!pathInside(full, ROOT)) continue;
    if (!(await fileExists(full))) continue;
    await assertRealPathInside(full, ROOT_REAL, "search path");
    const stat = await fs.stat(full);
    if (stat.isFile()) {
      if (!seen.has(full)) {
        seen.add(full);
        files.push(full);
      }
      continue;
    }
    if (!stat.isDirectory()) continue;
    const walked = await walk(full);
    for (const file of walked) {
      if (seen.has(file)) continue;
      seen.add(file);
      files.push(file);
    }
  }
  return files;
}

async function readTextFile(relativePath) {
  const { relative, absolute } = normalizeRelative(relativePath);
  await assertRealPathInside(absolute, ROOT_REAL, "path");
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
  const scope = String(args?.scope || "active").trim().toLowerCase();
  if (!query) throw new Error("query is required");

  const files = await collectSearchFiles(searchPathsForScope(scope));
  const lowerQuery = query.toLowerCase();
  const queryTerms = lowerQuery.split(/\s+/).filter(Boolean);
  const matches = [];

  for (const file of files) {
    if (!ALLOWED_SEARCH_EXTENSIONS.has(path.extname(file).toLowerCase())) continue;
    const rel = path.relative(ROOT, file);
    const stat = await fs.stat(file);
    if (stat.size > MAX_READ_BYTES) continue;
    const text = await fs.readFile(file, "utf8");
    const lowerText = text.toLowerCase();
    const lowerRel = rel.toLowerCase();
    const exactIndex = lowerText.indexOf(lowerQuery);
    let bestIndex = exactIndex;
    let score = exactIndex === -1 ? 0 : 50;
    const matchedTerms = [];
    for (const term of queryTerms) {
      const textIndex = lowerText.indexOf(term);
      const pathIndex = lowerRel.indexOf(term);
      if (textIndex === -1 && pathIndex === -1) continue;
      matchedTerms.push(term);
      score += pathIndex === -1 ? 10 : 18;
      if (textIndex !== -1 && (bestIndex === -1 || textIndex < bestIndex)) {
        bestIndex = textIndex;
      }
    }
    if (score === 0) continue;
    if (bestIndex === -1) bestIndex = 0;
    const start = Math.max(0, bestIndex - 120);
    const end = Math.min(text.length, bestIndex + Math.max(query.length, matchedTerms.join(" ").length) + 180);
    matches.push({
      path: rel.replaceAll(path.sep, "/"),
      snippet: text.slice(start, end).replace(/\s+/g, " ").trim(),
      score,
      matchedTerms,
    });
  }

  return matches
    .sort((a, b) => b.score - a.score || a.path.localeCompare(b.path))
    .slice(0, maxResults);
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
  assertNoSensitiveContent(`${title}\n${summary}\n${body}`, "proposal");
  await fs.mkdir(PENDING_DIR, { recursive: true });

  let filename = safePendingFilename(title);
  let full = path.join(PENDING_DIR, filename);
  let counter = 2;
  while (await fileExists(full)) {
    filename = filename.replace(/(?:-\d+)?\.md$/, `-${counter}.md`);
    full = path.join(PENDING_DIR, filename);
    counter += 1;
  }
  await assertPendingTargetPath(full);

  const now = new Date().toISOString();
  const content = `---\ntitle: ${JSON.stringify(title)}\nstatus: pending\ncreated_at: ${now}\nsource: mcp\n---\n\n# Proposal: ${title}\n\n## Summary\n\n${summary || "TODO"}\n\n## Scope\n\n- Global / domain / stack / project-specific:\n- Applies to:\n- Does not apply to:\n\n## Proposed Destination\n\n- rules:\n- workflow:\n- domain:\n- stack:\n- skill:\n- router:\n- eval:\n\n## Rationale\n\n${body || "TODO"}\n\n## Risks\n\n- 是否过度泛化：\n- 是否包含敏感信息：\n- 是否与现有规则冲突：\n\n## Draft\n\nTODO\n`;
  await fs.writeFile(full, content, "utf8");
  return { path: path.relative(ROOT, full).replaceAll(path.sep, "/") };
}

async function appendPendingProposal(args) {
  const filename = String(args?.filename || "").trim();
  const note = String(args?.note || "").trim();
  if (!filename || !filename.endsWith(".md")) throw new Error("filename must be a pending .md file");
  if (path.basename(filename) !== filename) throw new Error("filename must not include path separators");
  if (!note) throw new Error("note is required");
  assertNoSensitiveContent(`${filename}\n${note}`, "proposal update");

  const full = path.resolve(PENDING_DIR, filename);
  await assertPendingTargetPath(full, { mustExist: true });
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
        scope: {
          type: "string",
          enum: ["active", "history", "all"],
          description: "Search scope. Defaults to active; history explicitly searches accepted/rejected proposals.",
        },
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
