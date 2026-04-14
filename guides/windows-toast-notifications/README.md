# Windows Toast Notifications for Claude Code

Native Windows toast notifications for Claude Code hook events. Shows which project triggered the notification so you can find the right VS Code window when running multiple sessions.

## What You Get

| Event | Title | Message |
|-------|-------|---------|
| Response finished | Claude Code (my-project) | Response finished |
| Background task done | Claude Code (my-project) | *notification message* |
| Permission needed | Claude Code (my-project) | Requesting permission: Bash |

## Requirements

- Windows 10+
- PowerShell 5.1+ (ships with Windows)
- No external dependencies

## Install

### Step 1: Copy the script

Copy `claude-hook-toast.ps1` to `~/.claude/`:

```powershell
Copy-Item claude-hook-toast.ps1 "$env:USERPROFILE\.claude\claude-hook-toast.ps1"
```

### Step 2: Add hooks to settings.json

Open `~/.claude/settings.json` and add the following entries to the `hooks` object.

Pick the events you want notifications for:

#### Stop (response finished)

```json
"Stop": [
  {
    "hooks": [
      {
        "type": "command",
        "command": "powershell -ExecutionPolicy Bypass -File \"$USERPROFILE\\.claude\\claude-hook-toast.ps1\""
      }
    ]
  }
]
```

#### Notification (background tasks, idle prompts)

```json
"Notification": [
  {
    "hooks": [
      {
        "type": "command",
        "command": "powershell -ExecutionPolicy Bypass -File \"$USERPROFILE\\.claude\\claude-hook-toast.ps1\""
      }
    ]
  }
]
```

#### PermissionRequest (tool approval needed)

```json
"PermissionRequest": [
  {
    "hooks": [
      {
        "type": "command",
        "command": "powershell -ExecutionPolicy Bypass -File \"$USERPROFILE\\.claude\\claude-hook-toast.ps1\""
      }
    ]
  }
]
```

### All three at once

If you want all events, merge them into your existing `hooks` object:

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "powershell -ExecutionPolicy Bypass -File \"$USERPROFILE\\.claude\\claude-hook-toast.ps1\""
          }
        ]
      }
    ],
    "Notification": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "powershell -ExecutionPolicy Bypass -File \"$USERPROFILE\\.claude\\claude-hook-toast.ps1\""
          }
        ]
      }
    ],
    "PermissionRequest": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "powershell -ExecutionPolicy Bypass -File \"$USERPROFILE\\.claude\\claude-hook-toast.ps1\""
          }
        ]
      }
    ]
  }
}
```

## How It Works

Claude Code pipes a JSON payload to hook commands via stdin. The script:

1. Reads the JSON from stdin
2. Extracts `hook_event_name`, `cwd`, `tool_name`, and `message`
3. Maps the event to a human-readable message
4. Uses the folder name from `cwd` as the toast title (e.g. "Claude Code (my-project)")
5. Sends a native Windows toast notification via the WinRT API

### Why `$USERPROFILE` and not `%USERPROFILE%`?

Claude Code runs hook commands through **bash** (even on Windows). Bash doesn't expand `%VAR%` syntax — that's `cmd.exe`. Instead, bash expands `$USERPROFILE` from the inherited Windows environment variables. Using `-File` (not `-Command`) ensures PowerShell receives stdin correctly for `$input` to work.

## Verify

Run a quick test after install:

```powershell
echo '{"hook_event_name":"Stop","cwd":"C:\\Users\\You\\my-project"}' | powershell -ExecutionPolicy Bypass -File "$env:USERPROFILE\.claude\claude-hook-toast.ps1"
```

You should see a toast: **Claude Code (my-project)** / "Response finished".

## Troubleshooting

| Problem | Cause | Fix |
|---------|-------|-----|
| Toast shows "Claude Code" with no message | Using `-Command` instead of `-File` | Stdin doesn't pipe through `-Command "& script.ps1"`. Use `-File` |
| Path error: `%USERPROFILE%.claude...` | Using `%VAR%` syntax | Bash doesn't expand `%VAR%`. Use `$USERPROFILE` instead |
| Path error: `:USERPROFILE\...` | `$` was eaten by bash | In JSON, escape as `\\$` so bash passes literal `$` to PowerShell. But with `-File`, bash expands `$USERPROFILE` itself — so no escaping needed |
| No toast appears | PowerShell execution policy | Run `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned` or use the `-ExecutionPolicy Bypass` flag (already included) |
| Toast appears but notification center doesn't show it | Windows notification settings | Check Settings > System > Notifications and ensure PowerShell notifications are enabled |
