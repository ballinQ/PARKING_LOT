# Phase 2 Development Thread Responsibility

This document defines the responsibility of the main Phase 2 development thread.

## Role

Main product development and architecture implementation.

This thread focuses on design and implementation. Near the end of Phase 2, it also owns the development verification loop for its own changes: focused self-testing, build/simulator checks, blocking-debug fixes, documentation, and handoff notes. The Test/QA thread still owns formal test-case creation, test-document updates, full QA execution, formal reports, Excel reports, and manual evidence capture. The Debug thread owns deeper unrelated or non-blocking bug investigation.

## Responsibilities

### End-To-End Development Loop

When implementing Phase 2 release-candidate work, this thread should handle:

- UI design and SwiftUI implementation.
- Function and business-logic design.
- Code development.
- Focused unit/UI self-testing for changed behavior.
- Simulator/build/log checks when relevant.
- Debugging failures that block development-owned verification.
- Verification before declaring work complete.
- README, roadmap, and Test/QA handoff updates.

Preferred supporting skills and workflows:

- UI: use `build-ios-apps:swiftui-ui-patterns` when available.
- Business logic: use a test-driven loop for store/view-model/service behavior.
- Simulator/log checks: use `build-ios-apps:ios-debugger-agent` or approved `xcodebuild`/`simctl` flows.
- Failures: use systematic debugging; identify root cause before patching.
- Completion: verify with focused tests/builds or clearly document why verification could not run.

### Feature Development

- Design new features.
- Implement new features.
- Improve existing features.
- Maintain code consistency with the current app architecture.
- Keep Phase 1 behavior frozen unless the user explicitly approves a Phase 1 reliability fix.

### Architecture

- Keep architecture clean and scalable.
- Prevent unnecessary coupling.
- Maintain project structure consistency.
- Prefer existing stores, services, models, and view-model patterns before adding new abstractions.
- Keep behavior in stores/view models/services when it is app logic.
- Keep SwiftUI views focused on presentation and interaction.

### Development Logging

Maintain development records after every feature update.

Required for every completed task:

- feature or task name
- goal
- files changed
- functions/types changed
- new logic introduced
- expected behavior
- behavior intentionally not changed
- known risks
- known limitations
- notes for the Test/QA thread

Development records must be written in:

- `README.md` work log
- relevant design/architecture/roadmap documents when the task changes product direction or architecture
- a Test handoff document under `docs/phase2/handoffs/` when a feature or behavior slice is completed

## Scope Rules

Phase 2 development must remain:

- local-only
- no backend
- no login
- no cloud sync
- no analytics
- no machine learning
- no continuous background location tracking
- no old History list screen

Green P / public parking work is currently research only unless the source is official and reliable enough for a disabled/static prototype. Production Green P data belongs no earlier than Phase 3. Real-time availability, payment, or deeper integration belongs no earlier than Phase 4 and requires an official API or partnership.

## Development Rules

Before implementing:

- Read `README.md` first.
- Check `docs/phase2/PHASE2_ROADMAP.md` for feature order and phase boundaries.
- Check `docs/phase2/PHASE2_ARCHITECTURE_REVIEW.md` for known risks.
- Confirm the requested work does not violate Phase 1 freeze or Phase 2 non-goals.

During implementation:

- Prefer small, reviewable feature slices.
- Keep map features map-first.
- Do not revive the old History list.
- Do not add backend/cloud/ML/community features.
- Use focused tests for changed app logic and high-risk UI paths.
- Debug failures that block implementation or verification before handing off.
- Do not deeply investigate unrelated bugs unless they block the feature being developed.
- Do not create formal Test/QA runbook cases as a primary responsibility of this thread.
- Do not perform full formal QA as a primary responsibility of this thread.
- Do not update the Test/QA thread's test runbook as a primary responsibility of this thread.

After implementation:

- Run appropriate focused verification before saying complete.
- Update `README.md` work log.
- Update relevant design, architecture, or roadmap docs.
- Create or update the feature handoff for Test/QA.
- Record expected behavior clearly enough that the Test/QA thread can create or update test cases.
- Record known risks and limitations.

## What This Thread Does Not Own

This thread does not own:

- writing formal Test/QA runbook cases
- maintaining the Phase 2 self-test runbook as the source of QA truth
- running full formal QA
- producing final readiness reports
- generating Excel test reports
- collecting manual visual evidence
- deeply investigating unrelated or non-blocking bugs

Those belong to the Test/QA or Debug threads.

## Output Documents

### Development Log

Use `README.md` as the main development log unless the user asks for a separate `DEVELOPMENT_LOG.md`.

Each completed task entry should include:

- task name
- description
- files modified
- functions/types changed
- expected behavior
- risks
- notes for testing

### Test Handoff

At the end of each completed feature or behavior slice, create a handoff document under:

`docs/phase2/handoffs/`

Use this naming pattern:

`YYYYMMDD_HHMM_feature_name_TEST_HANDOFF.md`

The handoff is not a test case. It is a development summary that the Test/QA thread uses to create test cases and update the relevant test documents.

## Test Handoff Template

```markdown
# Test Handoff: <Feature Name>

Date: <YYYY-MM-DD>
Phase: Phase 2
Development thread owner: Codex
Test owner: Test/QA thread / Clawdbot

## Development Summary

<Short explanation of what changed and why.>

## Goal

<Product or architecture goal.>

## Files Changed

- `<path>` - <what changed>

## Functions / Types Changed

- `<Type.function>` - <what changed>

## New Logic Introduced

- <New logic or flow>

## Expected Behavior Summary

- <What the user or system should do after this change>

## Behavior Intentionally Not Changed

- Phase 1 core loop remains unchanged.
- App remains local-only.
- History remains map-only.
- No backend, login, cloud sync, analytics, ML, or continuous background location added.

## Known Risks

- <Risk for Test/QA to consider>

## Known Limitations

- <Limitations or accepted gaps>

## Notes For Test/QA

- <What Test/QA should consider when creating test cases>
- <Suggested areas to verify, without writing exact test cases>
```

## Current Handoff Expectations

For UI-visible features, the handoff should describe visible states, interaction states, and edge cases.

For store/view-model/service changes, the handoff should describe logic paths, inputs, outputs, and expected state transitions.

For Live Activity / Dynamic Island changes, the handoff should describe Lock Screen and Dynamic Island states that Test/QA should capture visually.

For Map changes, the handoff should describe:

- map-first workflow expectations
- whether personal history, search results, or future public layers are affected
- marker selection behavior
- search/filter state behavior
- how to return to a previous state

## Latest Rule Update

This development thread records design and implementation. The Test/QA thread creates test cases, updates test documents, runs QA, and writes formal reports.
