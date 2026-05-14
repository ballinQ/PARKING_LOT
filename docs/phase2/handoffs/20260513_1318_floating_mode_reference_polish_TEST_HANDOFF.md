# Phase 2 Test Handoff: Floating Mode Reference Polish

Date: 2026-05-13
Owner: Development thread
Scope: Phase 2 UI polish

## Development Summary

Adjusted the shared Home/Map mode switch and collapsed Map search surface to better match the user's visual reference. The switch now sits in the lower-right corner, and the collapsed Map screen reads as a compact floating search capsule with a separate circular Home switch beside it.

## Goal

Make the Home to Map transition and resting Map layout feel closer to the provided Apple Maps-style reference while keeping the app's two-mode navigation simple and map-first.

## Files Changed

- `SmartParkingReminder/SmartParkingReminder/Views/Shared/ContentView.swift` - moved the shared floating switch from lower-left to lower-right and adjusted Map-mode bottom spacing.
- `SmartParkingReminder/SmartParkingReminder/Views/Map/HistoryMapView.swift` - removed the visible full-width bottom-card treatment from collapsed Map state and reserved trailing room for the circular Home switch.
- `README.md` - recorded the development log entry.

## Functions / Types Changed

- `ContentView.body` - changed the overlay alignment and trailing padding for the shared mode switch.
- `AppMode.switchBottomPadding` - reduced Map-mode bottom spacing so the Home switch aligns with the collapsed search capsule.
- `HistoryMapView.bottomSheet(in:)` - conditionally hides the drag handle and large material sheet background when collapsed.
- `HistoryMapView.sheetBackground` - new presentation helper for collapsed versus expanded/medium sheet backgrounds.
- `HistoryMapView.sheetShape` - new presentation helper for collapsed versus expanded/medium clipping.

## New Logic Introduced

- Collapsed Map state now uses a transparent bottom-sheet container with only the search capsule visible.
- Collapsed Map state adds trailing room so the search capsule does not sit under the lower-right Home switch.
- Medium and expanded states still use the existing rounded material sheet treatment.

## Expected Behavior Summary

- Home shows the circular Map switch at the lower-right.
- Tapping the switch opens Map using the existing transition behavior.
- Map collapsed state shows a compact search capsule and a separate circular Home switch at the lower-right.
- Map medium/expanded states still show the normal draggable sheet content.
- Search, Personal History, selected marker details, relocate, and Search This Area behavior should remain unchanged.

## Behavior Intentionally Not Changed

- Phase 1 core loop remains unchanged.
- App remains local-only.
- History remains map-only.
- No backend, login, cloud sync, analytics, ML, community map, or continuous background location was added.
- No old History list screen was restored.

## Verification

Build:

```bash
xcodebuild build-for-testing \
  -project SmartParkingReminder/SmartParkingReminder.xcodeproj \
  -scheme SmartParkingReminder \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/SmartParkingReminderFloatingModeReferenceBuild
```

Result: `** TEST BUILD SUCCEEDED **`

Focused UI:

```bash
xcodebuild test \
  -project SmartParkingReminder/SmartParkingReminder.xcodeproj \
  -scheme SmartParkingReminder \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:SmartParkingReminderUITests/Phase1UITests/test_Phase2ModeSwitch_TogglesBetweenHomeAndMapWithoutTabBar \
  -derivedDataPath /tmp/SmartParkingReminderFloatingModeReferenceUITests
```

Result: `** TEST SUCCEEDED **`

Runtime launch:

- XcodeBuildMCP `build_run_sim` result: `SUCCEEDED`
- Home screenshot: `/var/folders/1t/jt00hh9n531g8csbnk5vmfm00000gn/T/screenshot_optimized_5e481e41-c326-4899-ac62-5e44b8ea0f65.jpg`

## Known Risks

- XCTest verifies the mode switch flow and collapsed landing state, but it does not judge animation quality.
- XcodeBuildMCP coordinate tapping did not switch from Home to Map during the manual screenshot attempt, although the focused XCTest tap passed. Test/QA should visually verify the Map-side resting state on simulator/device.

## Notes For Test/QA

- Compare Home lower-right switch placement against the reference image.
- Compare Map collapsed state against the reference: search capsule on the lower-left/center, circular Home switch on the lower-right, map visible behind.
- Verify the collapsed sheet no longer looks like a large bottom card.
- Verify dragging/tapping search still opens medium/expanded content.
- Verify the lower-right switch does not block Start Parking, Search, relocated controls, Search This Area, or marker/detail flows.
