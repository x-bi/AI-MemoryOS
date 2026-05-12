# Skills

这里保存模型无关的 skill 规格，不等于 Codex 自动发现的 skills。

Codex Desktop 自动发现入口是：

- `C:\Users\btf\.codex\skills`

MemoryOS 源目录是：

- `C:\Users\btf\AI-MemoryOS\adapters\codex\skills`

当前只映射 4 个 MVP skills：

- memory-curator
- routing-auditor
- bugfix-with-regression-test
- frontend-component-review

其他 skill 先作为候选规格保留，等真实任务验证后再通过 junction 映射到 Codex Desktop。
