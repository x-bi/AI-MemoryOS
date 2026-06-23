---
title: "AI Memory OS Lite Black-Box Distribution With Local Configuration"
type: future-direction-note
status: active
created_at: 2026-05-26T08:39:27.736Z
source: conversation
not_directly_promotable: true
---

# Future Direction: AI Memory OS Lite Black-Box Distribution With Local Configuration

## 中文说明

这是一条长期重大方向说明，不是普通 pending proposal，也不能通过一次审核直接晋升成正式规则。

未来可以从当前 AI Memory OS 维护仓库中拆出一个面向普通用户的 Lite 使用版。Lite 版不暴露 proposal、dashboard、Obsidian、MCP、CodeGraph、审计、self-optimize、accepted/rejected 维护链路等复杂结构，只保留模型日常使用需要的核心逻辑：adapter bootstrap / gate、router、workflow、skill、skill 映射脚本、安全边界和本地配置。

Lite 版的产品目标是：其他用户下载后，只需要修改一个配置文件，运行一个统一入口脚本，就能让 Codex 或 Claude 找到对应 OS 文件，并按 route / workflow / skill 读取规则工作。其余实现细节应放在黑盒目录中，普通用户不需要理解内部目录结构。

## Background

当前完整仓库同时承担两类职责：

- 使用职责：让 Codex / Claude 在真实工程任务中读取 bootstrap、gate、router、workflow 和 skill，执行 review、bugfix、自检、Git 指导、前端检查等任务。
- 维护职责：通过 proposals、accepted/rejected、logs、dashboard、Obsidian、MCP、CodeGraph、evals、audit、self-optimize 等结构维护 Memory OS 自身。

对维护者本人来说，两类职责放在一个仓库里可接受；但对普通用户来说，这会带来过高的接入成本。用户真正需要的是一个简单可用的运行包，而不是完整治理系统。

因此，未来更合适的产品形态不是维护"公共版"和"个人版"两条长期分支，而是保留完整仓库作为开发维护版，再从中导出一个 AI Memory OS Lite 使用版。Lite 版可以作为单独仓库、release artifact，或由完整仓库脚本生成的分发目录。

## Product Goal

Lite 版应满足以下目标：

- 用户只需要看到并修改一个配置文件。
- 用户只需要运行一个公开入口脚本。
- 支持用户只有 Codex、只有 Claude、或两者都有的情况。
- 脚本先识别配置中是否启用并配置了某个 adapter，再执行对应初始化。
- 对用户已有 `AGENTS.md`、`CLAUDE.md`、`settings.json` 等文件尽量只追加或合并，不整文件覆盖。
- 所有写入都应可重复运行、可检查、可回滚。
- 内部仍保留 route / workflow / skill 逻辑，但放在黑盒目录中。
- 不要求普通用户理解 proposals、MCP、Obsidian、CodeGraph、dashboard、evals 或审计机制。

目标用户的理想使用方式：

```powershell
notepad .\memoryos.config.json
.\install.ps1
.\install.ps1 -Check
```

## Proposed Package Shape

Lite 版根目录只暴露少量文件：

```text
ai-memoryos-lite/
  README.md
  INSTALL.md
  memoryos.config.json
  install.ps1
  .memoryos/
```

其中：

- `memoryos.config.json` 是唯一主要配置文件。
- `install.ps1` 是唯一主要执行入口。
- `.memoryos/` 是黑盒内部目录，普通用户不需要打开。
- `README.md` 和 `INSTALL.md` 只解释配置项、脚本命令、验证方式和卸载方式。

黑盒内部目录建议为：

```text
.memoryos/
  adapters/
    codex/
      bootstrap.md
      gate.md
      skills/
    claude/
      bootstrap.md
      CLAUDE.md
      skills/
  core/
    usage-rules.md
    safety-rules.md
  router/
    intent-map.md
    domain-map.md
    workflow-map.md
    skill-map.md
  workflows/
    diff-review-lite.md
    pre-commit-self-check.md
    feature-development.md
    bugfix-with-regression-test.md
    frontend-prototype-driven-development.md
  skills/
    registry.json
    pr-review/
      SKILL_SPEC.md
    bugfix-with-regression-test/
      SKILL_SPEC.md
    frontend-component-review/
      SKILL_SPEC.md
    vue-change-self-check/
      SKILL_SPEC.md
    git-ops-guide/
      SKILL_SPEC.md
  templates/
    codex-user-AGENTS.md.tmpl
    claude-user-CLAUDE.md.tmpl
    claude-hook.ps1.tmpl
    codex-bootstrap.md.tmpl
    codex-gate.md.tmpl
    claude-bootstrap.md.tmpl
    claude-gate.md.tmpl
    skill.md.tmpl
  tools/
    install-core.ps1
    render-adapters.ps1
    sync-skills.ps1
    patch-user-entry.ps1
    patch-claude-hook.ps1
    validate.ps1
    inject-bootstrap-reminder.ps1
  private.example/
    README.md
```

