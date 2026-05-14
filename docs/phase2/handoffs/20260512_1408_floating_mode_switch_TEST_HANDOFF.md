# Test Handoff: Floating Mode Switch

Date: 2026-05-12
Phase: Phase 2
Development thread owner: Codex
Test owner: Test/QA thread / Clawdbot

## Development Summary

The app now uses a single floating circular mode switch instead of the standard Home/Map tab bar. Home shows a Map icon; Map shows a Home icon. This keeps the Map screen cleaner and avoids the bottom tab bar competing with the Map search sheet.

## Goal

Make switching between the app's two modes feel lighter, more intentional, and less disruptive to the Map surface.

## Files Changed

- `SmartParkingReminder/SmartParkingReminder/Views/Shared/ContentView.swift` - replaces `TabView` with explicit mode state and floating switch.
- `SmartParkingReminder/SmartParkingReminder/Views/History/HistoryView.swift` - removes Home-return callback and tab-bar hiding.
- `SmartParkingReminder/SmartParkingReminder/Views/Map/HistoryMapView.swift` - removes previous top Home pill.
- `SmartParkingReminder/SmartParkingReminder/App/AccessibilityIDs.swift` - adds `modeSwitch.mapButton` and `modeSwitch.homeButton`.
- `SmartParkingReminder/SmartParkingReminderUITests/Phase1UITests.swift` - updates Map navigation to use the floating mode switch.
- `README.md` - records development log.

## Functions / Types Changed

- `ContentView` - now owns `selectedMode` instead of `TabView(selection:)`.
- `AppMode` - private Home/Map mode enum with icon, accessibility, padding, and toggle helpers.
- `FloatingModeSwitchButton` - private circular material-style switch button.
- `HistoryView` / `HistoryMapView` - removed `onReturnHome` dependency.

## New Logic Introduced

- Home/Map switching is now explicit local SwiftUI state in `ContentView`.
- The floating switch toggles to the opposite mode and changes icon/accessibility ID based on current mode.
- Tests use `modeSwitch.mapButton` to enter Map and `modeSwitch.homeButton` to return Home.

## Expected Behavior Summary

- No standard system tab bar is visible.
- Home shows a circular Map switch near the lower-left.
- Tapping the Map switch opens Map.
- Map shows a circular Home switch near the lower-left, positioned above the collapsed search sheet.
- Tapping the Home switch returns to Home.
- Map search, personal history, marker details, relocate, and Search This Area behavior remain unchanged.

## Behavior Intentionally Not Changed

- Phase 1 core loop remains unchanged.
- App remains local-only.
- History remains map-only.
- No backend, login, cloud sync, analytics, ML, or continuous background location added.
- No old History list screen was reintroduced.

## Known Risks

- The switch bottom padding is fixed per mode; Test/QA should visually check smaller devices and expanded Map sheet states.
- UI tests or external scripts that still use `app.tabBars.buttons["Map"]` must switch to `modeSwitch.mapButton`.

## Known Limitations

- The glass style uses iOS 17-compatible native material rather than iOS 26-only Liquid Glass APIs.
- Development did not run the full UI test suite for this slice.

## Notes For Test/QA

- Verify the standard tab bar is absent on Home and Map.
- Verify the switch is circular, compact, and glass-like.
- Verify the switch does not block Home primary actions or Map search/detail controls.
- Verify existing Map workflows still open through `modeSwitch.mapButton`.
