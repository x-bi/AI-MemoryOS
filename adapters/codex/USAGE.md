# Codex Usage

## 自动边界判定

直接提问或要求修改，不需要声明任务简单或复杂。Codex 先做轻量 Memory OS Gate 判定，判断是否需要长期工程记忆参与。

## 普通任务

普通 explain / debug / small implement 不读取 `C:\Users\btf\AI-MemoryOS`，直接基于当前项目上下文处理。

## 复杂工程任务

架构、重构、复杂排错、长期规范、安全/权限/发布流程等任务可自动读取 `C:\Users\btf\AI-MemoryOS\_index.md`，最多再读 3 个直接相关页面。读取 Memory OS 不等于写入记忆。

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
