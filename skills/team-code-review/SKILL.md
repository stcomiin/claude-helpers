---
name: team-code-review
description: 'Comprehensive 6-stage code review pipeline that orchestrates multi-perspective review of code changes: agent-team debate via /simplify, frontier-model Codex/GPT-5.4 security & design review, CC-native /everything-claude-code:code-review, adversarial /bmad-review:bmad-code-review, consolidation, and Devil''s Advocate capstone challenge. Use this skill whenever the user wants a thorough code review, says "run the team code review", "full review", "6-stage review", "multi-model review", "comprehensive review", "team review", or is finishing a feature/story and wants quality assurance before committing or opening a PR. Trigger even when the user just says "code review" in a context where they have completed work and want layered review, since this pipeline provides the most rigorous review available.'
---

# Team Code Review Pipeline

Orchestrates a 6-stage code review where each stage attacks changes from a fundamentally different angle. Different reviewers have different blind spots, and different model families catch different bug classes — layering independent perspectives is how you catch issues that any single reviewer would miss. The Devil's Advocate capstone then challenges the consensus itself, hunting for group-think and shared blind spots.

The pipeline runs: **(1) agent-team debate → (2) Codex frontier-model review → (3) CC-native review → (4) BMAD adversarial review → (5) consolidation → (6) Devil's Advocate challenge.**

## Step 0: Establish Review Scope

Scope must be settled ONCE upfront because downstream skills (bmad-review:bmad-code-review, everything-claude-code:code-review) will otherwise each re-prompt the user. Establishing it here makes the pipeline feel like one cohesive review instead of four separate ones.

**Detect scope from the user's request:**

1. If the user explicitly named a scope ("staged changes", "branch diff vs main", "last commit", specific files), use that.
2. Otherwise, check git state in order of preference:
   - If on a feature branch with commits ahead of main: use `git diff main...HEAD` (branch diff — most common case when finishing a story)
   - Else if there are staged changes: use `git diff --staged`
   - Else if there are uncommitted changes: use `git diff HEAD`
   - Else: HALT and ask the user what to review
3. Capture the diff with `git diff <scope> --stat` for a summary and `git diff <scope>` for the full content.

**Present the detected scope to the user:**

> "Running 4-stage team code review on `{scope_description}` ({N} files changed, {+X/-Y} lines). Proceeding through all stages unless you say otherwise."

Save the scope description phrase (e.g., "branch diff vs main", "staged changes") — you'll reuse it verbatim when invoking downstream skills so they auto-detect the same scope.

## Execution: Parallel Subagent Dispatch

All 4 stages run as parallel subagents dispatched in a single message. This cuts review time from ~15-20min (sequential) to ~5-7min (parallel). Step 0 (scope) runs first in the main thread so every subagent reviews the same code.

**Dispatch all 4 in one message using the Agent tool:**

### Stage 1: Agent Team Debate Review

Single-perspective reviews have systematic blind spots. Structured debate between reviewers with different priors surfaces disagreements that are often the highest-value findings.

```
Agent tool:
  description: "Stage 1: debate review"
  subagent_type: "general-purpose"
  model: "opus"
  prompt: |
    You are the orchestrator for a multi-agent debate code review.

    DIFF TO REVIEW ({scope_description}):
    ```
    {diff_content}
    ```

    STEP 1: Invoke the Skill tool:
      skill: "simplify"
      args: "on the following git diff, run agent teams — dispatch multiple agents per review category (security, performance, design/DRY-KISS-YAGNI, maintainability/readability) from different points of view to debate findings, then have a synthesizer agent collect the debate results and produce a consolidated review"

    If the simplify skill does not dispatch agent teams, implement the debate directly:

    1. Dispatch 4 reviewer agents IN PARALLEL (single message, multiple Agent calls):
       - Security Hawk — vulnerabilities, injection, auth/authz, secrets, SSRF
       - Simplification Advocate — DRY/KISS/YAGNI violations, over-engineering, premature abstraction
       - Maintainability Reviewer — readability, naming, cognitive load, coupling, testability
       - Performance Analyst — algorithmic issues, N+1 queries, unnecessary allocations

       Each returns findings as markdown with severity (critical/high/medium/low/nit) and file:line refs.

    2. After all 4 complete, dispatch a SYNTHESIZER agent with all findings. Its job:
       - Identify consensus findings (multiple reviewers agree)
       - Flag contested findings (reviewers disagreed on severity/validity)
       - Produce one consolidated list. Contested findings are the most valuable.

    Return the synthesized output with: consensus findings, contested findings, synthesizer verdict.
```

