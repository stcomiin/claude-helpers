# Verification Report Template

Template for `{implementation_artifacts}/{{story_key}}-verification.md`.

---

## File Template

```markdown
---
story: {{story_key}}
title: {{story_title}}
verified: YYYY-MM-DDTHH:MM:SSZ
status: passed | gaps_found | human_needed
score: N/M truths verified
re_verification:           # Only if previous verification existed
  previous_status: gaps_found
  previous_score: 2/5
  gaps_closed:
    - "Truth that was fixed"
  gaps_remaining: []
  regressions: []
gaps:                      # Only if status: gaps_found
  - truth: "Observable truth that failed"
    status: failed
    reason: "Why it failed"
    artifacts:
      - path: "src/path/to/file.py"
        issue: "What's wrong"
    missing:
      - "Specific thing to add/fix"
    severity: blocker | major | minor | cosmetic
human_verification:        # Only if status: human_needed
  - test: "What to do"
    expected: "What should happen"
    why_human: "Why can't verify programmatically"
---

# Story {{story_key}}: {{story_title}} — Verification Report

**Story Goal:** {{story description from AC}}
**Verified:** {{timestamp}}
**Status:** {{status}}
**Re-verification:** {{Yes — after gap closure | No — initial verification}}

## Goal Achievement

### Observable Truths

| #   | Truth                        | Status      | Evidence            |
| --- | ---------------------------- | ----------- | ------------------- |
| 1   | {{truth from AC}}            | VERIFIED    | {{what confirmed}}  |
| 2   | {{truth from AC}}            | FAILED      | {{what is wrong}}   |
| 3   | {{truth from AC}}            | UNCERTAIN   | {{why can't check}} |

**Score:** {{N}}/{{M}} truths verified

### Required Artifacts

| Artifact          | Expected               | Exists | Substantive | Wired | Data-Flow | Status   |
| ----------------- | ---------------------- | ------ | ----------- | ----- | --------- | -------- |
| `path/to/file.py` | {{purpose}}            | yes    | yes         | yes   | yes       | VERIFIED |
| `path/to/file.py` | {{purpose}}            | yes    | no          | —     | —         | STUB     |

**Artifacts:** {{N}}/{{M}} verified

### Key Link Verification

| From            | To              | Via                   | Status      | Details                           |
| --------------- | --------------- | --------------------- | ----------- | --------------------------------- |
| {{source file}} | {{target file}} | {{import/call}}       | WIRED       | Line N: code that connects A to B |
| {{source file}} | {{target file}} | {{import/call}}       | NOT_WIRED   | {{what is missing}}               |

**Wiring:** {{N}}/{{M}} connections verified

### Behavioral Spot-Checks

| Behavior         | Command          | Result           | Status |
| ---------------- | ---------------- | ---------------- | ------ |
| {{truth}}        | {{command}}      | {{output}}       | PASS   |
| {{truth}}        | {{command}}      | {{output}}       | FAIL   |

**Spot-checks:** {{N}}/{{M}} passed

### Anti-Patterns Found

| File              | Line | Pattern                     | Severity | Impact              |
| ----------------- | ---- | --------------------------- | -------- | ------------------- |
| `path/to/file.py` | 42   | `# TODO: implement`         | WARNING  | Indicates incomplete |
| `path/to/file.py` | 15   | `return None  # placeholder` | BLOCKER  | No real output      |

**Anti-patterns:** {{N}} found ({{blockers}} blockers, {{warnings}} warnings)

## UAT Results

### Tests

| #   | Test Name              | Expected                  | Result  | Details              |
| --- | ---------------------- | ------------------------- | ------- | -------------------- |
| 1   | {{test name}}          | {{expected behavior}}     | pass    |                      |
| 2   | {{test name}}          | {{expected behavior}}     | issue   | {{user's report}}    |
| 3   | {{test name}}          | {{expected behavior}}     | skipped | {{reason}}           |

### Summary

| Result  | Count |
| ------- | ----- |
| Passed  | {{N}} |
| Issues  | {{N}} |
| Skipped | {{N}} |
| Blocked | {{N}} |

## Human Verification Required

{{If none:}}
None — all verifiable items checked programmatically and via UAT.

{{If needed:}}

### 1. {{Test Name}}
**Test:** {{What to do}}
**Expected:** {{What should happen}}
**Why human:** {{Why can't verify programmatically}}

## Gaps Summary

{{If no gaps:}}
**No gaps found.** Story goal achieved. Ready to mark done.

{{If gaps found:}}

### Critical Gaps (Block Progress)

1. **{{Gap name}}**
   - Missing: {{what's missing}}
   - Impact: {{why this blocks the goal}}
   - Fix: {{what needs to happen}}
   - Severity: {{blocker/major}}

### Non-Critical Gaps (Can Defer)

1. **{{Gap name}}**
   - Issue: {{what's wrong}}
   - Impact: {{limited impact because...}}
   - Recommendation: {{fix now or defer}}
   - Severity: {{minor/cosmetic}}

## Verification Metadata

**Verification approach:** Goal-backward (derived from story acceptance criteria)
**Must-haves source:** Story Acceptance Criteria
**Automated checks:** {{N}} passed, {{M}} failed
**UAT tests:** {{N}} presented, {{M}} passed
**Human checks required:** {{N}}
**Verifier:** Claude (bmad-verify-story)

---
*Verified: {{timestamp}}*
```

---

## Guidelines

**Status values:**
- `passed` — All truths verified, no blockers, UAT clean
- `gaps_found` — One or more critical gaps found (automated or UAT)
- `human_needed` — Automated checks pass but human verification required for items that cannot be tested programmatically or via UAT

**Evidence types:**
- For EXISTS: "File at path, exports X"
- For SUBSTANTIVE: "N lines, has patterns X, Y, Z — not placeholder"
- For WIRED: "Line N: imported by file Y, called at line M"
- For DATA-FLOWING: "Return value used by caller at file:line"
- For FAILED: "Missing because X" or "Stub because Y"

**Severity levels:**
- BLOCKER: Prevents goal achievement, must fix before done
- WARNING: Indicates incomplete but does not block goal
- INFO: Notable but not problematic

**Re-verification metadata:**
When a previous VERIFICATION.md exists, the re-verification section tracks:
- Which gaps were closed (truths that now pass)
- Which gaps remain open
- Any regressions (truths that previously passed but now fail)
