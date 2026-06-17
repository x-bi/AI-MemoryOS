## Codex L1 Tendency

This is a Codex-only temporary adapter overlay. The current priority is expanding real task coverage: L1 defaults to triggered; L2 content reads and L3 writes remain conservative.

This overlay does not change:

- L0 tasks still do not read Memory OS content.
- L2 still reads only `_index.md` plus directly relevant pages within the normal page budget.
- L3 writing still requires explicit user request or confirmation.
- Shared skill specs remain model-neutral.
- Claude gate remains unchanged.

Codex Desktop discovers skills from `C:\Users\btf\.codex\skills`; active skills are junction-mapped. Do not assume external repo skills are auto-discovered.

Review this overlay when task coverage or model balance changes.
