---
title: "L1 workflow/skill 候选信号应触发 router map 轻量探针"
status: pending
created_at: 2026-06-05T02:21:16.081Z
updated_at: 2026-06-05
source: mcp
---

# Proposal: L1 workflow/skill 候选信号应触发 router map 轻量探针

## Summary

补齐 gate 与 router map 之间的执行缝隙：当 L1/L2 任务出现明确 workflow 或 skill 候选信号时，不把具体规则塞进 gate，而是先轻量读取 `router/workflow-map.md` 或 `router/skill-map.md` 做探针；命中后只读取对应 workflow/skill，避免已有路由规则未被触发。

## Scope

- Global：影响两个 adapter gate + eval
- Applies to：`adapters/claude/CLAUDE.md`、`adapters/codex/gate.md` 的 L1/L2 执行路径；`evals/router-test-cases.md` 的回归验证
- Does not apply to：L0 任务；L3 写入规则

## Proposed Destination

- gate：`adapters/claude/CLAUDE.md` + `adapters/codex/gate.md` 同步新增 `## Workflow / Skill Probe` 小节
- eval：`evals/router-test-cases.md` 补充正反样例 + 信号分类评判参考
- 不修改：`router/workflow-map.md`、`router/skill-map.md`、`router/intent-map.md`、L0-L3 定义

## Rationale

# L1 workflow/skill 候选信号应触发 router map 轻量探针

## Context

一次 `D:\xiangmeifu\admin-vue` 原型读取任务中，用户输入为"读取 CoDesign 原型文档、解析黑名单标签页面、准备进行开发"。正式 `router/workflow-map.md` 已有"CoDesign / 原型 / 设计稿 / iframe + 后续开发 / 页面还原"触发 `workflows/frontend-prototype-driven-development.md` 的规则，但执行时先进入浏览器读取，没有先触发该 workflow。

这暴露的问题不是某一条 workflow 规则缺失，而是 gate 与 router map 之间存在执行缝隙：

- `gate.md` 说明 L1 可触发轻量 workflow / skill，但 L1 默认不读取 Memory OS 正文。
- `_index.md` 说明完整路由链是 gate -> intent -> domain -> workflow/skill map。
- 当任务明显带有 workflow/skill 候选信号时，如果模型没有主动读取 `workflow-map.md` / `skill-map.md`，就可能绕过正式路由事实。

不能把每个 workflow / skill 的触发条件复制进 gate。否则 gate 会变成第二套 router，造成重复维护、规则漂移和过度膨胀。更合理的修法是：gate 只补一条"候选信号触发 router map 轻量探针"的通用执行规则。

## Reusable Lesson

路由纠正：当 L1/L2 任务出现明确 workflow/skill 候选信号时，应先读取 `router/workflow-map.md` 和/或 `router/skill-map.md` 做轻量探针；命中后只读取对应 workflow/skill，不把具体 workflow/skill 触发表复制进 gate。

## Core Design: Gate 精简规则 + Map 做匹配 + Eval 做回归

三层分工：

| 层 | 职责 | 内容 |
|---|---|---|
| Gate | 判断"要不要读 map" | 精简规则 + 1-2 个 inline example |
| Map 文件 | 判断"命中哪条" | 每条已有 `Use When` / `Do Not Use When` |
| Eval | 判断"判对了没有" | 正反样例 + 信号分类评判参考 |

运行时判断流程：

1. Gate 精简规则 → 模型判断"这是候选信号吗？" → 是，读 map
2. Map 的 `Use When` / `Do Not Use When` → 模型判断"命中哪条？" → 读对应 workflow/skill
3. Eval 用完整正反样例做回归验证

Gate 不需要也不应该在运行时读取信号分类参考——精简规则足以让模型识别候选信号，模糊边界由 eval 覆盖而非靠更多规则文本消除。

## How To Judge Clear workflow/skill Candidate Signals

> 以下分类不放入 gate，作为 `evals/router-test-cases.md` 的评判参考和开发者理解辅助。

