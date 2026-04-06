# team-code-review

A comprehensive 6-stage code review pipeline that orchestrates multi-perspective review of code changes. Different reviewers have different blind spots — layering independent perspectives catches issues any single reviewer would miss.

## Pipeline Overview

```
Main Thread: Scope → Dispatch 4 parallel stages → Consolidate → Devil's Advocate → Final Output
                          │
                          ├── Stage 1: Agent Team Debate (simplify)
                          ├── Stage 2: Codex Frontier Model Review (GPT-5.4)
                          ├── Stage 3: CC-Native Review (code-reviewer)
                          └── Stage 4: BMAD Adversarial Review (bmad-code-review)
                                            ↓
                          Stage 5: Consolidation (main thread)
                                            ↓
                          Stage 6: Devil's Advocate Challenge (devils-advocate)
```

**Stages 1-4** run in parallel (~5-7 min total vs ~15-20 min sequential).
**Stage 5** consolidates in the main thread.
**Stage 6** challenges the consensus as a sequential subagent.

## Stages

| Stage | Name | What It Does | Source |
|-------|------|-------------|--------|
| 1 | Agent Team Debate | 4 reviewers (security, performance, design, maintainability) debate findings, then a synthesizer resolves disagreements | `simplify` skill |
| 2 | Codex Frontier Model | Cross-model review using GPT-5.4 — catches issues Claude-based reviewers collectively miss | `codex:codex-rescue` agent |
| 3 | CC-Native Review | Language-specific quality checks (code-reviewer, python-reviewer, or go-reviewer) | `everything-claude-code` plugin |
| 4 | BMAD Adversarial | Blind Hunter, Edge Case Hunter, Acceptance Auditor — hunts for issues other stages dismiss | `bmad-code-review` skill |
| 5 | Consolidation | Deduplicates, reconciles severity conflicts, highlights unique and contested findings | Built-in (main thread) |
| 6 | Devil's Advocate | Steel-Man → Challenge → Verdict. Pre-mortem, inversion, and Socratic probing against consensus | `devils-advocate` skill |

## Prerequisites

### Plugins (install via Claude Code)

These are Claude Code plugins installed at the user level. Each team member needs to install them once.

#### 1. Everything Claude Code

Provides the `code-reviewer`, `python-reviewer`, and `go-reviewer` agents used in Stage 3.

- **Source:** [affaan-m/everything-claude-code](https://github.com/affaan-m/everything-claude-code)
- **Plugin ID:** `everything-claude-code@everything-claude-code`
- **Install:** Install from the `everything-claude-code` marketplace via Claude Code plugin manager

#### 2. Codex Plugin

Provides the `codex:codex-rescue` agent used in Stage 2 for GPT-5.4 cross-model review.

- **Source:** [f5xc-salesdemos/codex-plugin-cc](https://github.com/f5xc-salesdemos/codex-plugin-cc)
- **Plugin ID:** `codex@openai-codex`
- **Install:** Install from the `openai-codex` marketplace via Claude Code plugin manager
- **Additional requirement:** OpenAI Codex CLI must be installed globally:
  ```bash
  npm install -g @openai/codex
  ```
- **API key:** Requires a valid OpenAI API key configured for Codex CLI access

### Skills (project-scoped)

These skills are **not** globally installed plugins — they live in the `ss-platform-bmad` repository's `.claude/skills/` directory. They are only available when Claude Code can resolve them.

#### 3. bmad-code-review

Used in Stage 4 for adversarial review.

- **Location:** `ss-platform-bmad/.claude/skills/bmad-code-review/`
- **Scope:** Project-local to `ss-platform-bmad`

#### 4. devils-advocate

Used in Stage 6 for the capstone challenge. Includes reference files (`ai-blind-spots.md`, `blind-spots.md`, `questioning-frameworks.md`).

- **Location:** `ss-platform-bmad/.claude/skills/devils-advocate/`
- **Scope:** Project-local to `ss-platform-bmad`

### Built-in

#### 5. simplify

Used in Stage 1 for agent team debate orchestration. Ships with Claude Code — no installation needed.

## Making Project-Scoped Skills Available

The `bmad-code-review` and `devils-advocate` skills are project-scoped to `ss-platform-bmad`. To use them from other repos, you have two options:

**Option A:** Add the `ss-platform-bmad` skills path to your global settings:

```jsonc
// ~/.claude/settings.json
{
  "skills": [
    "/path/to/ss-platform-bmad/.claude/skills"
  ]
}
```

**Option B:** Copy the skills into this repo's `skills/` directory (if the team decides to centralize them here).

If these skills are unavailable at runtime, Stages 4 and 6 will fail gracefully — the pipeline consolidates results from whichever stages succeed.

## Usage

```
/team-code-review
```

The skill auto-detects scope from git state:
1. Feature branch with commits ahead of main → `git diff main...HEAD`
2. Staged changes → `git diff --staged`
3. Uncommitted changes → `git diff HEAD`

### Customizing

- `skip codex` — run stages 1, 3, 4 only
- `skip devils advocate` — run stages 1-5 only
- `just run bmad` — stage 4 only
- `focus on security` — weight security findings higher across all stages
