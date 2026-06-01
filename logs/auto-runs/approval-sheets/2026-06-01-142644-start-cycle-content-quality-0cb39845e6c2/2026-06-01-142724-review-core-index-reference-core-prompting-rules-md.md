---
run_id: ""
script: ""
created_at: ""
status: pending
tier: C
approved: false
---

# C 级审批单：Review core index reference: core\prompting-rules.md

## 申请变更

- 范围：core/rules/router index coverage
- 文件：- core\prompting-rules.md
- _index.md
- 原因：Core/rules/router file is not directly referenced from _index.md.

## 安全检查

- 敏感内容检查：required before apply
- 路径边界检查：required before apply
- 验证命令：powershell -NoProfile -ExecutionPolicy Bypass -File tools\validate-memory-os.ps1

## Diff 预览

Human review required.

## 人工审批

- Approved: false
- Approved by:
- Approved at:
- Decision reason:

## 执行说明

只有明确审批后，才能用 `--ApplyApproved` 执行该审批单对应的修改。自动化不得 merge 到 main。
