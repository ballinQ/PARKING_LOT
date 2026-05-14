# Test Handoff: Map Search This Area

Date: 2026-05-06
Phase: Phase 2
Development thread owner: Codex
Test owner: Test/QA thread / Clawdbot

## Development Summary

Added an Apple Maps-style `Search This Area` control to the Map. The control appears after manual map pan/zoom and lets the user refresh nearby saved Personal History markers around the currently visible map center.

## Goal

Keep the Map workflow map-first while giving users a clear way to search the area they are currently looking at, without reintroducing the old History list or adding any backend/public parking layer.

## Files Changed

- `SmartParkingReminder/SmartParkingReminder/Views/Map/HistoryMapView.swift` - tracks visible camera center, shows/hides the floating control, and routes taps into the view model.
- `SmartParkingReminder/SmartParkingReminder/ViewModels/HistoryMapViewModel.swift` - adds `searchThisMapArea(center:)` and reuses existing nearby saved-history filtering.
- `SmartParkingReminder/SmartParkingReminder/App/AccessibilityIDs.swift` - adds `history.searchThisAreaButton`.
- `SmartParkingReminder/SmartParkingReminderTests/Phase1ModelAndLogicTests.swift` - adds focused logic coverage for the new view-model behavior.
- `README.md` - records the development log and verification result.
- `docs/phase2/PHASE2_ROADMAP.md` - records the map-filtering polish as part of Phase 2.

## Functions / Types Changed

- `HistoryMapView.handleMapCameraChange(_:)` - stores the visible map center and marks the map as manually changed when appropriate.
- `HistoryMapView.searchThisAreaButton(in:)` - renders the compact floating button.
- `HistoryMapView.searchThisMapArea()` - sends the visible center to the view model and returns the bottom sheet to a medium map-workflow state.
- `HistoryMapView.setMapCamera(_:)` - centralizes app-driven camera updates so the floating button does not appear after programmatic recenter/search/detail camera moves.
- `HistoryMapView.shouldDisplaySearchThisAreaButton` - hides the control for detail, relocation, and expanded-sheet states.
- `HistoryMapViewModel.searchThisMapArea(center:)` - clears address search text/results, sets `searchCenter`, labels the status as `this map area`, reapplies existing radius/metadata filtering, and clears selected details.
- `A11y.historySearchThisAreaButton` - stable UI-test identifier.

## New Logic Introduced

- Manual camera movement now makes the visible map center available as a local search center.
- App-driven camera changes are temporarily ignored so normal search/recenter/detail transitions do not flash the button.
- `Search This Area` keeps the existing selected radius and metadata filters.
- Address search result rows are cleared when the user chooses to search the visible map area.
- Spot markers remain Personal History markers only.

## Expected Behavior Summary

- Opening Map still follows current location or Toronto fallback as before.
- Recenter still uses current location or Toronto fallback as before.
- After the user pans or zooms the map, `Search This Area` appears as a compact floating button when no detail is open and the bottom sheet is not expanded.
- Tapping the button refreshes nearby saved spots around the visible map center and shows status text using `this map area`.
- Current radius selection continues to control how far nearby saved spots are included.
- Active metadata filters remain applied.
- Selecting markers/details keeps the user inside the map-only History workflow.

## Behavior Intentionally Not Changed

- Phase 1 core loop remains unchanged.
- App remains local-only.
- History remains map-only.
- The old History list screen was not restored.
- No backend, login, cloud sync, analytics, ML, public/community map, Green P production layer, or continuous background location was added.

## Known Risks

- Manual UI validation should confirm the button placement does not conflict with the navigation bar, Dynamic Island/safe area, or the bottom sheet on smaller screens.
- SwiftUI Map camera callbacks may feel slightly different on real device versus simulator, especially during fast gestures.
- The current implementation uses a short ignore window after programmatic camera changes; Test/QA should watch for unwanted button flashes after search, detail selection, recenter, and initial location focus.

## Known Limitations

- This is personal saved-history filtering only; it does not search external parking data.
- The button does not appear while the sheet is expanded because the useful map area is mostly covered.
- No UI automation for physical map pan gestures was added in this development slice; Test/QA should decide whether to keep this as manual coverage or add a simulator gesture test.

## Notes For Test/QA

- Create/update checks for opening Map, panning away, seeing `Search This Area`, tapping it, and verifying nearby Personal History markers/status update for the visible area.
- Verify radius changes still update results after `Search This Area`.
- Verify favorite/tag/rating filters remain active after `Search This Area`.
- Verify tapping a marker/detail hides or avoids blocking the detail flow.
- Verify recenter remains separate and still returns to current location or Toronto fallback.
- Suggested accessibility ID for automation: `history.searchThisAreaButton`.

## Development Verification

- Focused unit check passed: 3 tests, 0 failures.
- Build-for-testing check passed: `** TEST BUILD SUCCEEDED **`.
