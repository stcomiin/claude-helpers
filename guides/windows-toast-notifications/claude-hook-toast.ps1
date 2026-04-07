# Claude Code Windows Toast Notifications
#
# Sends native Windows toast notifications for Claude Code hook events.
# Shows the project folder name in the title so you can identify which
# session needs attention when running multiple instances.
#
# Supported events:
#   Stop              → "Response finished"
#   Notification      → The notification message from Claude Code
#   PermissionRequest → "Requesting permission: <tool_name>"
#   SessionStart      → "Session started"
#   SessionEnd        → "Session completed"
#
# Requires: Windows 10+, PowerShell 5.1+
# No external dependencies.

try { $json = ($input | Out-String) | ConvertFrom-Json } catch { exit }
if (-not $json) { exit }
$hookEvent = $json.hook_event_name
$folder = if ($json.cwd) { Split-Path $json.cwd -Leaf } else { "unknown" }
$message = switch ($hookEvent) {
    "SessionStart"        { "Session started" }
    "SessionEnd"          { "Session completed" }
    "Stop"                { "Response finished" }
    "Notification"        { if ($json.message) { $json.message } else { "Notification" } }
    "PermissionRequest"   { "Requesting permission: $($json.tool_name)" }
    default               { if ($json.message) { "$hookEvent : $($json.message)" } else { $hookEvent } }
}

# Windows Toast Notification
$template = [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime]::GetTemplateContent(
    [Windows.UI.Notifications.ToastTemplateType, Windows.UI.Notifications, ContentType = WindowsRuntime]::ToastText02
)
$template.SelectSingleNode('//text[@id="1"]').InnerText = "Claude Code ($folder)"
$template.SelectSingleNode('//text[@id="2"]').InnerText = $message
$appId = '{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\WindowsPowerShell\v1.0\powershell.exe'
$toast = [Windows.UI.Notifications.ToastNotification, Windows.UI.Notifications, ContentType = WindowsRuntime]::new($template)
[Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($appId).Show($toast)
