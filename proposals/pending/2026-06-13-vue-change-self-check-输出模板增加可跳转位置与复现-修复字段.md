---
title: "vue-change-self-check 输出模板增加可跳转位置与复现/修复字段"
status: pending
created_at: 2026-06-13T08:42:27.641Z
source: mcp
---

# Proposal: vue-change-self-check 输出模板增加可跳转位置与复现/修复字段

## Summary

vue-change-self-check 当前 output-contract 中 `位置` 是纯文本路径，无法在 IDE 中点击跳转；同时模板缺少「复现步骤」与「修复方向」字段，与用户实际工作流（按编号逐项复现并手动修改 / 指示改法）不匹配。本提案在 SKILL_SPEC.md 与两个 adapter 的 references/output-contract.md 中规范化这三处变更。

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

# vue-change-self-check 输出模板补丁提案

## 背景

`vue-change-self-check` skill 当前输出契约（`adapters/claude|codex/skills/vue-change-self-check/references/output-contract.md`）存在两个执行漂移：

1. **位置字段不可跳转**：第 18 行规定 `位置：path/to/file`，输出端落地为纯文字路径，IDE 中需要手动定位。
2. **缺复现/修复字段**：模板只有 `建议动作` 一项，且取值被锁死在 `直接修复` / `先确认接口/业务规则` / `只需回归验证` 三个枚举，无法承载具体复现路径或修复草稿。用户实际工作流为「对着每个 # 编号逐项复现 → 手动改或反向告诉模型怎么改」，当前模板不能直接服务这一回路。

## 变更范围

唯一事实源是 `skills/vue-change-self-check/SKILL_SPEC.md`；adapter 下的 SKILL.md 与 references 由 `tools/sync-skills.ps1` 生成。本提案改动以下文件（按 L3 流程，先落 pending）：

1. `skills/vue-change-self-check/SKILL_SPEC.md`：在 `## Output` 段补一句「位置必须为 markdown 链接；按 output-contract 决定是否给复现步骤与修复方向」。
2. `adapters/claude/skills/vue-change-self-check/references/output-contract.md`
3. `adapters/codex/skills/vue-change-self-check/references/output-contract.md`

同步两个 references 文件中以下条目（共享 spec 不区分 adapter，描述保持一致）。

## 模板调整细节

### 1. 位置字段强制为可跳转 markdown 链接

把：

```
位置：path/to/file
```

改为：

> `位置`：必须使用 markdown 链接，格式 `[file:line](relative/path#Lline)` 或 `[file:line-line](relative/path#Lline-Lline)`。多个位置用 `、` 分隔。仓库根为相对路径基准。禁止只写裸路径或反引号路径。

示例：

```
位置：[mine.vue:142](src/pages/mine/mine.vue#L142)、[useUserStore.ts:88-95](src/stores/useUserStore.ts#L88-L95)
```

### 2. 新增 `复现步骤`、`修复方向` 两个字段

字段位置紧跟原 `建议动作` / `影响面` 之后，整体形状：

```
[#1] 风险标题
级别：高
置信度：中
分类：待确认风险
类型：页面状态
位置：[xx.vue:142](src/pages/xx/xx.vue#L142)
状态：可修复
证据：...
原因：...
建议动作：先确认接口/业务规则
影响面：...
复现步骤：
  1. 操作 → 预期 / 实际
  2. ...
修复方向：
  方案 A：在 [useUserStore.ts:90](src/stores/useUserStore.ts#L90) 切换前缓存 token，切换后重写
  方案 B：让 switchRole() 不再调 clearAll()，仅清业务态
```

### 3. 字段填写规则（按风险类型/动作分类，避免无脑全填）

- **复现步骤**：仅当风险类型为「页面状态 / 路由 / 导航 / 交互流程 / 登录态 / 渲染异常」时必填；纯静态契约风险（接口字段缺失、配置项漏挂、构建入口）填 `不适用，需接口 / 配置 / 构建侧验证`。每条 ≤ 3 步，写「操作 → 预期 / 实际」。
- **修复方向**：仅当 `建议动作 ∈ { 直接修复, 先确认接口/业务规则 }` 时给；`只需回归验证` 不需要。只指明改哪一行 / 改哪个变量 / 走哪个分支，不出完整代码；多方案用 `方案 A / 方案 B` 列出。
- 仍遵守 skill 边界：triage 阶段不自动改代码，等用户说 `处理 #N` 才动手。

## 不变的部分

- `级别` / `置信度` / `分类` / `类型` / `状态` / `建议动作` 取值集合保持不变。
- 编号规则不变。
- skill 的 Memory OS 边界、私有 overlay 规则不变。
- 不影响其他 skill、router、registry。

## 落地步骤（待用户批准提案后执行）

1. 编辑 `skills/vue-change-self-check/SKILL_SPEC.md` 的 `## Output` 段。
2. 编辑两个 adapter 下的 `references/output-contract.md`。
3. 运行 `tools/sync-skills.ps1`。
4. 运行 `tools/validate-memory-os.ps1`。
5. 不执行任何 git 操作。

## 待用户确认

字段触发偏好（默认建议 b）：

- (a) 默认全开：每条风险都尝试给 `复现步骤` + `修复方向`。
- (b) 默认按规则（推荐）：按上面第 3 节规则决定是否给。

## Risks

- 是否过度泛化：
- 是否包含敏感信息：
- 是否与现有规则冲突：

## Draft

TODO
