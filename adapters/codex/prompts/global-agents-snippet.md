# Codex Bootstrap

每个用户输入先读取：

`C:\Users\btf\AI-MemoryOS\adapters\codex\gate.md`

并按其中规则处理回答风格、Memory OS Gate、任务量级、验证策略和写入边界。

读取 `gate.md` 只用于加载 Codex 运行策略，不等于读取 Memory OS 正文。

如果 `gate.md` 读取失败：

- 使用简洁、直接、工程化的中文回答。
- 普通 explain / 单点 debug / small implement 直接处理。
- 涉及架构、跨模块、安全/权限、发布流程、Memory OS 维护、长期规范时，先询问用户是否读取 Memory OS。
- 不自动写入 Memory OS；只有用户明确要求或确认后，才写入 `C:\Users\btf\AI-MemoryOS\proposals\pending\`。

项目本地 `AGENTS.md`、README、代码事实优先于 AI Memory OS。