"明确候选信号"不应等同于单个关键词。推荐用"用户目标 + 任务对象 + 交付物/流程约束 + 反向排除"的组合判断。

### 1. 必须触发 router map 探针的信号

满足以下任一类，且没有被反向排除条件否定时，应读取对应 map 做探针。

#### A. 用户显式点名 workflow / skill / Memory OS 路由对象

- "为什么没有触发这个 workflow"
- "这个任务应该命中哪个 skill"
- "修正这个 route misclassification"
- "写进 pending proposal"
- "用 `$vue-change-self-check` 看一下"

→ 最高置信度。直接按点名对象读取相关 skill/workflow 或路由文件。如果是路由误判触发 `routing-auditor`；如果是写入/沉淀触发 `memory-curator`。

#### B. 用户目标动词本身对应稳定流程

- review / 审查 / 看下风险 / 检查 diff / 检查 staged / 提交前自检
- 修 bug 并防止复发 / 加回归测试 / 查根因
- 读取原型 / 设计稿 / iframe，并用于开发、还原页面、实现弹窗/表格/表单
- 复盘 / 沉淀 / 记住 / 更新 Memory OS / 生成 proposal
- Git 操作步骤咨询

→ 不直接凭动词选择最终 workflow/skill；先读 map 中相关候选条目，命中再读对应 workflow/skill。

#### C. 任务对象是已知路由对象

- `diff`、`PR`、`commit`、`staged changes`、`当前改动`
- `.vue`、`pages.json`、`manifest.json`、uni-app 页面或前端路由配置
- CoDesign / Lanhu / Figma / Axure / 原型 / 设计稿 / iframe
- Memory OS / gate / router / skill-map / workflow-map / proposal / pending
- CodeGraph / 项目图 / 调用链 / 影响面 / 架构定位

→ 对象信号必须结合用户目标判断。"解释这个 diff"可能只是 explain；"review 这个 diff 风险"则应触发探针。

#### D. 用户要求的输出形态明显是 workflow/skill 产物

- 编号风险清单
- 提交前检查结论
- 回归验证路径
- 四要素原型读取清单
- pending proposal / router correction proposal

→ 输出形态说明用户要的不只是答案，而是某个稳定流程的产物。

#### E. 任务包含安全、写入、权限或长期规则边界

- 写入 Memory OS
- 修改 gate / router / skill / workflow
- 处理权限、沙箱、发布、CI/CD、长期规范
- 可能影响多个 adapter 的规则同步

→ 通常至少 L2，先读 `_index.md` 再读相关 router/map/workflow/skill。

### 2. 可选触发探针的中置信度信号

- 用户只说"帮我看看这里有没有问题"，但没有给 diff、组件、页面、交互或风险目标
- 小功能实现，未出现原型、review、自检、防回归、Memory OS、Git 等稳定流程对象
- "这个报错什么意思"，但没有要求修复、防复发或加测试

→ 先按 L0/L1 普通任务处理；如果过程中发现任务实际需要稳定流程，再补读 map。

### 3. 不应触发探针的反向排除

- 纯解释：解释概念/字段/报错，无修改、无流程要求
- 单点 debug：只定位一个问题，没有防回归/测试/长期沉淀要求
- 小实现：局部小改动，未涉及跨模块、原型还原、review、自检、权限、安全、发布或长期规则
- 用户明确跳过某流程："不要跑 review，只告诉我这个字段怎么传"
- 任务对象只是背景：链接里有 `design` 字样，但用户只是问登录方式或页面能否打开

## Example Eval Cases

> 建议补充到 `evals/router-test-cases.md`。

