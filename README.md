# Smart Parking Reminder

Local-only iOS MVP for recording a parking session, saving where the car is, showing a countdown, sending local reminders, and reviewing saved parking spots on a map.

This README is also the project handoff note for Codex, Clawdbot, and any other AI agent. Read this first before scanning the whole folder.

## Current Direction

Phase 1 should be boringly reliable before Phase 2 starts.

The app is intentionally local-only:

- no backend
- no login
- no cloud sync
- no analytics
- no machine learning
- no continuous background location tracking

Current UX decision: History is map-only. The old History list was removed because it was not useful enough. The better flow is:

1. Open History.
2. Search an address or nearby landmark.
3. The map relocates to that address.
4. Saved parking history near that searched area appears as markers.
5. Tap a marker to inspect recent sessions and navigation actions.

## Repo Layout

- `SmartParkingReminder/SmartParkingReminder.xcodeproj` - Xcode project.
- `SmartParkingReminder/SmartParkingReminder/` - app source.
- `SmartParkingReminder/SmartParkingReminderTests/` - unit tests.
- `SmartParkingReminder/SmartParkingReminderUITests/` - UI tests.
- `PHASE1_SELF_TEST.md` - Clawdbot self-test runbook and reporting instructions.
- `Self_report/` - self-test report output folders.
- `scripts/generate_phase1_report.py` - dependency-free report generator.
- `scripts/generate_phase1_report.mjs` - Node wrapper that calls the Python generator.

## Main App Pieces

- `ParkingSessionStore` is the single source of truth for sessions, active session state, countdown time, persistence, and notification scheduling/canceling.
- `ParkingSessionStorageService` persists sessions as local JSON.
- `ParkingNotificationService` schedules local notifications at T-15 minutes and expiry.
- `LocationService` captures location once when starting a session.
- `HistoryMapView` is the only History UI now.
- `HistoryMapViewModel` groups saved sessions, performs address search with `MKLocalSearch`, filters nearby history within 1 km, and drives selected marker state.
- `ParkingSpotGroupingService` groups nearby sessions into a single marker using a simple 30 m threshold.
- `ParkingSpotDetailSheetView` shows grouped spot details, recent sessions, notes, counts, lat/lon, and Apple/Google Maps actions.
- `MapHandoffService` opens Apple Maps or Google Maps URLs. It still has Swift 6 sendability warnings but builds.

## Phase 1 Feature Status

Implemented:

- Start parking session with location name, duration, optional note, and optional lat/lon.
- Home active-session card with countdown.
- Manual end parking flow.
- Local JSON persistence.
- Restore active/completed sessions after relaunch.
- Notification request scheduling and cancellation logic.
- History map with grouped saved spots.
- Address search in History map.
- Nearby-history filtering around searched address.
- Marker detail sheet with recent sessions and navigation buttons.
- UI-test mode that avoids permission prompts using deterministic location and noop notification center.

Removed:

- History list mode.
- `SessionRowView.swift`.
- History list accessibility/test hooks.

Manual verification still needed:

- Real device or simulator notification delivery.
- Location permission prompt behavior on device.
- Visual map behavior with real GPS coordinates.
- Apple Maps and Google Maps handoff on device.

## Recent Work Log

2026-04-24:

- Reviewed latest self-test report at `Self_report/20260424_093917_phase1_report`.
- Found prior automated failure was only TC-07/TC-08 UI test querying the old History list as a table.
- Fixed earlier UI-test storage isolation with `UITEST_STORAGE_FILE`.
- Fixed app launch reload behavior so `ParkingSessionStore.start()` does not clobber in-memory UI state after saving.
- Added accessibility IDs for Home active/no-active states and map/detail-sheet test hooks.
- Fixed `ParkingNotificationService` async adapter recursion.
- Rewrote `PHASE1_SELF_TEST.md` as a Clawdbot runbook with required Markdown, Excel, JSON, log, and `.xcresult` outputs.
- Added dependency-free Phase 1 report generation through `scripts/generate_phase1_report.py`.
- Changed History design from List/Map segmented mode to map-only.
- Added address search and nearby saved-history filtering to the History map.
- Updated UI tests so TC-07/TC-08 validates the History map detail sheet, not the removed list.
- Updated the self-test runbook to describe the new map-only History requirement.

## Testing

Preferred Clawdbot full self-test command is documented in `PHASE1_SELF_TEST.md`.

For quick build verification:

```bash
xcodebuild build-for-testing \
  -project SmartParkingReminder/SmartParkingReminder.xcodeproj \
  -scheme SmartParkingReminder \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/SmartParkingReminderBuild
```

Known local limitation for Codex in this environment: full simulator `xcodebuild test` may fail because CoreSimulatorService access is restricted. Clawdbot should run the real self-test and save logs/reports.

Latest build-for-testing result after the History map/search change:

- `** TEST BUILD SUCCEEDED **`
- Remaining warnings are in `MapHandoffService.swift` about Swift 6 sendability/main-actor isolation.

## Phase 1 Self-Test Deliverables

Clawdbot should save each run under a timestamped folder and include:

- `PHASE1_TEST_REPORT.md` - conclusion report with reasons for failures.
- `PHASE1_TEST_REPORT.xlsx` - Excel overview of all test cases.
- `PHASE1_TEST_REPORT_DATA.json` - structured source data for the report.
- `xcodebuild_<timestamp>.log` - full test log.
- `Phase1Tests_<timestamp>.xcresult` - Xcode result bundle.
- manual screenshots/logs where required.

Important current test mapping:

- TC-07/TC-08 UI test: `Phase1UITests.test_TC07_TC08_EndSession_AppearsInHistoryMapDetail`
- TC-11/TC-12 UI test: `Phase1UITests.test_TC11_TC12_MapDetailSheet_ShowsSpotInfoAndActions`
- TC-14 UI test: `Phase1UITests.test_TC14_Relaunch_RestoresActiveSession`

## Agent Notes

- Do not bring the History list back unless the user explicitly changes the product decision.
- Search should improve the map workflow, not become a separate results list.
- Keep Phase 1 simple: no advanced clustering, no ML, no backend.
- Avoid Node spreadsheet dependencies in this iCloud workspace; prior `exceljs`/`jszip` imports hung. Use the Python report generator.
- Be careful with the dirty worktree. There are existing generated/user changes and report folders. Do not revert unrelated files.
- Prefer `build-for-testing` locally; ask Clawdbot to run full simulator tests.

## Next Good Improvements

- Add a focused unit test for `HistoryMapViewModel` search filtering if MapKit search can be injected/mocked cleanly.
- Improve `MapHandoffService` protocol isolation to remove Swift 6 warnings.
- Add small visual polish to the History map search overlay after Clawdbot confirms functional tests.
- Add screenshots to the self-test evidence for map-only History behavior.

## Phase 2 Parking Lot

Only after Phase 1 is stable:

- frequent parking spot summaries
- smarter history visualization
- favorite/recent spots
- personalized reminder suggestions
- risk scoring
- ML prediction of forgetfulness risk
