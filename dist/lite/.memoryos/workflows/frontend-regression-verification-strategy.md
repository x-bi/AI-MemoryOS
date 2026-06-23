# Frontend Regression Verification Strategy

前端代码修改后的回归验证默认采用分层策略：先做 diff 和静态链路检查，只有改动触达入口、路由、配置、公共模块、平台条件分支、构建链路，或用户明确要求时，才执行对应范围的构建、测试或生成类验证。执行可能产生副作用的命令前后，都要检查工作区状态并区分交付内容和临时产物。

## Default Checks

- 查看 `git diff --name-only` 和相关业务 diff。
- 检查路由、页面注册、分包配置和跳转链路。
- 检查接口字段、组件 props / emits、状态边界、空态、错误态和分页边界。
- 检查平台条件编译分支和 import / export 影响面。

## Build Triggers

- 新增、移动或删除页面。
- 修改路由、分包、入口配置或构建配置。
- 修改共享组件、公共方法、import / export 或构建敏感代码。
- 修改 `#ifdef` / 平台条件编译分支。
- 用户明确要求构建验证。
- 提交前检查发现改动影响入口、路由、配置、公共模块、平台条件分支或构建链路。

## Side Effect Triggers

默认不把以下命令当作只读验证步骤执行，除非项目规范、改动影响面或用户要求使其必要：

- 完整构建或多平台构建。
- 会生成 coverage、report、截图、视频或 snapshot 的测试命令。
- 会写 `.tsbuildinfo`、框架缓存或临时编译目录的类型检查 / 编译检查。
- 带 `--fix` / `--write` 的 lint / format 命令。
- OpenAPI / GraphQL / protobuf / ORM client 等代码生成命令。
- `npm install` / `pnpm install` / `yarn install` 等依赖安装命令。
- dev server、预览服务、Storybook、VitePress、Docusaurus、typedoc 等会生成缓存、静态站点、文档或报告的命令。

## Platform Selection

- 涉及微信小程序或 uni-app 分包时，优先验证 `mp-weixin`。
- H5 构建只在用户要求验证 H5，或改动明确影响 H5 时执行。
- 多平台共享逻辑变化时，按实际影响面选择最小必要平台集合。

## Verification Side Effects

验证后检查工作区污染。清理前必须确认路径限定在构建、缓存、报告、覆盖率、截图、视频或测试产物目录：

- 已跟踪构建产物被改动时，使用 `git restore -- <build-path>`。
- 未跟踪构建产物需要删除时，使用 `git clean -fd -- <build-path>`。
- coverage、测试报告、截图、视频、框架缓存等非交付产物，可在确认路径后限定目录清理。
- 源码、lockfile、snapshot、generated 文件、API 类型文件是否保留，必须按项目约定或用户确认处理，不能自动清理。
- 禁止把 `git clean` 扩大成全仓清理；必须遵守当前权限和用户授权规则。
