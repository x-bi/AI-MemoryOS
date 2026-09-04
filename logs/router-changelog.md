# Router Changelog 路由变更日志

## 2026-09-04

- 随后停用 `frontend-prototype-to-figma-design.md`：从 `router/workflow-map.md` 移除低保真原型到 Figma 的默认路由，保留 workflow 文件仅供历史追溯和显式恢复。
- 更新路由 eval：低保真原型要求提升审美时不再自动调用 Figma；用户显式指定 Figma 也不自动恢复默认 workflow。
- 接受 proposal：`2026-09-04-低保真原型通过官方-figma-skills-进入视觉设计流程`。
- 新增 `frontend-prototype-to-figma-design.md` 路由入口：低保真/功能原型且没有正式 UI、用户要求先提升审美或生成高保真 Figma 时，先编排官方 Figma Skills 完成设计和人工确认，再进入开发。
- 收窄 `frontend-prototype-driven-development.md` 的路由边界：已有正式设计稿、具有视觉约束或用户明确直接开发时继续命中；低保真先设计场景不再被通用原型开发行抢占。
- 补充正反 eval：覆盖低保真先设计、官方 Skills 外部托管、正式 Figma 稿直接实现、保留原型样式直接开发四类边界。

## 2026-06-17

- 接受 proposal：`2026-06-17-路由纠正-正式规则文件改动应由-ai-自动按-companion-映射同步关联文件`。
- 新增 Write Companions 路由/写入回归样例：覆盖 router map 改动、skill source 改动、MCP policy 改动、两端 gate 同步、`logs/README.md` 日志规则说明、普通业务代码不触发、pending 草稿不晋升不触发、用户要求暂不同步时仍需列出未完成 companion。
- 影响：正式规则写入路径新增执行前读取 `core/change-companions.md` 的判定样例，防止 router/eval/changelog 配套关系再次只依赖用户追问。

## 2026-06-13

- 接受 proposal：`2026-06-13-审查类前端任务跳过-router-map-探针的执行漂移补丁`。
- 扩展 `router/workflow-map.md` 的 review workflow 触发边界：新增功能全量、从零到现在、跨提交累计、分支差异、上线前整体变更等非默认基线 changeset 也应命中 `workflows/diff-review-lite.md`。
- 明确前端文件范围命中时，review workflow 后应继续读取 `router/skill-map.md` 判定 `vue-change-self-check` / `frontend-component-review`，避免通用 review 输出形态抢占前端四段式自检。
- 补充 router eval，覆盖审查新增前端目录、staged `.vue` 风险检查、以及纯解释 `watch` 不触发 skill probe。
- 接受 proposal：`2026-06-13-反模式-diff-基线泛化识别-不要把-非默认-diff-基线-误判为非-diff-任务`。
- 扩展 `router/skill-map.md` 的 diff 类 skill 触发边界：新增功能全量、从零到现在、跨提交累计、分支差异、上线前整体变更等非默认基线 changeset 仍应触发 `pr-review`，前端文件范围命中时也应触发 `vue-change-self-check`。
- 明确无变更窗口的解释、通读、单点 debug 不因“review / 审查”措辞自动触发 diff 类 skill。

## 2026-06-11

- 新增 `workflows/skill-maintenance.md` 路由入口，用于新增、修改、同步和校验 Memory OS managed skill。
- 补充 router eval，覆盖 managed skill 维护的正向命中，以及 skill 维护类 pending proposal 仍优先走 `proposal-promotion.md` 的反向排除。
- 明确普通项目“技能”泛称、使用已有 skill、以及 `proposals/pending/*` 审查/晋升不触发 `skill-maintenance.md`。

## 2026-06-05 (回填 2026-06-16)

- 接受 proposal：`2026-06-05-l1-workflow-skill-候选信号应触发-router-map-轻量探针`。
- 在 `adapters/claude/CLAUDE.md` 与 `adapters/codex/gate.md` 同步新增 `## Workflow / Skill Probe` 段，明确 L1/L2 出现明确 workflow/skill 候选信号时应先轻量读 `router/workflow-map.md` / `router/skill-map.md` 做探针。
- 在 L1 描述里加例外句：候选信号出现时按 Workflow / Skill Probe 规则读 map，但仍不读取 Memory OS 正文。
- 在 `evals/router-test-cases.md` 新增 `## Workflow / Skill Probe Cases` 子表与 `## Signal Classification Reference`，覆盖原型读取/纯访问、Git 命令咨询、proposal 写入等正反样例。
- 不修改 `router/intent-map.md` / `router/workflow-map.md` / `router/skill-map.md` 内容；只在 gate 层补一条通用执行规则。
- 影响：L1 读取边界从“不读 Memory OS 正文”扩展为“候选信号下可读 map 文件做探针”；这是 gate 与 router map 的执行衔接，不是 L0-L3 定义本身的变更。
- 验证：手工执行 `tools/validate-memory-os.ps1`；在原型读取与 review 任务上 Probe Cases 通过。

## 2026-06-04 (回填 2026-06-16)

- 接受 proposal：`2026-06-04-补充-workflow-map-以触发前端原型驱动开发流程`。
- 新建 `router/workflow-map.md` 文件作为 workflow 触发边界索引，初始包含一行：CoDesign / Lanhu / Figma / Axure / 原型 / 设计稿 / iframe + 后续开发 / 页面还原 → `workflows/frontend-prototype-driven-development.md`。
- 在 `_index.md` Routing 第 4 步登记 `router/workflow-map.md` 作为 workflow 触发边界入口；`domains/frontend/README.md` 补充原型读取类任务先读 workflow 的提示。
- 来源：`admin-vue` CoDesign 原型读取任务直接进入浏览器读取，未先触发前端原型驱动 workflow。
- 接受 proposal：`2026-06-04-补齐-workflow-map-的通用-workflow-触发边界`。
- 补齐 `router/workflow-map.md` 的通用 workflow 行：CodeGraph / diff-review-lite / frontend-regression-verification / memory-retrospective / pre-commit-self-check / proposal-promotion / weekly-audit / retrospective-lite / refactor-with-safety / script-automation / test-strategy 共 11 行，每行都带 `Use When` 与 `Do Not Use When`。
- 显式排除：`workflows/feature-development.md` 不进入 workflow-map，避免泛化默认实现步骤稀释路由价值。
- 影响：让已具备稳定 Trigger 的 workflow 都有上层路由入口；通过反向排除条件防止 review/refactor/script/test 等泛化触发。

## 2026-05-26 (回填 2026-06-16)

- 接受 proposal：`2026-05-26-修正-vue-uni-app-改动检查未触发-vue-change-self-check`。
- 扩展 `router/skill-map.md` 的 `vue-change-self-check` 触发边界：用户要求检查改动 / 未提交改动 / staged / commit / diff，且仓库或轻量 diff 命中 `.vue` / `pages.json` / `manifest.json` / 前端路由/页面/导航配置 / uni-app 分包页面时也应触发；可与 `pr-review` 并行触发。
- 在 `router/skill-map.md` Notes 中加“`pr-review` 与 `vue-change-self-check` 同时命中时输出优先采用 vue-change-self-check 四段式”规则。
- 来源：`h5-vue` 项目“检查我的改动 + 某个 commit”任务，Codex 只触发了 `pr-review`，需用户显式 `$vue-change-self-check` 才走四段式。
- 配套 skill spec / adapter / eval 改动见 `logs/skill-changelog.md` 同日条目。

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
