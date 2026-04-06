# claude-helpers

Shared repository for common Claude Code resources used by our internal dev team — skills, plugins, and related configurations.

## Folder Walkthrough

```
claude-helpers/
├── README.md                              # This file — repo overview and setup
├── hooks/                                 # Shared Claude Code hooks
│   └── README.md                          #   Copy-paste JSON snippets and hook index
├── skills/                                # Claude Code skills (SKILL.md convention)
│   └── team-code-review/                  # 6-stage multi-model code review pipeline
│       ├── SKILL.md                       #   Skill definition (orchestration logic)
│       └── README.md                      #   Prerequisites, setup, and usage guide
└── vendor/                                # Git submodules — external skill repos
    ├── claude-code-skills/                #   notmanas/claude-code-skills (devils-advocate)
    └── BMAD-METHOD/                       #   bmad-code-org/BMAD-METHOD (bmad-code-review)
```

## Skills

| Skill | Origin | Description | Invoke |
|-------|--------|-------------|--------|
| [team-code-review](skills/team-code-review/) | Internal | 6-stage multi-model code review pipeline — agent debate, Codex/GPT-5.4 cross-model review, CC-native review, BMAD adversarial review, consolidation, and Devil's Advocate challenge | `/team-code-review` |

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

### Skills

Add both the internal and vendor skill paths to your Claude Code settings:

```jsonc
// In ~/.claude/settings.json
{
  "skills": [
    "/path/to/claude-helpers/skills",
    "/path/to/claude-helpers/vendor/claude-code-skills/skills",
    "/path/to/claude-helpers/vendor/BMAD-METHOD/src/bmm-skills/4-implementation"
  ]
}
```

Then invoke skills by name (e.g., `/team-code-review`). See each skill's README for additional prerequisites.

### Hooks

Hooks are standalone scripts — add them individually to your `~/.claude/settings.json` hooks config. See each hook's README entry for the exact JSON snippet.

## Adding Resources

### Skills

1. Create a directory under `skills/` with your skill name
2. Add a `SKILL.md` with YAML frontmatter (`name`, `description`) and the skill body
3. Add a `README.md` with prerequisites, setup instructions, and usage
4. Open a PR for team review

### Hooks

1. Create a script in `hooks/` (`.sh`, `.js`, or `.py`)
2. Include install instructions as a comment header
3. Add an entry to `hooks/README.md` and the root README hooks table
4. Open a PR for team review
