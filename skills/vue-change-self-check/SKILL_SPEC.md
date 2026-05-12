# Skill Spec: vue-change-self-check

## Trigger

用户要求对 Vue / uni-app / frontend 当前改动做提交前自检、diff 风险扫描、回归风险评估，或希望得到稳定编号的风险清单。

## Do Not Trigger

- 用户只是要求修一个明确 bug，并且需要直接修复和补回归测试；优先 `bugfix-with-regression-test`。
- 用户只是审查单个组件交互、表单流程或 UI 行为；优先 `frontend-component-review`。
- 非前端或非 Vue 改动。

## Input

- 当前 Git diff。
- 必要时读取变更文件、页面配置、路由配置、API 文件、共享组件使用边界。
- 如果存在本机 private overlay，可读取本地项目规则，但不要把 private 内容写入公共 MemoryOS 文件。

## Output

按固定结构输出：

1. `变更影响扫描`
2. `风险清单`
3. `建议验证路径`
4. `本次未覆盖盲区`

风险清单使用稳定编号：

- `[#1]`
- `[#2]`
- `[#3]`

用户只要求 self-check 时，输出风险后等待用户选择编号，不自动修复。

## Low Cost Strategy

- 优先读 `git diff --name-only`、`git diff --stat` 和目标 diff hunk。
- 只围绕当前改动扩展到必要的配置、路由、页面注册、API consumer、共享组件边界。
- 不默认扫描整个仓库。
- 不默认展开 unchanged dependency internals，除非有直接证据或用户要求。

## Eval Cases

| Input | Expected |
|---|---|
| 检查当前 Vue 改动有没有回归风险 | 触发，输出编号风险清单 |
| 提交前帮我扫一下 h5 页面改动 | 触发，优先 diff-first |
| 处理 #2 | 延续上一轮编号，只处理对应风险 |
| 这个 bug 修完加回归测试 | 不触发，优先 bugfix-with-regression-test |
