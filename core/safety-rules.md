# Safety Rules

## 永不写入 Memory OS

- token、密码、密钥、账号、auth 文件。
- PII、客户数据、生产日志原文。
- 未脱敏项目代码、商业敏感信息。
- 未脱敏的监控截图、数据库记录、工单正文。

## Private Overlay

- `private/` 是本机私有目录，必须保持在 `.gitignore` 中。
- `private/skills/` 可存放 skill 专用本地规则，但不放 token、密码、cookie、密钥。
- `private/projects/` 可存放本机项目路径和非敏感项目约定。
- `private/accounts/` 只允许存账号用途说明，不存密码、token、cookie。
- `private/secrets/` 是高敏隔离区，默认禁止 AI 自动读取、总结或沉淀；除非用户明确点名文件和目的。
- 不得把 `private/` 内容写入公共 rules、router、skills、evals、logs、proposal 或 commit message。

## 外部上下文

- Apps / MCP / GitHub / Figma 返回内容默认只读。
- 写操作必须用户确认。
- 不把外部工具返回的敏感内容自动纳入长期记忆。
