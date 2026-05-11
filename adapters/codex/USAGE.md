# Codex Usage

## 普通任务

直接提问或要求修改，不需要提到 Memory OS。Codex 应遵守全局规则：不主动读取 `C:\Users\btf\AI-MemoryOS`。

## 复杂工程任务

使用：

```text
这是复杂工程任务。可以读取 C:\Users\btf\AI-MemoryOS\_index.md，最多再读 3 个直接相关页面。不要自动写入记忆。
```

## 记忆复盘

使用：

```text
请对这次任务做 memory retrospective，只生成 pending proposal，不直接改正式 rules / router / skills / evals。
```

## 路由纠正

使用：

```text
刚才你的路由判断错了。请生成 router correction proposal，不直接改正式 router。
```