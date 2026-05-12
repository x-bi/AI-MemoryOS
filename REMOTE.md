# Remote Repository 远程仓库

## Origin 远程地址

```text
https://github.com/x-bi/AI-MemoryOS.git
```

## Branch 分支

```text
main
```

## Local Git Identity 本仓库 Git 身份

```text
x-bi <924992512@qq.com>
```

## Push Policy 推送策略

- 当前允许手动 push。
- Obsidian Git 已启用自动 push，用于同步已确认的本地 vault 变更。
- 首选流程：

```text
local changes
→ validate-memory-os.ps1
→ validate-obsidian.ps1
→ git diff / review
→ commit
→ manual push 或 Obsidian Git auto push
```

## Remote Safety 远程安全

推送前做本地敏感信息扫描。扫描模式不要写入仓库文档；无输出才推送。
