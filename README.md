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

1. Open Map.
2. Search an address or nearby landmark.
3. The map relocates to that address.
4. Saved parking history near that searched area appears as markers.
5. Tap a marker to inspect recent sessions and navigation actions.

## Repo Layout

- `SmartParkingReminder/SmartParkingReminder.xcodeproj` - Xcode project.
- `SmartParkingReminder/SmartParkingReminder/` - app source.
- `SmartParkingReminder/SmartParkingReminderTests/` - unit tests.
- `SmartParkingReminder/SmartParkingReminderUITests/` - UI tests.
- `docs/phase1/PHASE1_SELF_TEST.md` - Clawdbot Phase 1 self-test runbook and reporting instructions.
- `docs/phase2/PHASE2_SELF_TEST.md` - Clawdbot Phase 2 self-test runbook and reporting instructions.
- `docs/phase2/PHASE2_ROADMAP.md` - Phase 2 product roadmap and implementation order.
- `docs/phase2/PHASE2_ARCHITECTURE_REVIEW.md` - Phase 2 architecture risks, sequencing, and preparation notes.
- `Self_report/phase1/runs/` - Phase 1 self-test report output folders.
- `Self_report/phase2/runs/` - reserved Phase 2 self-test report output folders.
- `scripts/generate_phase1_report.py` - dependency-free report generator.
- `scripts/generate_phase1_report.mjs` - Node wrapper that calls the Python generator.
- `tools/legacy-node-reporting/` - old `exceljs` install artifacts kept out of the active project root.

## Main App Pieces

- `ParkingSessionStore` is the single source of truth for sessions, active session state, countdown time, persistence, and notification scheduling/canceling.
- `ParkingSessionStorageService` persists sessions as local versioned JSON and still reads legacy Phase 1 bare-array JSON.
- `ParkingNotificationService` schedules local notifications at T-15 minutes and expiry.
- `LocationService` captures location once when starting a session.
- `HistoryMapView` is the only History UI now.
- `HistoryMapViewModel` groups saved sessions, performs address search with `MKLocalSearch`, filters nearby history within 1 km, and drives selected marker state.
- `ParkingSpotGroupingService` groups nearby sessions into a single marker using a simple 30 m threshold.
- `ParkingSpotDetailSheetView` shows grouped spot details, recent sessions, notes, counts, lat/lon, and Apple/Google Maps actions.
- `MapHandoffService` opens Apple Maps or Google Maps URLs. Prior Swift 6 sendability/main-actor warnings are fixed.
- `ParkingReminderActivityAttributes` defines the shared ActivityKit Live Activity payload.
- `ActivityKitParkingActivityLifecycleManager` starts, updates, restores, and ends Live Activities through the store lifecycle.
- `SmartParkingReminderWidgetExtension` renders the Lock Screen and Dynamic Island Live Activity UI.

## Phase 1 Feature Status

Implemented:

- Start parking session with location name, duration, optional note, and optional lat/lon.
- Home active-session card with countdown.
- Manual end parking flow.
- Local JSON persistence.
- Restore active/completed sessions after relaunch.
- Notification request scheduling and cancellation logic.
- Map with grouped saved spots.
- Address search in Map.
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

- Reviewed latest self-test report at `Self_report/phase1/runs/20260424_093917_phase1_report`.
- Found prior automated failure was only TC-07/TC-08 UI test querying the old History list as a table.
- Fixed earlier UI-test storage isolation with `UITEST_STORAGE_FILE`.
- Fixed app launch reload behavior so `ParkingSessionStore.start()` does not clobber in-memory UI state after saving.
- Added accessibility IDs for Home active/no-active states and map/detail-sheet test hooks.
- Fixed `ParkingNotificationService` async adapter recursion.
- Rewrote `docs/phase1/PHASE1_SELF_TEST.md` as a Clawdbot runbook with required Markdown, Excel, JSON, log, and `.xcresult` outputs.
- Added dependency-free Phase 1 report generation through `scripts/generate_phase1_report.py`.
- Changed History design from List/Map segmented mode to map-only.
- Added address search and nearby saved-history filtering to the Map.
- Updated UI tests so TC-07/TC-08 validates the Map detail sheet, not the removed list.
- Updated the self-test runbook to describe the new map-only History requirement.

2026-04-27:

