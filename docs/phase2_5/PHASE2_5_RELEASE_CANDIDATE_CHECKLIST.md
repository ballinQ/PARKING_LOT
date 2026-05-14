# Phase 2.5 Release Candidate Checklist

Status: draft.

## Source / Data

- [ ] Phase 2 is accepted or frozen.
- [ ] Green P/public parking source review is approved.
- [ ] Licence/terms allow bundled/static in-app display.
- [ ] Source attribution copy is approved.
- [ ] Stale-data warning copy is approved.
- [ ] Static catalog import report exists.
- [ ] At least 10 sampled lots were manually checked.

## App Behavior

- [ ] Public parking data is separate from personal history.
- [ ] Public markers use a distinct visual style.
- [ ] Personal history markers remain visible.
- [ ] Address search shows nearby static public parking when available.
- [ ] Search This Area refreshes static public parking candidates.
- [ ] Public detail sheet shows source/update warning.
- [ ] Directions handoff uses public lot coordinate.
- [ ] Missing rate fields are omitted, not guessed.

## Scope Guard

- [ ] No backend or Supabase implementation.
- [ ] No login/account.
- [ ] No cloud sync.
- [ ] No analytics.
- [ ] No ML/prediction.
- [ ] No real-time availability claim.
- [ ] No payment automation.
- [ ] No community/public user map.
- [ ] No continuous background location.
- [ ] No old History list.

## Verification

- [ ] Unit tests pass.
- [ ] Focused UI tests pass.
- [ ] Manual map visual review completed.
- [ ] Phase 2.5 report saved under `Self_report/phase2_5/runs/`.
- [ ] Test/QA handoff is complete.
- [ ] Debug-thread blockers are closed or documented as accepted risk.

## Final Decision

Release recommendation:

- [ ] READY
- [ ] READY WITH ACCEPTED RISK
- [ ] NOT READY

Reason:

```text
Fill in final recommendation reason here.
```

