# claude-helpers

Shared Claude Code plugin for multi-perspective code review — skills, hooks, and related configurations for dev teams.

## Structure

```
claude-helpers/
├── .claude-plugin/
│   ├── plugin.json                        # Plugin manifest
│   └── marketplace.json                   # Self-hosted marketplace catalog
├── skills/                                # Claude Code skills (SKILL.md convention)
│   ├── team-code-review/                  #   6-stage multi-model code review pipeline
│   │   ├── SKILL.md                       #     Skill definition (orchestration logic)
│   │   └── README.md                      #     Prerequisites, setup, and usage guide
│   ├── devils-advocate/                   #   Thin wrapper → vendor/claude-code-skills
│   │   └── SKILL.md
│   └── bmad-code-review/                  #   Thin wrapper → vendor/BMAD-METHOD
│       └── SKILL.md
├── hooks/                                 # Shared Claude Code hooks
│   └── README.md                          #   Copy-paste JSON snippets and hook index
├── vendor/                                # Git submodules — external skill repos (do NOT modify)
│   ├── claude-code-skills/                #   notmanas/claude-code-skills (devils-advocate)
│   └── BMAD-METHOD/                       #   bmad-code-org/BMAD-METHOD (bmad-code-review)
└── README.md                              # This file
```

## Skills

| Skill | Origin | Description | Invoke |
|-------|--------|-------------|--------|
| [team-code-review](skills/team-code-review/) | Internal | 6-stage multi-model code review pipeline — agent debate, Codex/GPT-5.4 cross-model review, CC-native review, BMAD adversarial review, consolidation, and Devil's Advocate challenge | `/claude-helpers:team-code-review` |
| [devils-advocate](skills/devils-advocate/SKILL.md) | Vendor | Challenges AI-generated plans, code, designs, and decisions using pre-mortem analysis, inversion thinking, and Socratic questioning | `/claude-helpers:devils-advocate` |
| [bmad-code-review](skills/bmad-code-review/SKILL.md) | Vendor | Adversarial code review using parallel review layers (Blind Hunter, Edge Case Hunter, Acceptance Auditor) with structured triage | `/claude-helpers:bmad-code-review` |

## Dependency Map

Skills in this repo may depend on external plugins, project-scoped skills, or built-in Claude Code features. This table tracks origin and ownership so the team knows where to look for updates or file issues.

| Skill / Dependency | Origin | Source | Maintained By |
|--------------------|--------|--------|---------------|
| team-code-review | Internal | This repo | Our team |
| bmad-code-review | Submodule | [bmad-code-org/BMAD-METHOD](https://github.com/bmad-code-org/BMAD-METHOD) → `vendor/BMAD-METHOD/` | BMAD project |
| devils-advocate | Submodule | [notmanas/claude-code-skills](https://github.com/notmanas/claude-code-skills) → `vendor/claude-code-skills/` | Community |
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

This repo is both a **plugin** and a self-hosted **marketplace**. Install in two steps: add the marketplace, then install the plugin from it.

### 1. Add the marketplace

```bash
/plugin marketplace add <your-org>/claude-helpers
```

This registers the repo as a plugin source. For non-GitHub hosts, use the full URL:

```bash
/plugin marketplace add https://gitlab.com/<your-org>/claude-helpers.git
```

### 2. Install the plugin

```bash
/plugin install claude-helpers@claude-helpers
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
        "repo": "<your-org>/claude-helpers"
      }
    }
  }
}
```

When team members trust the project folder, Claude Code prompts them to install the marketplace and its plugins.

### Update

Refresh the marketplace listing and update installed plugins:

```bash
/plugin marketplace update claude-helpers
```

Or enable auto-updates via `/plugin` → **Marketplaces** → select `claude-helpers` → **Enable auto-update**.

### Local development

To test the plugin without installing from the marketplace:

```bash
git clone --recursive https://github.com/<your-org>/claude-helpers.git
claude --plugin-dir ./claude-helpers
```

Use `/reload-plugins` to pick up changes without restarting.

### Verify

After installing, confirm skills are visible:

```
/claude-helpers:team-code-review
/claude-helpers:devils-advocate
/claude-helpers:bmad-code-review
```

The thin wrappers for vendor skills reference the submodule files via relative paths, so everything works without extra configuration.

**Hooks** are not auto-installed by the plugin. See [hooks/README.md](hooks/) for manual configuration.

## Adding Resources

### Skills

1. Create a directory under `skills/` with your skill name (kebab-case)
2. Add a `SKILL.md` with YAML frontmatter (`name`, `description`) and the skill body
3. Add a `README.md` with prerequisites, setup instructions, and usage
4. Open a PR for team review

### Vendor Skills

To wrap an external skill from a git submodule:

1. Add the upstream repo as a submodule under `vendor/`
2. Create a thin wrapper directory under `skills/<skill-name>/`
3. Add a `SKILL.md` that copies the `name` and `description` from the vendor skill and references the vendor `SKILL.md` via relative path
4. Open a PR for team review

### Hooks

1. Create a script in `hooks/` (`.sh`, `.js`, or `.py`)
2. Include install instructions as a comment header
3. Add an entry to `hooks/README.md` and the root README hooks table
4. Open a PR for team review

## Official Marketplace

This plugin can also be submitted to the official Anthropic marketplace via [claude.ai/settings/plugins/submit](https://claude.ai/settings/plugins/submit). Once accepted, users could install with:

```bash
/plugin install claude-helpers@claude-plugins-official
```
