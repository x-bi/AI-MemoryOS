# Router Test Cases

| Input | Expected task_type | Expected domain | Expected action |
|---|---|---|---|
| 这个报错怎么排查 | debug | unknown | 不读 Memory OS，先基于上下文排查 |
| 帮我做一次代码 review | review | project | 进入 review 模式，优先问题和风险 |
| 帮我 review 一下当前 diff | review | project | L1：触发轻量 review workflow，不默认读取 Memory OS |
| 提交前帮我自检一下 | review | project | L1：检查 diff、入口、调用链和验证缺口，不默认读取 Memory OS |
| 这个任务结束后有没有值得沉淀的经验 | retrospective | memory | L1：只判断是否值得沉淀，确认前不写入 |
| 帮我修这个 bug | debug | project | L1：执行修复并做轻量回归风险检查，不默认读取 Memory OS |
| 实现完这个功能后扫一遍风险 | review | project | L1：功能完成后的风险扫描，不默认读取 Memory OS |
| 改了这个接口字段，帮我看下影响 | review | backend | L1：字段契约影响检查；跨模块或长期规范再升 L2 |
| 修改路由配置后帮我检查一下 | review | project | L1：路由/配置轻量风险检查，不默认读取 Memory OS |
| 这次经验沉淀一下 | retrospective | memory | 读取 `_index.md`，生成 pending proposal |
| 前端组件交互有问题 | debug | frontend | 可按需读取 frontend checklist |
| 帮我规划这个功能怎么做 | architecture | project | 可读 `_index.md`，最多 3 页相关文档 |
| 这是复杂工程任务，可以读取 MemoryOS | architecture | project | MemoryOS 读取预算默认不超过 2k tokens，超出先说明范围 |
| 这个接口鉴权为什么 403 | debug | backend | 先按 API debugging 排查 |
| 写个批量处理文件的脚本 | implement | scripting | 先确认输入输出和副作用 |
| CI 在安装依赖时报错 | debug | devops | 先看失败命令、缓存、依赖版本 |
| 发现 token 泄露怎么办 | debug | security | 不复述 token，建议轮换和清理历史 |
| 审计一下 Memory OS 有没有重复 | maintenance | memory | 读取相关索引，输出 cleanup proposal |
| 检查 Memory OS 的 MCP 权限有没有漏洞 | maintenance | security | L2：读取 `_index.md` + MCP/security 相关页面，检查实现和规则是否一致 |
| 给 Memory OS 做一次 weekly audit | maintenance | memory | L2：读取治理入口和相关索引，输出 `logs/audits/YYYY-MM-DD.md` 审计记录 |
| Codex 和 Claude 的 Memory OS 接入是不是漂移了 | maintenance | memory | L2：检查 adapter 配置、skills 映射和外部配置快照 |
| Memory OS 里会不会误存 token 或客户日志 | maintenance | security | L2：检查 safety rules、写入入口、验证脚本和忽略规则 |
| 修一下 Memory OS 的验证脚本 | implement | scripting | L2：修改验证入口后做最小必要回归验证 |
| 这个 TypeScript 报错是什么意思 | explain | unknown | 不读取 Memory OS，直接解释当前报错 |
| 帮我修一下这个按钮点击没反应 | debug | frontend | 不读取 Memory OS，先基于当前项目上下文排查 |
| 这个模块要不要拆成独立包 | architecture | project | 触发 Memory OS Gate，可读 `_index.md` + 最多 3 个相关页面 |
| 这次接口字段命名以后怎么统一 | architecture | backend | 触发 Memory OS Gate，可读 `_index.md` + 命名/后端相关页面 |
| 这个 bug 修法会不会影响其他页面 | review | frontend | L1：先做影响面 review，不默认读取 Memory OS；跨模块或长期规则再升 L2 |
| 这个问题修完以后要不要沉淀成规则 | retrospective | memory | 先确认沉淀目标，再生成 pending proposal |
| 帮我写个一次性重命名文件脚本 | implement | scripting | 不读取 Memory OS，确认输入输出和副作用后处理 |
