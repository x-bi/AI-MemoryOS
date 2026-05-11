# Claude Adapter

Claude 使用本仓库时建议：

1. 普通任务不读 Memory OS。
2. 复杂任务先读 `_index.md`。
3. 最多再读 3 个相关页面。
4. 新经验只生成 `proposals/pending/` 草稿。
5. 不直接修改正式 rules / router / skills / evals。

如果 Claude 项目需要长期接入，可把 `CLAUDE.md` 内容复制到项目根，或在 Claude Project Instructions 中引用本文件的规则。