# Phase 2.5 Roadmap: Toronto Static Green P Discovery

Status: planned. Do not implement user-visible Green P features until Phase 2 is accepted or frozen and source review is approved.

## Product Goal

Phase 2.5 bridges Phase 2 and Phase 3 by adding Toronto Green P / public parking discovery from verified static data only.

Target user flow:

1. User opens Map or searches an address.
2. Map continues showing personal parking history.
3. If source review is approved, nearby static Green P/public parking options appear as a separate marker layer.
4. Tapping a public parking marker opens a detail sheet with address, distance, verified rate fields when available, directions, and a clear source/update warning.

## Scope

Allowed:

- official source/licence review
- static bundled public parking catalog
- import/validation tooling and import report
- separate public parking marker layer
- public lot detail sheet
- address search and Search This Area integration
- conservative source/update warnings

Not allowed:

- backend or Supabase implementation
- login/account
- cloud sync
- community/public user map
- real-time availability claims
- payment automation or Green P app payment integration
- ML/prediction
- analytics
- continuous background location
- old History list

Supabase/database planning may be mentioned only as Phase 3+ architecture discussion.

## Feature Order

### 1. Source Validation First

- Identify official or clearly reliable Green P/public parking source.
- Confirm licence/terms allow in-app static display and bundled/cached data.
- Confirm available fields: lot ID, address, lat/lon, rates, facility type, EV, height restriction, source URL, and last updated date.
- Record source decision in `PHASE2_5_GREENP_SOURCE_REVIEW.md`.
- No visible UI work until this is approved.

### 2. Static Catalog Foundation

- Keep public/provider data separate from personal history and personal spot metadata.
- Reuse or refine dormant models: `ParkingSource`, `PublicParkingLot`, and `GreenPParkingLot`.
- Add static catalog validation/import tooling before bundling any data.
- Produce an import report for every bundled catalog revision.

### 3. Map Layer Prototype

- Add a separate Green P/public parking marker layer.
- Keep personal history markers visible.
- Visually distinguish personal spots from public lots.
- Never show live availability unless a future official live source is approved.

### 4. Search Flow Integration

- Address search and Search This Area should refresh nearby personal history and nearby static public parking candidates.
- Radius behavior should be predictable and local.
- History remains map-only.

### 5. Release Polish

- Public detail sheet shows verified fields only.
- Detail sheet includes source/update warning.
- Directions handoff uses the public lot coordinate.
- Phase 2.5 self-test and release checklist must pass or explicitly record accepted risk.

## Exit Criteria

- Source/licence review is approved or Phase 2.5 is explicitly stopped before visible UI.
- Static catalog validation rejects unsafe data.
- No real-time availability wording appears.
- Personal history data remains local-only and separate.
- Map remains the only History surface.
- Public parking markers and detail sheet pass focused automated/manual checks.
- No backend/cloud/ML/community scope leaks into Phase 2.5.

