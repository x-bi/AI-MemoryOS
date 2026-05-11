# Frontend Performance

## Review Order

1. 是否重复请求。
2. 是否重复渲染。
3. 是否组件边界过大。
4. 是否首屏阻塞。
5. 是否事件处理、计算、动画过重。

## Guardrails

- 先测量再优化。
- 先解决大头问题。
- 不把 memo / cache 当默认答案。
- 不牺牲可维护性换未经验证的微优化。