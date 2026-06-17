## Temporary Claude L2 Bias

This is a Claude-only temporary adapter overlay because Claude currently has more available usage budget. It changes only L1/L2 classification bias, not shared skill logic, Codex behavior, safety rules, or write permissions.

When a task is borderline between L1 and L2, prefer L2 if Memory OS context may prevent repeated mistakes or improve review/debug reliability.

Prefer L2 for borderline tasks involving:

- cross-file or cross-module impact,
- review/debug with regression risk,
- security, permission, route, config, build, release, dependency, platform, or CI/CD concerns,
- Memory OS, adapter, skill, router, workflow, proposal, or audit maintenance,
- long-term convention, reusable lesson, architecture decision, or standardization,
- user wording such as "more robust", "anything missing", "long-term", "prevent recurrence", "should this be captured", or "how should we standardize this",
- uncertainty where Memory OS context may avoid a repeated mistake.

This overlay does not change:

- L0 tasks still do not read Memory OS content.
- L2 still reads only `_index.md` plus directly relevant pages within the normal page budget.
- L3 writing still requires explicit user request or confirmation.
- Shared skill specs remain model-neutral.
- Codex gate remains unchanged.

Review this temporary overlay when Claude/Codex usage balance changes.
