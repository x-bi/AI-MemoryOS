# Remote Repository

## Origin

```text
https://github.com/x-bi/AI-MemoryOS.git
```

## Branch

```text
main
```

## Local Git Identity

```text
x-bi <924992512@qq.com>
```

## Push Policy

- 当前允许手动 push。
- Obsidian Git 当前关闭自动 push，避免误推未审核内容。
- 首选流程：

```text
local changes
→ validate-memory-os.ps1
→ validate-obsidian.ps1
→ git diff / review
→ commit
→ manual push
```

## Remote Safety

推送前做本地敏感信息扫描。扫描模式不要写入仓库文档；无输出才推送。
