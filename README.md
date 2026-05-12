# Smart Parking Reminder

Local-only iOS MVP for recording a parking session, saving where the car is, showing a countdown, sending local reminders, and reviewing saved parking spots on a map.

This README is also the project handoff note for Codex, Clawdbot, and any other AI agent. Read this first before scanning the whole folder.

## Current Direction

Phase 2 is in progress, with Phase 1 behavior frozen as the reliability baseline.

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
- `docs/phase2/PHASE2_PRIVACY_DATA_BOUNDARY.md` - local-only privacy rules for location-derived Phase 2 assistant behavior.
- `docs/phase2/PHASE2_WIDGET_SHARED_STATE_DECISION.md` - App Group/shared-state decision for current Live Activities and future widgets.
- `docs/phase2/PHASE2_TEST_QA_THREAD.md` - Phase 2 Test/QA thread rules, report format, and Debug-thread handoff format.
- `docs/phase2/PHASE2_DEVELOPMENT_THREAD_RESPONSIBILITY.md` - main Phase 2 development-thread responsibility, documentation rules, and Test handoff template.
- `docs/phase2/PHASE2_DEBUG_THREAD_RESPONSIBILITY.md` - Phase 2 debug-thread responsibility, bug investigation format, and fix recommendation template.
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
- `HistoryMapViewModel` groups saved sessions, asks an injectable map search provider for address results, filters nearby history within 1 km, and drives selected marker state.
- `HistoryMapFilteringService` applies pure saved-history filtering for local text search, nearby radius results, and personal metadata filters.
- `HistoryMapMarkerItem` gives map markers explicit layer/source identity so future public parking layers do not mix directly with personal-history groups.
- `PublicParkingLot`, `GreenPParkingLot`, and related source/rate/availability models are dormant Phase 2 architecture for future public parking research; they are not wired into UI or data loading.
- `MapKitSearchProvider` is the production address search adapter over `MKLocalSearch`; tests can inject fake providers without network/MapKit search.
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
- Fixed a Phase 1 History detail UX trap inside the map-only bottom-sheet workflow.
- Saved spot detail now has a visible `< Personal History` back control at the top of the detail sheet.
- Tapping Back clears the selected detail state, keeps the map region/markers visible, and returns to the prior History/search panel state.
- Added stable accessibility identifiers: `historyDetailBackButton`, `historySpotDetailSheet`, `historySearchPanel`, and `historyPreviewPanel`.
- Added UI coverage for opening a History detail, tapping Back, and confirming the user returns to the History/search panel without leaving Map.
- Focused History back UI verification passed: 3 UI tests, 0 failures, on iPhone 17 Simulator.
- Continued Phase 2 map-search foundation work.
- Extracted direct address lookup from `HistoryMapViewModel` into `MapSearchProviding` with a production `MapKitSearchProvider`.
- Added deterministic unit coverage for successful address search filtering nearby saved history, and for search failure keeping existing personal history visible.
- Regenerated the Xcode project with XcodeGen so `MapSearchProviding.swift` is included.
- Focused Map search provider tests passed: 2 unit tests, 0 failures, on iPhone 17 Simulator.
- Full unit verification passed after the map search provider seam: 31 tests, 0 failures, on iPhone 17 Simulator.
- Phase 2 progress estimate after the map search provider foundation: about 64% complete.

2026-04-29:

- Ran the first managed Phase 2 self-test and saved the report set under `Self_report/phase2/runs/20260429_165543_phase2_report`.
- Final Phase 2 readiness from this run: `READY WITH ACCEPTED MANUAL RISK`.
- Final full simulator verification passed on iPhone 17 / iOS 26.2 Simulator: 31 unit tests + 8 UI tests, 0 failures.
- Generated required Phase 2 report deliverables:
  - `PHASE2_TEST_REPORT.md`
  - `PHASE2_TEST_REPORT.xlsx`
  - `PHASE2_TEST_REPORT_DATA.json`
  - `xcodebuild_20260429_165543_final.log`
  - `Phase2Tests_20260429_165543_final.xcresult`
  - `attachments_manual/README.md`
- Initial sandboxed xcodebuild attempt was blocked because Xcode could only see placeholder simulators; reran with CoreSimulator access and preserved the blocked log.
- First full rerun exposed two UI-test fixture failures caused by stale per-test storage restoring old active sessions.
- Fixed UI test isolation in `Phase1UITests` by assigning a unique `UITEST_STORAGE_FILE` for each test run.
- Adjusted the seeded Due Soon UI state to use a safer 12 minute offset.
- Focused rerun of the two previously failing UI tests passed: 2 UI tests, 0 failures.
- Final full rerun passed and is the official evidence bundle for this checkpoint.
- Scope scan found no forbidden Phase 2 app-code additions: no backend, login, cloud sync, analytics, ML, continuous background location, or old History list.
- Remaining accepted manual risk: Live Activity / Dynamic Island visual presentation still needs supported simulator or device evidence before the Live Activity feature is called release-ready.

2026-04-30:

