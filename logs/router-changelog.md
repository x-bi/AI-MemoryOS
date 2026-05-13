# Router Changelog 路由变更日志

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