### Stage 2: Codex Frontier Model Review

Model diversity catches issues all Claude-based reviewers might collectively miss — different training data, different architecture, different blind spots.

**Before dispatching:** Save the diff to a temp file so Codex reads it directly (avoids overhead of Codex shelling out for `git diff`):
```bash
git diff {scope_git_args} > /tmp/review-diff.patch
```

**Codex parameters:**
- `--effort xhigh` — maximum reasoning depth for thorough review
- No `--write` — review is read-only, Codex should not edit files
- No `--model` — defaults to GPT-5.4 (latest frontier)

**XML-structured prompt** — Codex performs significantly better with block-structured prompts using XML tags. The `gpt-5-4-prompting` skill (loaded automatically by the codex:codex-rescue agent) guides prompt construction. Use this structure:

```
Agent tool:
  description: "Stage 2: Codex review"
  subagent_type: "codex:codex-rescue"
  prompt: |
    --effort xhigh

    Code review the diff at /tmp/review-diff.patch. Use XML-structured prompting per the gpt-5-4-prompting skill:

    <task>
    Review the code diff at /tmp/review-diff.patch for a {language} {domain} project.
    Scope: {scope_description}.
    Focus areas: (1) security and vulnerabilities, (2) DRY/KISS/YAGNI violations, (3) readability and maintainability.
    </task>

    <grounding_rules>
    Every finding MUST cite a specific file path and line number from the diff.
    Do not infer behavior from function names alone — read the actual implementation.
    If you suspect a test failure, state it as a hypothesis with "UNVERIFIED" tag, not as fact.
    If you suspect dead code, grep for callers before claiming it is unused.
    Do not flag patterns that appear 5+ times across the codebase as violations — they are conventions.
    </grounding_rules>

    <structured_output_contract>
    Return findings as markdown with this structure per finding:
    - **Title** (severity: critical/high/medium/low/nit)
    - `file:line` reference
    - What: 1-2 sentence description
    - Why it matters: consequence if unaddressed
    - Fix: concrete recommendation
    Group findings by focus area (Security, DRY/KISS/YAGNI, Readability).
    Maximum 15 findings. Quality over quantity.
    </structured_output_contract>

    <dig_deeper_nudge>
    Look for things the diff does NOT do that it should: missing error handling on new code paths,
    functions that changed signature but callers were not updated, new config that is declared but
    never consumed, test assertions that pass trivially (e.g., asserting on default values).
    </dig_deeper_nudge>
```

### Stage 3: Everything Claude Code Review

Opinionated CC-native review with language-specific quality checks.

```
Agent tool:
  description: "Stage 3: CC-native review"
  subagent_type: "everything-claude-code:code-reviewer"
  model: "opus"
  prompt: |
    Review the following code changes for quality, security, and maintainability.

    SCOPE: {scope_description}

    Run `git diff {scope_git_args}` to get the changes, then perform a comprehensive code review.
    Focus on: code quality, security vulnerabilities, maintainability issues, and design problems.

    Return findings as markdown with file:line references and severity (critical/high/medium/low/nit).
```

For Python projects, prefer `subagent_type: "everything-claude-code:python-reviewer"` to get PEP 8, type hint, and Pythonic idiom checks. For Go, use `"everything-claude-code:go-reviewer"`.

### Stage 4: BMAD Adversarial Review

Multi-layer adversarial review (Blind Hunter, Edge Case Hunter, Acceptance Auditor) — hunts for issues other stages dismiss, especially edge cases.

```
Agent tool:
  description: "Stage 4: BMAD adversarial review"
  subagent_type: "general-purpose"
  model: "opus"
  prompt: |
    Run a BMAD adversarial code review on {scope_description}.

    Invoke the Skill tool:
      skill: "bmad-review:bmad-code-review"
      args: "review the {scope_description}"

    The bmad-code-review skill will:
    1. Detect scope from your invocation text (use the exact phrase "{scope_description}")
    2. Dispatch its own parallel subagents: Blind Hunter, Edge Case Hunter, Acceptance Auditor
    3. Triage findings into categories: intent_gap, bad_spec, patch, defer, reject

    Return ALL findings from the triage step. Do not filter or summarize — the main orchestrator needs the raw triage output.
```

### Critical finding verification rule (applies to ALL stages)

Every stage prompt should include this instruction: **"If you believe a finding is Critical severity, verify it before reporting. If you claim tests fail, run `pytest <specific_test>` first. If you claim a function doesn't exist, `grep` for it first. Attach the verification command + output. Unverified Critical findings will be downgraded during consolidation."**

