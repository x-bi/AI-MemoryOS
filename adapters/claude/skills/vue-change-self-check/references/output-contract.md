# Vue Change Self Check Output Contract

Always respond in this order:

1. `变更影响扫描`
2. `风险清单`
3. `建议验证路径`
4. `本次未覆盖盲区`

Each risk item must use a stable number and this shape:

```md
[#1] 风险标题
级别：高
置信度：中
分类：待确认风险
类型：页面状态
位置：path/to/file
状态：可修复
证据：...
原因：...
建议动作：先确认接口/业务规则
影响面：...
```

## Severity

- `阻塞`: likely to break entry, request success, page render, route access, login flow, payment, or a critical business path.
- `高`: likely visible regression, but not guaranteed hard failure.
- `中`: plausible issue, missing guard, or behavior that should be verified.

## Confidence

- `高`: direct code evidence shows a mismatch or defect.
- `中`: strong signal, but confirmation depends on nearby code, runtime data, or backend contract.
- `低`: suspicious pattern with limited evidence.

## Category

- `确定问题`: direct evidence shows a defect or inconsistent binding.
- `待确认风险`: confirmation depends on runtime data, backend contract, or business expectation.

## Action

- `直接修复`
- `先确认接口/业务规则`
- `只需回归验证`

## Numbering Rules

Number findings by practical impact:

1. Broken entry, registration, or navigation.
2. Broken API, auth, request, or payment flow.
3. Broken page state or shared component contract.
4. Likely regression or missing validation.
5. Lower-confidence observations.