- Continued Phase 2 map-only search/filtering polish after the first managed Phase 2 checkpoint.
- Added a local nearby-history radius control to the Map bottom sheet after an address is selected.
- Radius options are 500 m, 1 km, and 2 km; changing radius recomputes visible saved spots without running another address lookup.
- `HistoryMapViewModel` now owns `HistorySearchRadius` and keeps radius filtering testable outside SwiftUI.
- Added `history.searchRadiusPicker` accessibility ID for future UI coverage.
- Added unit coverage for changing search radius from 500 m to 2 km and verifying visible saved history updates.
- Focused map-radius verification passed: 3 unit tests, 0 failures, on iPhone 17 Simulator.
- Full unit verification passed after the map-radius slice: 32 tests, 0 failures, on iPhone 17 Simulator.
- Phase 2 progress estimate after the radius control: about 66% complete.
- Added local saved-history text search inside the same Map search field.
- Typing now filters Personal History locally by grouped spot name, past session location names, and notes.
- Pressing Search still runs address lookup through the `MapSearchProviding` seam; if address lookup fails, saved history remains visible or local matches stay shown.
- The Map search placeholder now reads `Search address or saved spot`, and address results are labeled separately from Personal History rows.
- Added unit coverage for local name/note matching and no-address-result fallback to local history matches.
- Focused local History search verification passed: 4 unit tests, 0 failures, on iPhone 17 Simulator.
- Full unit verification passed after local History search: 34 tests, 0 failures, on iPhone 17 Simulator.
- Phase 2 progress estimate after local History search: about 68% complete.
- Continued Phase 2 Live Activity verification.
- Found and fixed the missing app target `NSSupportsLiveActivities` declaration.
- Added a DEBUG-only `LIVE_ACTIVITY_TESTING` launch mode that seeds a deterministic parking session, uses the real ActivityKit lifecycle manager, avoids notification prompts, and can auto-end for dismissal evidence.
- Verified the built app Info.plist now contains `NSSupportsLiveActivities => true`.
- ActivityKit simulator logs now confirm Live Activity request, creation, active updates, end, dismissal, and removal.
- Saved the Live Activity verification report and evidence under `Self_report/phase2/runs/20260430_152900_live_activity_verification/`.
- Debug build-for-testing and Release simulator build both passed after the verification hook cleanup.
- Phase 2 progress estimate after Live Activity lifecycle verification: about 71% complete.
- Fixed Dynamic Island / Live Activity timer text so it uses SwiftUI live timer rendering instead of a frozen `timeText` string from the ActivityKit payload.
- Countdown and overdue views now render from `expectedEndTime`, allowing the system Live Activity UI to tick while the app is not foregrounded.
- Added defensive date-range clamping around the widget timer text to avoid invalid ranges at the scheduled end boundary.
- Build verification passed after the Dynamic Island timer fix on iPhone 17 Pro Simulator.
- Reduced Dynamic Island information density after the live timer fix made the Island reserve too much space.
- Compact Island now shows only the parking icon and a short live timer; no location/status text is shown in Dynamic Island.
- Interim expanded Island density was reduced before the final icon-plus-timer direction below removed Dynamic Island text entirely.
- Build verification passed after the compact Dynamic Island layout fix on iPhone 17 Pro Simulator.
- Fixed a stale Dynamic Island status-color issue where the parking `P` icon stayed on the old color until the app reopened.
- Live Activity visible status/color now derives from `expectedEndTime` inside the widget using a periodic timeline, so `Remaining`, `Due Soon`, and `Overdue` presentation can update without waiting for the app store to publish a new ActivityKit state.
- Build verification passed after the Dynamic Island status-color fix on iPhone 17 Pro Simulator.
- Final Dynamic Island direction for this slice: icon plus live timer only. The detailed label/location/status text remains on the Lock Screen Live Activity, not in Dynamic Island.
- Tightened the Dynamic Island footprint by reducing the icon font size and timer frame width; iOS still controls the final minimum capsule size.
- Started the next Phase 2 feature: local-only personal spot metadata inside the existing Map detail sheet.
- Added saved spot metadata for favorite, 1-5 rating, local tags, and a spot-level note without adding backend, cloud, ML, analytics, or an old History list.
- Personal metadata persists in a separate local JSON envelope, is attached to map spot groups by stable spot ID, and is included in local Map search matching.
- Added focused unit coverage for metadata storage round-trip, metadata-backed search, and selection staying visible after metadata edits.
- Continued the personal metadata slice with local Map filter chips for All, Favorites, 4+ Stars, and supported tags.
- Metadata filters compose with address radius search and local saved-history search, while keeping markers/results inside the Map bottom-sheet workflow.
- Added focused unit coverage for favorite-only filtering and metadata filters combined with nearby address radius filtering.
- Continued Quick Start polish with a local recent-duration option derived from the most recent completed session.
- Quick Start still keeps the 30 min, 1 hr, and 2 hr defaults, and only adds a rounded recent duration when it is not already one of those defaults.
- The Home Quick Start row now scrolls horizontally so additional local presets do not crowd the main screen.
- Added focused unit coverage for recent-duration Quick Start suggestions and confirmed the suggested duration still uses the shared `ParkingSessionDraft.quickStart` path.
- Created `docs/phase2/PHASE2_DEBUG_THREAD_RESPONSIBILITY.md` for the Phase 2 Debug thread.
- Debug thread scope is now documented as bug investigation and targeted fixes only, using the required issue summary/root cause/affected files/fix strategy/regression risk/retest recommendation format.
- Fixed the Phase 2 Live Activity stale-status bug in the Debug thread.
- Live Activity content state is now date-driven with session ID, location name, start date, scheduled end date, and last updated date; the widget no longer depends on stored formatted countdown strings.
- Dynamic Island and Lock Screen status/timer now render from `ContentState.scheduledEndDate`, so status can transition while the app is locked/suspended.
- Removed foreground timer-driven `Activity.update` calls from `ParkingSessionStore`; Live Activity updates are now reserved for real events such as start, add time, end, and launch reconciliation.
- Added local add-time store support that persists the new scheduled end date, reschedules local notifications, and publishes a date-driven Live Activity update.
- App launch reconciliation now restores/updates the active Live Activity when an active session exists, and asks ActivityKit to end orphaned activities when no active session exists.
- Added focused regression coverage for date-driven ActivityKit payload, add-time Live Activity updates, and no-active-session orphan cleanup.
- Added `docs/phase2/PHASE2_DEVELOPMENT_THREAD_RESPONSIBILITY.md` to define this thread as the main Phase 2 development thread, including required change records and the Test Handoff Document template.
- Updated the Phase 2 development-thread responsibility so this thread is development-only: it records design/implementation and handoff summaries, while Test/QA owns test-case creation, test-document updates, QA runs, and formal reports.
- Continued Phase 2 map architecture preparation by extracting pure saved-history filtering from `HistoryMapViewModel` into `HistoryMapFilteringService`.
- Local text search, address-radius filtering, and metadata filter chips now share the same testable filtering service while keeping the existing Map UI behavior unchanged.
- Added direct unit coverage for filtering service metadata text matching and nearby metadata-filter composition.
- Created Test Handoff: `docs/phase2/handoffs/20260501_1545_history_map_filtering_service_TEST_HANDOFF.md`.
- Continued Phase 2 map-layer architecture preparation by adding `HistoryMapMarkerItem` and `HistoryMapLayerKind`.
- Personal history markers and the search-area marker now have explicit layer/source identity while preserving the current Map UI behavior.
- Created Test Handoff: `docs/phase2/handoffs/20260501_1605_history_map_layer_model_TEST_HANDOFF.md`.
- Continued Phase 2 public parking architecture preparation by adding dormant `ParkingSource`, `PublicParkingLot`, and `GreenPParkingLot` model types.
- Public parking availability now has explicit semantics so the app cannot claim real-time availability unless both the source and lot availability are official real-time.
- No Green P/public parking UI, bundled data, network loading, backend, cloud, analytics, ML, payment, or production layer was added.
- Created Test Handoff: `docs/phase2/handoffs/20260502_0929_public_parking_models_TEST_HANDOFF.md`.
- Continued Phase 2 architecture preparation with `docs/phase2/PHASE2_PRIVACY_DATA_BOUNDARY.md`.
- Documented hard local-only privacy rules for parking sessions, one-shot location, Live Activity payloads, personal spot metadata, Quick Start suggestions, Map search state, and future public parking source metadata.
- Marked the roadmap privacy-notes checklist item complete; this was documentation-only and did not change app UI, storage, networking, tests, backend, cloud, analytics, ML, or community behavior.
- Created Test Handoff: `docs/phase2/handoffs/20260502_0934_privacy_data_boundary_TEST_HANDOFF.md`.
- Continued Phase 2 Live Activity/widget architecture design with `docs/phase2/PHASE2_WIDGET_SHARED_STATE_DECISION.md`.
- Decided the current Phase 2 Live Activity does not need App Group shared storage because ActivityKit content state already carries the minimal extension-safe display payload.
- Documented future App Group review triggers for regular widgets, widget controls, saved/favorite spot widgets, persisted widget preferences, or public parking provider caches.
- Updated the roadmap, architecture review, Live Activity spike notes, and Phase 2 document index with the shared-state decision.
- Created Test Handoff: `docs/phase2/handoffs/20260502_1142_widget_shared_state_decision_TEST_HANDOFF.md`.
- Continued Phase 2 personal spot metadata polish by exposing the existing local-only saved spot `displayName` field in the Map detail sheet.
- The Personal Details section now includes a `Spot name` field alongside favorite, rating, tags, and spot note.
- Custom spot names remain local-only, persist through the existing saved-spot metadata envelope, and stay inside the map-only History workflow.
- Added accessibility ID `spotDetail.displayName` for the new field.
- Created Test Handoff: `docs/phase2/handoffs/20260502_1650_personal_spot_display_name_TEST_HANDOFF.md`.
- Added a floating Map relocate button that requests current location once, recenters the map, and reuses the existing nearby saved-history radius/filter workflow.
- Passed the existing `LocationServiceProtocol` from `ContentView` into the Map tab instead of creating a new location service.
- Added accessibility ID `history.relocateButton` for the relocate control.
- Relocation remains local-only and does not add continuous/background location tracking.
- Created Test Handoff: `docs/phase2/handoffs/20260502_1901_map_relocate_button_TEST_HANDOFF.md`.
- Improved real-device Map startup behavior so the Map tab always renders a map, shows `UserAnnotation()`, starts with `MapCameraPosition.userLocation(followsHeading:fallback:)`, and falls back to Toronto if location is denied or unavailable.
- Toronto fallback is latitude `43.6532`, longitude `-79.3832`, with `0.03` latitude/longitude span.
- Fixed one-shot permission timing in `LocationService` so a fresh When In Use grant can request location after authorization changes instead of racing the prompt.
- Created Test Handoff: `docs/phase2/handoffs/20260502_1909_map_initial_location_behavior_TEST_HANDOFF.md`.

