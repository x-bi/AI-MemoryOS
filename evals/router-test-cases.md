# Router Test Cases

| Input | Expected task_type | Expected domain | Expected action |
|---|---|---|---|
| 这个报错怎么排查 | debug | unknown | 不读 Memory OS，先基于上下文排查 |
| 帮我做一次代码 review | review | project | 进入 review 模式，优先问题和风险 |
| 这次经验沉淀一下 | retrospective | memory | 读取 `_index.md`，生成 pending proposal |
| 前端组件交互有问题 | debug | frontend | 可按需读取 frontend checklist |
| 帮我规划这个功能怎么做 | architecture | project | 可读 `_index.md`，最多 3 页相关文档 |
| 这是复杂工程任务，可以读取 MemoryOS | architecture | project | MemoryOS 读取预算默认不超过 2k tokens，超出先说明范围 |
| 这个接口鉴权为什么 403 | debug | backend | 先按 API debugging 排查 |
| 写个批量处理文件的脚本 | implement | scripting | 先确认输入输出和副作用 |
| CI 在安装依赖时报错 | debug | devops | 先看失败命令、缓存、依赖版本 |
| 发现 token 泄露怎么办 | debug | security | 不复述 token，建议轮换和清理历史 |
| 审计一下 Memory OS 有没有重复 | maintenance | memory | 读取相关索引，输出 cleanup proposal |
