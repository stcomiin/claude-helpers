---
main_config: '{project-root}/_bmad/bmm/config.yaml'
---

# Verify Story Workflow

**Goal:** Goal-backward verification that a completed story actually delivers what it promised. Task completion does not equal goal achievement — this workflow starts from what must be TRUE for the story to succeed, then verifies each truth against the actual codebase.

**Your Role:** Independent verifier. You do NOT trust dev-story completion notes, code-review findings, or any claims about what was implemented. You verify what ACTUALLY exists in the code. These often differ.

- Communicate all responses in {communication_language} and language MUST be tailored to {user_skill_level}
- Generate all documents in {document_output_language}
- Execute ALL steps in exact order; do NOT skip steps

---

## INITIALIZATION

### Configuration Loading

Load config from `{project-root}/_bmad/bmm/config.yaml` and resolve:

- `project_name`, `user_name`
- `communication_language`, `document_output_language`
- `user_skill_level`
- `implementation_artifacts`
- `date` as system-generated current datetime

### Paths

- `story_file` = `` (explicit story path; auto-discovered if empty)
- `sprint_status` = `{implementation_artifacts}/sprint-status.yaml`

### Context

- `project_context` = `**/project-context.md` (load if exists)
- `CLAUDE.md` = `./CLAUDE.md` (load if exists — follow all project-specific guidelines)

---

## EXECUTION

