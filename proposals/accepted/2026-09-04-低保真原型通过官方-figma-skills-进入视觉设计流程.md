---
title: "低保真原型通过官方 Figma Skills 进入视觉设计流程"
status: accepted
created_at: 2026-09-04
accepted_at: 2026-09-04
source: conversation
source_episode: "conversation:2026-09-04"
decision_reason: "区分正式设计稿还原与低保真原型视觉设计，复用官方 Figma Skills 并由 Memory OS 负责编排，可避免直接照搬粗糙原型或维护官方 Skill 副本。"
---

# Accepted Proposal: 低保真原型通过官方 Figma Skills 进入视觉设计流程

## Proposal

Original pending proposal:

```text
proposals/pending/2026-09-04-低保真原型通过官方-figma-skills-进入视觉设计流程.md
```

## Accepted At

2026-09-04

## Destination

- `workflows/frontend-prototype-to-figma-design.md`
- `router/workflow-map.md`
- `evals/router-test-cases.md`
- `adapters/codex/external-config.md`
- `adapters/claude/external-config.md`
- `logs/router-changelog.md`
- `logs/memory-changelog.md`

## Context

现有 `frontend-prototype-driven-development` workflow 面向已有正式设计稿或具有明确视觉布局约束的原型，强调按原型结构和视觉意图实现。实际开发还存在另一类任务：用户只有功能原型、线框图或低保真页面，明确不把原型样式作为最终 UI，希望先借助 Figma 官方 MCP Skills 形成高保真设计，再进入前端实现。

## Reusable lesson

“已有正式设计稿的页面还原”和“只有低保真原型的视觉设计”必须分开路由。前者以原型视觉为约束，后者只继承功能、信息架构和交互事实，并通过官方 Figma Skills 完成设计系统、页面生成、视觉验证和人工确认。

Figma 官方 Skills 应继续由 Figma/Codex 或 Figma/Claude 的官方安装机制管理；Memory OS 只编排它们，不复制、修改或注册官方 Skill 正文。

## Proposed Memory OS change

1. 新增 `workflows/frontend-prototype-to-figma-design.md`，编排以下官方能力：
   - 无目标文件时：`figma-create-new-file`。
   - 需要设计基础时：`figma-generate-library` + `figma-use`。
   - 生成或调整页面时：`figma-generate-design` + `figma-use`。
   - 视觉稿确认后：`figma-design-to-code`。
2. 更新 `router/workflow-map.md`：新增“低保真/功能原型 + 无正式 UI + 先设计/提升审美”的专用路由，并收窄原有原型开发行，避免抢占。
3. 更新 `evals/router-test-cases.md` 和 `logs/router-changelog.md`，覆盖正向和反向路由。
4. 在 Codex、Claude 的 `external-config.md` 中分别记录官方 Figma MCP/Skills 的恢复方式；不保存 OAuth、token、插件缓存版本路径。
5. 写入 `logs/memory-changelog.md`，记录外部恢复语义变化。

## Safety and sensitivity check

- 不保存 OAuth token、Cookie、账号数据或 Figma 私有文件内容。
- 不复制官方 Skills 到 Memory OS managed skill registry。
- 不写死插件缓存版本目录。
- Figma MCP 或官方 Skills 不可用时停止在设计准备阶段，不声称已生成设计。

## Source task or evidence summary

用户明确说明只有原型、没有对应 UI，希望使用 Figma MCP 提升视觉设计质量，并确认将官方 Skills 作为执行能力，由 Memory OS 提供可复用流程编排。