This exists because AI reviewers are prone to consensus hallucination — multiple stages can independently fabricate the same false finding with high confidence. Verification is the only antidote.

### Dispatching all stages

Send all 4 Agent tool calls **in a single message** so they execute concurrently. After all 4 return, proceed to Stage 5 (Consolidation).

If a stage fails or times out, note the failure and consolidate results from the stages that succeeded — partial results are still valuable.

## Stage 5: Consolidation

This is where the pipeline's value crystallizes. Four independent reviewers each produced findings — now you need to make the combined output actionable, not overwhelming.

### Consolidation approach

1. **Deduplicate.** Group findings that describe the same issue across stages. A finding flagged by 2+ independent reviewers deserves higher confidence than one flagged by only one. Note which stages caught each finding.

2. **Resolve severity conflicts.** If stages disagree on severity (e.g., Stage 1 says "critical", Stage 4 says "low"), investigate the disagreement. Usually the reviewer with more detailed evidence is correct, but flag the conflict so the user sees it.

3. **Verify Critical findings before publishing.** AI reviewers are prone to consensus hallucination — multiple stages can confidently report the same fabricated issue (e.g., "tests are failing" when they actually pass). Before promoting ANY finding to Critical severity:
   - If the finding claims tests fail: run `pytest <specific_test>` and verify the failure
   - If the finding claims a function doesn't exist or isn't called: run `grep -r` to verify
   - If the finding claims a security vulnerability: verify the actual code path exists
   - Attach the verification command + output to the Critical finding. No verification = no Critical.

4. **Check codebase conventions before flagging patterns.** When a stage flags a code pattern as wrong (e.g., "using datetime.now(UTC) breaks determinism"), search for other occurrences. If the same pattern appears 5+ times across the codebase, it's likely an established convention — downgrade to "convention concern" with a note about the pattern's prevalence. Individual findings should not contradict codebase-wide architecture unless they can articulate why THIS instance is different.

5. **Distinguish vulnerabilities from defense-in-depth.** When a finding claims "missing security isolation," verify whether the invariant is already enforced through another mechanism (e.g., FK chain, upstream query filter). If the isolation IS enforced transitively, downgrade from "vulnerability" to "defense-in-depth improvement" — the distinction matters for prioritization.

6. **Highlight unique findings.** Issues caught by only one stage are often the most valuable — they represent the blind spots the multi-stage approach is designed to catch. Don't bury these.

7. **Preserve contested findings.** The debate synthesizer (Stage 1) produces contested findings where agents disagreed. These go in their own section — they need human judgment.

### Output format

Always use this exact template:

```markdown
# Team Code Review Summary

**Scope:** {scope_description} ({N} files, {+X/-Y} lines)
**Stages completed:** {list of stages that ran successfully}
**Stages failed/skipped:** {list with reasons, if any}

## 🔴 Critical (must fix before merge)
- **{finding title}** — `{file}:{line}` — flagged by {stages}
  {1-2 line rationale}

## 🟠 High Priority
- ...

## 🟡 Medium Priority
- ...

## 🟢 Low / Nit
- ...

## ⚖️ Contested Findings (reviewer judgment needed)
- **{finding}** — {stage A} said {X}, {stage B} said {Y}. Evidence: {...}

## 🔍 Single-Stage Findings (blind-spot catches)
- **{finding}** — only {stage} caught this. {why it matters}

## Cross-Stage Observations
- {patterns like "3 of 4 stages flagged coupling in module X"}
- {notable disagreements or convergences}
```

Hold this summary — Stage 6 will challenge it before you present anything to the user.

## Stage 6: Devil's Advocate Capstone

The first 4 stages produced findings and Stage 5 consolidated them. But when 4 AI reviewers all look at the same code with similar training biases, they can collectively miss the same things — happy-path bias, scope acceptance ("this feature is reasonable because they asked for it"), or consensus hallucinations where everyone agrees something is fine but isn't.

Devil's Advocate is the capstone that challenges the consensus itself.

**Dispatch as a subagent** (sequential, after Stage 5 consolidation):