- Renamed the user-facing History tab/title to `Map`.
- Added the collapsible `Personal History` side panel on the Map view.
- Fixed the Map detail UI test path to open saved spot details from the visible personal-history panel instead of the hidden SwiftUI Map test hook.
- Ran full Phase 1 automated self-test on iPhone 17 / iOS 26.2 Simulator.
- Latest managed report: `Self_report/phase1/runs/20260427_162344_phase1_report`.
- Automated result: 13 Xcode tests passed, 0 failed (`** TEST SUCCEEDED **`).
- Manual-only/manual-confirmation checks remain recorded in the report as `NOT RUN` where device permissions, notification delivery, visual map search, or external map handoff need human evidence.

2026-04-28:

- Created `docs/phase2/PHASE2_ROADMAP.md` and `docs/phase2/PHASE2_ARCHITECTURE_REVIEW.md` as planning-only documents before Phase 2 implementation.
- Confirmed Phase 2 direction: assistant upgrade, not platform expansion.
- Froze Phase 1 scope for Phase 2 planning: local-only, no backend, no login, no cloud sync, no analytics, no ML, no continuous background location, and no old History list.
- Decided Phase 2 should start with foundation work before user-facing feature expansion.
- First implementation target is Phase 2A foundation:
  - persistence schema versioning and migration safety
  - pure active-session display/status formatter
  - notification lifecycle audit for start/end/replacement/relaunch
  - Swift 6 warning cleanup around map handoff
- First user-visible Phase 2 feature should be improved active-session UI, especially due-soon and overdue states.
- First platform spike should be Live Activity / Dynamic Island after the display model and lifecycle rules are stable.
- Quick Start, personal spot metadata, richer map filtering, and nearby parking discovery research are intentionally later Phase 2 slices.
- Reorganized project folders before Phase 2:
  - Phase 1 runbook moved to `docs/phase1/`.
  - Phase 2 design documents moved to `docs/phase2/`.
  - Phase 1 self-test reports moved to `Self_report/phase1/runs/`.
  - Phase 2 report folder reserved at `Self_report/phase2/runs/`.
  - Legacy Node spreadsheet dependencies moved to `tools/legacy-node-reporting/`.
