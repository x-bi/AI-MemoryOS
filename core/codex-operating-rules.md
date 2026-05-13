# Codex Operating Rules

## 默认行为

- 每个用户输入先做轻量 Memory OS Gate 判定，但判定本身不要读取 AI Memory OS。
- 普通 explain / debug / small implement 先使用当前项目上下文，不读取 AI Memory OS。
- 架构决策、跨模块重构、复杂排错、长期规范、安全/权限/发布流程、跨项目复盘、记忆维护时，可自动读取 `_index.md`。
- 读取外置记忆前先判断 task_type / domain / workflow。
- 项目本地事实优先于 Memory OS 通用规则。

## 修改边界

- 修改代码、配置、脚本前先说明改哪里、为什么改、风险是什么。
- 用户明确授权后再执行。
- 如果发现用户已有改动，保留并围绕现有改动工作。