## Public Configuration File

Lite 版只暴露一个配置文件：`memoryos.config.json`。

配置文件建议使用 JSON，而不是 TOML。原因是 Windows PowerShell 原生支持 `ConvertFrom-Json` / `ConvertTo-Json`，Lite 版不需要额外依赖或自带 TOML parser。JSON 不如 TOML 适合人工注释，但更符合 Lite 版"少依赖、可直接运行"的目标。

示例：

```json
{
  "memoryos": {
    "root": "D:\\ai-memoryos-lite",
    "language": "zh-CN"
  },
  "codex": {
    "enabled": true,
    "user_agents": "C:\\Users\\you\\.codex\\AGENTS.md",
    "skills_dir": "C:\\Users\\you\\.codex\\skills",
    "mode": "append"
  },
  "claude": {
    "enabled": false,
    "user_claude": "",
    "settings_json": "",
    "skills_dir": "",
    "install_hook": false,
    "mode": "append"
  },
  "skills": {
    "active": [
      "pr-review",
      "bugfix-with-regression-test",
      "frontend-component-review",
      "vue-change-self-check",
      "git-ops-guide"
    ]
  },
  "local": {
    "private_dir": "D:\\ai-memoryos-lite\\private"
  }
}
```

字段语义：

- `memoryos.root`：Lite 包所在目录。
- `memoryos.language`：默认响应语言。
- `codex.enabled`：是否初始化 Codex。
- `codex.user_agents`：Codex 用户级 `AGENTS.md` 路径。
- `codex.skills_dir`：Codex skill discovery 目录。
- `codex.mode`：对用户入口文件的修改策略，默认 `append`。
- `claude.enabled`：是否初始化 Claude。
- `claude.user_claude`：Claude 用户级 `CLAUDE.md` 路径。
- `claude.settings_json`：Claude `settings.json` 路径。
- `claude.skills_dir`：Claude skill discovery 目录。
- `claude.install_hook`：是否安装 Claude `UserPromptSubmit` hook。
- `claude.mode`：对用户入口文件的修改策略，默认 `append`。
- `skills.active`：要映射到 adapter 的 active skills。
- `local.private_dir`：本机私有目录，用于项目路径、非敏感本地偏好和 skill 本地补充。

高级配置未来可以放入 `advanced` 对象，但默认不应要求普通用户编辑。

配置校验必须满足：

- `memoryos.root` 必填，指向 Lite 包根目录。
- 至少一个 adapter 的 `enabled` 为 `true`。
- 启用 Codex 时，`codex.user_agents` 和 `codex.skills_dir` 必填。
- 启用 Claude 时，`claude.user_claude` 和 `claude.skills_dir` 必填。
- `claude.install_hook = true` 时，`claude.settings_json` 必填；否则只跳过 hook，不阻断 Claude 主入口初始化。
- `skills.active` 至少包含一个 skill。
- Lite MVP 只支持 Windows PowerShell；跨平台支持是后续方向，不进入第一版目标。

## Path Resolution Rule

Lite 版所有脚本、模板、hook、adapter 入口、skill junction 和验证逻辑都必须从 `memoryos.config.json` 解析路径，不能写死维护者或用户安装路径。

路径来源规则：

- Lite 包根目录来自 `memoryos.root`。
- 黑盒内部目录由 `memoryos.root` 派生，例如 `${memoryos.root}\.memoryos\...`。
- Codex 用户入口来自 `codex.user_agents`。
- Codex skill discovery 目录来自 `codex.skills_dir`。
- Claude 用户入口来自 `claude.user_claude`。
- Claude settings 路径来自 `claude.settings_json`。
- Claude skill discovery 目录来自 `claude.skills_dir`。
- 本机私有目录来自 `local.private_dir`。
- active skill 列表来自 `skills.active`。