- Added `.gitignore` entries for macOS metadata, Python cache files, generated app test output, Xcode local state, and legacy Node dependency installs.
- Started Phase 2A foundation implementation.
- Added persistence schema versioning in `ParkingSessionStorageService`.
- New parking-session saves now write a versioned local envelope with `schemaVersion`, `savedAt`, and `sessions`.
- Existing Phase 1 bare `[ParkingSession]` JSON still loads for backward compatibility.
- Unsupported future storage schema versions now fail explicitly instead of silently decoding as current data.
- Added storage tests for versioned saves, legacy Phase 1 array loading, and unsupported future schema rejection.
- Added `ParkingSessionDisplayFormatter` for defensive time formatting and store-backed active-session timer display logic.
- `ParkingSessionStore.remainingTimeString(for:)` now delegates countdown formatting to the display formatter instead of owning formatting itself.
- Added store/display tests for active, due-soon, overdue, completed, and defensive negative interval formatting.
- Fixed `MapHandoffService` Swift 6 isolation/sendability warnings by making `URLLaunching` main-actor isolated, matching UIKit's sendable completion handler, and removing `UIApplication.shared` from the default argument path.
- Quiet build-for-testing no longer reports the prior `MapHandoffService.swift` warnings.
- Added `docs/phase2/PHASE2_NOTIFICATION_LIFECYCLE_AUDIT.md`.
- Added notification lifecycle coverage for active-session replacement, verifying the old session notification is canceled and the new session notification is scheduled.
- Focused unit verification passed: 17 tests, 0 failures, using `xcodebuild test -skip-testing:SmartParkingReminderUITests`.
- Turned the negative countdown fix into an explicit overdue timer feature.
- Added `ParkingSessionStatus` with `active`, `dueSoon`, and `overdue` states calculated in `ParkingSessionStore`.
- Added store-level overdue helpers while keeping the prior expired helper as a compatibility wrapper.
- Home active-session card now shows `Remaining`, `Due Soon`, or `Overdue` labels from the store timer display model.
- Overdue active sessions remain active until the user taps End Parking, but now show positive elapsed overdue time instead of `Expired` or a negative countdown.
- Added tests for future end time showing `Remaining`, end time within 15 minutes showing `Due Soon`, past active sessions showing `Overdue`, relaunch restore of overdue active sessions, and defensive negative interval formatting.
- Focused unit verification passed after the overdue timer feature: 18 tests, 0 failures, on iPhone 17 / iOS 26.2 Simulator.
- Redesigned the Map screen around an Apple Maps-style draggable bottom sheet.
- Default Map state now keeps the map visually dominant and shows only a compact search bar in the collapsed sheet.
- Dragging up or tapping search opens a medium sheet with the search bar, `Personal History` header, and a small saved-spot preview.
- Expanded sheet shows address search results plus nearby saved parking history rows inside the map workflow; the old separate History list remains removed.
- Search results are now stored in `HistoryMapViewModel`, and selecting a result recenters the map and filters nearby saved parking markers.
- Marker selection now opens spot/session details inside the same bottom-sheet flow instead of a separate large floating history card.
- Updated the map-detail UI test helper so existing history-map tests can open a saved spot from the new bottom-sheet workflow.
- Focused Map bottom-sheet UI verification passed: 2 UI tests, 0 failures, on iPhone 17 Simulator.
- Focused unit verification passed after the Map bottom-sheet change and search-state cleanup: 18 tests, 0 failures, on iPhone 17 Simulator.
- Continued Phase 2 active-session presence work.
- Redesigned the Home active-session card to make `Remaining`, `Due Soon`, and `Overdue` states visually distinct with a status capsule, state-specific color, progress bar, and clearer helper copy.
- Overdue Home display now reads `Overdue by ...` while still using the store-owned positive display interval.
- Added `home.sessionStatus` accessibility ID for stable UI testing of active-session state.
- Added a DEBUG/UI-test-only active-session launch seed so XCTest can open deterministic due-soon and overdue states without changing normal app behavior.
- Added focused UI tests for due-soon and overdue Home card states, including the rule that overdue sessions stay active until manual End Parking.
- Focused active-session UI verification passed: 2 UI tests, 0 failures, on iPhone 17 Simulator.
- Focused unit verification passed after the active-session card update: 18 tests, 0 failures, on iPhone 17 Simulator.
- Fixed a Phase 1 History detail accuracy bug where late completed sessions were counted only as `Completed` and not as overdue results.
- Added separate history timing outcome logic on `ParkingSession`: lifecycle remains `active`/`completed`, while timing result is `onTime`/`dueSoon`/`overdue`.
- `ParkingSpotGroup.timingSummary(now:)` now counts `On Time`, `Active`, and `Overdue`, so completed-late sessions appear in the `Overdue` statistic.
- Updated the spot detail sheet statistic boxes from `Completed / Active / Overdue` to `On Time / Active / Overdue`.
- Updated recent session rows to show combined lifecycle/timing labels such as `Completed · On time`, `Completed · Overdue`, and `Active · Overdue`.
- Recent session rows now show `Ended: ...` for completed sessions and `Overdue by ...` for completed-late or active-overdue sessions.
- Added tests for completed on-time count, completed-overdue count, active-overdue count, row overdue-duration text, and restored completed-overdue sessions after relaunch/load.
- Focused unit verification passed after the History timing fix: 23 tests, 0 failures, on iPhone 17 Simulator.
- Focused History map detail UI verification passed after the timing sheet update: 2 UI tests, 0 failures, on iPhone 17 Simulator.
- Continued Phase 2 from the notebook with a Live Activity / Dynamic Island readiness spike.
- Added `docs/phase2/PHASE2_LIVE_ACTIVITY_SPIKE.md` to record the app-side seam, privacy boundary, test result, and next real ActivityKit steps.
- Added a privacy-safe `ParkingActivitySnapshot` for future Live Activity display state: session ID, location name, expected end time, status, display time, display text, and update time.
- Added `ParkingActivityLifecycleManaging` with a no-op default manager so current app behavior remains unchanged until an ActivityKit-backed manager is built.
- Wired `ParkingSessionStore` to publish lifecycle events when a session starts, restores after relaunch, updates on the timer, or ends manually.
- Added tests for start snapshot publishing, manual end publishing, and overdue active-session restore publishing.
- Focused unit verification passed after the Live Activity readiness spike: 26 tests, 0 failures, on iPhone 17 Simulator.
- Added `docs/phase2/PHASE2_SELF_TEST.md` as the dedicated Phase 2 Clawdbot runbook.
- Phase 2 reports must now be saved under `Self_report/phase2/runs/<timestamp>_phase2_report/` with Markdown conclusion, Excel overview, JSON data, xcodebuild log, xcresult bundle, and manual evidence when needed.
- Initial Phase 2 self-test progress estimate recorded in the runbook: about 45% complete before the real Live Activity implementation pass.
- Implemented the first real ActivityKit-backed Live Activity pass.
- Added `SmartParkingReminderWidgetExtension` through `SmartParkingReminder/project.yml` and regenerated the Xcode project with XcodeGen.
- Added shared `ParkingReminderActivityAttributes` and a Lock Screen / Dynamic Island widget UI for active parking sessions.
- Added `ActivityKitParkingActivityLifecycleManager`, wired into normal app startup while UI tests still use the no-op notification/activity path.
- Live Activity requests use local ActivityKit only with `pushType: nil`; no backend, push service, cloud sync, analytics, ML, or continuous background location was added.
- Added a unit test for privacy-safe ActivityKit payload mapping.
- Build-for-testing verification passed with the widget extension embedded: `xcodebuild build-for-testing ... -derivedDataPath /tmp/SmartParkingReminderLiveActivityBuild2`.
- Focused unit verification passed after the ActivityKit implementation: 27 tests, 0 failures, on iPhone 17 Simulator.
- Phase 2 progress estimate updated after the first Live Activity implementation pass: about 55% complete.
- Implemented the first Quick Start parking pass.
- Added `ParkingSessionDraft` so the full New Session flow and Quick Start flow use the same `ParkingSessionStore.startNewSession(from:)` creation path.
- Home now shows compact Quick Start controls when there is no active session, with 30 min, 1 hr, and 2 hr starts.
- Quick Start uses one-shot current coordinate capture and a local-only suggested location name; no background location, backend, account, analytics, cloud, or ML was added.
- Preserved the existing full New Session behavior by routing it through a `.fullForm` draft.
- Added Quick Start unit coverage for draft-based session creation and using the most recent completed location as the next suggestion.
- Added Quick Start UI coverage for starting a 30 minute session from Home.
- Fixed the Quick Start accessibility wiring so the panel label and duration buttons have separate stable identifiers.
- Focused unit verification passed after Quick Start: 29 tests, 0 failures, on iPhone 17 Simulator.
- Focused Quick Start UI verification passed: 1 UI test, 0 failures, on iPhone 17 Simulator.
- Phase 2 progress estimate updated after the first Quick Start implementation pass: about 62% complete.

