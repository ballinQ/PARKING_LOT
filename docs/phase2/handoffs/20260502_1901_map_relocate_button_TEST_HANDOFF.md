# Test Handoff: Map Relocate Button

Date: 2026-05-02
Phase: Phase 2
Development thread owner: Codex
Test owner: Test/QA thread / Clawdbot

## Development Summary

Added a map relocate button that performs a one-shot current-location request and recenters the Map screen on the user's current location. The same nearby saved-history filtering path used by address search is reused for current location.

## Goal

Make the Map screen more useful and Apple Maps-like while staying local-only and preserving the map-first History workflow.

## Files Changed

- `SmartParkingReminder/SmartParkingReminder/App/AccessibilityIDs.swift` - added the relocate button accessibility identifier.
- `SmartParkingReminder/SmartParkingReminder/Views/Shared/ContentView.swift` - passes the existing one-shot location service into the Map tab.
- `SmartParkingReminder/SmartParkingReminder/Views/History/HistoryView.swift` - passes the location service into `HistoryMapView`.
- `SmartParkingReminder/SmartParkingReminder/ViewModels/HistoryMapViewModel.swift` - added current-location relocation state handling.
- `SmartParkingReminder/SmartParkingReminder/Views/Map/HistoryMapView.swift` - added the floating relocate button and one-shot relocation flow.
- `README.md` - development log and verification notes updated.
- `docs/phase2/PHASE2_ROADMAP.md` - map search/filtering feature notes updated.

## Functions / Types Changed

- `A11y.historyRelocateButton` - new identifier for the Map relocate button.
- `HistoryView.locationService` - injects the one-shot location service.
- `HistoryMapView.locationService` - receives the one-shot location service.
- `HistoryMapViewModel.relocateToCurrentLocation(_:)` - clears address search result state, sets current location as the search center, and applies nearby saved-history filtering.
- `HistoryMapViewModel.markRelocateFailure()` - records a user-visible status message when one-shot location fails.
- `HistoryMapView.relocateButton(in:)` - renders the floating map control.
- `HistoryMapView.relocateToCurrentLocation()` - performs the one-shot location request and recenters the camera.

## New Logic Introduced

- Tapping the relocate button requests current location once through `LocationServiceProtocol.currentCoordinateOnce()`.
- On success, the camera centers on the current coordinate, the sheet moves to medium, and nearby saved spots are filtered using the current radius.
- On failure, the sheet moves to medium and shows a permission/location failure message.
- The button shows a progress spinner and is disabled while relocation is in flight.

## Expected Behavior Summary

- The Map screen shows a compact floating relocate icon above the bottom sheet.
- Tapping it should relocate the map to the user's current location.
- Personal History remains map-only.
- No continuous/background location is started.
- Existing address search, local saved-history search, marker selection, and detail sheet behavior remain unchanged.

## Behavior Intentionally Not Changed

- Phase 1 core loop remains unchanged.
- History remains map-only.
- The old History list is not restored.
- No backend, login, cloud sync, analytics, ML, community behavior, public parking layer, or continuous background location added.
- No new formal test cases or QA runbook changes were created by the development thread.

## Known Risks

- Location permission denial or simulator location failure returns a user-visible failure message but does not show a permission-management flow.
- The button position follows the current bottom-sheet height and may need visual polish on very small devices.

## Known Limitations

- Relocation does not persist a "near me" search.
- Relocation uses the existing current radius filter; it does not introduce custom nearby preferences.
- No formal UI test was added by the development thread.

## Notes For Test/QA

- Treat this as a visible Map workflow feature.
- Suggested validation area: tap relocate with location permission available and confirm the map recenters and nearby saved history updates.
- Also check denied/unavailable location behavior and small-screen button placement.

