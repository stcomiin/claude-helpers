# claude-helpers

Shared repository for common Claude Code resources used by our internal dev team — skills, plugins, and related configurations.

## Folder Walkthrough

```
claude-helpers/
├── README.md                          # This file — repo overview and setup
└── skills/                            # Claude Code skills (SKILL.md convention)
    └── team-code-review/              # 6-stage multi-model code review pipeline
        ├── SKILL.md                   # Skill definition (frontmatter + orchestration logic)
        └── README.md                  # Prerequisites, setup, and usage guide
```

## Skills

| Skill | Description | Invoke |
|-------|-------------|--------|
| [team-code-review](skills/team-code-review/) | 6-stage multi-model code review pipeline — agent debate, Codex/GPT-5.4 cross-model review, CC-native review, BMAD adversarial review, consolidation, and Devil's Advocate challenge | `/team-code-review` |

## Dependency Map

Skills in this repo may depend on external plugins, project-scoped skills, or built-in Claude Code features. This table tracks origin and ownership so the team knows where to look for updates or file issues.

| Skill / Dependency | Origin | Source | Maintained By |
|--------------------|--------|--------|---------------|
| team-code-review | Internal | This repo | Our team |
| bmad-code-review | External (project-scoped) | `ss-platform-bmad/.claude/skills/` | BMAD project |
| devils-advocate | External (project-scoped) | `ss-platform-bmad/.claude/skills/` | BMAD project |
| simplify | Built-in | Ships with Claude Code | Anthropic |
| code-reviewer | Plugin | [affaan-m/everything-claude-code](https://github.com/affaan-m/everything-claude-code) | Community |
| python-reviewer | Plugin | [affaan-m/everything-claude-code](https://github.com/affaan-m/everything-claude-code) | Community |
| go-reviewer | Plugin | [affaan-m/everything-claude-code](https://github.com/affaan-m/everything-claude-code) | Community |
| codex-rescue | Plugin | [f5xc-salesdemos/codex-plugin-cc](https://github.com/f5xc-salesdemos/codex-plugin-cc) | Community |

## Setup

Add this repo's `skills/` directory to your Claude Code skill paths so skills are available in any project:

```jsonc
// In your Claude Code settings (~/.claude/settings.json)
{
  "skills": [
    "/path/to/claude-helpers/skills"
  ]
}
```

Then invoke skills by name (e.g., `/team-code-review`). See each skill's README for additional prerequisites.

## Adding Skills

1. Create a directory under `skills/` with your skill name
2. Add a `SKILL.md` with YAML frontmatter (`name`, `description`) and the skill body
3. Add a `README.md` with prerequisites, setup instructions, and usage
4. Open a PR for team review