禁止写法：

```text
C:\Users\btf\AI-MemoryOS\...
C:\Users\btf\.codex\...
C:\Users\btf\.claude\...
D:\ai-memoryos-lite\...
```

允许写法：

```text
${memoryos.root}\.memoryos\adapters\codex\bootstrap.md     # template/input only
${memoryos.root}\.memoryos\adapters\claude\CLAUDE.md       # template/input only
${codex.user_agents}
${claude.settings_json}
${local.private_dir}
```

说明文档可以展示示例路径，但必须明确它们只是示例值；实际生成内容必须使用配置文件解析后的路径。

重要边界：adapter 用户入口和 Claude hook command 本身不能动态读取 `memoryos.config.json`。它们最终只能写入安装脚本解析配置后得到的固定绝对路径。因此，如果用户移动 Lite 包目录或修改关键路径，应先修改 `memoryos.config.json`，再运行 `.\install.ps1 -Check` 查看漂移，最后运行 `.\install.ps1` 按当前配置更新所有 Lite 托管块、hook command、skill junction 和 manifest。`memoryos.config.json` 是安装脚本的输入源，不是已安装 adapter 入口的运行时动态依赖。

生成目标中不允许残留未解析占位符，例如 `${memoryos.root}`、`${codex.user_agents}` 或 `${claude.settings_json}`。`validate` 应扫描用户入口、hook command 和 adapter bootstrap / gate，发现占位符残留时报告失败。

## Runtime Access Boundary

Lite 安装脚本只能保证路径配置、文件生成和用户入口提示词写入正确，不能绕过 Codex / Claude 的运行时沙盒、workspace roots、trusted project 或文件访问限制。

如果模型运行时无法读取 `${memoryos.root}` 下的 `.memoryos/` 文件，Lite 版应在说明文档中提示用户按对应工具的授权方式处理，例如把 Lite 包放入可访问工作区、调整 trusted workspace，或按工具要求增加可读目录。`.\install.ps1 -Check` 可以检查文件存在和配置完整，但不能保证模型在所有沙盒策略下都能实际读取该路径。

## Public Script Interface

Lite 版只暴露一个主要脚本：`install.ps1`。

推荐命令：

```powershell
.\install.ps1
.\install.ps1 -Check
.\install.ps1 -Uninstall
```

命令语义：

- `.\install.ps1`：读取配置并执行安装或幂等更新；Lite 包移动或配置变化后，也用这个命令更新已有 Lite 托管内容。
- `.\install.ps1 -Check`：只检查，不修改文件。
- `.\install.ps1 -Uninstall`：只移除 Lite 托管块、Lite hook 和 Lite skill junction，不删除用户原文件。

`install.ps1` 内部可以调用 `.memoryos/tools/*`，但用户不需要直接运行内部脚本。

## Installer Execution Flow

`install.ps1` 的执行顺序建议为：

```text
1. 读取 memoryos.config.json
2. 解析用户请求参数：Check / Uninstall
3. 检查 memoryos.root 和 .memoryos/ 是否存在
4. 初始化 local.private_dir
5. 根据配置筛选要处理的 adapter
6. 渲染 adapter bootstrap / gate / hook 脚本
7. 同步 active skills 到 adapter skill 目录
8. 创建或更新 skill junction
9. 追加或更新 Codex AGENTS.md 托管块
10. 追加或更新 Claude CLAUDE.md 托管块
11. 合并 Claude settings.json hook
12. 记录 install-state manifest
13. 运行 validate
14. 输出处理结果和下一步提示
```

内部脚本建议职责：

```text
install.ps1
  -> .memoryos/tools/install-core.ps1
       -> render-adapters.ps1
       -> sync-skills.ps1
       -> patch-user-entry.ps1
       -> patch-claude-hook.ps1
       -> validate.ps1
```

## Adapter Gating

脚本不能假设用户同时拥有 Codex 和 Claude。每个 adapter 都必须独立判断。

Codex 执行条件：

```text
codex.enabled = true
codex.user_agents 非空
codex.skills_dir 非空
```

Codex 跳过条件：

