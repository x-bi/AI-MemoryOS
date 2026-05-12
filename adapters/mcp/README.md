# MCP Adapter

本 adapter 用于混合架构：

```text
Markdown + Git = 唯一事实源
Codex Skills = 高频工作流触发
MCP = 受限自动化工具层
Obsidian = 人类审核前台
```

## 当前策略

MCP 只做安全自动化入口：

- 读：允许读取 Memory OS 中的 Markdown 等文本文件。
- 搜：允许搜索 Memory OS 文本内容。
- 列：允许列出 `proposals/pending/`。
- 写：只允许创建或追加更新 `proposals/pending/`。

MCP 默认不允许：

- 删除文件。
- 批量重写。
- 直接修改 `rules/`、`router/`、`skills/`、`evals/`。
- 直接把 pending 晋升为 accepted。

这样既能让支持 MCP 的模型自动化操作 Memory OS，又不会绕过 proposal 审核和 Git diff。