## Testing

Preferred Clawdbot full self-test command is documented in `docs/phase1/PHASE1_SELF_TEST.md`.

Preferred Clawdbot Phase 2 checkpoint self-test command is documented in `docs/phase2/PHASE2_SELF_TEST.md`.

For quick build verification:

```bash
xcodebuild build-for-testing \
  -project SmartParkingReminder/SmartParkingReminder.xcodeproj \
  -scheme SmartParkingReminder \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/SmartParkingReminderBuild
```

Latest full automated self-test result:

- Report folder: `Self_report/phase1/runs/20260427_162344_phase1_report`
- `** TEST SUCCEEDED **`
- Unit tests: 9 passed, 0 failed.
- UI tests: 4 passed, 0 failed.
- Prior `MapHandoffService.swift` Swift 6 sendability/main-actor isolation warnings were fixed during Phase 2A.

Latest Phase 2 focused unit check:

- Command: `xcodebuild test -project SmartParkingReminder/SmartParkingReminder.xcodeproj -scheme SmartParkingReminder -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:SmartParkingReminderTests -derivedDataPath /tmp/SmartParkingReminderQuickStartUnitTests3`
- Result: `** TEST SUCCEEDED **`
- Unit tests: 29 passed, 0 failed.

Latest Phase 2 focused Quick Start UI check:

- Command: `xcodebuild test -project SmartParkingReminder/SmartParkingReminder.xcodeproj -scheme SmartParkingReminder -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:SmartParkingReminderUITests/Phase1UITests/test_Phase2QuickStart_ThirtyMinutesStartsActiveSession -derivedDataPath /tmp/SmartParkingReminderQuickStartUITests2`
- Result: `** TEST SUCCEEDED **`
- UI tests: 1 passed, 0 failed.

