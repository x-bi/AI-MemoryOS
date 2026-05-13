---
title: "Frontend verification build strategy"
status: pending
created_at: 2026-05-13T05:55:10.553Z
source: mcp
---

# Proposal: Frontend verification build strategy

## Summary

前端/uni-app 验证时默认先做 diff 和静态链路检查，避免每次完整构建导致日志 token 消耗和 dist 污染；仅在关键节点或提交前执行构建，并及时清理构建产物。

## Scope

- Global / domain / stack / project-specific:
- Applies to:
- Does not apply to:

## Proposed Destination

- rules:
- workflow:
- domain:
- stack:
- skill:
- router:
- eval:

## Rationale

# Proposal: Frontend verification build strategy

## 背景

在 `D:\xiangmeifu\h5-vue` 的 brandWall 模块验证中，完整执行 H5/MP-WEIXIN 构建会产生大量终端输出，并改动 `dist/build/**` 构建产物，导致后续 `git status` / `git diff` 输出膨胀，增加上下文 token 消耗和审查噪音。

## 建议规则

当用户要求验证 Vue / uni-app / 前端模块改动时，默认采用分层验证策略：

1. 优先执行轻量静态验证：
   - `git diff --name-only`
   - 针对相关业务文件查看 diff / 代码链路
   - 检查路由 / pages.json / 分包注册
   - 检查接口字段、组件 props/emits、条件编译、跳转链路、空态和分页边界

2. 不默认每次执行完整构建。

3. 只有满足以下条件之一时才执行构建：
   - 新增页面、移动页面、修改分包或路由注册
   - 修改 import/export、公共方法、共享组件或构建敏感代码
   - 修改 `#ifdef` / 平台条件编译分支
   - 用户明确要求构建验证
   - 提交前最后确认

4. 构建平台按改动影响选择：
   - 涉及微信小程序或 uni-app 分包时，优先跑 `mp-weixin` 构建。
   - H5 构建只在用户要求验证 H5 或改动明确影响 H5 时执行。

5. 构建后立即检查并清理构建产物污染：
   - 已跟踪构建产物被改动：用 `git restore -- <build-path>` 恢复。
   - 未跟踪构建产物：用 `git clean -fd -- <build-path>` 删除。
   - 清理前必须确认路径限定在构建目录，不触碰业务代码。

## 适用范围

适用于 Vue、uni-app、H5、小程序前端项目的代码审查、自检和回归验证。

## 不适用范围

- 用户明确要求完整构建或打包产物。
- 构建产物本身就是交付内容。
- 发布流程要求每次验证必须构建。

## Risks

- 是否过度泛化：
- 是否包含敏感信息：
- 是否与现有规则冲突：

## Draft

TODO