```
Agent tool:
  description: "Stage 6: Devil's Advocate"
  subagent_type: "general-purpose"
  model: "opus"
  prompt: |
    Invoke the devils-advocate skill to challenge this consolidated code review.

    CONTEXT — Diff under review ({scope_description}):
    ```
    {diff_content}
    ```

    CONTEXT — Consolidated review from 4 reviewers (Stage 5 output):
    ```
    {stage_5_consolidated_review}
    ```

    Your task:
    1. Invoke the Skill tool with skill: "devils-advocate:devils-advocate"
    2. Follow its process: Steel-Man → Challenge → Verdict
    3. Apply pre-mortem ("this shipped and failed 3 months later — what went wrong?"), inversion ("what would guarantee failure?"), and Socratic probing
    4. Cross-reference against the AI blind spots file — look for things the 4 AI reviewers collectively missed
    5. Specifically challenge:
       - Assumptions the reviewers shared without questioning
       - Anything where the review consensus seems confident but under-examined
       - Production failure modes the reviewers treated as unlikely
       - "This feature should exist" — is the diff solving the right problem?

    Return the Devil's Advocate output EXACTLY in its standard format:
    - Steel-man ("Here's what this gets right: ...")
    - Up to 7 concerns (Concern, Severity, Framework, What I see, Why it matters, What to do)
    - Verdict: Ship it / Ship with changes / Rethink this
```

**Why a subagent**: Devil's Advocate reads its full skill + potentially 3 reference files (~800 lines combined). Running it in the main thread would bloat context. The subagent returns a compact challenge report that merges into the final output.

## Final output

Combine Stage 5 (consolidation) + Stage 6 (Devil's Advocate) into the presentation:

```markdown
[Stage 5 consolidated review here — Critical/High/Medium/Low, Contested, Single-Stage]

---

## 😈 Devil's Advocate Challenge

**Steel-man:** [what the approach gets right]

### Concerns

[Up to 7 concerns in Devil's Advocate format]

### Verdict: [Ship it / Ship with changes / Rethink this]
```

If Devil's Advocate returns "Rethink this", call this out explicitly before any other output — the user should see that verdict immediately. If it returns "Ship it" despite the other reviewers flagging many findings, investigate the disagreement (usually means the flagged findings are lower-severity than they looked).

Present this combined output to the user. If there are Critical findings OR Devil's Advocate returns "Rethink this", clearly state these must be addressed before committing/merging.

## Stage failures and partial results

If a stage fails (tool unavailable, timeout, error):
- Note the failure in the summary
- Continue to the next stage — partial results are still valuable
- Do not halt the pipeline unless ALL stages fail

If the user interrupts mid-pipeline, summarize findings from completed stages and offer to resume.

## Skipping or customizing stages

Honor user requests to customize:
- "skip codex" → run stages 1, 3, 4 only (+ 5, 6)
- "skip devils advocate" → run stages 1-5 only
- "just run bmad" → run stage 4 only, skip consolidation, skip devil's advocate
- "just consolidate" → user is passing findings manually, skip stages 1-4
- "focus on security" → tell each stage to weight security findings higher in their prompts

The pipeline is modular. The sequence matters less than the diversity of perspectives.

## Execution model: when to run what

```
Main Thread: Step 0 (scope) ──→ Dispatch 4 parallel subagents ──→ Stage 5 (consolidate) ──→ Stage 6 subagent (Devil's Advocate) ──→ Final output
                                    │
                                    ├── Stage 1: general-purpose (debate)
                                    ├── Stage 2: codex:codex-rescue (GPT-5.4)
                                    ├── Stage 3: code-reviewer / python-reviewer
                                    └── Stage 4: general-purpose (BMAD)
```

**Stages 1-4 run in parallel** because they're independent — no anchoring bias, and total wall-clock time drops from ~15-20min to ~5-7min. Each subagent gets its own context window, so the main thread stays clean.

**Stage 5 runs in the main thread** because consolidation needs all 4 results in one place to deduplicate and reconcile.

**Stage 6 runs as a sequential subagent** because Devil's Advocate explicitly needs to challenge the consensus AFTER it forms. Running it in parallel would give it nothing to challenge. It runs as a subagent (not main thread) because it reads ~800 lines of skill + reference files and would bloat the main thread's context.

Each subagent type maps to a real capability:
- `general-purpose` — has access to ALL tools (Skill, Agent, Bash), can invoke `/simplify`, `/bmad-review:bmad-code-review`, `/devils-advocate:devils-advocate`, and dispatch sub-subagents
- `codex:codex-rescue` — dedicated Codex bridge with Bash access to invoke the CLI
- `everything-claude-code:code-reviewer` / `python-reviewer` — specialized review agents with built-in review logic

**Sequential fallback**: If the user says "run stages one at a time" or if parallel dispatch fails, fall back to invoking each stage sequentially via Skill tool calls. Always preserve the order: 1-4 (any order) → 5 → 6.
