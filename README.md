# claude-helpers

Shared repository for common Claude Code resources used by our internal dev team — skills, plugins, and related configurations.

## Structure

```
claude-helpers/
├── .claude/
│   └── skills/                            # Claude Code skills (SKILL.md convention)
│       ├── team-code-review/              #   6-stage multi-model code review pipeline
│       │   ├── SKILL.md                   #     Skill definition (orchestration logic)
│       │   └── README.md                  #     Prerequisites, setup, and usage guide
│       ├── devils-advocate/               #   Thin wrapper → vendor/claude-code-skills
│       │   └── SKILL.md
│       └── bmad-code-review/              #   Thin wrapper → vendor/BMAD-METHOD
│           └── SKILL.md
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
| [team-code-review](.claude/skills/team-code-review/) | Internal | 6-stage multi-model code review pipeline — agent debate, Codex/GPT-5.4 cross-model review, CC-native review, BMAD adversarial review, consolidation, and Devil's Advocate challenge | `/team-code-review` |
| [devils-advocate](.claude/skills/devils-advocate/SKILL.md) | Vendor | Challenges AI-generated plans, code, designs, and decisions using pre-mortem analysis, inversion thinking, and Socratic questioning | `/devils-advocate` |
| [bmad-code-review](.claude/skills/bmad-code-review/SKILL.md) | Vendor | Adversarial code review using parallel review layers (Blind Hunter, Edge Case Hunter, Acceptance Auditor) with structured triage | `/bmad-code-review` |

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

## Setup

### Clone

```bash
git clone --recursive https://github.com/<org>/claude-helpers.git
```

The `--recursive` flag pulls the external skill repos into `vendor/` automatically.

If you already cloned without `--recursive`:

```bash
git submodule update --init --recursive
```

### Install skills

Claude Code auto-discovers `.claude/skills/` from additional directories. Add this repo as an additional directory to make all skills permanently available.

#### Option A: settings.json (recommended)

Add the repo path to `additionalDirectories` in `~/.claude/settings.json`:

```jsonc
{
  "permissions": {
    "additionalDirectories": [
      "/path/to/claude-helpers"
    ]
  }
}
```

This persists across sessions. Claude Code will auto-discover and live-reload all skills from `.claude/skills/` in this repo.

#### Option B: Per-session with `--add-dir`

If you prefer not to modify settings:

```bash
claude --add-dir /path/to/claude-helpers
```

Same skill discovery, but only lasts for the current session.

#### Verify

After installing, confirm skills are visible:

```
/team-code-review
/devils-advocate
/bmad-code-review
```

The thin wrappers for vendor skills reference the submodule files via relative paths, so everything works without extra configuration.

### Hooks

Hooks are standalone scripts — add them individually to your `~/.claude/settings.json` hooks config. See each hook's README entry for the exact JSON snippet.

## Adding Resources

### Skills

1. Create a directory under `.claude/skills/` with your skill name
2. Add a `SKILL.md` with YAML frontmatter (`name`, `description`) and the skill body
3. Add a `README.md` with prerequisites, setup instructions, and usage
4. Open a PR for team review

### Vendor Skills

To wrap an external skill from a git submodule:

1. Add the upstream repo as a submodule under `vendor/`
2. Create a thin wrapper directory under `.claude/skills/<skill-name>/`
3. Add a `SKILL.md` that copies the `name` and `description` from the vendor skill and references the vendor `SKILL.md` via relative path
4. Open a PR for team review

### Hooks

1. Create a script in `hooks/` (`.sh`, `.js`, or `.py`)
2. Include install instructions as a comment header
3. Add an entry to `hooks/README.md` and the root README hooks table
4. Open a PR for team review
