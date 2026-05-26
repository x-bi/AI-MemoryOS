---
title: "Single Shared OS With Isolated User Configuration Overlay"
type: future-direction-note
status: active
created_at: 2026-05-26T08:39:27.736Z
source: conversation
not_directly_promotable: true
---

# Future Direction: Single Shared OS With Isolated User Configuration Overlay

## 中文说明

这是一条长期重大方向说明，不是普通 pending proposal。

未来 AI Memory OS 不应分成“公共版”和“个人版”两套长期分支。更理想的方向是：所有人，包括维护者本人，都使用同一个通用 OS 版本；每个用户自己的路径、工具配置、项目绑定、运行缓存、索引和本地偏好，统一放在隔离的本地 overlay 中，例如 ignored 的 `private/` 和 `state/`。

这条记录只提供未来理解基础。它不能通过一次审核直接晋升成正式规则，也不代表现在就要改造。等系统足够稳定、实际使用路径足够清楚后，再基于它拆出具体 proposal、设计文档、迁移计划或任务清单。

## Background

当前仓库仍包含一些维护者本机路径和工具配置细节。曾考虑过维护公共分支和个人分支，但长期看这会让个人分支逐渐变成另一个产品，也会增加合并公共改进的成本。

更合适的产品模型是：Git-tracked 仓库只保存可共享 OS 行为、模板、schema、默认配置、adapter、工具和文档；用户身份、路径、本机工具设置、项目绑定、运行缓存、生成索引和私有偏好都由本地 overlay 注入。

## Direction Principles

- 一个共享 OS 版本供所有用户使用。
- 用户差异不通过长期个人分支表达，而通过本地 overlay 表达。
- `private/` 保持 ignored，用于用户本地配置和非敏感项目约定。
- `state/` 可作为 ignored 运行态目录，用于缓存、索引、生成态和非源码产物。
- 公共仓库只提交可共享规则、模板、默认值、schema、adapter、工具和文档。
- 安全边界不能被 overlay 放宽；overlay 只能增加本地信息或收紧规则。

## Possible Precedence Model

```text
project local overlay
> user local overlay
> adapter defaults
> OS core defaults
```

## Non-Goals

- 不在当前阶段立即重构仓库。
- 不把本机配置迁入公共规则或公共日志。
- 不通过“个人分支长期叠加公共分支”的方式解决本地配置问题。
- 不允许 overlay 绕过 token、账号、密钥、PII、生产日志或客户私有信息的写入边界。

## Future Trigger Conditions

可以在以下条件更成熟时重新评估是否启动具体改造：

- AI Memory OS 的日常使用路径已经稳定。
- Codex / Claude / MCP / skills / CodeGraph 等主要 adapter 的边界已经清楚。
- 本机路径和外部工具配置反复成为复用或开源障碍。
- 用户需要更顺滑地 clone、初始化、接入和贡献通用 OS。

## Possible Follow-Up Work

未来真正实施时，应拆成更具体的工作，而不是直接晋升本说明：

- 定义 overlay schema 和加载优先级。
- 新增 `state/` ignored 运行态目录。
- 把本机路径替换为环境变量、占位符或初始化生成的 local config。
- 把 adapter 的真实本机配置与可共享模板拆清楚。
- 更新安装文档和验证脚本。
- 审计工具、MCP server、skills 生成链路是否需要识别 overlay。

## Safety And Sensitivity Check

本方向说明不包含 token、账号、密钥、客户数据、生产日志或未脱敏私有项目代码。它只记录架构方向和泛化后的配置隔离模型。
