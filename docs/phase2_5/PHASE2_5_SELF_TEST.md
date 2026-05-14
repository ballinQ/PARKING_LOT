# Phase 2.5 Self-Test Runbook

Status: draft for Clawdbot/Test thread. Use after a Phase 2.5 feature handoff says a slice is ready to validate.

## Scope

Phase 2.5 validates static Toronto Green P / public parking discovery only.

Do not validate or require:

- backend
- Supabase
- login/account
- cloud sync
- analytics
- ML/prediction
- real-time availability
- payment automation
- community/public user map
- continuous background location
- old History list

## Report Folder

Save each Phase 2.5 run under:

`Self_report/phase2_5/runs/<YYYYMMDD_HHMMSS>_phase2_5_report/`

Required artifacts:

- `PHASE2_5_TEST_REPORT.md` - conclusion report with reasons for failures.
- `PHASE2_5_TEST_REPORT.xlsx` - Excel overview of all test cases.
- `PHASE2_5_TEST_REPORT_DATA.json` - structured report data.
- `xcodebuild_<timestamp>.log` - full build/test log.
- `.xcresult` bundle for automated runs.
- screenshots/manual evidence for map marker and public detail validation.

## Source Review Tests

Before visible UI:

- Confirm `PHASE2_5_GREENP_SOURCE_REVIEW.md` has an approved source decision.
- Confirm source/licence allows in-app display.
- Confirm source/licence allows bundled/cached static data.
- Confirm source attribution and stale-data warning are approved.
- Confirm no real-time availability source is claimed unless official live support exists.

If source review is not approved, result is **NOT READY FOR VISIBLE GREEN P UI**.

## Static Catalog Validation Tests

Expected validation coverage:

- rejects duplicate provider lot IDs
- rejects invalid coordinates
- rejects missing source URL
- rejects missing source attribution
- rejects unofficial real-time availability claim
- handles missing optional rate fields by omitting them from UI
- distance-sorts nearby lots
- keeps public catalog separate from personal history storage

## Map Workflow Tests

When visible marker layer exists:

- Open Map.
- Confirm personal history markers remain visible.
- Search a Toronto address.
- Confirm nearby Green P/public markers appear as a distinct layer.
- Use Search This Area and confirm public candidates refresh for visible map area.
- Tap a public marker.
- Confirm public detail sheet appears.
- Confirm detail sheet shows source/update warning.
- Confirm directions handoff uses public lot coordinate.
- Confirm no old History list appears.

## No-Claim Tests

Confirm the UI does not show:

- "available spaces"
- "real-time availability"
- "live occupancy"
- "pay now"
- "reserve"
- "community report"
- "synced"
- "account"

## Release Recommendation

Use one:

- `READY` - all automated and required manual checks passed.
- `READY WITH ACCEPTED RISK` - only documented manual/source limitations remain.
- `NOT READY` - source review, data validation, map behavior, or no-claim checks failed.