```text
codex.enabled = false
或 codex.user_agents 为空
或 codex.skills_dir 为空
```

Claude 执行条件：

```text
claude.enabled = true
claude.user_claude 非空
claude.skills_dir 非空
```

Claude hook 执行条件：

```text
claude.enabled = true
claude.install_hook = true
claude.settings_json 非空
```

Claude hook 跳过不应阻断 Claude 主入口初始化。例如：`claude.user_claude` 和 `claude.skills_dir` 已配置，但 `claude.settings_json` 为空时，应只跳过 hook，并提示用户 hook 未安装。

推荐输出示例：

```text
Codex: enabled, configured, installed.
Claude: enabled, configured, installed.
Claude hook: skipped, settings_json is empty.
```

或：

```text
Codex: skipped, enabled=false.
Claude: skipped, user_claude is empty.
```

## Adapter User Entry Patching

Lite 版必须能修改适配器入口提示词，让模型知道去哪里读取 OS 文件。

但修改策略应尽量保守：默认只追加托管块，不整文件覆盖。

托管块应放在目标文件最开头，而不是文件末尾。这样即使用户原文件中已有其他提示词，Lite 入口仍优先出现。托管块之后的用户原内容仍保留，但应明确告诉模型：后续用户原内容只作为个人偏好，不得覆盖 Lite 入口路径、读取顺序和安全边界。

托管块格式：

```md
<!-- AI-MEMORYOS-LITE:BEGIN -->
本托管块是 AI Memory OS Lite 的入口指示。先按本托管块读取 Lite bootstrap。
本托管块之后的原有内容只作为用户个人偏好，不得覆盖 Lite 入口路径、读取顺序和安全边界。

每个用户输入先读取：

<resolved-codex-bootstrap-absolute-path>

该文件负责判断是否需要读取完整 gate：

<resolved-codex-gate-absolute-path>

如果 bootstrap 读取失败，按普通模型任务处理。
项目本地 AGENTS.md、CLAUDE.md、README、代码事实优先。
<!-- AI-MEMORYOS-LITE:END -->
```

`<resolved-...>` 只表示说明文档中的占位。实际写入 `AGENTS.md` 或 `CLAUDE.md` 时，必须是 `install.ps1` 根据 `memoryos.config.json` 解析出的绝对路径，不能保留占位符。

写入规则：

- 目标文件不存在：创建文件，只写 Lite 托管块。
- 目标文件存在但没有托管块：把 Lite 托管块插入到文件最开头，用户原内容整体后移。
- 目标文件存在且已有托管块：只替换托管块中间内容。
- 托管块外的用户原内容完全不动。
- 如果检测到旧版 Lite 托管块，也应识别并更新为当前托管块。
- 如果检测到明显冲突的其他 Memory OS / bootstrap 入口，不自动删除；只报告冲突并提示用户人工确认。
- 每次实际写入前，在同目录创建备份文件。
- `-Check` 模式只报告状态，不写入。
- `-Uninstall` 模式只移除托管块，不删除用户文件。

备份文件示例：

```text
AGENTS.md.bak.20260623-153000
CLAUDE.md.bak.20260623-153000
settings.json.bak.20260623-153000
```

## Codex Initialization

Codex 初始化应完成：

```text
1. 渲染 .memoryos/adapters/codex/bootstrap.md
2. 渲染 .memoryos/adapters/codex/gate.md
3. 渲染 .memoryos/adapters/codex/skills/<skill>/SKILL.md
4. 创建或更新 codex.skills_dir 下的 skill junction
5. 追加或更新 codex.user_agents 中的 Lite 托管块
```

Codex 用户入口托管块应指向：

```text
.memoryos/adapters/codex/bootstrap.md
.memoryos/adapters/codex/gate.md
```

Codex 不应要求 MCP、CodeGraph 或 Obsidian。

## Claude Initialization

Claude 初始化应完成：

```text
1. 渲染 .memoryos/adapters/claude/bootstrap.md
2. 渲染 .memoryos/adapters/claude/CLAUDE.md
3. 渲染 .memoryos/adapters/claude/skills/<skill>/SKILL.md
4. 创建或更新 claude.skills_dir 下的 skill junction
5. 追加或更新 claude.user_claude 中的 Lite 托管块
6. 在 claude.install_hook=true 时合并 settings_json hook
```