2026-05-05:

- Fixed the Map/History detail sheet layout and keyboard bug from the Phase 2 Debug thread.
- The Map bottom sheet now reserves extra scrollable bottom space so detail-sheet action buttons are not hidden by the floating tab bar or home indicator.
- The bottom sheet now lifts above the keyboard, keeping search results and Personal History rows physically tappable while the search field is focused.
- Added a keyboard `Done` toolbar for the Map search field and kept keyboard dismissal on map tap, sheet drag, and search submit.
- Kept the map-only History workflow intact; no old History list, backend, cloud, ML, analytics, or continuous background location behavior was added.
- Updated `docs/phase2/PHASE2_SELF_TEST.md` with keyboard, safe-area, and small-screen manual checks for `P2-TC-09`.
- Focused search-to-detail UI regression passed on iPhone 17 Pro Simulator: `Phase1UITests.test_Phase2HistoryMapSearch_LocalNoteSearchOpensMatchingSpotDetail`.
- Focused detail action visibility UI regression passed on iPhone 17 Pro Simulator: `Phase1UITests.test_TC11_TC12_MapDetailSheet_ShowsSpotInfoAndActions`.
- Fixed the Phase 1 / Phase 1.1 regression bundle before deeper Phase 2 work:
  - Quick Start now always creates sessions named `Quick Start` instead of reusing the most recent saved spot name.
  - Manual Start now supports precise custom duration selection with hour/minute wheels plus 15 min, 30 min, 1 hr, and 2 hr presets.
  - Invalid zero-minute session drafts are rejected at the store boundary.
  - Map address search now keeps Personal History visible, ranks nearby saved spots by distance from the selected result, and fits the map camera to the selected result plus nearby history markers.
  - Search result camera range now respects broad MapKit result regions when available and uses a close range for specific address results.
  - Live Activity / Dynamic Island state was rechecked against the date-driven contract: ActivityKit content remains based on session ID, location name, start date, scheduled end date, and last-updated date, with updates only on real session events.
- Updated `docs/phase1/PHASE1_SELF_TEST.md` and `docs/phase2/PHASE2_SELF_TEST.md` with the new Quick Start, map search, Live Activity, and Manual Start regression checks.
- Fixed the Map range-filter camera-scale bug from the Phase 2 Debug thread.
- The Map already used a mutable `Map(position: $camera)` binding; the missing behavior was that radius button taps updated filtering only, not camera zoom.
- `HistoryMapViewModel.selectedRangeMeters` now drives both nearby-history filtering and range-camera construction.
- Tapping 500 m, 1 km, or 2 km now animates the map camera around the active search/current-location center using the selected range.
- Selecting a search result now recenters with the current selected range while keeping nearby Personal History visible inside the map workflow.
- Added unit coverage for selected-range camera scale and selected-result centering.

2026-05-06:

- Continued Phase 2 Map polish with an Apple Maps-style `Search This Area` control.
- `HistoryMapView` now tracks the visible map center from SwiftUI MapKit camera updates and shows a compact floating `Search This Area` button after manual pan/zoom.
- The button is hidden while a spot detail is open, while relocation is running, or when the bottom sheet is expanded enough to cover the useful map area.
- Tapping `Search This Area` uses the current visible map center as the local search center, clears address result rows, keeps the selected radius, preserves metadata filters, and refreshes nearby Personal History markers.
- Recenter remains unchanged: it still uses current location or Toronto fallback, while `Search This Area` uses the visible map center.
- Added accessibility ID `history.searchThisAreaButton`.
- Added focused unit coverage for nearby filtering, metadata-filter preservation, and clearing address results.
- Created Test Handoff: `docs/phase2/handoffs/20260506_1413_map_search_this_area_TEST_HANDOFF.md`.
- Focused Search This Area unit verification passed: 3 tests, 0 failures, on iPhone 17 Pro Simulator.
- Build-for-testing verification passed after the Search This Area slice: `xcodebuild build-for-testing ... -derivedDataPath /tmp/SmartParkingReminderSearchThisAreaBuild`.
- Started the Phase 2 release-candidate polish pass while Test/QA and Debug can continue in parallel.
- Tightened the Map bottom sheet states so collapsed is smaller, medium shows a lighter preview, expanded remains the full search/history state, and floating controls avoid covered/detail/keyboard-heavy states.
- Reduced medium-sheet Personal History preview density to keep the map-first workflow dominant.
- Polished the saved-spot metadata section to read as a lightweight local saved-spot editor instead of a heavy form, while keeping spot name, favorite, rating, tags, and note local-only.
- Polished Quick Start visual treatment so it stays compact and secondary to the full Start Parking flow while still using the shared `ParkingSessionDraft.quickStart` path.
- Polished Lock Screen Live Activity code-side presentation by aligning the status row and applying the date-derived status color to the parking label; Dynamic Island remains icon plus timer only.
- Added `docs/phase2/PHASE2_RELEASE_CANDIDATE_CHECKLIST.md`.
- Created Test Handoff: `docs/phase2/handoffs/20260506_1526_phase2_release_candidate_polish_TEST_HANDOFF.md`.
- Build-for-testing verification passed after the release-candidate polish pass: `xcodebuild build-for-testing ... -derivedDataPath /tmp/SmartParkingReminderPhase2RCPolishBuild`.
- Focused release-candidate UI sanity verification passed: Quick Start, Map detail content/actions, and History detail Back flow, 3 UI tests, 0 failures.

2026-05-12:

- Updated the project-local `phase2-develop` skill for the end-of-Phase-2 execution mode.
- Development thread now explicitly owns UI design, function/business-logic design, implementation, focused self-testing, development-owned debugging, simulator/build/log checks, verification before completion, README updates, and Test/QA handoffs for its own work.
- The skill now maps requested workflows to available/equivalent capabilities:
  - SwiftUI UI work: `build-ios-apps:swiftui-ui-patterns`
  - business logic: test-driven development loop
  - simulator/log checks: `build-ios-apps:ios-debugger-agent` or approved `xcodebuild`/`simctl`
  - failures: systematic debugging / `phase2-debug` when blocking
  - completion: verification-before-completion discipline
- Updated `docs/phase2/PHASE2_DEVELOPMENT_THREAD_RESPONSIBILITY.md` with the same responsibility shift.

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

- Command: `xcodebuild test -project SmartParkingReminder/SmartParkingReminder.xcodeproj -scheme SmartParkingReminder -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:SmartParkingReminderTests -derivedDataPath /tmp/SmartParkingReminderMapSearchProviderUnitTests`
- Result: `** TEST SUCCEEDED **`
- Unit tests: 31 passed, 0 failed.

Latest managed Phase 2 self-test:

- Report folder: `Self_report/phase2/runs/20260429_165543_phase2_report`
- Readiness: `READY WITH ACCEPTED MANUAL RISK`
- Final command: `xcodebuild test -project SmartParkingReminder/SmartParkingReminder.xcodeproj -scheme SmartParkingReminder -destination 'platform=iOS Simulator,name=iPhone 17' -resultBundlePath Self_report/phase2/runs/20260429_165543_phase2_report/Phase2Tests_20260429_165543_final.xcresult`
- Result: `** TEST SUCCEEDED **`
- Unit tests: 31 passed, 0 failed.
- UI tests: 8 passed, 0 failed.
- Manual gap: Live Activity / Dynamic Island visual evidence not captured.

Latest Phase 2 full unit check:

- Command: `xcodebuild test -project SmartParkingReminder/SmartParkingReminder.xcodeproj -scheme SmartParkingReminder -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:SmartParkingReminderTests -derivedDataPath /tmp/SmartParkingReminderLocalHistorySearchUnitTests2`
- Result: `** TEST SUCCEEDED **`
- Unit tests: 34 passed, 0 failed.

Latest Phase 2 focused Quick Start UI check:

- Command: `xcodebuild test -project SmartParkingReminder/SmartParkingReminder.xcodeproj -scheme SmartParkingReminder -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:SmartParkingReminderUITests/Phase1UITests/test_Phase2QuickStart_ThirtyMinutesStartsActiveSession -derivedDataPath /tmp/SmartParkingReminderQuickStartUITests2`
- Result: `** TEST SUCCEEDED **`
- UI tests: 1 passed, 0 failed.

Latest Phase 2 Search This Area check:

- Unit command: `xcodebuild test -project SmartParkingReminder/SmartParkingReminder.xcodeproj -scheme SmartParkingReminder -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SmartParkingReminderTests/Phase1ModelAndLogicTests/test_Phase2HistoryMapSearch_SearchThisAreaFiltersNearbyHistory -only-testing:SmartParkingReminderTests/Phase1ModelAndLogicTests/test_Phase2HistoryMapSearch_SearchThisAreaPreservesMetadataFilter -only-testing:SmartParkingReminderTests/Phase1ModelAndLogicTests/test_Phase2HistoryMapSearch_SearchThisAreaClearsAddressResults -derivedDataPath /tmp/SmartParkingReminderSearchThisAreaUnitTests`
- Unit result: `** TEST SUCCEEDED **`
- Unit tests: 3 passed, 0 failed.
- Build command: `xcodebuild build-for-testing -project SmartParkingReminder/SmartParkingReminder.xcodeproj -scheme SmartParkingReminder -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/SmartParkingReminderSearchThisAreaBuild`
- Build result: `** TEST BUILD SUCCEEDED **`

Latest Phase 2 release-candidate polish build check:

- Command: `xcodebuild build-for-testing -project SmartParkingReminder/SmartParkingReminder.xcodeproj -scheme SmartParkingReminder -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/SmartParkingReminderPhase2RCPolishBuild`
- Result: `** TEST BUILD SUCCEEDED **`
- Coverage: app target, unit/UI test bundles, and embedded `SmartParkingReminderWidgetExtension.appex`.

Latest Phase 2 release-candidate focused UI sanity check:

- Command: `xcodebuild test -project SmartParkingReminder/SmartParkingReminder.xcodeproj -scheme SmartParkingReminder -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SmartParkingReminderUITests/Phase1UITests/test_Phase2QuickStart_ThirtyMinutesStartsActiveSession -only-testing:SmartParkingReminderUITests/Phase1UITests/test_TC11_TC12_MapDetailSheet_ShowsSpotInfoAndActions -only-testing:SmartParkingReminderUITests/Phase1UITests/test_Phase1HistoryDetail_BackReturnsToHistoryPanel -derivedDataPath /tmp/SmartParkingReminderPhase2RCPolishUITests`
- Result: `** TEST SUCCEEDED **`
- UI tests: 3 passed, 0 failed.

Latest Phase 2 Live Activity build check:

- Command: `xcodebuild build-for-testing -project SmartParkingReminder/SmartParkingReminder.xcodeproj -scheme SmartParkingReminder -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/SmartParkingReminderLiveActivityBuild2`
- Result: `** TEST BUILD SUCCEEDED **`
- Coverage: app target, unit/UI test bundles, and embedded `SmartParkingReminderWidgetExtension.appex`.

Latest Phase 2 Live Activity lifecycle verification:

- Report folder: `Self_report/phase2/runs/20260430_152900_live_activity_verification`
- Report: `LIVE_ACTIVITY_VERIFICATION_REPORT.md`
- Debug build command: `xcodebuild build-for-testing -project SmartParkingReminder/SmartParkingReminder.xcodeproj -scheme SmartParkingReminder -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath /tmp/SmartParkingReminderLiveActivityManualBuild4`
- Debug build result: `** TEST BUILD SUCCEEDED **`
- Release compile command: `xcodebuild build -configuration Release -project SmartParkingReminder/SmartParkingReminder.xcodeproj -scheme SmartParkingReminder -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/SmartParkingReminderReleaseLiveActivityCheck`
- Release compile result: `** BUILD SUCCEEDED **`
- ActivityKit log evidence: `activitykit_auto_end_log_excerpt.txt`
- Result: ActivityKit request, create, update, end, dismiss, and removal lifecycle verified by simulator logs.
- Remaining manual gap: final visual Lock Screen and Dynamic Island screenshot/video capture on supported device or simulator.

Latest Phase 2 Dynamic Island timer fix check:

- Changed `ParkingReminderLiveActivityWidget` from static `context.state.timeText` rendering to live SwiftUI `Text(timerInterval:countsDown:)` rendering.
- Command: `xcodebuild build-for-testing -project SmartParkingReminder/SmartParkingReminder.xcodeproj -scheme SmartParkingReminder -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath /tmp/SmartParkingReminderDynamicIslandTimerFix`
- Result: `** TEST BUILD SUCCEEDED **`

Latest Phase 2 compact Dynamic Island layout check:

- Reduced compact and expanded Dynamic Island content so the Island stays glanceable instead of using Lock Screen-level detail.
- Command: `xcodebuild build-for-testing -project SmartParkingReminder/SmartParkingReminder.xcodeproj -scheme SmartParkingReminder -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath /tmp/SmartParkingReminderDynamicIslandCompactFix`
- Result: `** TEST BUILD SUCCEEDED **`

Latest Phase 2 Dynamic Island status-color fix check:

- Changed Dynamic Island and Lock Screen visible status/color from stored ActivityKit status only to a time-derived status based on `expectedEndTime`.
- Command: `xcodebuild build-for-testing -project SmartParkingReminder/SmartParkingReminder.xcodeproj -scheme SmartParkingReminder -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath /tmp/SmartParkingReminderDynamicIslandStatusColorFix`
- Result: `** TEST BUILD SUCCEEDED **`

Latest Phase 2 Dynamic Island icon-plus-timer check:

- Removed Dynamic Island label/location/status text while preserving the colored parking icon and live timer.
- Command: `xcodebuild build-for-testing -project SmartParkingReminder/SmartParkingReminder.xcodeproj -scheme SmartParkingReminder -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath /tmp/SmartParkingReminderDynamicIslandIconTimerFix`
- Result: `** TEST BUILD SUCCEEDED **`

Latest Phase 2 Dynamic Island smaller-footprint check:

- Reduced Dynamic Island icon sizing and capped the timer frame more tightly while keeping icon plus timer visible.
- Command: `xcodebuild build-for-testing -project SmartParkingReminder/SmartParkingReminder.xcodeproj -scheme SmartParkingReminder -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath /tmp/SmartParkingReminderDynamicIslandSmallFootprintFix`
- Result: `** TEST BUILD SUCCEEDED **`

