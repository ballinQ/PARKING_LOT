# Phase 2 Debug Thread Responsibility

This document defines the responsibility of the Phase 2 Debug thread.

This thread is for bug investigation, root-cause analysis, safe fix planning, and targeted patches when the user asks for a fix. It should not drive unrelated Phase 2 feature work or UI redesign.

## Core Responsibility

The Phase 2 Debug thread should:

- Read test reports from the Test thread or Clawdbot.
- Investigate failed or suspicious test results.
- Reproduce failures when possible.
- Identify root causes in code, data, tests, or documentation.
- Discuss newly discovered user-reported bugs.
- Propose safe fixes before making changes when risk is non-trivial.
- Prepare targeted patches only for confirmed bugs or reliability issues.
- Recommend focused and regression retests after every fix.

## Scope Rules

Debug work must remain focused on bugs only.

Allowed:

- Fixing failing tests.
- Fixing user-reported defects.
- Fixing regressions caused by recent Phase 2 work.
- Adding or updating tests that prove a bug is fixed.
- Updating README and relevant Phase 2 runbooks to record the bug, fix, and retest result.

Not allowed unless explicitly requested:

- Implementing unrelated features.
- Redesigning UI.
- Expanding Phase 2 scope.
- Adding backend, login, cloud sync, analytics, ML, community features, continuous background location, or the old History list.
- Reworking architecture beyond what is needed for a safe fix.

## Bug Investigation Format

Every investigation should use this structure:

1. Issue summary
2. Root cause
3. Affected files
4. Fix strategy
5. Regression risk
6. Retest recommendation

Short investigations can be concise, but they should still answer each item.

## Bug Sources

Accepted bug sources:

- Test thread reports.
- Clawdbot managed self-test reports.
- User-discovered bugs.
- Local focused test failures found while reproducing a reported issue.

Do not invent speculative bugs as implementation tasks. Record speculative concerns as risks only.

## Investigation Workflow

Before changing code:

- Read `README.md` first for current project state.
- Read the relevant test report or user bug description.
- Identify the smallest likely affected area.
- Inspect existing tests before adding new ones.
- Check whether the bug violates Phase 1 frozen behavior or a Phase 2 acceptance criterion.

During debugging:

- Prefer focused reproduction over broad refactoring.
- Keep edits small and local to the failing behavior.
- Preserve map-only History.
- Preserve local-only behavior.
- Do not revert unrelated dirty worktree changes.
- Avoid changing UI layout unless the bug is specifically a usability or accessibility blocker.

After a fix:

- Add or update a focused regression test when feasible.
- Run the focused test first.
- Run broader unit/UI tests if shared logic or navigation behavior changed.
- Update `README.md` with the bug fix and verification result.
- Update `docs/phase2/PHASE2_SELF_TEST.md` if the bug changes expected test behavior or adds a new regression case.

## Fix Recommendation Template

```markdown
# Bug Fix Recommendation: <Bug Name>

Date: <YYYY-MM-DD>
Phase: Phase 2
Debug owner: Codex
Source: Test thread / Clawdbot / User report

## 1. Issue Summary

<What failed or what the user observed.>

## 2. Root Cause

<Why it happened. Include code path, state mismatch, timing issue, data issue, or test issue.>

## 3. Affected Files

- `<path>` - <why it matters>

## 4. Fix Strategy

- <Smallest safe fix>
- <Tests to add/update>

## 5. Regression Risk

- <Low/Medium/High>
- <What nearby behavior could be affected>

## 6. Retest Recommendation

- Focused: `<test or manual step>`
- Regression: `<broader suite or report run>`
```

## Patch Rules

When a patch is needed:

- Patch only the bug.
- Keep unrelated feature work out of the diff.
- Prefer existing patterns and services.
- Add focused regression tests close to the affected behavior.
- Keep documentation updates factual and brief.

## Report Reading Notes

When reading a Test thread report:

- Check final readiness first.
- List all `FAIL`, `BLOCKED`, and accepted-risk `NOT RUN` items.
- Separate product bugs from test-environment or evidence gaps.
- Do not mark visual/manual evidence gaps as code bugs unless they reveal an actual product defect.

## Latest Rule Update

This document is the standing contract for the Phase 2 Debug thread. Future agents should use it when the user identifies this thread as the debug lane.
