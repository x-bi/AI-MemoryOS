# Active Codex Skills

这些目录是 MemoryOS active Codex skills 的源目录。

Codex Desktop 实际读取：

```text
C:\Users\btf\.codex\skills
```

同步方式：

```text
tools\sync-codex-skills.ps1
ai_memoryos MCP 启动时自动同步
```

目标目录使用真实副本，不再依赖 junction。

- `memory-curator`
- `routing-auditor`
- `bugfix-with-regression-test`
- `frontend-component-review`

不要把所有候选 skill 都同步给 Codex。skills 过多会增加初始上下文和误触发风险。
