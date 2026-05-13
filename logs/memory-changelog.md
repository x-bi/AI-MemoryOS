# Memory Changelog 记忆变更日志

## 2026-05-13

- 增加 Memory OS Gate 读取边界：每个用户输入先做轻量判定，但判定本身不读取 Memory OS。
- 将“用户明确声明复杂任务才读取”调整为“Codex 自动判断是否需要长期工程记忆参与”。
- 保留写入边界：读取 Memory OS 不等于写入记忆，写入仍需用户明确要求或确认，并只写 `proposals/pending/`。

## 2026-05-12

- 接受 proposal：`2026-05-12-set-default-memoryos-read-budget-for-complex-tasks`。
- 将普通复杂任务的 MemoryOS 默认读取预算设为不超过 2k tokens。
- 在 `_index.md` 和 `core/memory-rules.md` 中写入读取预算边界。
- 明确 2k 预算只统计 MemoryOS 自身读取内容，不包含业务项目代码、diff、报错日志、接口文档、终端输出、当前对话或 Codex 系统上下文。
- 维护、weekly audit、proposal 晋升、skill 晋升等任务可临时放宽到 5k-8k tokens，但需要说明读取范围。

## 2026-05-11

- 创建 AI Memory OS 仓库。
- 增加低消耗读取策略：普通任务默认不读取 Memory OS。
- 建立 proposal-first 治理机制：新经验默认只写入 `proposals/pending/`。
- 建立 core / router / workflow / domain 基础骨架。
- 增加 frontend MVP 领域包和跨模型 adapters。

## 记录格式建议

```text
日期：
来源 proposal：
变更目标：rules / router / skills / evals / wiki
变更原因：
验证方式：
风险：
```
