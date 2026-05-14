# Phase 2 Test Handoff: Home to Map Transition Animation

Date: 2026-05-13
Owner: Development thread
Scope: Phase 2 UI polish

## Summary

Added a subtle SwiftUI matched-geometry transition from the lower-left Home Map mode switch into the Map screen collapsed search bar. The goal is to make the Map surface feel like it expands/emerges from the tapped Home control without changing Map behavior.

## Files Changed

- `SmartParkingReminder/SmartParkingReminder/Views/Shared/ContentView.swift`
- `SmartParkingReminder/SmartParkingReminder/Views/History/HistoryView.swift`
- `SmartParkingReminder/SmartParkingReminder/Views/Map/HistoryMapView.swift`
- `SmartParkingReminder/SmartParkingReminderUITests/Phase1UITests.swift`
- `README.md`

## New Behavior

- On Home, tapping the circular `modeSwitch.mapButton` switches to Map with a short `0.38s` smooth transition.
- The transition visually links the Home Map switch and the Map collapsed search bar through `matchedGeometryEffect`.
- After the transition completes, the Map remains in its normal collapsed state:
  - map visible
  - search field visible
  - keyboard closed
  - Personal History/search panel not expanded
  - no marker/detail sheet opened

## Expected Unchanged Behavior

- The lower-left floating switch still toggles between Home and Map.
- The Map remains map-first and History remains map-only.
- Tapping the Map search field later still expands the bottom sheet as before.
- No parking-session, timer, notification, storage, map-search, metadata, backend, cloud, analytics, ML, or old History list behavior was intentionally changed.

## Test Notes

Development updated the existing focused UI test:

- `Phase1UITests.test_Phase2ModeSwitch_TogglesBetweenHomeAndMapWithoutTabBar`

The test now verifies:

- standard system tab bar is absent
- Home shows `modeSwitch.mapButton`
- tapping it opens Map
- `history.searchField` appears
- `historySearchPanel` is not present immediately after transition
- keyboard is not open immediately after transition
- Map shows `modeSwitch.homeButton`
- tapping it returns Home

## Verification Run

Build:

```bash
xcodebuild build-for-testing \
  -project SmartParkingReminder/SmartParkingReminder.xcodeproj \
  -scheme SmartParkingReminder \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/SmartParkingReminderHomeMapTransitionBuild
```

Result: `** TEST BUILD SUCCEEDED **`

Focused UI:

```bash
xcodebuild test \
  -project SmartParkingReminder/SmartParkingReminder.xcodeproj \
  -scheme SmartParkingReminder \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:SmartParkingReminderUITests/Phase1UITests/test_Phase2ModeSwitch_TogglesBetweenHomeAndMapWithoutTabBar \
  -derivedDataPath /tmp/SmartParkingReminderHomeMapTransitionUITests
```

Result: `** TEST SUCCEEDED **`

## Manual QA Suggestions

- Watch the Home to Map transition on simulator/device and confirm it feels like the search bar grows from the Home Map switch.
- Confirm the animation is subtle and does not feel slow or distracting.
- Confirm the Map lands collapsed with no keyboard and no full history/details panel.
- Confirm repeated Home/Map toggles do not leave stale animation artifacts.
- Confirm tapping the Map search field after transition still opens the normal sheet workflow.

## Risks / Limitations

- XCTest verifies landing state, not animation quality. Visual review is still needed.
- The matched-geometry effect depends on SwiftUI view reconciliation across the current `ZStack` mode switch; if future navigation structure changes, this animation should be visually rechecked.