Latest Phase 2 personal spot metadata focused check:

- Command: `xcodebuild test -project SmartParkingReminder/SmartParkingReminder.xcodeproj -scheme SmartParkingReminder -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SmartParkingReminderTests/Phase1ModelAndLogicTests/test_Phase2PersonalSpotMetadata_LocalQueryFiltersTagsAndSpotNote -only-testing:SmartParkingReminderTests/Phase1ModelAndLogicTests/test_Phase2PersonalSpotMetadata_UpdatePersistsAndKeepsSelectionVisible -only-testing:SmartParkingReminderTests/Phase1StorageAndStoreTests/test_Phase2PersonalSpotMetadataStorage_RoundTripsLocalMetadata -derivedDataPath /tmp/SmartParkingReminderPersonalSpotMetadataTests2`
- Result: `** TEST SUCCEEDED **`
- Unit tests: 3 passed, 0 failed.

Latest Phase 2 full unit check after personal spot metadata:

- Command: `xcodebuild test -project SmartParkingReminder/SmartParkingReminder.xcodeproj -scheme SmartParkingReminder -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SmartParkingReminderTests -derivedDataPath /tmp/SmartParkingReminderPersonalSpotMetadataUnitTests`
- Result: `** TEST SUCCEEDED **`
- Unit tests: 37 passed, 0 failed.

Latest Phase 2 focused personal metadata filter check:

- Command: `xcodebuild test -project SmartParkingReminder/SmartParkingReminder.xcodeproj -scheme SmartParkingReminder -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SmartParkingReminderTests/Phase1ModelAndLogicTests/test_Phase2PersonalSpotMetadataFilter_FavoritesFiltersVisibleMapGroups -only-testing:SmartParkingReminderTests/Phase1ModelAndLogicTests/test_Phase2PersonalSpotMetadataFilter_ComposesWithAddressRadius -derivedDataPath /tmp/SmartParkingReminderMetadataFilterTests`
- Result: `** TEST SUCCEEDED **`
- Unit tests: 2 passed, 0 failed.

Latest Phase 2 full unit check after personal metadata filters:

- Command: `xcodebuild test -project SmartParkingReminder/SmartParkingReminder.xcodeproj -scheme SmartParkingReminder -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SmartParkingReminderTests -derivedDataPath /tmp/SmartParkingReminderMetadataFilterUnitTests`
- Result: `** TEST SUCCEEDED **`
- Unit tests: 39 passed, 0 failed.

Latest Phase 2 focused Quick Start recent-duration check:

- Command: `xcodebuild test -project SmartParkingReminder/SmartParkingReminder.xcodeproj -scheme SmartParkingReminder -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SmartParkingReminderTests/Phase1StorageAndStoreTests/test_Phase2QuickStartDurationOptions_IncludeRecentNonDefaultDuration -derivedDataPath /tmp/SmartParkingReminderQuickStartRecentDurationTests`
- Result: `** TEST SUCCEEDED **`
- Unit tests: 1 passed, 0 failed.

Latest Phase 2 full unit check after Quick Start recent-duration polish:

- Command: `xcodebuild test -project SmartParkingReminder/SmartParkingReminder.xcodeproj -scheme SmartParkingReminder -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SmartParkingReminderTests -derivedDataPath /tmp/SmartParkingReminderQuickStartRecentDurationUnitTests`
- Result: `** TEST SUCCEEDED **`
- Unit tests: 40 passed, 0 failed.

Latest Phase 2 Live Activity date-driven stale-status fix check:

- Command: `xcodebuild test -project SmartParkingReminder/SmartParkingReminder.xcodeproj -scheme SmartParkingReminder -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SmartParkingReminderTests/Phase1StorageAndStoreTests/test_Phase2ActivityKitPayload_MapsPrivacySafeSnapshot -only-testing:SmartParkingReminderTests/Phase1StorageAndStoreTests/test_Phase2ActivityLifecycle_AddTimePublishesDateDrivenUpdateAndReschedulesNotifications -only-testing:SmartParkingReminderTests/Phase1StorageAndStoreTests/test_Phase2ActivityLifecycle_RestoreWithoutActiveSessionEndsOrphanedActivities -only-testing:SmartParkingReminderTests/Phase1StorageAndStoreTests/test_Phase2ActivityLifecycle_RestoreActiveSessionPublishesRestoredSnapshot -derivedDataPath /tmp/SmartParkingReminderLiveActivityDateDrivenTests`
- Result: `** TEST SUCCEEDED **`
- Unit tests: 4 passed, 0 failed.

Latest Phase 2 full unit check after Live Activity date-driven stale-status fix:

- Command: `xcodebuild test -project SmartParkingReminder/SmartParkingReminder.xcodeproj -scheme SmartParkingReminder -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SmartParkingReminderTests -derivedDataPath /tmp/SmartParkingReminderLiveActivityDateDrivenUnitTests`
- Result: `** TEST SUCCEEDED **`
- Unit tests: 44 passed, 0 failed.

Latest Phase 2 focused History filtering service check:

- Command: `xcodebuild test -project SmartParkingReminder/SmartParkingReminder.xcodeproj -scheme SmartParkingReminder -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SmartParkingReminderTests/Phase1ModelAndLogicTests/test_Phase2HistoryMapFilteringService_LocalQueryIncludesMetadataFields -only-testing:SmartParkingReminderTests/Phase1ModelAndLogicTests/test_Phase2HistoryMapFilteringService_NearbyFilterComposesWithMetadataFilter -only-testing:SmartParkingReminderTests/Phase1ModelAndLogicTests/test_Phase2PersonalSpotMetadataFilter_ComposesWithAddressRadius -only-testing:SmartParkingReminderTests/Phase1ModelAndLogicTests/test_Phase2HistoryMapSearch_LocalQueryFiltersSavedSpotNamesAndNotes -derivedDataPath /tmp/SmartParkingReminderHistoryFilterServiceTests`
- Result: `** TEST SUCCEEDED **`
- Unit tests: 4 passed, 0 failed.

Latest Phase 2 full unit check after History filtering service extraction:

- Command: `xcodebuild test -project SmartParkingReminder/SmartParkingReminder.xcodeproj -scheme SmartParkingReminder -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SmartParkingReminderTests -derivedDataPath /tmp/SmartParkingReminderHistoryFilterServiceUnitTests`
- Result: `** TEST SUCCEEDED **`
- Unit tests: 42 passed, 0 failed.

Latest Phase 2 History map layer-model compile check:

- Command: `xcodebuild build-for-testing -project SmartParkingReminder/SmartParkingReminder.xcodeproj -scheme SmartParkingReminder -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/SmartParkingReminderHistoryLayerModelBuild`
- Result: `** TEST BUILD SUCCEEDED **`
- Scope: compile/build verification only; no formal QA or new test cases were created by the development thread.

Latest Phase 2 dormant public parking model compile check:

- Command: `xcodebuild build-for-testing -project SmartParkingReminder/SmartParkingReminder.xcodeproj -scheme SmartParkingReminder -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/SmartParkingReminderPublicParkingModelsBuild`
- Result: `** TEST BUILD SUCCEEDED **`
- Scope: compile/build verification only; no Green P/public parking UI, data loading, formal QA, or new test cases were created by the development thread.

Latest Phase 2 privacy data-boundary update:

- Added `docs/phase2/PHASE2_PRIVACY_DATA_BOUNDARY.md`.
- Updated roadmap and architecture review docs.
- Created handoff `docs/phase2/handoffs/20260502_0934_privacy_data_boundary_TEST_HANDOFF.md`.
- Scope: documentation/design only; no build or formal QA needed because no app code changed.

