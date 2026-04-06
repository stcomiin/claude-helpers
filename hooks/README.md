# Hooks

Shared Claude Code hook configurations for the team. Each hook is documented with a copy-paste JSON snippet — add it directly to your `~/.claude/settings.json` under the appropriate event.

## Available Hooks

### Destructive Command Guard

Intercepts Bash tool calls containing destructive delete commands (`rm`, `rmdir`, `shred`, `unlink`, `find -delete`) and forces a confirmation prompt before execution.

**Event:** `PreToolUse` | **Matcher:** `Bash`

#### Install

Add this entry to the `PreToolUse` array in `~/.claude/settings.json`:

```json
{
  "matcher": "Bash",
  "hooks": [
    {
      "type": "command",
      "command": "jq -r '.tool_input.command // \"\"' | grep -qE '(^|[^-])\\brm\\b|\\b(rmdir|shred|unlink)\\b|-delete' && printf '{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"permissionDecision\":\"ask\",\"permissionDecisionReason\":\"DESTRUCTIVE ACTION: delete command detected (rm/rmdir/shred/unlink/-delete). Please review and confirm.\"}}' || true",
      "timeout": 5,
      "statusMessage": "Checking for destructive delete commands..."
    }
  ]
}
```

#### Requires

- `jq` (for parsing tool input JSON from stdin)

## Adding Hooks

1. Document the hook in this README with the event type, matcher, and copy-paste JSON snippet
2. Open a PR for team review