Claude 用户入口托管块应指向：

```text
.memoryos/adapters/claude/bootstrap.md
.memoryos/adapters/claude/CLAUDE.md
```

Claude hook 是增强项，用于提醒 Claude 每轮先读 bootstrap。它不替代用户级 `CLAUDE.md`，也不复制完整 gate 内容。

## Claude Hook

Lite 版应保留一个简化的 Claude `UserPromptSubmit` hook 脚本：

```text
.memoryos/tools/inject-bootstrap-reminder.ps1
```

该脚本只输出一行提醒：

```text
[强制] 本轮第一个工具调用必须先 Read <resolved-claude-bootstrap-absolute-path>，再按 bootstrap 判断是否读取 full gate。
```

hook 注册应合并到 `claude.settings_json`：

```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "powershell.exe -NoProfile -ExecutionPolicy Bypass -File \"<resolved-hook-script-absolute-path>\""
          }
        ]
      }
    ]
  }
}
```

`<resolved-hook-script-absolute-path>` 只表示说明文档中的占位。实际写入 `settings.json` 的 hook command 必须是解析后的绝对路径。

合并规则：

- `settings.json` 不存在：创建最小 JSON。
- `settings.json` 存在且 JSON 合法：只合并 Lite hook。
- 已有其他 hooks：保留。
- 已有 Lite hook：更新 command 路径。
- JSON 解析失败：不写入，输出错误和手动修复提示。
- `-Uninstall`：只移除 Lite hook，不删除其他 hooks。
- 不输出、总结或复制 `settings.json` 中与 auth、provider、account、plugin 或 UI state 相关的原内容。
- 写入 `settings.json` 时使用备份文件和临时文件替换，避免写到一半损坏 JSON。
- PowerShell 写回 JSON 时必须设置足够 `Depth`，避免嵌套配置被截断。

hook 也必须带 Lite 标记。推荐在 hook command 或相邻 manifest 中记录 `AI-MEMORYOS-LITE` 标识，方便更新和卸载时精准识别。

## Skill Mapping

Lite 版仍需要 skill 映射脚本，因为 active skill 要从共享 `SKILL_SPEC.md` 渲染到各 adapter 的 `SKILL.md`。但 Lite 版只使用当前发布包内置的 active skills，不提供 skill 维护、晋升、评估或 changelog 功能。

保留：

```text
.memoryos/skills/registry.json
.memoryos/skills/<skill>/SKILL_SPEC.md
.memoryos/templates/skill.md.tmpl
.memoryos/tools/sync-skills.ps1
```

`sync-skills.ps1` 职责：

- 读取 `memoryos.config.json` 中的 `skills.active`。
- 读取 `.memoryos/skills/registry.json`。
- 校验 active skill 是否存在。
- 用 adapter skill template 渲染 `SKILL.md`。
- 同步 skill references。
- 为 Codex / Claude 分别创建或更新 skill junction。
- 支持 `-Check`。
- 支持 adapter gating，只处理已启用且配置完整的 adapter。
- 不生成 `skills.active` 之外的 skill。
- 已由 Lite 管理但不再 active 的 skill junction 应标记为 stale；默认不删除，可在 `-Prune` 或 `-Uninstall` 中清理。

Lite 版不需要完整仓库中的 proposal-promotion、skill changelog、dashboard skill 页面或 eval companion。

## Validation

Lite 版 `validate` 只验证使用链路，不验证维护链路。

`.\install.ps1 -Check` 或内部 `.memoryos/tools/validate.ps1` 应检查：

- `memoryos.config.json` 存在且可解析。
- `memoryos.root`、至少一个启用 adapter、启用 adapter 的用户入口和 `skills_dir`、`skills.active` 满足必填规则。
- `.memoryos/adapters/<adapter>/bootstrap.md` 存在。
- `.memoryos/adapters/<adapter>/gate.md` 或 `CLAUDE.md` 存在。
- 启用的 adapter 用户入口文件存在，或目标目录可创建。
- 用户入口文件中存在 Lite 托管块。
- 用户入口托管块中的 bootstrap / gate 路径等于当前 `memoryos.config.json` 派生出的绝对路径。
- Claude 启用 hook 时，`settings.json` 中存在 Lite hook，且 hook command 等于当前配置派生出的绝对路径。
- active skill 已渲染到 adapter skill 目录。
- skill junction 指向当前配置派生出的 Lite adapter skill 目录。
- `install-state.json` 中记录的 root / config path 与当前配置一致。
- 生成目标中不存在 `${...}` 这类未解析配置占位符。
- `router/intent-map.md`、`router/domain-map.md`、`router/workflow-map.md`、`router/skill-map.md` 存在。
- 常用 workflows 存在。