Latest Phase 2 widget shared-state decision update:

- Added `docs/phase2/PHASE2_WIDGET_SHARED_STATE_DECISION.md`.
- Current decision: no App Group shared container is needed for the Phase 2 Live Activity; ActivityKit content state remains the extension boundary.
- Updated roadmap, architecture review, Live Activity spike notes, and Phase 2 docs index.
- Created handoff `docs/phase2/handoffs/20260502_1142_widget_shared_state_decision_TEST_HANDOFF.md`.
- Scope: documentation/design only; no build or formal QA needed because no app code changed.

Latest Phase 2 personal spot display-name polish:

- Added a `Spot name` field to the existing Map spot detail Personal Details section.
- Changed files: `AccessibilityIDs.swift`, `ParkingSpotDetailSheetView.swift`, `PHASE2_ROADMAP.md`, and the handoff below.
- Created handoff `docs/phase2/handoffs/20260502_1650_personal_spot_display_name_TEST_HANDOFF.md`.
- Build check command: `xcodebuild build-for-testing -project SmartParkingReminder/SmartParkingReminder.xcodeproj -scheme SmartParkingReminder -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/SmartParkingReminderSpotDisplayNameBuild`
- Build check result: `** TEST BUILD SUCCEEDED **`
- Scope: small UI/code polish using existing local metadata storage; no new storage model, no History list, no backend/cloud/ML/analytics/community behavior, and no formal QA run by the development thread.

Latest Phase 2 Map relocate button:

- Added a floating current-location button to the Map screen.
- Changed files: `AccessibilityIDs.swift`, `ContentView.swift`, `HistoryView.swift`, `HistoryMapViewModel.swift`, `HistoryMapView.swift`, `PHASE2_ROADMAP.md`, and the handoff below.
- Created handoff `docs/phase2/handoffs/20260502_1901_map_relocate_button_TEST_HANDOFF.md`.
- Build check command: `xcodebuild build-for-testing -project SmartParkingReminder/SmartParkingReminder.xcodeproj -scheme SmartParkingReminder -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/SmartParkingReminderMapRelocateBuild`
- Build check result: `** TEST BUILD SUCCEEDED **`
- Scope: one-shot location only; no continuous/background location, backend, cloud, ML, analytics, community behavior, or old History list.

Latest Phase 2 / Phase 1 Map initial-location behavior improvement:

- Map now opens as a real map even when no saved history exists.
- Added `UserAnnotation()` so the user location dot is visible when permission is available.
- Initial camera now uses `MapCameraPosition.userLocation(followsHeading: true, fallback: Toronto)`.
- Recenter uses current location when available and Toronto fallback when denied/unavailable.
- Changed files: `LocationService.swift`, `HistoryMapViewModel.swift`, `HistoryMapView.swift`, `PHASE2_ROADMAP.md`, and the handoff below.
- Created handoff `docs/phase2/handoffs/20260502_1909_map_initial_location_behavior_TEST_HANDOFF.md`.
- Build check command: `xcodebuild build-for-testing -project SmartParkingReminder/SmartParkingReminder.xcodeproj -scheme SmartParkingReminder -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/SmartParkingReminderMapInitialLocationBuild`
- Build check result: `** TEST BUILD SUCCEEDED **`
- Scope: one-shot foreground location only; no continuous/background location, backend, cloud, ML, analytics, community behavior, or old History list.

Latest Phase 2 Map sheet keyboard/safe-area fix:

- Changed `HistoryMapView` so the bottom sheet reserves 116 pt of bottom scroll space, lifts above the keyboard, and keeps history/search row taps responsive while the keyboard is up.
- Command: `xcodebuild test -project SmartParkingReminder/SmartParkingReminder.xcodeproj -scheme SmartParkingReminder -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SmartParkingReminderUITests/Phase1UITests/test_Phase2HistoryMapSearch_LocalNoteSearchOpensMatchingSpotDetail -only-testing:SmartParkingReminderUITests/Phase1UITests/test_TC11_TC12_MapDetailSheet_ShowsSpotInfoAndActions -derivedDataPath /tmp/SmartParkingReminderMapKeyboardSafeAreaFinalUITests`
- Result: `** TEST SUCCEEDED **`
- UI tests: 2 passed, 0 failed.
- Xcode result bundle: `/tmp/SmartParkingReminderMapKeyboardSafeAreaFinalUITests/Logs/Test/Test-SmartParkingReminder-2026.05.05_10-03-29--0400.xcresult`

Latest Phase 2 / Phase 1.1 regression bundle check:

- Scope: date-driven Live Activity regression coverage, Quick Start fixed naming, Manual Start precise duration, Map search camera fitting, and nearby Personal History preservation.
- Focused unit command: `xcodebuild test -project SmartParkingReminder/SmartParkingReminder.xcodeproj -scheme SmartParkingReminder -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SmartParkingReminderTests/Phase1StorageAndStoreTests/test_Phase2QuickStartDraft_UsesSameSessionCreationPath -only-testing:SmartParkingReminderTests/Phase1StorageAndStoreTests/test_Phase1QuickStartName_DoesNotReuseMostRecentSessionLocation -only-testing:SmartParkingReminderTests/Phase1StorageAndStoreTests/test_Phase2QuickStartDurationOptions_IncludeRecentNonDefaultDuration -only-testing:SmartParkingReminderTests/Phase1StorageAndStoreTests/test_Phase1ManualStartCustomDuration_UsesSelectedDurationForScheduleAndActivity -only-testing:SmartParkingReminderTests/Phase1StorageAndStoreTests/test_Phase1ManualStartInvalidZeroDuration_DoesNotCreateSession -only-testing:SmartParkingReminderTests/Phase1StorageAndStoreTests/test_Phase2ActivityLifecycle_AddTimePublishesDateDrivenUpdateAndReschedulesNotifications -only-testing:SmartParkingReminderTests/Phase1ModelAndLogicTests/test_Phase1MapSearch_AddressResultsDoNotHidePersonalHistoryBeforeSelection -only-testing:SmartParkingReminderTests/Phase1ModelAndLogicTests/test_Phase1MapSearch_SelectedAddressRanksNearbyHistoryByDistance -only-testing:SmartParkingReminderTests/Phase1ModelAndLogicTests/test_Phase1MapSearch_CameraUsesBroadResultRegionWhenProvided -only-testing:SmartParkingReminderTests/Phase1ModelAndLogicTests/test_Phase1MapSearch_CameraFramesSelectedResultAndNearbyHistory -derivedDataPath /tmp/SmartParkingReminderPhase1IssuesUnitTests`
- Focused unit result: `** TEST SUCCEEDED **`; 10 tests passed, 0 failed.
- Full unit command: `xcodebuild test -project SmartParkingReminder/SmartParkingReminder.xcodeproj -scheme SmartParkingReminder -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SmartParkingReminderTests -derivedDataPath /tmp/SmartParkingReminderPhase1IssuesFullUnitTests`
- Full unit result: `** TEST SUCCEEDED **`; 50 tests passed, 0 failed.
- Focused UI command: `xcodebuild test -project SmartParkingReminder/SmartParkingReminder.xcodeproj -scheme SmartParkingReminder -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SmartParkingReminderUITests/Phase1UITests/test_TC01_StartSession_ShowsActiveSessionAndCountdown -only-testing:SmartParkingReminderUITests/Phase1UITests/test_Phase2QuickStart_ThirtyMinutesStartsActiveSession -only-testing:SmartParkingReminderUITests/Phase1UITests/test_Phase2HistoryMapSearch_LocalNoteSearchOpensMatchingSpotDetail -derivedDataPath /tmp/SmartParkingReminderPhase1IssuesUITests`
- Focused UI result: `** TEST SUCCEEDED **`; 3 tests passed, 0 failed.
- Xcode result bundles: `/tmp/SmartParkingReminderPhase1IssuesFullUnitTests/Logs/Test/Test-SmartParkingReminder-2026.05.05_11-59-09--0400.xcresult` and `/tmp/SmartParkingReminderPhase1IssuesUITests/Logs/Test/Test-SmartParkingReminder-2026.05.05_12-01-37--0400.xcresult`.

