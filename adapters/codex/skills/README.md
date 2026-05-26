# Active Codex Skills

这些目录是 MemoryOS active Codex skills 的源目录。

这些 `SKILL.md` 由 `skills/registry.json` 和 `skills/<skill>/SKILL_SPEC.md` 生成。修改 active skill 核心逻辑时，先改共享 spec，再运行 `tools/sync-skills.ps1`；不要手写两份 Codex / Claude 外壳。

Codex Desktop 实际读取：

```text
C:\Users\btf\.codex\skills
```

映射方式：

```text
New-Item -ItemType Junction -Path C:\Users\btf\.codex\skills\<skill> -Target C:\Users\btf\AI-MemoryOS\adapters\codex\skills\<skill>
```

`SKILL.md` 必须是 UTF-8 no BOM，让文件第一个字节就是 `---`。

- `memory-curator`
- `routing-auditor`
- `bugfix-with-regression-test`
- `frontend-component-review`
- `git-ops-guide`
- `pr-review`
- `vue-change-self-check`

不要把所有候选 skill 都映射给 Codex。skills 过多会增加初始上下文和误触发风险。