不检查：

- proposals。
- accepted / rejected。
- logs。
- dashboard。
- Obsidian。
- MCP。
- CodeGraph。
- evals。
- self-optimize。
- governance promotion flow。

## Managed Markers And Manifest

Lite 版必须同时使用文本标记和 manifest 追踪外部写入，避免卸载或更新时误删用户自己的内容。

所有写到 Lite 包目录以外的内容都必须记录，包括：

- `codex.user_agents` 中插入或更新的托管块。
- `claude.user_claude` 中插入或更新的托管块。
- `claude.settings_json` 中插入或更新的 Lite hook。
- `codex.skills_dir` 中创建的 skill junction。
- `claude.skills_dir` 中创建的 skill junction。
- 写入前创建的备份文件。

推荐 manifest 路径：

```text
${memoryos.root}\.memoryos\install-state.json
```

manifest 至少记录：

```json
{
  "schema": 1,
  "installed_at": "2026-06-23T00:00:00Z",
  "memoryos_root": "D:\\ai-memoryos-lite",
  "config_path": "D:\\ai-memoryos-lite\\memoryos.config.json",
  "managed_files": [
    {
      "path": "C:\\Users\\you\\.codex\\AGENTS.md",
      "kind": "managed-block",
      "begin_marker": "<!-- AI-MEMORYOS-LITE:BEGIN -->",
      "end_marker": "<!-- AI-MEMORYOS-LITE:END -->",
      "backup": "C:\\Users\\you\\.codex\\AGENTS.md.bak.20260623-153000"
    }
  ],
  "managed_hooks": [
    {
      "settings_json": "C:\\Users\\you\\.claude\\settings.json",
      "id": "AI-MEMORYOS-LITE",
      "command_contains": "inject-bootstrap-reminder.ps1"
    }
  ],
  "managed_junctions": [
    {
      "path": "C:\\Users\\you\\.codex\\skills\\pr-review",
      "target": "D:\\ai-memoryos-lite\\.memoryos\\adapters\\codex\\skills\\pr-review"
    }
  ]
}
```

卸载或更新时必须同时满足：

- 目标记录存在于 manifest。
- 目标文件或 junction 仍带 Lite 标记，或 junction target 仍指向当前 Lite root。
- 对用户文件只移除 Lite 托管块或 Lite hook，不删除 marker 外内容。

如果 manifest 缺失，卸载脚本不应按文件名猜测删除。它只能进入保守模式：扫描并报告可能的 Lite 标记，要求用户确认或手动处理。

## Uninstall And Rollback

Lite 版必须支持低风险卸载。

`.\install.ps1 -Uninstall` 应执行：

- 移除 `codex.user_agents` 中的 Lite 托管块。
- 移除 `claude.user_claude` 中的 Lite 托管块。
- 移除 `claude.settings_json` 中的 Lite hook。
- 移除 manifest 中记录且 target 仍指向当前 Lite root 的 skill junction。
- 保留用户原文件。
- 保留备份文件。
- 默认不删除 `.memoryos/`、`private/` 或用户配置文件。
- manifest 缺失或标记不匹配时，不执行删除，只报告需要人工确认的项目。

如需删除 Lite 包目录，应由用户手动删除，不由卸载脚本自动递归删除。

## Documentation Requirements

Lite 版必须包含用户说明，至少覆盖：

