# tools/

本目录脚本启动命令速查。需要详细参数说明请直接看脚本头部 `param()` 块。

---

## self-optimize-scan.ps1

扫描 GitHub + Web 找同类项目的可借鉴点，让 Claude CLI 评估后生成中文报告到 `reports/`。

### 前置条件

- `claude` CLI 在 PATH
- `$env:GITHUB_TOKEN` 已设置（用户级环境变量，5000 req/hr 不会撞限）

验证：

```powershell
$env:GITHUB_TOKEN.Substring(0, 15)    # 应输出 github_pat_xxxx...
Get-Command claude                     # 应能找到
```

### 常用命令（直接复制）

```powershell
# 默认全自动（推荐 — 9 个自动推导关键词 + TopN 10 + WebSearch，约 1-3 分钟）
pwsh -NoProfile -File "C:\Users\btf\AI-MemoryOS\tools\self-optimize-scan.ps1"

# 小规模快速试跑（候选 3 个，省时省 token）
pwsh -NoProfile -File "C:\Users\btf\AI-MemoryOS\tools\self-optimize-scan.ps1" -TopN 3

# 启用对抗验证（候选 >10 时建议；多一轮 Claude 调用 ≈ token 2.5x）
pwsh -NoProfile -File "C:\Users\btf\AI-MemoryOS\tools\self-optimize-scan.ps1" -Verify

# 改小每批大小（候选多/输出易截断时把每批降到 2，更稳但慢）
pwsh -NoProfile -File "C:\Users\btf\AI-MemoryOS\tools\self-optimize-scan.ps1" -TopN 10 -BatchSize 2

# 最完整跑法：对抗验证 + 小分批（推荐日常使用）
pwsh -NoProfile -File "C:\Users\btf\AI-MemoryOS\tools\self-optimize-scan.ps1" -Verify -BatchSize 2

# 只组装 prompt 不调 Claude（调试用，零 token）
pwsh -NoProfile -File "C:\Users\btf\AI-MemoryOS\tools\self-optimize-scan.ps1" -DryRun

# 手填关键词，跳过自动推导
pwsh -NoProfile -File "C:\Users\btf\AI-MemoryOS\tools\self-optimize-scan.ps1" -Keywords "claude code memory,agent skill registry" -TopN 5

# 强制指定模型（默认跟随 claude CLI 当前配置）
pwsh -NoProfile -File "C:\Users\btf\AI-MemoryOS\tools\self-optimize-scan.ps1" -Model claude-opus-4-8
```

### 参数速查

| 参数              | 默认                       | 说明                                               |
| ----------------- | -------------------------- | -------------------------------------------------- |
| `-Root`           | `C:\Users\btf\AI-MemoryOS` | 项目根路径                                         |
| `-Keywords`       | 空 → 自动推导              | CSV 关键词，覆盖自动推导                           |
| `-TopN`           | 10                         | 去重后保留的 GitHub 候选数                         |
| `-BatchSize`      | 3                          | 每批送给 Claude 的候选数（避免单次输出过长被截断） |
| `-ReadmeBytes`    | 5120                       | 每份 README 截断上限                               |
| `-MaxPromptBytes` | 204800                     | 发给 claude 的 prompt 硬上限                       |
| `-Verify`         | 关                         | 启用 pass-2 对抗验证                               |
| `-DryRun`         | 关                         | 只组装 prompt 不调 claude                          |
| `-Model`          | 空 → claude CLI 默认       | 转发给 `claude --model`                            |

### 输出

- 报告：`reports/self-optimize-<yyyy-MM-dd-HHmm>.md`
- DryRun 预览：`reports/self-optimize-prompt-preview-<ts>.md`
- Claude 失败时：`reports/.last-claude-error.txt`

报告含：概览 / 候选清单表 / 详细借鉴点（含 effort+value+risks）/ 下一步建议 / 原始 JSON。

### 不会做的事

- 不会自动写 `proposals/pending/` 或 `proposals/future-directions/`
- 不会修改 `skills/registry.json` 或任何 adapter 配置
- 报告只读，所有借鉴点须人工评估后再走 `tools/new-proposal.ps1` 流程

### 建议节奏

每 1-2 周跑一次。GitHub 候选变化不快，频率更高没意义。

---

## 其他脚本（一句话索引）

| 脚本                     | 用途                                                      |
| ------------------------ | --------------------------------------------------------- |
| `new-proposal.ps1`       | 从模板创建新的 `proposals/pending/<date>-<title>.md`      |
| `sync-skills.ps1`        | 同步 `skills/registry.json` 到各 adapter 的 SKILL.md 副本 |
| `validate-memory-os.ps1` | 校验 Memory OS 文件结构与 frontmatter 完整性              |
| `validate-obsidian.ps1`  | 校验 Obsidian wikilink 与文件引用                         |
| `codegraph-project.ps1`  | 注册/启用/准备项目的 codegraph 索引                       |
| `codegraph-wrapper.ps1`  | codegraph MCP server 启动包装                             |

详细用法直接看脚本头部 `param()` 块或 `Get-Help <script>`。
