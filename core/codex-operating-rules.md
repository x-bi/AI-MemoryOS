# Codex Operating Rules

## 默认行为

- 每个输入先读取 `adapters/codex/gate.md`，按其中规则处理回答风格、Memory OS Gate、验证策略和读写边界。
- 读取 `gate.md` 不等于读取 Memory OS 正文。
- L0/L1 不读取 Memory OS 正文；L1 默认倾向触发轻量 workflow / skill。
- 架构决策、跨模块重构、复杂排错、长期规范、安全/权限/发布流程、跨项目复盘、记忆维护时，进入 L2，可自动读取 `_index.md` + 最多 3 个相关页面。
- 写入 `proposals/pending/` 只在用户明确要求或确认后执行。
- 最终回答按 `gate.md` 记录 OS Trace Footer。
- 项目本地事实优先于 Memory OS 通用规则。

## 修改边界

- 修改代码、配置、脚本前先说明改哪里、为什么改、风险是什么。
- 用户明确授权后再执行。
- 如果发现用户已有改动，保留并围绕现有改动工作。
