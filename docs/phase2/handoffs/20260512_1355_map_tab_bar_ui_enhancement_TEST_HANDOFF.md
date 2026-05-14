# Test Handoff: Map Tab Bar UI Enhancement

Date: 2026-05-12
Phase: Phase 2
Development thread owner: Codex
Test owner: Test/QA thread / Clawdbot

Superseded: this handoff was replaced later on 2026-05-12 by `docs/phase2/handoffs/20260512_1408_floating_mode_switch_TEST_HANDOFF.md`. Use the floating mode switch handoff as the current source of truth.

## Development Summary

The Map screen now hides the standard bottom tab bar and provides a compact floating `Home` control inside the Map surface. This prevents the Home/Map switch bar from visually blocking or competing with the Map search/bottom sheet.

## Goal

Make the Map screen feel more Apple Maps-like and keep the search sheet visually clean, while keeping Home one tap away.

## Files Changed

- `SmartParkingReminder/SmartParkingReminder/Views/Shared/ContentView.swift` - added explicit tab selection and Home return closure.
- `SmartParkingReminder/SmartParkingReminder/Views/History/HistoryView.swift` - hides the system tab bar on Map and passes Home return action.
- `SmartParkingReminder/SmartParkingReminder/Views/Map/HistoryMapView.swift` - adds floating `Home` button.
- `SmartParkingReminder/SmartParkingReminder/App/AccessibilityIDs.swift` - added the original Map return button ID, later superseded by `modeSwitch.mapButton` and `modeSwitch.homeButton`.
- `SmartParkingReminder/SmartParkingReminderUITests/Phase1UITests.swift` - adds focused UI coverage.
- `README.md` - records development log.

## Functions / Types Changed

- `ContentView` - now owns local `selectedTab` state.
- `AppTab` - new private enum for `home` and `map` selection.
- `HistoryView` - accepted a Home-return callback in this superseded design.
- `HistoryMapView` - rendered a Map-only return button in this superseded design.

## New Logic Introduced

- Map-only tab bar hiding through SwiftUI toolbar visibility.
- Floating Map `Home` control calls back to `ContentView` and switches the selected tab to Home.

## Expected Behavior Summary

- On Home, the normal Home/Map tab bar remains visible.
- Tapping Map opens the Map screen and hides the standard tab bar.
- The collapsed Map search sheet is no longer blocked by the Home/Map bar.
- The floating `Home` button is visible near the top-left of the Map.
- Tapping the floating `Home` button returns to Home and restores the standard tab bar.
- Map search, personal history, marker details, relocate, and Search This Area behavior remain unchanged.

## Behavior Intentionally Not Changed

- Phase 1 core loop remains unchanged.
- App remains local-only.
- History remains map-only.
- No backend, login, cloud sync, analytics, ML, or continuous background location added.
- No old History list screen was reintroduced.

## Known Risks

- Visual spacing should be checked on smaller devices to confirm the floating `Home` button does not compete with future top overlays or the `Search This Area` control.
- UI tests that assume the old tab bar remains visible should use the current `modeSwitch.mapButton` / `modeSwitch.homeButton` flow instead.

## Known Limitations

- Development verification did not capture a reliable XcodeBuildMCP screenshot for this exact Map state because the MCP UI snapshot returned an empty hierarchy after launch.
- Focused XCTest did verify the navigation behavior.

## Notes For Test/QA

- Verify Home tab bar visibility on Home.
- Verify Map tab bar hiding and that the collapsed search sheet has clean bottom spacing.
- This handoff is superseded; verify the current floating mode switch behavior instead.
- Verify expanded sheet, spot detail, relocate, and Search This Area are not blocked by the floating Home control.