- 这个包解决什么问题。
- 需要安装或已有 Codex / Claude 中的哪一个。
- 当前 MVP 只支持 Windows PowerShell。
- 如何编辑 `memoryos.config.json`。
- 只配置 Codex 的示例。
- 只配置 Claude 的示例。
- 同时配置 Codex 和 Claude 的示例。
- 如何运行 `.\install.ps1`。
- `-Check` 和 `-Uninstall` 的作用。
- 脚本会修改哪些文件。
- 脚本如何保护用户已有内容。
- 如何确认安装成功。
- 如何卸载。
- Lite 包移动目录后，需要修改 `memoryos.config.json`，运行 `.\install.ps1 -Check` 查看哪些路径过期，再运行 `.\install.ps1` 按当前配置更新 Lite 托管内容；不需要单独的 repair 脚本。
- 沙盒或 workspace 权限可能阻止模型读取 Lite 文件，需按对应工具授权方式处理。
- 哪些能力不包含在 Lite 版中。

README 应优先面向普通用户，不应把完整仓库维护逻辑放在第一屏。

## Internal Black-Box Principle

`.memoryos/` 是实现细节，但不是安全黑箱。高级用户可以查看它；普通用户不需要理解它。

设计原则：

- 黑盒内部可以保留必要的 route / workflow / skill 结构。
- 根目录只暴露配置、安装脚本和说明。
- 任何内部脚本都不应要求用户直接运行。
- 内部路径全部由 `memoryos.config.json` 或 `install.ps1` 派生。
- 内部模板不能写死维护者本机路径。
- 内部脚本不能把示例路径当成默认真实路径；路径缺失时应跳过对应 adapter 并提示配置缺失。
- Lite 版生成的用户入口提示词只指向 bootstrap，不复制完整 gate。

## Non-Goals

Lite 版不包含：

- MCP server。
- Obsidian dashboard。
- CodeGraph。
- proposal 审核和晋升。
- accepted / rejected 历史库。
- weekly audit。
- self-optimize。
- router / skill evals。
- changelog companion。
- Memory OS 维护治理流程。
- 自动写入长期记忆。
- token、账号、密钥、cookie 或任何敏感配置管理。

Lite 版不负责替代完整维护仓库。完整仓库仍用于维护规则、审查 proposal、改进路由、沉淀经验、生成 Lite 发行包。

## Suggested Migration Path

未来实施时，不应直接重构当前仓库，而应分阶段推进。

第一阶段：导出原型。

```text
dist/lite/
  memoryos.config.json
  install.ps1
  .memoryos/
```

从完整仓库复制最小文件集合，手动验证一个 Codex-only 配置和一个 Claude-only 配置。

第二阶段：脚本化导出。

新增完整仓库内部脚本：

```text
tools/export-lite.ps1
```

它负责从完整仓库生成 `dist/lite/`，避免长期维护两套源文件。

第三阶段：安装器收敛。

完成 `install.ps1` 的幂等、追加式 patch、hook 合并、skill junction、`-Check`、`-Uninstall`。

第四阶段：文档收敛。

补齐 `README.md`、`INSTALL.md` 和配置示例，让普通用户能按说明完成初始化。

第五阶段：分发形态选择。

可选形态：

- 单独 GitHub 仓库：适合公开给其他用户下载。
- 完整仓库 release artifact：适合由维护仓库自动导出 zip。
- 当前仓库 `lite` 分支：适合早期试运行，但长期可能增加同步成本。

推荐最终形态是：完整仓库继续作为维护版，Lite 版作为单独 repo 或 release artifact，由 `tools/export-lite.ps1` 生成。

## Safety And Sensitivity Check

本方向说明不包含 token、账号、密钥、cookie、客户数据、生产日志或未脱敏私有项目代码。

Lite 版未来实施时必须遵守：

- 不把用户本机 `settings.json`、账号配置、auth 状态或 provider 配置复制进 Lite 仓库。
- 不整文件覆盖用户 `AGENTS.md`、`CLAUDE.md` 或 `settings.json`。
- 不读取或总结 `private/secrets/`。
- 不把 private overlay 内容写入公共仓库、commit message 或文档。
- 默认只追加或更新 Lite 托管块。
- 所有写入前创建备份。
- 支持 `-Check` 和 `-Uninstall`。

## Future Trigger Conditions

可以在以下条件满足时拆成具体 proposal 或实施任务：

- 当前完整仓库的 adapter bootstrap / gate 已稳定。
- Codex / Claude 的用户入口和 skill discovery 机制已稳定。
- active skills 的最小集合已经明确。
- 有至少一个非维护者用户需要下载使用。
- 本机路径、adapter 配置和技能映射反复成为接入障碍。
- 维护者希望把完整治理系统和普通使用包分离。
