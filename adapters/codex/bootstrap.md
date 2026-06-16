# Codex MemoryOS Bootstrap

Full gate:

```text
C:\Users\btf\AI-MemoryOS\adapters\codex\gate.md
```

Every user input should read this bootstrap first. This file only decides whether the full gate must be read; it is not the full operating policy.

Read the full gate when:

- this is the first user input in a new thread;
- the loaded full-gate state is unknown or cannot be confirmed from current context;
- the user discusses or asks to modify gate, AGENTS, adapter policy, router, workflow, skill, or Memory OS operating rules;
- the task involves Memory OS maintenance, proposals, pending or accepted proposals, long-term conventions, write boundaries, safety boundaries, git operation boundaries, CodeGraph, cross-adapter sync, or adapter sync;
- the previous response missed or malformed the Final Trace footer;
- the previous turn's actual read behavior clearly did not match its declared Memory OS level;
- context was compacted, the thread was resumed, or five consecutive turns have passed without refreshing the full gate and the current turn is not clearly pure L0.

Reading the full gate only loads Codex operating policy. It is not the same as reading Memory OS content.

The full gate is the source of truth for all operating rules. If this bootstrap and the full gate conflict, follow the full gate.
