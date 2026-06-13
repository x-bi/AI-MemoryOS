# Router Changelog 路由变更日志

## 2026-06-13

- 接受 proposal：`2026-06-13-反模式-diff-基线泛化识别-不要把-非默认-diff-基线-误判为非-diff-任务`。
- 扩展 `router/skill-map.md` 的 diff 类 skill 触发边界：新增功能全量、从零到现在、跨提交累计、分支差异、上线前整体变更等非默认基线 changeset 仍应触发 `pr-review`，前端文件范围命中时也应触发 `vue-change-self-check`。
- 明确无变更窗口的解释、通读、单点 debug 不因“review / 审查”措辞自动触发 diff 类 skill。

## 2026-06-11

- 新增 `workflows/skill-maintenance.md` 路由入口，用于新增、修改、同步和校验 Memory OS managed skill。
- 补充 router eval，覆盖 managed skill 维护的正向命中，以及 skill 维护类 pending proposal 仍优先走 `proposal-promotion.md` 的反向排除。
- 明确普通项目“技能”泛称、使用已有 skill、以及 `proposals/pending/*` 审查/晋升不触发 `skill-maintenance.md`。

## 2026-05-14

- 放宽 OS 触发机制：收窄 L0 为纯解释/纯问答/无改动无决策任务，放宽 L1 为默认倾向触发轻量 workflow / skill。
- L1 新增覆盖：普通 bugfix 后回归风险检查、功能实现后的风险扫描、排错结束后的经验判断、配置/脚本/接口字段/路由/权限/构建入口变更的轻量风险检查。
- 明确 L1 可组合多个 workflow / skill，但只读取完成任务所需的最小规则集；重型 skill 的详细规则按需读取。
- 新增 OS Trace Footer：最终回答末尾记录 L 级别、skills、workflow、读取和写入；不展示 token 估算，不为 trace 额外读取文件。
- 继续保持 L2 正文读取和 L3 pending 写入保守，避免扩大 token 消耗和污染长期记忆。
- 新增 `adapters/codex/gate.md` 作为 Codex 运行策略单一入口，统一维护回答风格、Memory OS Gate、验证策略和读写边界。
- 全局 `C:\Users\btf\.codex\AGENTS.md` 调整为 bootstrap：只负责引导读取 `gate.md`，不再维护完整 L0-L3 和验证策略。
- 将触发策略从简单/复杂两档调整为 L0-L3：
  - L0：普通 explain/debug/small implement，不触发 OS。
  - L1：轻量 workflow / skill，可适度多触发，但默认不读取 Memory OS。
  - L2：读取 `_index.md` + 最多 3 个相关页面。
  - L3：仅在用户明确要求或确认后写入 `proposals/pending/`。
- 新增轻量入口：diff review、提交前自检、任务后复盘提醒。
- 补充 `pr-review` 与轻量 workflow 的 router / skill trigger eval 样例。

## 2026-05-13

- 新增 Memory OS Gate：每个输入先做轻量边界判定，但判定本身不读取 Memory OS。
- 明确用户无需声明简单或复杂任务，Codex 根据任务范围、风险、跨模块程度和长期工程决策自动判断是否读取。
- 明确读取 Memory OS 不等于写入记忆；写入仍需用户明确要求或确认，并只进入 `proposals/pending/`。
- 补充 router / skill trigger eval，覆盖复杂任务自动读取、普通任务不读取、明确沉淀才触发写入类 skill。

## 2026-05-11

- 新增 `intent-map.md`：定义 explain / debug / implement / review / architecture / retrospective / maintenance。
- 新增 `domain-map.md`：定义 frontend / testing / backend / scripting / devops / security。
- 新增 `skill-map.md`：说明 active Codex skills 的触发边界。
- 新增初始 router eval 和 skill trigger eval 样例。

## 记录原则

- 只根据真实误判或真实高频需求更新 router。
- 不靠想象扩写大量路由规则。
- 每次 router 变更都应补 eval case。