Latest Phase 2 Map range camera-scale fix:

- Changed `HistoryMapViewModel` and `HistoryMapView` so selected range controls both nearby Personal History filtering and animated map camera scale.
- Focused unit command: `xcodebuild test -project SmartParkingReminder/SmartParkingReminder.xcodeproj -scheme SmartParkingReminder -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SmartParkingReminderTests/Phase1ModelAndLogicTests/test_Phase2HistoryMapSearch_AdjustingRadiusRecomputesNearbyHistory -only-testing:SmartParkingReminderTests/Phase1ModelAndLogicTests/test_Phase1MapSearch_SelectedRangeControlsCameraScale -only-testing:SmartParkingReminderTests/Phase1ModelAndLogicTests/test_Phase1MapSearch_SelectedRangeCameraCentersOnSearchResult -only-testing:SmartParkingReminderTests/Phase1ModelAndLogicTests/test_Phase1MapSearch_SelectedAddressRanksNearbyHistoryByDistance -derivedDataPath /tmp/SmartParkingReminderMapRangeCameraTests`
- Focused unit result: `** TEST SUCCEEDED **`; 4 tests passed, 0 failed.
- Full unit command: `xcodebuild test -project SmartParkingReminder/SmartParkingReminder.xcodeproj -scheme SmartParkingReminder -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SmartParkingReminderTests -derivedDataPath /tmp/SmartParkingReminderMapRangeCameraFullUnitTests`
- Full unit result: `** TEST SUCCEEDED **`; 52 tests passed, 0 failed.
- UI smoke command: `xcodebuild test -project SmartParkingReminder/SmartParkingReminder.xcodeproj -scheme SmartParkingReminder -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SmartParkingReminderUITests/Phase1UITests/test_Phase2HistoryMapSearch_LocalNoteSearchOpensMatchingSpotDetail -derivedDataPath /tmp/SmartParkingReminderMapRangeCameraUITests`
- UI smoke result: `** TEST SUCCEEDED **`; 1 test passed, 0 failed.
- Xcode result bundles: `/tmp/SmartParkingReminderMapRangeCameraFullUnitTests/Logs/Test/Test-SmartParkingReminder-2026.05.05_13-29-35--0400.xcresult` and `/tmp/SmartParkingReminderMapRangeCameraUITests/Logs/Test/Test-SmartParkingReminder-2026.05.05_13-31-19--0400.xcresult`.

Latest Phase 2 focused active-session UI check:

- Command: `xcodebuild test -project SmartParkingReminder/SmartParkingReminder.xcodeproj -scheme SmartParkingReminder -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:SmartParkingReminderUITests/Phase1UITests/test_Phase2ActiveSession_DueSoonStateIsVisible -only-testing:SmartParkingReminderUITests/Phase1UITests/test_Phase2ActiveSession_OverdueStateIsVisibleWithoutAutoEnding -derivedDataPath /tmp/SmartParkingReminderActiveSessionUITests`
- Result: `** TEST SUCCEEDED **`
- UI tests: 2 passed, 0 failed.

Latest Phase 2 focused Map bottom-sheet UI check:

- Command: `xcodebuild test -project SmartParkingReminder/SmartParkingReminder.xcodeproj -scheme SmartParkingReminder -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:SmartParkingReminderUITests/Phase1UITests/test_TC07_TC08_EndSession_AppearsInHistoryMapDetail -only-testing:SmartParkingReminderUITests/Phase1UITests/test_TC11_TC12_MapDetailSheet_ShowsSpotInfoAndActions -only-testing:SmartParkingReminderUITests/Phase1UITests/test_Phase1HistoryDetail_BackReturnsToHistoryPanel -derivedDataPath /tmp/SmartParkingReminderHistoryBackUITests2`
- Result: `** TEST SUCCEEDED **`
- UI tests: 3 passed, 0 failed.

Latest Phase 2 full simulator check:

- Command: `xcodebuild test -project SmartParkingReminder/SmartParkingReminder.xcodeproj -scheme SmartParkingReminder -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2' -derivedDataPath /tmp/SmartParkingReminderMapPanelTests -resultBundlePath /tmp/SmartParkingReminderMapPanelTests/MapPanelTests.xcresult`
- Result: `** TEST SUCCEEDED **`
- Unit tests: 17 passed, 0 failed.
- UI tests: 4 passed, 0 failed.

Latest Phase 2 local Map search UI hardening:

- Changed the Map search focus behavior so tapping the search field opens the expanded bottom sheet, keeping saved-history matches tappable while the keyboard is visible.
- Split panel-level accessibility markers from child controls so `history.searchStatus`, `history.personalSpotButton`, and detail controls remain individually targetable by UI tests.
- Added UI coverage for searching a saved note, opening the matching spot detail, and confirming the saved note appears.
- Verified `Phase1UITests.test_Phase2HistoryMapSearch_LocalNoteSearchOpensMatchingSpotDetail`: `** TEST SUCCEEDED **`.
- Re-verified `Phase1UITests.test_Phase1HistoryDetail_BackReturnsToHistoryPanel`: `** TEST SUCCEEDED **`.

2026-05-12 bounded UI redesign pass:

- Performed a UI-only polish pass before moving to the next phase; no store, model, notification, timer, persistence, or data-flow logic was intentionally changed.
- Home now uses a grouped background, stronger empty state panel, clearer active-session hierarchy, framed active-location map preview, and large action controls.
- Active sessions keep the same status/timer values but present the timer and progress in a clearer status block with a compact coordinate chip.
- New Session keeps the same form fields and start logic, but section headers, duration presets, and the picker surface are visually clearer.
- Map bottom sheet and map/detail rows received subtle stroke/spacing polish without changing map-first behavior or bringing back the old History list.
- Simulator build/run succeeded through XcodeBuildMCP on iPhone 17 Simulator with no reported build warnings/errors.
- Build verification passed: `xcodebuild build-for-testing -project SmartParkingReminder/SmartParkingReminder.xcodeproj -scheme SmartParkingReminder -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/SmartParkingReminderBoundedUIPassBuild`.
- Test handoff: `docs/phase2/handoffs/20260512_1105_bounded_ui_redesign_TEST_HANDOFF.md`.

2026-05-12 Map tab bar UI enhancement:

- Superseded later the same day by the floating mode switch refinement below.
- Changed the app shell to use explicit Home/Map tab selection so the Map screen can return Home from inside its own immersive map workflow.
- Hid the standard system tab bar only on the Map screen so it no longer blocks or visually competes with the collapsed Map search sheet.
- Added a compact floating `Home` control on the Map surface. This earlier control was removed by the floating mode switch refinement.
- Home keeps the standard Home/Map tab bar visible; Map keeps the current bottom sheet/search/history/detail behavior unchanged.
- No map search logic, parking-session logic, storage, timer, notification, backend, cloud, analytics, ML, or old History list behavior was intentionally changed.
- Added focused UI coverage: `Phase1UITests.test_Phase2Map_HidesTabBarAndReturnsHomeWithFloatingButton`.
- Focused UI result: `** TEST SUCCEEDED **`; 1 UI test passed, 0 failed.
- Build verification passed: `xcodebuild build-for-testing -project SmartParkingReminder/SmartParkingReminder.xcodeproj -scheme SmartParkingReminder -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/SmartParkingReminderMapTabBarBuild`.
- Test handoff: `docs/phase2/handoffs/20260512_1355_map_tab_bar_ui_enhancement_TEST_HANDOFF.md`.

