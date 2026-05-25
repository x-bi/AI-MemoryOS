# Skills

这里保存模型无关的 skill 规格，不等于 Codex 自动发现的 skills。

Codex Desktop 自动发现入口是：

- `C:\Users\btf\.codex\skills`

MemoryOS 源目录是：

- `C:\Users\btf\AI-MemoryOS\adapters\codex\skills`

当前只映射 active skills：

- memory-curator
- routing-auditor
- bugfix-with-regression-test
- frontend-component-review
- pr-review
- vue-change-self-check

其他 skill 先作为候选规格保留，等真实任务验证后再通过 junction 映射到 Codex Desktop。

## Claude Code Skills

Claude Code uses a separate adapter-specific skill source:

- `C:\Users\btf\AI-MemoryOS\adapters\claude\skills`

Claude Code discovers active skills from:

- `C:\Users\btf\.claude\skills`

The Claude discovery directory uses junctions to the repository source, just like Codex, but the files are not shared with Codex. Keep Claude and Codex skill files separate because their tool boundaries, trigger wording, and operating constraints differ.

Current active Claude skills:

- memory-curator
- routing-auditor
- bugfix-with-regression-test
- frontend-component-review
- pr-review
- vue-change-self-check
- git-ops-guide
