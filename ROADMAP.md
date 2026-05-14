# Roadmap 路线图

## 7 天 MVP

- Day 1：建立独立仓库、全局 AGENTS 接入、Codex skills junction 映射。
- Day 2：补齐 core / router / workflows / frontend / proposals / evals。
- Day 3：完善前端 rules、review checklist、common failures、testing、performance。
- Day 4：扩充 router-test-cases 和 skill-trigger-test-cases。
- Day 5：在真实前端项目试跑复杂任务和 bugfix 任务。
- Day 6：选 2~3 个已完成任务做 retrospective，只写 pending proposals。
- Day 7：第一次 audit，合并重复项，调整 skill description 和 router。

## 当前已完成的 MVP 基线

- 独立仓库已推送到个人 GitHub。
- Codex active skills 已通过 junction 映射到 `.codex\skills`。
- Obsidian dashboard、QuickAdd、Templater、Dataview、Git 已配置。
- MCP adapter 已接入全局 Codex config。
- 验证脚本已通过。
- `pr-review` 已从 workflow 封装为 active Codex skill。
- 已新增轻量 workflow 入口，用于在真实任务中收集 review、自检和复盘样例。

## 当前阶段重点

- 轻量 workflow 可以适度多触发，用于扩大真实案例输入。
- Memory OS 正文读取仍限定在 L2 场景。
- 写入仍限定为用户明确要求或确认后的 pending proposal。
- 优先补真实 eval case 和 proposal 晋升样例，再扩展更多重型 skills。

## 30 天

- 纳入 testing 域和 Playwright / Vitest stack 页面。
- 建立第一次 accepted proposal 流程。
- 每周一次 memory audit。
- 路由纠正案例累计到 10~20 条。
- 让 prompts 与 skills 开始互相引用。

## 90 天

- 加入 scripting / backend 基础包。
- 评估 private / team / public 分层。
- 建 monthly review。
- 把高频路由误判提升为正式 router 规则。
- 对 stale memories 做归档。
