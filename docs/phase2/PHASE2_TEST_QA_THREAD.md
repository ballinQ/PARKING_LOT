# Phase 2 Test / QA Thread

Status: Active QA thread document.
Owner: Test / QA thread.
Primary source: `docs/phase2/PHASE2_SELF_TEST.md`

This thread maintains Phase 2 test coverage, validates Phase 2 behavior, and produces structured reports. It does not redesign features and does not fix bugs.

## Responsibilities

1. Follow the latest Test Handoff Document from Phase 2.
2. Read relevant design, roadmap, architecture, and handoff notes before testing a feature.
3. Update test cases when a design or handoff changes expected behavior.
4. Update `docs/phase2/PHASE2_SELF_TEST.md` for test-only changes:
   - new or changed test cases
   - expected results
   - automation/manual coverage
   - report evidence requirements
   - blocked/not-run guidance
5. Execute feature validation.
6. Verify expected behavior matches documentation.
7. Check for regressions against the frozen Phase 1 core loop.
8. Identify edge cases.
9. Produce structured test reports and Debug-thread handoffs.

## Source Order

Use this order when deciding what to test:

1. Latest file under `docs/phase2/handoffs/`, if present.
2. `docs/phase2/PHASE2_SELF_TEST.md`.
3. `README.md` project log.
4. `docs/phase2/PHASE2_ROADMAP.md`.
5. `docs/phase2/PHASE2_ARCHITECTURE_REVIEW.md`.

Current note: if no handoff file exists, treat `PHASE2_SELF_TEST.md` as the authoritative test handoff.

## QA Rules

- Do not redesign features.
- Do not implement or patch code.
- Do not change product scope, design decisions, roadmap priorities, or architecture except to quote them as test expectations.
- Only update `PHASE2_SELF_TEST.md` and QA/reporting documents when the change is test-related.
- Do not silently fix test data or app behavior.
- Do not revive the old History list.
- Do not add backend, login, cloud sync, analytics, ML, continuous background location, community map, or payment features.
- Report bugs with reproduction steps, severity, and regression risk.
- If a bug blocks testing, mark the case `BLOCKED` and create a Debug Report section.

## Test Case Maintenance

When a new design note, roadmap update, architecture note, or Test Handoff Document appears:

1. Read the new note and identify user-visible behavior, logic behavior, scope boundaries, and non-goals.
2. Compare it against `PHASE2_SELF_TEST.md`.
3. Add or revise only test-related content:
   - test matrix rows
   - detailed test steps
   - expected behavior
   - automated test names
   - manual evidence requirements
   - report data/reporting instructions
4. Keep wording factual and testable.
5. Preserve Phase 1 freeze and Phase 2 non-goals.
6. Record the QA notebook/self-test update in `README.md`.

Do not convert research ideas into active test cases until a design/handoff note says they are ready to validate. For example, Toronto Green P remains research-only unless a future handoff explicitly introduces a disabled/static prototype for testing.

## Phase Boundary Checks

Every Phase 2 validation pass must confirm:

- App remains local-only.
- Phase 1 core loop remains intact:
  - Start parking -> show countdown -> send reminder -> end session -> save history -> find saved spot on map.
- History remains map-only.
- Map search/filtering remains inside the map workflow.
- Green P / public parking work remains research-only unless a future handoff explicitly says a disabled/static prototype is ready to test.

## Standard Test Report Format

Use this structure for every feature report:

```markdown
# Phase 2 QA Report: <Feature>

Date: <YYYY-MM-DD>
Tester: Test / QA thread
Source document: <handoff or PHASE2_SELF_TEST.md>
Build / commit: <branch and SHA>
Device / simulator: <name and OS>

## 1. Feature Tested

<Feature name and scope.>

## 2. Test Cases Executed

| Case ID | Test type | Description | Result |
| --- | --- | --- | --- |
| P2-TC-XX | Automated / Manual | <description> | PASS / FAIL / BLOCKED / NOT RUN |

## 3. Passed Items

- <Passed behavior.>

## 4. Failed Items

- <Failed behavior or `None`.>

## 5. Reproduction Steps

1. <Step>
2. <Step>
3. <Observed result>
4. <Expected result>

## 6. Severity

P0 / P1 / P2 / P3 with reason.

## 7. Regression Risk

Low / Medium / High with reason.

## Debug Report For Debug Thread

### Summary

<Short bug or blocker summary.>

### Suspected Area

- <Store / view model / view / service / test harness / unknown>

### Evidence

- <Logs, screenshots, xcresult path, or manual notes.>

### Reproduction

1. <Step>
2. <Step>

### Expected

<Expected behavior from documentation.>

### Actual

<Observed behavior.>

### Severity / Risk

<Severity and regression risk.>
```

## Report Storage

Save managed Phase 2 reports under:

`Self_report/phase2/runs/<timestamp>_phase2_report/`

Required artifacts for full runs:

- `PHASE2_TEST_REPORT.md`
- `PHASE2_TEST_REPORT.xlsx`
- `PHASE2_TEST_REPORT_DATA.json`
- `xcodebuild_<timestamp>.log`
- `Phase2Tests_<timestamp>.xcresult`
- `attachments_manual/` when screenshots, videos, or manual notes are needed

## Current QA Focus

The current Phase 2 checkpoint covers:

- active-session `Remaining` / `Due Soon` / `Overdue`
- no negative countdown
- Apple Maps-style Map bottom sheet
- map-only History workflow
- local saved-history search
- adjustable nearby-history radius
- completed-late History timing accuracy
- ActivityKit / Dynamic Island first implementation and visual evidence gap
- Quick Start first implementation
- personal spot metadata
- personal metadata filter chips

## Debug Handoff Rule

At the end of each validation pass, include a Debug Report section even if no failure is found. If no bug is found, write:

`No Debug-thread action required for this pass.`
