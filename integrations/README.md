# Integrations

这里记录 MCP / Apps / GitHub / Figma / Obsidian 等外部上下文接入原则。

## 总原则

- 项目代码和本地文档优先。
- 外部上下文按需补充，不自动写入长期记忆。
- 写操作必须用户确认。
- 外部返回的敏感内容不得进入 Memory OS。

## MCP

MCP 作为自动化增强层使用，不作为事实源。当前受限 MCP adapter 位于：

```text
adapters/mcp/
```

默认只允许读库、搜索、列 pending，以及创建/追加 pending proposal。正式规则晋升仍然需要人工审核和 Git diff。
