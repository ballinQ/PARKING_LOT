# Test Handoff: Personal Spot Display Name

Date: 2026-05-02
Phase: Phase 2
Development thread owner: Codex
Test owner: Test/QA thread / Clawdbot

## Development Summary

Exposed the existing local-only saved spot `displayName` metadata field in the Map spot detail sheet. Users can now rename a personal saved spot from the existing Personal Details area, and the sheet title uses that saved display name.

## Goal

Make personal saved spots feel more useful without adding a separate History list, backend, cloud sync, analytics, ML, or public/community behavior.

## Files Changed

- `SmartParkingReminder/SmartParkingReminder/App/AccessibilityIDs.swift` - added an accessibility identifier for the display-name text field.
- `SmartParkingReminder/SmartParkingReminder/Views/Map/ParkingSpotDetailSheetView.swift` - added a `Spot name` field to the Personal Details section.
- `README.md` - development log and verification notes updated.
- `docs/phase2/PHASE2_ROADMAP.md` - personal metadata current-slice notes updated.

## Functions / Types Changed

- `A11y.detailSpotDisplayNameField` - new identifier for the spot display-name field.
- `PersonalSpotMetadataView.body` - now renders a `Spot name` text field bound to `SavedParkingSpotMetadata.displayName`.

## New Logic Introduced

- Editing `Spot name` updates the existing `SavedParkingSpotMetadata.displayName` field.
- Whitespace-only values clear the custom display name.
- The existing `ParkingSpotGroup.displayName` behavior continues to decide whether to show the custom name or fall back to the derived group name.

## Expected Behavior Summary

- Opening a saved spot detail still happens inside the Map bottom-sheet workflow.
- The Personal Details section now includes favorite, rating, tags, spot name, and spot note.
- Entering a spot name should update the saved spot title locally.
- Clearing the spot name should return the title to the derived saved-history name.
- Saved spot display names remain local-only.

## Behavior Intentionally Not Changed

- Phase 1 core loop remains unchanged.
- History remains map-only.
- The old History list is not restored.
- No backend, login, cloud sync, analytics, ML, community behavior, public parking layer, or continuous background location added.
- No new formal test cases or QA runbook changes were created by the development thread.

## Known Risks

- The text field saves through the same best-effort local metadata path as notes, favorites, ratings, and tags.
- If storage fails, the in-memory edit remains visible for the current app session, matching existing metadata behavior.

## Known Limitations

- There is no separate rename confirmation.
- There is no duplicate-name warning.
- Custom spot names are still tied to the current coordinate-bucket-based spot ID, not a future first-class `SavedSpot` model.

## Notes For Test/QA

- Treat this as a visible Map detail metadata polish.
- Suggested validation area: rename a saved spot, close/reopen the detail, and verify the custom name remains local-only and map-first.
- Also consider clearing the name and confirming the derived title returns.