Latest Phase 2 Live Activity build check:

- Command: `xcodebuild build-for-testing -project SmartParkingReminder/SmartParkingReminder.xcodeproj -scheme SmartParkingReminder -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/SmartParkingReminderLiveActivityBuild2`
- Result: `** TEST BUILD SUCCEEDED **`
- Coverage: app target, unit/UI test bundles, and embedded `SmartParkingReminderWidgetExtension.appex`.

Latest Phase 2 focused active-session UI check:

- Command: `xcodebuild test -project SmartParkingReminder/SmartParkingReminder.xcodeproj -scheme SmartParkingReminder -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:SmartParkingReminderUITests/Phase1UITests/test_Phase2ActiveSession_DueSoonStateIsVisible -only-testing:SmartParkingReminderUITests/Phase1UITests/test_Phase2ActiveSession_OverdueStateIsVisibleWithoutAutoEnding -derivedDataPath /tmp/SmartParkingReminderActiveSessionUITests`
- Result: `** TEST SUCCEEDED **`
- UI tests: 2 passed, 0 failed.

Latest Phase 2 focused Map bottom-sheet UI check:

- Command: `xcodebuild test -project SmartParkingReminder/SmartParkingReminder.xcodeproj -scheme SmartParkingReminder -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:SmartParkingReminderUITests/Phase1UITests/test_TC07_TC08_EndSession_AppearsInHistoryMapDetail -only-testing:SmartParkingReminderUITests/Phase1UITests/test_TC11_TC12_MapDetailSheet_ShowsSpotInfoAndActions -derivedDataPath /tmp/SmartParkingReminderHistoryTimingUITests`
- Result: `** TEST SUCCEEDED **`
- UI tests: 2 passed, 0 failed.

Latest Phase 2 full simulator check:

- Command: `xcodebuild test -project SmartParkingReminder/SmartParkingReminder.xcodeproj -scheme SmartParkingReminder -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2' -derivedDataPath /tmp/SmartParkingReminderMapPanelTests -resultBundlePath /tmp/SmartParkingReminderMapPanelTests/MapPanelTests.xcresult`
- Result: `** TEST SUCCEEDED **`
- Unit tests: 17 passed, 0 failed.
- UI tests: 4 passed, 0 failed.

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

- Always update this README work log after meaningful project changes so future agents can orient here first.
- Do not bring the History list back unless the user explicitly changes the product decision.
- Search should improve the map workflow, not become a separate results list.
- Keep Phase 1 simple: no advanced clustering, no ML, no backend.
- Avoid Node spreadsheet dependencies in this iCloud workspace; prior `exceljs`/`jszip` imports hung. Use the Python report generator.
- Be careful with the dirty worktree. There are existing generated/user changes and report folders. Do not revert unrelated files.
- Prefer `build-for-testing` locally; ask Clawdbot to run full simulator tests.
- Live Activity now has a first ActivityKit/widget implementation. Device/simulator visual verification is still needed for Lock Screen and Dynamic Island presentation.
- Quick Start now has a first local-only implementation. Keep future polish on the same `ParkingSessionDraft` / store creation path.

## Next Good Improvements

- Tag/freeze the Phase 1 baseline before Phase 2 code work.
- Ask Clawdbot to run the Phase 2 self-test, including Quick Start, and manually verify Live Activity presentation on a supported simulator/device.
- Next implementation slice should be map-only search/filtering abstraction or personal spot metadata groundwork after the Phase 2 checkpoint report is saved.

## Phase 2 Direction

Phase 2 implementation order is now defined in `docs/phase2/PHASE2_ROADMAP.md` and `docs/phase2/PHASE2_ARCHITECTURE_REVIEW.md`.

Recommended order:

1. Persistence schema versioning and migration safety.
2. Pure active-session display/status formatter with tests.
3. Notification lifecycle audit.
4. Swift 6 warning cleanup.
5. Improved active/due-soon/overdue session UI.
6. Real ActivityKit-backed Live Activity manager and widget extension.
7. Quick Start on the same session creation path.
8. Map-only search/filtering improvements.
9. Personal spot metadata after storage versioning is stable.
10. Nearby parking discovery research only.
