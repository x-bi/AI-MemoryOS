---
title: "避免在要求 LLM 输出 JSON 时使用联合类型伪 schema"
status: rejected
created_at: 2026-06-04T02:53:52.553Z
rejected_at: 2026-06-16
source: mcp
---

## Rejection Note

机制本身通用（LLM "示例即契约"，伪 schema 示例容易被照抄成非法 JSON），但当前触发面窄：

- 自 2026-06-04 修复 `tools/self-optimize-scan.ps1` 后未再复发。
- 现有 LLM 结构化输出主链路已切换到 MCP tool schema / Anthropic structured output / Workflow `schema:`，由 SDK 强制 JSON Schema 校验，不经过"模型自由生成字符串 → 严格 parser"这一段，伪 schema 写法不会触发故障。
- 存量 prompt-based JSON 脚本已修为合法 JSON 示例。

不进入正式规则/skill；如未来再次出现 prompt-based JSON 输出场景并复发，重新作为新 pending 捕获即可。

# Proposal: 避免在要求 LLM 输出 JSON 时使用联合类型伪 schema

## Summary

可复用模式：当 prompt 要求模型仅输出 JSON 时，示例必须本身就是可被 JSON parser 解析的 JSON；不要在示例中使用 TypeScript/OpenAPI 风格的联合类型、undefined、注释或裸枚举值，否则模型可能照抄导致结构化解析失败。

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

# 避免在要求 LLM 输出 JSON 时使用联合类型伪 schema

## Context

在维护 `tools/self-optimize-scan.ps1` 的过程中，脚本多次出现类似警告：

```text
WARNING:   Batch 3/5: no structured candidates returned.
```

前一个相邻问题是 verification 阶段解析失败：模型返回了 `undefined` 或裸 `unclear`，PowerShell `ConvertFrom-Json` 无法解析。修复 verification 后，主评估批次仍然越来越频繁地出现 `no structured candidates returned`。

排查发现，脚本 prompt 要求 Claude “仅输出一个 ```json 块”，但示例本身混入了非 JSON 的 schema 写法，例如：

```json
{
  "channel": "github" | "web",
  "estimated_effort": "S" | "M" | "L",
  "estimated_value": "low" | "med" | "high"
}
```

这类写法适合描述类型约束，但不是合法 JSON。模型在结构化输出任务中可能照抄示例，从而输出不可被 `ConvertFrom-Json`、`JSON.parse` 或其它严格 JSON parser 解析的内容。随着模型行为、上下文、批次输入或采样波动变化，这类失败概率可能上升，并表现为“某些 batch 没有结构化候选”。

## Reusable Lesson

当 prompt 明确要求 LLM 输出 JSON 时，示例 JSON 必须本身就是合法 JSON。

不要在 JSON 示例块中放入以下内容：

- 联合类型写法，例如 `"S" | "M" | "L"`。
- 裸枚举值，例如 `unclear`。
- JavaScript 特有值，例如 `undefined`。
- 注释，例如 `// ...`。
- 占位表达式，例如 `true|false|unclear`。
- 任何不能被目标 parser 直接解析的 schema 说明。

如果需要表达枚举约束，应把约束写在 JSON 块外的自然语言中，并在 JSON 块内只给一个合法样例值，例如：

```text
JSON 要求：estimated_effort 只能是字符串 "S"、"M" 或 "L"。
```

```json
{
  "estimated_effort": "M"
}
```

如果允许空结果，也应显式要求模型返回合法空结构，例如：

```json
{
  "borrow_candidates": [],
  "web_queries_used": [],
  "overview": "本批没有发现足够具体的可借鉴候选。"
}
```

这样可以区分两种情况：

- `borrow_candidates: []`：模型成功返回结构化 JSON，只是没有候选。
- 无法解析 JSON 或缺失必要字段：模型输出格式失败，应记录原始输出用于排查。

## Proposed Memory OS Change

建议将此模式沉淀到以下一个或多个位置，由维护者审核后选择合适落点：

1. `skills/prompt-improver/SKILL_SPEC.md`
   - 增加一条结构化输出 prompt 检查项：当要求模型输出 JSON 时，示例必须是合法 JSON，不得混入联合类型伪 schema。

2. `domains/scripting/README.md` 或相关脚本工作流
   - 增加脚本调用 LLM 并解析 JSON 时的稳定性建议：
     - prompt 使用合法 JSON 示例。
     - 空结果也返回结构化空数组。
     - parser 失败时保存原始模型输出。
     - 对常见非 JSON 值做有限修复，但不要把修复当成主要契约。

3. 未来如存在 JSON/LLM 输出专门规则页，可沉淀为通用规则：
   - “示例即契约”：模型更容易模仿示例而不是遵守抽象描述，因此示例必须严格符合机器解析格式。

## Suggested Checklist

在编写或 review 需要 LLM 输出 JSON 的 prompt 时，检查：

- JSON fenced block 能否直接复制给 `ConvertFrom-Json` / `JSON.parse` 解析。
- 枚举值是否使用普通字符串示例，而不是联合类型。
- 空结果是否有明确、合法的返回结构。
- 是否禁止额外正文、注释、Markdown 列表和解释性尾巴。
- 是否把 parser 失败和业务空结果分开处理。
- 是否在失败时保存原始输出，方便定位是模型没结果、字段缺失还是 JSON 语法坏。

## Safety and Sensitivity Check

本 proposal 不包含 token、密码、密钥、账号、PII、客户数据、生产日志原文或商业敏感信息。

涉及的脚本名和错误类型来自本地 Memory OS 维护任务，内容已抽象为通用 LLM JSON 输出稳定性经验；没有沉淀未脱敏私有业务代码。

## Source Task or Evidence Summary

来源任务：修复 `tools/self-optimize-scan.ps1` 的结构化输出解析稳定性。

证据摘要：

- verification 阶段曾因 `undefined` / 裸 `unclear` 导致 `ConvertFrom-Json` 失败。
- 主评估 prompt 中存在非法 JSON 示例：`"github" | "web"`、`"S" | "M" | "L"`、`"low" | "med" | "high"`。
- 修复方向包括：
  - JSON 示例改为合法 JSON。
  - 枚举约束移到 JSON 块外的自然语言说明。
  - 空结果明确返回 `borrow_candidates: []`。
  - 真正解析失败时保存原始 Claude 输出以便排查。

## Risks

- 是否过度泛化：
- 是否包含敏感信息：
- 是否与现有规则冲突：

## Draft

TODO