<workflow>
  <critical>Task completion does NOT equal goal achievement. A task can be marked [x] while the acceptance criterion it serves remains unmet. Verify outcomes, not checkboxes.</critical>
  <critical>Do NOT trust story completion notes, code-review findings, or SUMMARY claims. Verify what ACTUALLY exists in the codebase.</critical>
  <critical>Do NOT assume file existence equals implementation. Check all 4 levels: exists, substantive, wired, data-flowing.</critical>
  <critical>80% of stubs hide in the wiring — pieces exist but are not connected. Always verify key links.</critical>
  <critical>Communicate all responses in {communication_language} and language MUST be tailored to {user_skill_level}</critical>

  <!-- ============================================================ -->
  <!-- STEP 1: DISCOVER AND LOAD STORY                              -->
  <!-- ============================================================ -->

  <step n="1" goal="Find story and load complete context" tag="sprint-status">
    <check if="{{story_path}} is provided">
      <action>Use {{story_path}} directly</action>
      <goto anchor="load_story" />
    </check>

    <check if="{{sprint_status}} file exists">
      <action>Load the FULL file: {{sprint_status}}</action>
      <action>Find the FIRST story where status is "review" or "done" (prefer "review")</action>
      <action>If no "review" stories, find the most recently completed "done" story</action>
      <check if="no review or done story found">
        <output>No stories in "review" or "done" status found in sprint-status.yaml.

          Verification works best on stories that have completed dev-story and/or code-review.

          **Options:**
          1. Specify a story file path to verify
          2. Check sprint status to see current state
        </output>
        <ask>Provide story file path, or choose [1] or [2]:</ask>
      </check>
    </check>

    <anchor id="load_story" />

    <action>Read the COMPLETE story file</action>
    <action>Parse ALL sections: Story, Acceptance Criteria, Tasks/Subtasks, Dev Notes, Dev Agent Record, File List, Change Log, Status</action>
    <action>Extract story_key from filename</action>
    <action>Load {project_context} for architecture patterns and coding standards</action>

    <action if="story file inaccessible">HALT: "Cannot verify without access to story file"</action>
    <action if="no Acceptance Criteria found">HALT: "Story has no Acceptance Criteria — nothing to verify against"</action>
  </step>

  <!-- ============================================================ -->
  <!-- STEP 2: CHECK FOR PREVIOUS VERIFICATION                     -->
  <!-- ============================================================ -->

  <step n="2" goal="Detect re-verification mode">
    <action>Check for existing verification report: {implementation_artifacts}/{{story_key}}-verification.md</action>

    <check if="previous verification report exists">
      <action>Read previous report</action>
      <action>Extract previous status, score, and gaps</action>
      <action>Set is_re_verification = true</action>

      <output>Previous verification found.

        **Previous status:** {{previous_status}}
        **Previous score:** {{previous_score}}
        **Gaps found:** {{gap_count}}

        Entering re-verification mode — focusing on previously failed items with full checks, passed items get quick regression check only.
      </output>

      <action>Extract must_haves from previous report (truths, artifacts, key_links)</action>
      <action>Extract gaps (items that failed)</action>
      <goto step="3" />
    </check>

    <check if="no previous verification report">
      <action>Set is_re_verification = false</action>
      <goto step="3" />
    </check>
  </step>

  <!-- ============================================================ -->
  <!-- STEP 3: ESTABLISH MUST-HAVES                                 -->
  <!-- ============================================================ -->

  <step n="3" goal="Derive observable truths from acceptance criteria">
    <critical>Observable truths are user-visible, testable behaviors — not implementation details. "Function X exists" is NOT a truth. "User can see migration status for a repo" IS a truth.</critical>

    <check if="is_re_verification == true">
      <action>Use must-haves from previous verification (Step 2)</action>
      <action>For failed items: will run full verification</action>
      <action>For passed items: will run quick regression check</action>
      <goto step="4" />
    </check>

    <!-- Initial verification: derive must-haves from acceptance criteria -->
    <action>For each Acceptance Criterion in the story, derive one or more observable truths:
      - State the truth as a testable, user-observable behavior
      - Not implementation details — "status command shows pipeline stages" not "PIPELINE_STAGES constant exists"
    </action>

    <action>For each truth, identify supporting artifacts:
      - What files MUST EXIST for this truth to hold?
      - Use File List from story as primary source
      - Add any additional files that logically must exist
    </action>

    <action>For each artifact, identify key links:
      - What must this file IMPORT or BE IMPORTED BY?
      - What function calls connect this to the rest of the system?
      - Where do stubs typically hide in these connections?
    </action>

    <action>Document the must-haves before proceeding:
      - truths: List of 3-10 observable, testable behaviors
      - artifacts: List of files with expected purpose
      - key_links: List of from→to→via connections
    </action>

    <output>**Must-Haves Established**

      **Observable Truths:** {{truth_count}}
      **Required Artifacts:** {{artifact_count}}
      **Key Links:** {{link_count}}

      Proceeding to verification...
    </output>
  </step>

  <!-- ============================================================ -->
  <!-- STEP 4: VERIFY OBSERVABLE TRUTHS                             -->
  <!-- ============================================================ -->

  <step n="4" goal="Verify each truth against the actual codebase">
    <action>For each observable truth, verify it by checking its supporting artifacts through all 4 levels</action>

    <action>For each truth:
      1. Identify the artifacts that support this truth
      2. Check artifact status (Step 5 logic, inline)
      3. Check wiring status — are the pieces connected?
      4. Determine truth status:
         - VERIFIED: All supporting artifacts pass all checks
         - FAILED: One or more artifacts missing, stub, or unwired
         - UNCERTAIN: Cannot verify programmatically (needs human UAT)
    </action>

    <action>Record evidence for each truth — what confirmed or disproved it:
      - For VERIFIED: specific file, line, code that proves it
      - For FAILED: what is wrong, what is missing
      - For UNCERTAIN: why it cannot be verified automatically
    </action>
  </step>

  <!-- ============================================================ -->
  <!-- STEP 5: VERIFY ARTIFACTS (4-LEVEL)                           -->
  <!-- ============================================================ -->

  <step n="5" goal="Check every artifact at 4 levels: exists, substantive, wired, data-flowing">
    <critical>Read ./references/verification-patterns.md for language-specific stub detection and wiring patterns before running checks</critical>

    <action>For each artifact in File List and must-haves:</action>

    <!-- LEVEL 1: EXISTS -->
    <action>Check file exists at the expected path.
      Status: EXISTS or MISSING
    </action>

    <!-- LEVEL 2: SUBSTANTIVE -->
    <action>Check file has real implementation, not placeholder:
      - More than trivial line count for its type
      - No placeholder text ("TODO", "not implemented", "coming soon", "placeholder")
      - Has expected patterns for its type (exports, class definitions, test assertions)
      - No empty returns (return None, return {}, return []) without real logic
      Status: SUBSTANTIVE or STUB
    </action>

    <!-- LEVEL 3: WIRED -->
    <action>Check file is connected to the rest of the system:
      - Imported by at least one other file (check with grep)
      - Its exports/functions are actually called (not just imported)
      - For test files: actually discovered and run by the test framework
      Status: WIRED or ORPHANED or PARTIAL
    </action>

    <!-- LEVEL 4: DATA-FLOWING (for artifacts that produce/consume data) -->
    <action>Check real data flows through the wiring:
      - For functions: return values are used by callers (not ignored)
      - For models: actually instantiated with real data (not just defined)
      - For CLI commands: actually registered and callable
      - For state files: actually read and written by the pipeline
      Status: FLOWING or STATIC or DISCONNECTED
    </action>

    <action>Determine final artifact status:

      | Exists | Substantive | Wired | Data Flows | Status                                   |
      | ------ | ----------- | ----- | ---------- | ---------------------------------------- |
      | yes    | yes         | yes   | yes        | VERIFIED                                 |
      | yes    | yes         | yes   | no         | HOLLOW — wired but data disconnected     |
      | yes    | yes         | no    | —          | ORPHANED — exists but unused             |
      | yes    | no          | —     | —          | STUB — placeholder, not real             |
      | no     | —           | —     | —          | MISSING                                  |
    </action>
  </step>

  <!-- ============================================================ -->
  <!-- STEP 6: ANTI-PATTERN SCAN                                    -->
  <!-- ============================================================ -->

  <step n="6" goal="Systematic scan of modified files for anti-patterns">
    <action>Collect all files from the story's File List</action>

    <action>For each file, scan for anti-patterns:

      **Stub indicators:**
      - TODO/FIXME/XXX/HACK/PLACEHOLDER comments
      - "coming soon", "will be here", "not yet implemented", "not available"
      - Empty implementations: return None, return {}, return [], pass, ...
      - Log-only functions (function body is only print/logging)
      - Hardcoded empty data flowing to output

      **Code quality concerns:**
      - Functions with no callers (dead code)
      - Imports that are unused
      - Exception handlers that silently swallow errors (bare except: pass)
      - Hardcoded values where dynamic expected

      See ./references/verification-patterns.md for language-specific patterns.
    </action>

    <action>Classify each finding:
      - BLOCKER: Prevents goal achievement, must fix
      - WARNING: Indicates incomplete but does not block goal
      - INFO: Notable but not problematic
    </action>

    <action>A grep match is a STUB only when the value flows to user-visible output AND no other code path populates it with real data. A test helper, type default, or initial state that gets overwritten is NOT a stub. Check for data-population paths before flagging.</action>
  </step>

  <!-- ============================================================ -->
  <!-- STEP 7: BEHAVIORAL SPOT-CHECKS                               -->
  <!-- ============================================================ -->

  <step n="7" goal="Run actual commands to verify behavior">
    <critical>Each check must complete in under 10 seconds. Do not modify state — read-only verification only.</critical>

    <action>Identify 2-5 checkable behaviors from the observable truths. Select those that can be tested with a single command.</action>

    <action>Common spot-check patterns:

      **CLI tools:**
      - Command exists and shows help: `{{cli}} {{command}} --help 2>&1 | grep -q "{{expected_text}}"`
      - Subcommand is registered: `{{cli}} --help 2>&1 | grep -q "{{subcommand}}"`

      **Python modules:**
      - Module imports cleanly: `python -c "from {{module}} import {{symbol}}" 2>&1`
      - Function is callable: `python -c "from {{module}} import {{func}}; print(type({{func}}))" 2>&1`

      **Tests:**
      - Test suite passes: `{{test_runner}} {{test_path}} 2>&1 | tail -5`
      - Specific test file runs: `{{test_runner}} {{test_file}} -v 2>&1 | tail -10`

      **Build/lint:**
      - Linter passes: `{{linter}} {{path}} 2>&1`
      - Type checker passes: `{{type_checker}} {{path}} 2>&1`

      **Files and data:**
      - Output file is non-empty: `[ -s "{{output_path}}" ] && echo "EXISTS" || echo "MISSING"`
      - JSON/YAML is valid: `python -c "import json; json.load(open('{{path}}'))" 2>&1`
    </action>

    <action>Run each check and record:

      | Behavior | Command | Result | Status |
      | -------- | ------- | ------ | ------ |
      | {truth}  | {cmd}   | {out}  | PASS / FAIL / SKIP |

      - PASS: Command succeeded and output matches expected
      - FAIL: Command failed or output wrong — flag as gap
      - SKIP: Cannot test without running server or external service — route to UAT
    </action>

    <action>If the project has no runnable entry points yet, skip with: "Step 7: SKIPPED (no runnable entry points)"</action>
  </step>

  <!-- ============================================================ -->
  <!-- STEP 8: CREATE VERIFICATION REPORT                           -->
  <!-- ============================================================ -->

  <step n="8" goal="Write structured verification report">
    <action>Determine overall status:
      - **passed**: All truths VERIFIED, all artifacts pass levels 1-3, no blocker anti-patterns
      - **gaps_found**: One or more truths FAILED, artifacts MISSING/STUB, or blocker anti-patterns
      - **human_needed**: All automated checks pass but items need human UAT
    </action>

    <action>Calculate score: verified_truths / total_truths</action>

    <action>Read the template: ./templates/verification-report-template.md</action>

    <action>Write verification report to: {implementation_artifacts}/{{story_key}}-verification.md
      - Fill in all template sections with actual verification data
      - Include evidence for every truth (not just status)
      - Structure gaps in YAML frontmatter for downstream consumption
      - If re-verification: include re-verification metadata (previous status, gaps closed, regressions)
    </action>

    <output>**Automated Verification Complete**

      **Status:** {{status}}
      **Score:** {{verified_count}}/{{total_count}} truths verified
      **Artifacts:** {{artifact_verified}}/{{artifact_total}} verified
      **Anti-patterns:** {{antipattern_count}} found ({{blocker_count}} blockers)
      **Spot-checks:** {{spot_passed}}/{{spot_total}} passed

      {{if gaps_found}}
      ### Gaps Found
      {{gap_summary}}
      {{endif}}

      Proceeding to interactive UAT...
    </output>
  </step>

  <!-- ============================================================ -->
  <!-- STEP 9: INTERACTIVE UAT                                      -->
  <!-- ============================================================ -->

  <step n="9" goal="Present testable deliverables to user one-at-a-time">
    <critical>Present tests ONE AT A TIME. Wait for user response before advancing.</critical>
    <critical>NEVER ask "how severe is this?" — infer severity from the user's natural language.</critical>

    <action>Extract testable deliverables from story Acceptance Criteria.
      Focus on USER-OBSERVABLE outcomes, not implementation details.

      For each AC, create a test:
      - name: Brief test name
      - expected: What the user should see/experience (specific, observable)
    </action>

    <action>If story's File List includes files matching startup patterns (main.py, app.py, cli.py, __main__.py, docker-compose*, Dockerfile*), prepend a Cold Start Smoke Test:
      - name: "Cold Start Smoke Test"
      - expected: "Run the main CLI/app entry point from scratch. Application starts without errors, core commands are registered, and basic help output is correct."
    </action>

    <goto anchor="present_test" />

    <anchor id="present_test" />

    <action>Present the current test:

      ---
      **UAT Test {{N}}/{{total}}**

      **Test:** {{test_name}}
      **Expected:** {{expected_behavior}}

      Try this now and tell me what happened.
      (pass / describe any issue / skip / blocked)

      ---
    </action>

    <action>Wait for user response (plain text). Do NOT use AskUserQuestion — just wait.</action>
    <goto anchor="process_response" />

    <anchor id="process_response" />

    <!-- PASS -->
    <check if="response indicates pass: empty, 'yes', 'y', 'ok', 'pass', 'next', 'looks good'">
      <action>Record: result = pass</action>
    </check>

    <!-- SKIP -->
    <check if="response indicates skip: 'skip', 'can't test', 'n/a'">
      <action>Record: result = skipped, reason = user's reason if provided</action>
    </check>

    <!-- BLOCKED -->
    <check if="response indicates blocked: 'blocked', 'can't test - X not running', 'need Y'">
      <action>Infer blocked_by tag:
        - Contains server, not running, gateway, API -> server
        - Contains device, hardware -> physical-device
        - Contains release, build, deploy -> release-build
        - Contains third-party, external, configure -> third-party
        - Contains depends on, prior, prerequisite -> prior-phase
        - Default: other
      </action>
      <action>Record: result = blocked, blocked_by = {{tag}}, reason = verbatim response</action>
    </check>

    <!-- ISSUE (anything else) -->
    <check if="response is anything else (treat as issue description)">
      <action>Infer severity from natural language:

        | User says                                           | Severity |
        | --------------------------------------------------- | -------- |
        | "crashes", "error", "exception", "fails completely" | blocker  |
        | "doesn't work", "nothing happens", "wrong behavior" | major    |
        | "works but...", "slow", "weird", "minor issue"      | minor    |
        | "color", "spacing", "alignment", "looks off"        | cosmetic |

        Default to major if unclear.
      </action>

      <action>Record: result = issue, reported = verbatim response, severity = {{inferred}}</action>

      <action>Append to gaps section in verification report:
        ```yaml
        - truth: "{{expected behavior from test}}"
          status: failed
          reason: "User reported: {{verbatim response}}"
          severity: {{inferred}}
          test: {{N}}
        ```
      </action>
    </check>

    <!-- Advance -->
    <action>Update verification report with test result</action>

    <check if="more tests remain">
      <goto anchor="present_test" />
    </check>

    <check if="no more tests remain">
      <goto step="10" />
    </check>
  </step>

  <!-- ============================================================ -->
  <!-- STEP 10: COMPLETE AND RECOMMEND NEXT STEPS                   -->
  <!-- ============================================================ -->

  <step n="10" goal="Finalize verification and recommend actions" tag="sprint-status">
    <action>Update verification report with final UAT results:
      - Update Summary section with pass/issue/skip/blocked counts
      - Update overall status based on combined automated + UAT results
      - Update score
    </action>

    <action>Present final summary:

      ## Verification Complete: {{story_key}}

      | Check           | Result                              |
      | --------------- | ----------------------------------- |
      | Observable Truths | {{verified}}/{{total}} verified   |
      | Artifacts       | {{artifact_status}}                 |
      | Anti-patterns   | {{antipattern_summary}}             |
      | Spot-checks     | {{spot_summary}}                    |
      | UAT             | {{uat_passed}} passed, {{uat_issues}} issues, {{uat_skipped}} skipped |

      **Overall Status:** {{final_status}}
      **Report:** {implementation_artifacts}/{{story_key}}-verification.md
    </action>

    <!-- STATUS: PASSED -->
    <check if="final_status == passed AND story status == review">
      <action>Story verification passed. Do NOT automatically update sprint-status — the user decides when to mark done.</action>
      <output>All checks passed. Story is verified and ready to be marked done.

        **Recommended next steps:**
        - Mark story as "done" in sprint-status.yaml
        - If code review has not been run yet, run `bmad-code-review` first
        - Continue to next story with `bmad-create-story` or `bmad-dev-story`
      </output>
    </check>

    <!-- STATUS: GAPS FOUND -->
    <check if="final_status == gaps_found">
      <action>Count and categorize gaps</action>
      <output>### Gaps Found

        {{gap_count}} gap(s) blocking goal achievement:

        {{gap_list_with_recommendations}}

        **Recommended next steps:**
        - Address the gaps listed above (re-run `bmad-dev-story` with the story file, or fix directly)
        - After fixing, re-run `bmad-verify-story` to confirm gaps are closed (re-verification mode will focus on failed items)
        - Do NOT mark story as "done" until verification passes
      </output>
    </check>

    <!-- STATUS: HUMAN NEEDED -->
    <check if="final_status == human_needed">
      <output>### Human Verification Required

        All automated checks passed, but {{human_count}} items need manual testing:

        {{human_verification_list}}

        **Recommended next steps:**
        - Test the items listed above manually
        - If all pass, story can be marked "done"
        - If issues found, re-run `bmad-dev-story` to address them
      </output>
    </check>
  </step>

