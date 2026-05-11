# Skill Spec: frontend-performance-audit

## Trigger

用户要求审计前端性能、首屏、重复请求、重复渲染、卡顿或资源加载问题。

## Do Not Trigger

没有性能症状的普通前端 review。

## Output

- 测量入口。
- 最大嫌疑点排序。
- 修复建议。
- 验证方式。

## Low Cost Strategy

先看重复请求、重复渲染、组件边界和首屏阻塞，不默认展开全量性能分析。