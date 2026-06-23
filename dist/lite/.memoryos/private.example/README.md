# Private Overlay Layout

`private/` 是本机私有目录，不进入 Git。这里可以放本机项目规则、账号说明、临时草稿等内容，但要按类型分层，避免 skill 误读敏感信息。

推荐结构：

```text
private/
  skills/      # skill 可显式读取的本地规则，不放 token/password
  projects/    # 本机项目路径、目录约定、非敏感项目规则
  accounts/    # 账号用途说明，不放密码、token、cookie
  secrets/     # 高敏信息隔离区，默认禁止 AI 自动读取
  scratch/     # 临时草稿，可随时清理
```

## 读取规则

- `private/skills/`：只有对应 skill 明确说明时才读取，例如 `private/skills/vue-change-self-check.local.md`。
- `private/projects/`：只在用户明确要求使用某个本机项目规则时读取。
- `private/accounts/`：只记录账号用途、登录方式提示，不存密码/token。
- `private/secrets/`：默认禁止读取、禁止总结、禁止写入 MemoryOS；除非用户明确点名某个文件并说明目的。
- `private/scratch/`：临时内容，不作为长期事实源。

## 安全边界

- 不把 `private/` 内容写入 public MemoryOS 文件、proposal、logs、commit message。
- 不把 token、密码、cookie、密钥、生产凭据交给普通 skill。
- 如果必须处理 secrets，只做当前任务所需的最小读取，不复述原文，不沉淀。
