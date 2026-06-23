# Lite Usage Rules

- 每轮先读 adapter bootstrap，再按 bootstrap 判断是否读取完整 gate。
- Lite 版只负责日常使用链路，不包含 Memory OS 治理维护链路。
- 项目本地 `AGENTS.md`、`CLAUDE.md`、README 和代码事实优先。
- 不自动写入长期记忆；需要沉淀时先由用户明确指定保存位置。
- 安装器生成的托管块、hook command 和 junction 都来自 `memoryos.config.json` 解析结果。
- Lite 运行包移动目录后，先更新配置，再运行 `install.ps1 -Check` 和 `install.ps1`。