</workflow>

<severity_inference>
**Infer severity from user's natural language — NEVER ask the user to rate severity:**

| User says                                           | Infer    |
| --------------------------------------------------- | -------- |
| "crashes", "error", "exception", "fails completely" | blocker  |
| "doesn't work", "nothing happens", "wrong behavior" | major    |
| "works but...", "slow", "weird", "minor issue"      | minor    |
| "color", "spacing", "alignment", "looks off"        | cosmetic |

Default to **major** if unclear. User can correct if needed.
</severity_inference>

<update_rules>
**Batched writes for efficiency:**

Keep results in memory. Write to verification report only when:
1. **Issue found** — Preserve the problem immediately
2. **Session complete** — Final write with all results
3. **Checkpoint** — Every 5 passed tests (safety net for context resets)

On context reset: Report shows last checkpoint. Resume from there.
</update_rules>

<success_criteria>
- [ ] Story loaded with complete context (AC, File List, Dev Notes)
- [ ] Previous verification checked (re-verification mode if exists)
- [ ] Must-haves established (observable truths from acceptance criteria)
- [ ] All truths verified with status and evidence
- [ ] All artifacts checked at 4 levels (exists, substantive, wired, data-flowing)
- [ ] Anti-patterns scanned and categorized
- [ ] Behavioral spot-checks run on runnable code (or skipped with reason)
- [ ] Verification report created at {implementation_artifacts}/{{story_key}}-verification.md
- [ ] Interactive UAT presented one test at a time
- [ ] Severity inferred from user language (never asked)
- [ ] Overall status determined (passed / gaps_found / human_needed)
- [ ] Gaps structured in report for downstream re-engagement
- [ ] Next steps recommended based on outcome
</success_criteria>
