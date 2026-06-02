---
title: "Frontend regression verification strategy"
status: accepted
created_at: 2026-05-13T05:55:10.553Z
accepted_at: 2026-05-13
source: mcp
source_episode: "conversation:2026-05-13"
---

# Accepted Proposal: Frontend regression verification strategy

## Proposal

Original pending proposal:

```text
proposals/pending/2026-05-13-frontend-verification-build-strategy.md
```

## Accepted At

2026-05-13

## Destination

- `workflows/frontend-regression-verification-strategy.md`
- `domains/frontend/README.md`
- `domains/testing/README.md`
- `logs/memory-changelog.md`

## Reason

该 proposal 来自前端代码修改后的自动回归验证自检：完整构建和其他验证命令可能产生大量日志、构建产物、缓存、报告、截图、代码生成结果、lockfile 或源码自动修复噪音，导致 `git status` / `git diff` 膨胀并增加审查成本。

该经验满足晋升条件：能减少明确的重复错误，改善前端 review / testing 的稳定性，并降低回归验证时误清理业务文件或误扩大构建范围的风险。

## Files Changed

- `workflows/frontend-regression-verification-strategy.md`：新增前端代码修改后回归验证分层策略。
- `domains/frontend/README.md`：增加 workflow 引用。
- `domains/testing/README.md`：增加 workflow 引用。
- `logs/memory-changelog.md`：记录本次晋升。

## Eval / Test Coverage

- 轻量验证：检查 proposal 内容、目标 workflow 和 domain 引用。
- 未新增 router / skill / eval，因为该规则不改变任务路由或技能触发边界。

## Accepted Rule

前端代码修改后的回归验证默认采用分层策略：先做 diff 和静态链路检查，只有改动触达入口、路由、配置、公共模块、平台条件分支、构建链路，或用户明确要求时，才执行对应范围的构建、测试或生成类验证。

执行可能产生副作用的命令前后，都要检查工作区状态并区分交付内容和临时产物。源码、lockfile、snapshot、generated 文件、API 类型文件是否保留，必须按项目约定或用户确认处理，不能自动清理。`git clean` 只能限定到确认过的构建、缓存、报告、覆盖率、截图、视频或测试产物目录，不能扩大为全仓清理。
