---
run_id: ""
script: ""
created_at: ""
status: pending
tier: C
approved: false
---

# C 级审批单：{{title}}

## 申请变更

- 范围：{{scope}}
- 文件：{{files}}
- 原因：{{reason}}

## 安全检查

- 敏感内容检查：{{sensitive_check}}
- 路径边界检查：{{path_check}}
- 验证命令：{{validation_command}}

## Diff 预览

{{diff_preview}}

## 人工审批

- Approved: false
- Approved by:
- Approved at:
- Decision reason:

## 执行说明

只有明确审批后，才能用 `--ApplyApproved` 执行该审批单对应的修改。自动化不得 merge 到 main。
