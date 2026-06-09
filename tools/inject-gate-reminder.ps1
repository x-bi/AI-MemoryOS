# inject-gate-reminder.ps1
# Claude Code UserPromptSubmit hook: 注入一行强提醒,
# 强制 Claude 把读取 gate 作为本轮第一个工具调用。
#
# 输出会被 harness 包成 <system-reminder> 附加到当前这一轮的上下文。
# 真正的策略规则在 gate 文件本身,本脚本不复制规则内容,只负责提醒去读。
#
# 调用位置: C:\Users\btf\.claude\settings.json  hooks.UserPromptSubmit
# 无参数,无副作用,仅 stdout 输出一行。

Write-Output '[强制] 本轮第一个工具调用必须是 Read C:\Users\btf\AI-MemoryOS\adapters\claude\CLAUDE.md,先读取该 gate,再按其 L0-L3 分级决定后续动作。'
