---
title: "前端原型驱动开发：四要素完整读取流程"
status: accepted
created_at: 2026-06-04T07:48:53.711Z
accepted_at: 2026-06-04
source: mcp
source_episode: "conversation:2026-06-04-admin-vue-product-blocking-prototype"
decision_reason: "该 proposal 能防止前端原型读取只保留字段和文案、遗漏结构性视觉布局约束，降低按原型开发时的返工风险。"
---

# Accepted Proposal: 前端原型驱动开发：四要素完整读取流程

## Proposal

Original pending proposal:

```text
proposals/pending/2026-06-04-frontend-prototype-reading-must-include-visual-layout-constraints.md
```

## Accepted At

2026-06-04

## Destination

- `workflows/frontend-prototype-driven-development.md`
- `domains/frontend/README.md`
- `logs/memory-changelog.md`

## Reason

该 proposal 来自一次 `D:\xiangmeifu\admin-vue` 的商品屏蔽页面开发。用户要求读取 CoDesign iframe 原型并以两个 tab 原型为基准开发，但实现时只充分使用了字段、文案和业务规则，没有把抽屉弹窗的单行表单、控件宽度、表格缩进、按钮位置等视觉布局作为硬约束，导致页面先按项目常见两列表单习惯落地。

该经验满足晋升条件：能减少明确的前端原型还原返工，改善原型驱动开发的读取完整性，并把“结构性视觉布局约束，不是像素级复刻”固定为可执行 workflow。

## Files Changed

- `workflows/frontend-prototype-driven-development.md`：新增前端原型驱动开发四要素读取流程。
- `domains/frontend/README.md`：增加 workflow 引用。
- `logs/memory-changelog.md`：记录本次晋升。

## Eval / Test Coverage

- 轻量验证：检查 accepted proposal、目标 workflow、frontend domain 引用和 changelog。
- 未新增 router / skill / eval，因为该规则不改变 skill 触发边界；它作为前端领域 workflow，在用户要求按原型开发或还原页面时使用。

## Accepted Rule

从 CoDesign、Lanhu、Figma、Axure 或其他浏览器原型实现前端页面时，原型读取必须同时覆盖字段/数据、交互/状态、API 边界和视觉布局约束。视觉布局按结构性意图实现：单行/两列、label 对齐和宽度、控件相对宽度、表格缩进、按钮位置、面板/抽屉/弹窗结构、滚动区域、tab 状态差异等；无需追求像素级精度。

打开浏览器前，先检查是否已有符合该规则的独立 browser profile、remote debugging port 或目标 tab 可用；能连接并确认 title / url 匹配时复用已有窗口，避免重复打开浏览器或重复登录。

如果原型已经明确布局意图，不要用通用项目模式覆盖它。只有原型没有说明的地方，才用项目现有风格补齐。开发完成后，先按原型四要素清单做对照，再做类型检查、构建或其他验证；不能只用 DOM 文本存在、接口字段齐全或编译通过作为完成标准。
