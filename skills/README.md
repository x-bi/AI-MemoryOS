# Skills

这里保存模型无关的 skill 规格，不等于 Codex 自动发现的 skills。

Codex 自动发现入口是：

- `C:\Users\btf\.agents\skills`
- 项目内 `.agents\skills`

当前只自动暴露 4 个 MVP skills：

- memory-curator
- routing-auditor
- bugfix-with-regression-test
- frontend-component-review

其他 skill 先作为候选规格保留，等真实任务验证后再通过 junction 或 plugin 暴露给 Codex。