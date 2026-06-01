# Auto Runs 自动运行

展示 `logs/auto-runs/` 下的自动审计、迭代和优化运行记录。

## 最近运行

~~~dataview
TABLE script, status, findings_count, actions_count, max_severity, started_at
FROM "logs/auto-runs"
WHERE script
SORT started_at DESC
LIMIT 20
~~~

## 待人工决策

~~~dataview
TABLE script, pending_decisions_count, max_severity, started_at
FROM "logs/auto-runs"
WHERE pending_decisions_count > 0
SORT started_at DESC
LIMIT 20
~~~

## C 级审批单

~~~dataview
TABLE status, scope, created_at
FROM "logs/auto-runs/approval-sheets"
SORT created_at DESC
~~~