2026-05-12 floating mode switch refinement:

- Replaced the standard `TabView` shell with a two-mode `ZStack` shell because the app only has Home and Map modes.
- Removed the previous Map-only top `Home` pill and replaced it with one shared circular glass-style mode switch near the lower-left.
- Home mode shows an icon-only Map switch with accessibility ID `modeSwitch.mapButton`.
- Map mode shows an icon-only Home switch with accessibility ID `modeSwitch.homeButton`.
- The switch uses native iOS material styling, a circular shape, a subtle stroke, and shadow; no iOS 26-only Liquid Glass API dependency was added.
- Updated map UI tests to navigate through the new mode switch instead of the removed tab bar.
- No map search logic, parking-session logic, storage, timer, notification, backend, cloud, analytics, ML, or old History list behavior was intentionally changed.
- Build verification passed: `xcodebuild build-for-testing -project SmartParkingReminder/SmartParkingReminder.xcodeproj -scheme SmartParkingReminder -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/SmartParkingReminderFloatingModeSwitchBuild`.
- Focused UI result: `** TEST SUCCEEDED **`; `test_Phase2ModeSwitch_TogglesBetweenHomeAndMapWithoutTabBar` and `test_TC11_TC12_MapDetailSheet_ShowsSpotInfoAndActions` passed, 0 failed.
- Test handoff: `docs/phase2/handoffs/20260512_1408_floating_mode_switch_TEST_HANDOFF.md`.

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
- For Phase 2 development, follow `docs/phase2/PHASE2_DEVELOPMENT_THREAD_RESPONSIBILITY.md`; this thread records design/implementation and creates handoff summaries, while Test/QA creates test cases and updates test documents.
- Do not bring the History list back unless the user explicitly changes the product decision.
- Search should improve the map workflow, not become a separate results list.
- Keep Phase 1 simple: no advanced clustering, no ML, no backend.
- Avoid repo-local legacy Node spreadsheet dependencies in this iCloud workspace; prior `exceljs`/`jszip` imports hung. Use the Phase 1 Python generator or the bundled spreadsheet runtime for managed Excel report artifacts.
- Be careful with the dirty worktree. There are existing generated/user changes and report folders. Do not revert unrelated files.
- Prefer `build-for-testing` locally; ask Clawdbot to run full simulator tests.
- Live Activity now has a first ActivityKit/widget implementation, the required app `NSSupportsLiveActivities` declaration, and simulator lifecycle evidence. Device/simulator visual verification is still needed for final Lock Screen and Dynamic Island presentation evidence.
- Quick Start now has a local-only implementation with default presets plus a recent-duration option. Keep future polish on the same `ParkingSessionDraft` / store creation path.
- Personal spot metadata now has a first local-only Map-detail implementation plus local Map filter chips and custom spot names. Keep future polish inside the map workflow and avoid reviving the old History list.
- Map now has a one-shot relocate button and initial user-location camera with Toronto fallback. Keep it one-shot and local-only; do not turn it into continuous/background location tracking.
- `docs/phase2/PHASE2_PRIVACY_DATA_BOUNDARY.md` is the privacy rulebook for future location-derived assistant behavior. Future smart suggestions, saved/frequent spot models, App Group storage, search history, or public parking caches need a design review before implementation.
- `docs/phase2/PHASE2_WIDGET_SHARED_STATE_DECISION.md` records that current Live Activities stay ActivityKit-content-state-only; do not add App Group storage unless a future widget feature explicitly needs shared persisted state.
- Toronto Green P is a future nearby parking discovery track: Phase 2 is research and optional disabled/static marker prototype only; Phase 3 is the earliest production Green P data layer; Phase 4 is real-time availability/payment/deeper integration only with an official API or partnership.
- Created the Phase 2 Test/QA thread document. This thread now validates only, reports bugs, and generates Debug-thread handoffs without redesigning or fixing features.
- Updated the Phase 2 Test/QA responsibility: this thread now also reads design/handoff notes and maintains test-only updates in `docs/phase2/PHASE2_SELF_TEST.md`.
- Ran a managed Phase 2 QA checkpoint from the Test/QA thread and saved the report set under `Self_report/phase2/runs/20260501_152228_phase2_report/`.
- Automated rerun result: `** TEST SUCCEEDED **` with 40 unit tests and 9 UI tests passing on iPhone 17 Pro Simulator.
- Final QA readiness: `READY WITH ACCEPTED MANUAL RISK` because visual Lock Screen / Dynamic Island and other manual screenshot evidence was not captured in this pass.
- QA intake reviewed the new History map filtering service and marker layer model handoffs, then updated `docs/phase2/PHASE2_SELF_TEST.md` with marker-layer validation expectations only.
- Ran the Phase 2 release QA pass for the latest update and saved the managed report set under `Self_report/phase2/runs/20260505_163802_phase2_release_report/`.
- Release QA result: `NOT READY`. Unit coverage passed, but UI release validation failed on `Phase1UITests.test_Phase2ActiveSession_OverdueStateIsVisibleWithoutAutoEnding`.
- Failure summary: a seeded overdue active session did not show `home.activeSessionCard` after relaunch, so overdue active-session restore/presentation must be debugged before release.
- Updated `docs/phase2/PHASE2_SELF_TEST.md` with the latest test-only expectations for dormant public parking models, privacy/data-boundary decisions, widget shared-state decision, personal spot display names, and map current-location/relocate behavior.
- Ran the Phase 2 QA release check after the `Search This Area` handoff and saved the managed report set under `Self_report/phase2/runs/20260506_150030_phase2_report/`.
- Updated `docs/phase2/PHASE2_SELF_TEST.md` with test-only `P2-TC-17 Map Search This Area` coverage, including unit coverage and manual pan/zoom validation expectations.
- Automated result: 55 unit tests passed, including the three new `Search This Area` unit tests; 8 of 9 UI tests passed.
- Release QA result remains `NOT READY`: `Phase1UITests.test_Phase2ActiveSession_OverdueStateIsVisibleWithoutAutoEnding` failed in the full run and in focused rerun because `home.activeSessionCard` did not appear after seeded overdue relaunch.

## Next Good Improvements

- Tag/freeze the Phase 1 baseline before Phase 2 code work.
- Capture final visual Live Activity presentation on a supported simulator/device and attach evidence to the latest Phase 2 report folder.
- Run a managed Phase 2 checkpoint after visual review of personal spot metadata and remaining Live Activity evidence.

## Phase 2 Direction

Phase 2 implementation order is now defined in `docs/phase2/PHASE2_ROADMAP.md` and `docs/phase2/PHASE2_ARCHITECTURE_REVIEW.md`.

Recommended order:

1. Persistence schema versioning and migration safety.
2. Pure active-session display/status formatter with tests.
3. Notification lifecycle audit.
4. Swift 6 warning cleanup.
5. Improved active/due-soon/overdue session UI.
6. Real ActivityKit-backed Live Activity manager and widget extension.
7. Quick Start on the same session creation path. First polish pass with local recent-duration suggestion is done.
8. Map-only search/filtering improvements.
9. Personal spot metadata after storage versioning is stable. First pass done.
10. Toronto Green P / nearby parking discovery research only. Static prototype can be considered in Phase 2 only if official data is reliable; production data layer waits for Phase 3; real-time availability/payment waits for Phase 4 and official API/partnership.
