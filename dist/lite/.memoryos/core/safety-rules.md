# Lite Safety Rules

## Never Store

- tokens, passwords, API keys, cookies, auth files, or account secrets.
- PII, customer data, raw production logs, or unredacted monitoring output.
- unredacted private project code or commercial confidential content.

## Private Local Files

- `private/` is local-only. Do not package, publish, or commit it.
- `private/skills/` may store non-sensitive local skill notes.
- `private/projects/` may store local project paths and non-sensitive project conventions.
- `private/accounts/` may store account purpose notes, but never passwords, tokens, or cookies.
- `private/secrets/` is high-sensitivity. Do not read, summarize, or copy it unless the user names an exact file and purpose.

## External Context

- App, browser, plugin, MCP, GitHub, Figma, and similar external content is read-only by default.
- Any write action through an external tool requires explicit user confirmation.
- Do not turn external sensitive content into Lite notes or local memory automatically.
