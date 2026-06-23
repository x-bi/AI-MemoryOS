# Lite Intent Map

## task_type

- explain: explain a concept, code path, error, command, or tradeoff.
- debug: investigate a problem, locate likely cause, or give a repair path.
- implement: modify code, config, docs, scripts, or generated artifacts.
- review: inspect a diff, commit, current changes, feature slice, or implementation risk.
- architecture: choose an approach, design a refactor, reason about cross-module boundaries, or compare system options.
- retrospective: identify reusable lessons or local notes only when the user asks.
- lite-maintenance: install, uninstall, validate, update, or repair the Lite package, adapter entry, router, workflow, skill, hook, or junction.

## Notes

- L0-L3 definitions live in the adapter gate.
- Judge by user goal, task object, expected output, and write/safety boundary rather than a single keyword.
- Ask one key question only when missing context would make the action unsafe or materially wrong.
- Do not route ordinary application code "routes" into Lite router maintenance.
