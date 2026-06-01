---
run_id: ""
script: ""
triggered_by: ""
model_profile: ""
model_invocations_count: 0
model_tokens_estimate: 0
started_at: ""
duration_seconds: 0
exit_code: 0
findings_count: 0
actions_count: 0
pending_decisions_count: 0
max_severity: ""
status: ""
branch: ""
lock_id: ""
repair_attempts: 0
---

# 自动运行日志：{{script}}

## 先看这里

{{readable_summary}}

## 运行上下文

- **仓库根目录**：{{root}}
- **脚本阶段**：{{phase}}
- **运行参数**：
{{parameters}}

## 发现

| # | 严重度 | 类别 | 说明 | 路径 | 等级 |
|---|---|---|---|---|---|
{{finding_rows}}

## 已执行操作

| # | 等级 | 操作 | 目标 | 状态 |
|---|---|---|---|---|
{{action_rows}}

## 待人工决策

| # | 事项 | 等级 | 路径 | 状态 |
|---|---|---|---|---|
{{decision_rows}}

## 结构化数据（排查用）

~~~json
{{structured_json}}
~~~

## 验证

- `validate-memory-os.ps1`：{{validation_status}}
- 内容质量复查：{{content_recheck_status}}
