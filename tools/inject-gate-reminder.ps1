# inject-gate-reminder.ps1
# Claude Code UserPromptSubmit hook: 注入一行强提醒,
# 强制 Claude 把读取 bootstrap.md 作为本轮第一个工具调用,
# 由 bootstrap.md 自身的判定逻辑决定是否进一步读 full gate。
#
# 输出会被 harness 包成 <system-reminder> 附加到当前这一轮的上下文。
# 真正的策略规则在 bootstrap.md / gate 文件本身,本脚本不复制规则内容,只负责提醒去读。
#
# 调用位置: C:\Users\btf\.claude\settings.json  hooks.UserPromptSubmit
# 无参数,无副作用,仅 stdout 输出一行。

# 强制 UTF-8 输出,避免被 harness 按 GBK 误解码出现乱码。
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding           = [System.Text.Encoding]::UTF8

Write-Output '[强制] 本轮第一个工具调用必须是 Read C:\Users\btf\AI-MemoryOS\adapters\claude\bootstrap.md,先读取 bootstrap,再按其内部规则判定是否需要读 full gate,然后按 L0-L3 分级决定后续动作。读 bootstrap 之前不允许并行调用任何任务工具。'
