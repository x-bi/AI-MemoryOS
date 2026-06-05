---
title: "补充 workflow-map 以触发前端原型驱动开发流程"
status: accepted
created_at: 2026-06-04T10:13:34.584Z
accepted_at: 2026-06-04
source: mcp
source_episode: "conversation:2026-06-04-admin-vue-product-blocking-prototype"
decision_reason: "该 proposal 能降低读取 CoDesign / Lanhu / Figma / Axure 等原型并用于后续开发时的 workflow 路由误判，避免只触发浏览器读取而漏读前端原型驱动开发流程。"
---

# Accepted Proposal: 补充 workflow-map 以触发前端原型驱动开发流程

## Proposal

Original pending proposal:

```text
proposals/pending/2026-06-04-补充-workflow-map-以触发前端原型驱动开发流程.md
```

## Accepted At

2026-06-04

## Destination

- `router/workflow-map.md`
- `_index.md`
- `domains/frontend/README.md`
- `logs/memory-changelog.md`

## Reason

该 proposal 来自一次 `admin-vue` 前端原型读取任务。用户要求读取 CoDesign 原型并为后续开发做基础，但处理时先进入浏览器读取流程，没有先触发 `workflows/frontend-prototype-driven-development.md`，暴露出 workflow 已有 Trigger、上层 router 却没有 workflow 触发入口的问题。

该经验满足晋升条件：能减少明确的路由误判，改善前端原型驱动开发的触发稳定性，并把“原型/设计稿/iframe + 后续开发/页面还原”固定为可执行的 workflow 路由信号。

## Files Changed

- `router/workflow-map.md`：新增 workflow 触发边界表，加入前端原型驱动开发流程的正反触发条件。
- `_index.md`：Routing 第 4 步新增 `router/workflow-map.md` 入口，并在 Core Files 中登记该 router 文件。
- `domains/frontend/README.md`：补充前端原型读取类任务应先读取 `workflows/frontend-prototype-driven-development.md` 的领域入口提示。
- `logs/memory-changelog.md`：记录本次晋升。

## Eval / Test Coverage

- 轻量验证：`tools/validate-memory-os.ps1` 通过。
- 正向路由样例：`读取 CoDesign 原型，为后续开发做基础` 应触发 `workflows/frontend-prototype-driven-development.md`。
- 反向路由样例：`解释这个接口字段是什么意思` 不应触发该 workflow。

## Accepted Rule

当用户要求读取 CoDesign / Lanhu / Figma / Axure 等原型、设计稿或浏览器内嵌 iframe，并以后续开发、页面实现、页面还原、弹窗/表单/表格开发为目标时，先读取 `workflows/frontend-prototype-driven-development.md`，再进入浏览器读取或代码实现。

该触发必须同时满足“原型/设计稿/iframe”和“后续开发/还原目标”两个条件；只解释字段含义、纯接口联调、纯代码 bugfix，且用户没有要求按原型还原页面时，不触发该 workflow。