| Input | Expected |
|---|---|
| 读取 CoDesign 原型，准备开发这个页面 | 读 `router/workflow-map.md`，命中 `frontend-prototype-driven-development.md` |
| 打开这个 CoDesign 链接看看能不能访问 | 可只用浏览器读取；没有开发/还原目标时不强制命中原型开发 workflow |
| review 当前 staged diff | 读 `router/skill-map.md` / workflow map，命中 review/self-check 相关 skill/workflow |
| 解释这个接口字段是什么意思 | L0/L1 explain，不读 map |
| 修这个 bug，并加一个防回归测试 | 读 `router/skill-map.md`，命中 `bugfix-with-regression-test` |
| 为什么没有触发这个 workflow，修正路由 | 命中 `routing-auditor` |
| 把这次经验写进 pending proposal | 命中 `memory-curator`，只写 `proposals/pending/` |
| Git reset 和 revert 该用哪个 | 命中 `git-ops-guide`，只给命令指导，不执行 git |
| 帮我实现一个按钮颜色调整 | 普通小实现，不因 implement 泛化触发 workflow map |

## Safety And Sensitivity Check

- 不包含 token、cookie、账号、客户数据、生产日志、未脱敏私有代码或其他敏感信息。
- 本 proposal 只写入 pending，不直接修改正式 gate、router、skill、workflow 或 eval。
- 读取范围最小：只有存在明确候选信号时读 map；map 命中后只读命中项。
- 通过反向排除避免把所有普通 explain/debug/implement 都升级为 Memory OS 正文读取。

## Source Task Or Evidence Summary

- 真实误判：CoDesign 原型 + 准备开发本应触发前端原型驱动 workflow，但执行时先进入普通浏览器读取。
- 正式事实：`_index.md` 已定义 gate -> intent -> domain -> workflow/skill map 的路由链；`router/workflow-map.md` 和 `router/skill-map.md` 已分别保存 workflow/skill 触发边界。
- 已有相邻 pending：`2026-06-04-补齐-workflow-map-的通用-workflow-触发边界.md` 解决"workflow-map 里有哪些 workflow 条目"；本 proposal 解决"什么时候必须读取 map 做探针"。两者不重复。

## Landing Plan

1. 审核本 proposal 的精简 gate 规则文本（Draft 部分）。
2. 在 Codex / Claude gate 同步新增 `## Workflow / Skill Probe` 小节。
3. 补充 `evals/router-test-cases.md` 正反样例 + 信号分类评判参考。
4. 运行 `tools/validate-memory-os.ps1`。

## Risks

- **L1 读取边界扩展**：本 proposal 实质上扩展了 L1 的读取边界——从"不读 Memory OS 正文"变为"存在明确候选信号时可读 map 文件做探针"。这是最小扩展，但仍是 L1 定义的改变，需要在 gate 中明确标注。
- **信号判断模糊**：精简规则依赖模型对"候选信号"的理解，可能存在边界模糊。通过 eval 正反样例和信号分类参考做回归覆盖，而非靠加厚 gate 规则解决。
- **过度探针**：如果模型对候选信号判断过宽，可能对普通 explain/debug/implement 任务也读 map，增加不必要读取。通过反向排除 + eval 验证控制。
- **与现有规则冲突**：无。不修改 L0-L3 定义，不修改 map 文件，不修改 intent-map。仅在 gate 新增一条执行规则。

## Draft

以下文本同步插入 `adapters/claude/CLAUDE.md` 和 `adapters/codex/gate.md`，位于 L1/L2 规则之后：

```md
## Workflow / Skill Probe

L1/L2 任务中，如果用户输入出现明确 workflow 或 skill 候选信号，执行前先读取最小 router map：workflow 候选读 `router/workflow-map.md`，skill 候选读 `router/skill-map.md`。明确候选信号不是单个关键词，而是用户目标、任务对象、期望输出形态或安全/写入边界的稳定组合，且未被反向条件排除。例如："读取原型准备开发"（目标+对象）应触发 map 探针，而"打开链接看看能不能访问"（无开发目标）不需要。map 命中后只读取命中的 workflow/skill；map 未命中时按本地/项目上下文处理，并仅在真实误判出现时建议 router correction。
```
