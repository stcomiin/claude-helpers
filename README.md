# claude-helpers

Shared Claude Code marketplace for multi-perspective code review — a curated collection of plugins for dev teams.

## Structure

```
claude-helpers/
├── .claude-plugin/
│   ├── plugin.json                        # Plugin manifest (claude-helpers plugin)
│   └── marketplace.json                   # Marketplace catalog (3 plugins)
├── skills/                                # Skills for the claude-helpers plugin
│   ├── team-code-review/                  #   6-stage multi-model code review pipeline
│   │   ├── SKILL.md                       #     Skill definition (orchestration logic)
│   │   └── README.md                      #     Prerequisites, setup, and usage guide
│   └── bmad-verify-story/                 #   Goal-backward story verification
│       ├── SKILL.md                       #     Entry point
│       ├── workflow.md                    #     10-step verification workflow
│       ├── templates/                     #     Verification report template
│       └── references/                    #     Stub/wiring detection patterns
├── hooks/                                 # Shared Claude Code hooks
│   └── README.md                          #   Copy-paste JSON snippets and hook index
└── README.md                              # This file
```

## Plugins

This marketplace distributes three plugins. The `claude-helpers` plugin is internal; the other two are curated from upstream repos via `strict: false` marketplace entries that cherry-pick specific skills.

| Plugin | Skills | Source | Install |
|--------|--------|--------|---------|
| claude-helpers | [team-code-review](skills/team-code-review/), [bmad-verify-story](skills/bmad-verify-story/) | Internal | `claude plugin install claude-helpers@claude-helpers` |
| bmad-review | bmad-code-review | [bmad-code-org/BMAD-METHOD](https://github.com/bmad-code-org/BMAD-METHOD) | `claude plugin install bmad-review@claude-helpers` |
| devils-advocate | devils-advocate | [notmanas/claude-code-skills](https://github.com/notmanas/claude-code-skills) | `claude plugin install devils-advocate@claude-helpers` |

### Skill Invocation

| Skill | Invoke |
|-------|--------|
| team-code-review | `/claude-helpers:team-code-review` |
| bmad-verify-story | `/claude-helpers:bmad-verify-story` |
| bmad-code-review | `/bmad-review:bmad-code-review` |
| devils-advocate | `/devils-advocate:devils-advocate` |

## Dependency Map

The team-code-review pipeline orchestrates skills from multiple plugins. This table tracks origin and ownership so the team knows where to look for updates or file issues.

| Skill / Dependency | Origin | Source | Maintained By |
|--------------------|--------|--------|---------------|
| team-code-review | Internal | This repo | Our team |
| bmad-code-review | Marketplace | [bmad-code-org/BMAD-METHOD](https://github.com/bmad-code-org/BMAD-METHOD) | BMAD project |
| devils-advocate | Marketplace | [notmanas/claude-code-skills](https://github.com/notmanas/claude-code-skills) | Community |
| simplify | Built-in | Ships with Claude Code | Anthropic |
| code-reviewer | Plugin | [affaan-m/everything-claude-code](https://github.com/affaan-m/everything-claude-code) | Community |
| python-reviewer | Plugin | [affaan-m/everything-claude-code](https://github.com/affaan-m/everything-claude-code) | Community |
| go-reviewer | Plugin | [affaan-m/everything-claude-code](https://github.com/affaan-m/everything-claude-code) | Community |
| codex-rescue | Plugin | [f5xc-salesdemos/codex-plugin-cc](https://github.com/f5xc-salesdemos/codex-plugin-cc) | Community |

## Hooks

| Hook | Event | Matcher | Description |
|------|-------|---------|-------------|
| Destructive Command Guard | `PreToolUse` | `Bash` | Flags destructive delete commands (`rm`, `rmdir`, `shred`, `unlink`, `-delete`) and prompts for confirmation |

See [hooks/README.md](hooks/) for install instructions.

## Installation

This repo is a self-hosted **marketplace** containing three plugins. Add the marketplace, then install the plugins.

### 1. Add the marketplace

```bash
claude plugin marketplace add stcomiin/claude-helpers
```

For non-GitHub hosts, use the full URL:

```bash
claude plugin marketplace add https://gitlab.com/<your-org>/claude-helpers.git
```

### 2. Install plugins

```bash
claude plugin install claude-helpers@claude-helpers
claude plugin install bmad-review@claude-helpers
claude plugin install devils-advocate@claude-helpers
```

The format is `plugin-name@marketplace-name`.

### Team auto-install

Add the marketplace to your project's `.claude/settings.json` so it auto-installs for all team members:

```jsonc
{
  "extraKnownMarketplaces": {
    "claude-helpers": {
      "source": {
        "source": "github",
        "repo": "stcomiin/claude-helpers"
      }
    }
  }
}
```

When team members trust the project folder, Claude Code prompts them to install the marketplace and its plugins.

### Update

Refresh the marketplace listing and update installed plugins:

```bash
claude plugin marketplace update claude-helpers
```

Or enable auto-updates via `/plugin` → **Marketplaces** → select `claude-helpers` → **Enable auto-update**.

### Local development

To test the claude-helpers plugin locally without installing from the marketplace:

```bash
git clone https://github.com/stcomiin/claude-helpers.git
claude --plugin-dir ./claude-helpers
```

Use `/reload-plugins` to pick up changes without restarting.

### Verify

After installing, confirm skills are visible:

```
/claude-helpers:team-code-review
/bmad-review:bmad-code-review
/devils-advocate:devils-advocate
```

**Hooks** are not auto-installed by the plugin. See [hooks/README.md](hooks/) for manual configuration.

## Migrating from v0 (additionalDirectories)

If you previously installed this repo via `additionalDirectories` in `~/.claude/settings.json`:

1. Remove the `additionalDirectories` entry pointing to this repo
2. Follow the [Installation](#installation) steps above to add the marketplace and install all three plugins
3. Update skill references — all names changed:

| Old | New |
|-----|-----|
| `/team-code-review` | `/claude-helpers:team-code-review` |
| `/bmad-code-review` | `/bmad-review:bmad-code-review` |
| `/devils-advocate` | `/devils-advocate:devils-advocate` |

## Adding Resources

### Skills

1. Create a directory under `skills/` with your skill name (kebab-case)
2. Add a `SKILL.md` with YAML frontmatter (`name`, `description`) and the skill body
3. Add a `README.md` with prerequisites, setup instructions, and usage
4. Open a PR for team review

### Vendor Skills

To curate an external skill from an upstream repo:

1. Add a plugin entry to `.claude-plugin/marketplace.json` with `strict: false`
2. Set the `source` to the upstream GitHub repo
3. Use the `skills` array to cherry-pick specific skill directories
4. Open a PR for team review

### Hooks

1. Create a script in `hooks/` (`.sh`, `.js`, or `.py`)
2. Include install instructions as a comment header
3. Add an entry to `hooks/README.md` and the root README hooks table
4. Open a PR for team review
