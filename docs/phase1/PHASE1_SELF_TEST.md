# Phase 1 Self-Test Runbook

This file is the authoritative Phase 1 self-test instruction for Clawdbot. It covers the complete Phase 1 MVP scope from `README.md`, combines automated and manual checks, and defines the required report artifacts.

Phase 1 sign-off is allowed only when every P0 and P1 case is `PASS`, including manual-only cases that passed with evidence. Any `FAIL` or `BLOCKED` means **NOT READY**.

---

## Required Deliverables

Save all outputs under one timestamped Phase 1 report folder:

`Self_report/phase1/runs/<timestamp>_phase1_report/`

1. `PHASE1_TEST_REPORT.md`
   - Conclusion report.
   - Must include final readiness, failed-case reasons, likely failing area, and recommended next action.
2. `PHASE1_TEST_REPORT.xlsx`
   - Excel overview of all `TC-01` through `TC-14`.
   - Must include summary counts, detailed rows, and open issues.
3. `PHASE1_TEST_REPORT_DATA.json`
   - Structured source data used to generate the Markdown and Excel report.
4. `xcodebuild_<timestamp>.log`
   - Full raw `xcodebuild test` output.
5. `Phase1Tests_<timestamp>.xcresult`
   - Xcode result bundle from the automated run.
6. Manual evidence, when applicable:
   - screenshots, screen recordings, or short notes under `attachments_manual/`.

Use one timestamp for a full run, for example `20260424_091500`.

---

## Coverage Assessment

This runbook covers all Phase 1 requirements:

| Feature ID | Phase 1 requirement | Priority | Test cases | Coverage type |
|---|---|---:|---|---|
| F1 | Start parking session | P0 | TC-01 | UI automated |
| F2 | Save location name, duration, start time, note, optional lat/lon | P0 | TC-01, TC-02, TC-03, TC-08 | UI + unit + manual |
| F3 | Show active session on Home | P0 | TC-01, TC-14 | UI automated |
| F4 | Remaining time countdown and overdue transition | P0 | TC-04 | Unit automated + optional manual observation |
| F5 | Notifications at T-15 and expiry | P0 | TC-05, TC-06 | Unit automated + manual OS delivery |
| F6 | End session manually | P0 | TC-07 | UI + unit automated |
| F7 | Completed sessions saved to history | P0 | TC-07, TC-08, TC-14 | UI + unit automated |
| F8 | Map with address search | P0 | TC-08, TC-09 | UI automated + manual visual |
| F9 | One-shot current location capture, no continuous tracking | P1 | TC-02, TC-03 | Manual device check |
| F10 | Nearby sessions grouped into one marker | P1 | TC-10 | Unit automated + manual visual |
| F11 | Tap marker opens detail sheet, no auto-navigation | P1 | TC-11 | UI automated |
| F12 | Detail sheet shows grouped-spot details | P1 | TC-12 | UI automated |
| F13 | Apple Maps / Google Maps handoff | P1 | TC-13 | Unit URL check + manual app handoff |
| F14 | Sessions restored after app relaunch | P0 | TC-14 | UI + unit automated |

Known manual-only areas:

- OS permission prompts for location and notifications.
- Real local notification delivery timing.
- Real Apple Maps / Google Maps app switching.
- Visual correctness of the history map marker rendering.

Do not mark these as `PASS` based only on unit tests. Mark them `PASS` only after manual device/simulator observation, and include evidence notes in `failureHighlight`, `advice`, or a linked manual evidence path.

---

## Standard Setup

1. Use the latest workspace state.
2. Confirm the Xcode project opens/builds:
   - project: `SmartParkingReminder/SmartParkingReminder.xcodeproj`
   - scheme: `SmartParkingReminder`
3. Use an iOS Simulator for automated tests.
4. Use a real iPhone when validating:
   - notification delivery,
   - location permission behavior,
   - external map app handoff.
5. Reset app data before the manual full pass.
6. Record device/simulator:
   - device name,
   - iOS version,
   - Xcode version,
   - git commit SHA or branch.

Recommended automated destination:

```bash
platform=iOS Simulator,name=iPhone 17,OS=26.2
```

If that exact simulator is unavailable, use the newest available iPhone simulator and record the exact destination in `PHASE1_TEST_REPORT_DATA.json`.

---

## Automated Test Run

From the project root:

```bash
TS=$(date +%Y%m%d_%H%M%S)
REPORT_DIR="Self_report/phase1/runs/${TS}_phase1_report"
mkdir -p "${REPORT_DIR}"
xcodebuild test \
  -project "SmartParkingReminder/SmartParkingReminder.xcodeproj" \
  -scheme SmartParkingReminder \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2' \
  -resultBundlePath "${REPORT_DIR}/Phase1Tests_${TS}.xcresult" \
  2>&1 | tee "${REPORT_DIR}/xcodebuild_${TS}.log"
```

If the destination is unavailable, rerun with a valid simulator destination and preserve the failed log too.

Automated tests expected in this suite:

- `SmartParkingReminderTests.Phase1ModelAndLogicTests`
- `SmartParkingReminderTests.Phase1NotificationAndHandoffTests`
- `SmartParkingReminderTests.Phase1StorageAndStoreTests`
- `SmartParkingReminderUITests.Phase1UITests`

---

## Detailed Test Cases

### TC-01 (P0) Start Session From New Session Screen

Coverage:

- Automated UI: `Phase1UITests.test_TC01_StartSession_ShowsActiveSessionAndCountdown`

Manual confirmation:

1. Launch app from a fresh state.
2. Tap `Start Parking`.
3. Enter location name `Lot A`.
4. Use default duration or set `30 min`.
5. For the Phase 1.1 regression pass, also use the custom hour/minute duration picker once, such as `1 hr 25 min`.
6. Tap `Start`.

Expected:

- New Session sheet dismisses.
- Home shows active session card.
- Location name is `Lot A`.
- Countdown/remaining-time text is visible and changing.
- Custom duration changes the scheduled end time and countdown; the app must not allow a 0 minute session.

Fail reason guidance:

- If active card is missing, inspect `NewSessionView.startSession`, `ParkingSessionStore.startNewSession`, `HomeView`, and accessibility identifier `home.activeSessionCard`.

### TC-02 (P1) One-Time Current Location Capture

Coverage:

- Manual required.

Steps:

1. Use real device if possible.
2. Reset location permission for the app.
3. Start a new session with location name `GPS Spot`.
4. Allow location permission when prompted.
5. Save/start the session.
6. Open the active session card and Map after ending it.

Expected:

- Session starts successfully.
- Latitude/longitude are saved.
- Location is requested once for session creation.
- No background location indicator remains after capture.
- App does not require continuous/background location permission.

Fail reason guidance:

- If coordinates are missing after permission is allowed, inspect `LocationService.currentCoordinateOnce` and `NewSessionView.startSession`.

### TC-03 (P1) Location Denied Flow

Coverage:

- Manual required.

Steps:

1. Set app Location permission to `Denied`.
2. Start a new session with location name `Denied Spot`.
3. Attempt the current-location flow if UI exposes it.
4. Save/start the session.

Expected:

- App does not crash or hang.
- Session can start without coordinates.
- User has clear denied/unavailable feedback, or the app safely proceeds without coordinates.

Fail reason guidance:

- A crash, frozen Start button, or impossible save is a P1 failure.

### TC-04 (P0) Countdown And Overdue Transition

Coverage:

- Automated unit: `Phase1ModelAndLogicTests.test_TC04_CountdownAndOverdueTransition`

Optional manual confirmation:

1. Start a short session, ideally 2-3 minutes.
2. Watch countdown before and after expiry.

Expected:

- Remaining time decreases.
- Active session becomes overdue at or after expected end time.

### TC-05 (P0) T-15 Notification

Coverage:

- Automated request-level unit: `Phase1NotificationAndHandoffTests.test_TC05_TC06_NotificationRequestsScheduled_WhenFutureTimes`
- Automated edge unit: `Phase1NotificationAndHandoffTests.test_TC05_WarningSkipped_WhenAlreadyPast`
- Manual OS delivery required for final confidence.

Manual steps:

1. Allow notifications.
2. Start a 16-minute session.
3. Lock device or background app.
4. Wait about 1 minute.

Expected:

- Local notification appears at roughly T-15.
- Notification content identifies the parking session.

Fail reason guidance:

- If unit passes but OS delivery fails, inspect notification authorization, trigger creation, app notification settings, and Focus/Do Not Disturb state.

### TC-06 (P0) Expiry Notification

Coverage:

- Automated request-level unit: `Phase1NotificationAndHandoffTests.test_TC05_TC06_NotificationRequestsScheduled_WhenFutureTimes`
- Manual OS delivery required for final confidence.

Manual steps:

1. Allow notifications.
2. Start a short session, for example 2 minutes.
3. Lock device or background app.
4. Wait for expected end time.

Expected:

- Expiry notification appears at or near the expected end time.

### TC-07 (P0) End Parking Manually

Coverage:

- Automated UI: `Phase1UITests.test_TC07_TC08_EndSession_AppearsInHistoryMapDetail`
- Automated unit: `Phase1StorageAndStoreTests.test_TC07_EndSession_FinalizesAndCancelsNotifications`

Manual steps:

1. Start an active session.
2. Tap `End Parking`.

Expected:

- Active session disappears from Home.
- No-active state appears.
- Completed session is saved and appears in the Map detail sheet.
- Pending notifications for that session are canceled.

### TC-08 (P0) Map Detail Integrity

Coverage:

- Automated UI smoke: `Phase1UITests.test_TC07_TC08_EndSession_AppearsInHistoryMapDetail`
- Automated persistence: `Phase1StorageAndStoreTests.test_TC08_NotePersistence_RoundTrip`

Manual steps:

1. Create at least three completed sessions.
2. Include one note: `pillar B`.
3. Open Map.
4. Tap a saved parking marker and open its detail sheet.

Expected:

- Map tab shows the map only; there is no separate list mode.
- Saved parking spots appear as map markers.
- The marker detail sheet shows location names, notes, times, and statuses correctly.
- Recent sessions in a spot are understandable and stable.

### TC-09 (P0) Map Rendering

Coverage:

- Manual visual required.
- Related automated coverage: `Phase1UITests.test_TC11_TC12_MapDetailSheet_ShowsSpotInfoAndActions`

Steps:

1. Create at least two completed sessions with coordinates.
2. Open Map.

Expected:

- Map loads.
- Marker(s) appear for saved coordinates or grouped spots.
- Empty-state appears only when no coordinate-bearing sessions exist.
- Search field can relocate the map to an address and filter saved history near that address.
- Search result selection keeps nearby Personal History visible and ranked by distance.
- Specific address results zoom close; broad landmark/neighborhood results use a wider range.
- If nearby saved markers exist, the map frames the selected search result and those markers together.
- Range controls must change map camera scale: 500 m zooms closer, 1 km is medium, and 2 km zooms out.
- Changing range after address search must keep the camera centered around the searched coordinate.

Fail reason guidance:

- If saved sessions have coordinates but the map is empty, inspect `HistoryMapView`, `HistoryMapViewModel`, and `ParkingSpotGroupingService`.
- If address search does not relocate the map or filter nearby history, inspect `HistoryMapViewModel.searchAddressResults()`, `HistoryMapViewModel.selectSearchResult(_:)`, and the search camera helpers.

### TC-10 (P1) Group Nearby Sessions Into One Marker

Coverage:

- Automated unit: `Phase1ModelAndLogicTests.test_TC10_GroupNearbySessions`
- Automated unit: `Phase1ModelAndLogicTests.test_TC10_GroupingThreshold_BeyondThresholdCreatesSeparateGroups`

Manual visual confirmation:

1. Create repeated sessions at the same/nearby spot.
2. Open Map.

Expected:

- Nearby sessions appear as one grouped marker.
- Separate far-away sessions appear as separate groups.
- Group name uses the most recent session in the group.

### TC-11 (P1) Marker Interaction Flow

Coverage:

- Automated UI: `Phase1UITests.test_TC11_TC12_MapDetailSheet_ShowsSpotInfoAndActions`

Manual steps:

1. Open Map with at least one marker.
2. Tap the marker.

Expected:

- Detail sheet opens.
- Tapping marker does not auto-open navigation.

### TC-12 (P1) Detail Sheet Content

Coverage:

- Automated UI: `Phase1UITests.test_TC11_TC12_MapDetailSheet_ShowsSpotInfoAndActions`

Manual steps:

1. Open detail sheet from a grouped marker.

Expected:

- Spot name is visible.
- Coordinates are visible.
- Recent sessions are visible.
- Notes/status summary are visible when data exists.
- Grouped-session count is visible.
- Apple Maps and Google Maps buttons are visible.

### TC-13 (P1) Navigation Handoff Actions

Coverage:

- Automated URL unit: `Phase1NotificationAndHandoffTests.test_TC13_GoogleMapsURLGeneration`
- Manual external-app handoff required.

Manual steps:

1. Open a marker detail sheet with coordinates.
2. Tap `Open in Apple Maps`.
3. Return to app.
4. Tap `Open in Google Maps`.

Expected:

- Apple Maps opens directions or destination.
- Google Maps opens when installed.
- If Google Maps is unavailable, app fails gracefully or falls back to Apple Maps.
- Navigation is launched only from sheet buttons, not marker tap.

### TC-14 (P0) Persistence After Relaunch

Coverage:

- Automated UI: `Phase1UITests.test_TC14_Relaunch_RestoresActiveSession`
- Automated unit: `Phase1StorageAndStoreTests.test_TC14_PersistenceRoundTrip_LoadsActiveAndCompleted`

Manual steps:

1. Create one completed session.
2. Create one active session.
3. Force close app.
4. Relaunch app.

Expected:

- Active session is restored on Home.
- Completed session remains in History.
- Countdown resumes from restored expected end time.

---

## Result Classification Rules

Use these exact status values in `PHASE1_TEST_REPORT_DATA.json`:

- `PASS`: automated or manual case fully passed.
- `FAIL`: observed failure, assertion failure, wrong behavior, crash, missing UI, or incorrect saved data.
- `BLOCKED`: could not execute because of environment/tooling/device limitation.
- `NOT RUN`: intentionally not run. Avoid this for final sign-off unless the case is explicitly deferred.

Priority handling:

- Any P0 `FAIL` or `BLOCKED` means **NOT READY**.
- Any P1 `FAIL` or `BLOCKED` means **NOT READY**, unless the owner explicitly accepts the risk in the conclusion report.
- Manual-only cases must be called out. Do not hide them inside automated pass counts.

---

## Report Data Format

Create/update `PHASE1_TEST_REPORT_DATA.json` inside the timestamped report folder after the automated and manual pass. Use this structure:

```json
{
  "generatedAt": "2026-04-24T09:15:00-04:00",
  "project": "Smart Parking Reminder",
  "phase": "Phase 1",
  "xcresultPath": "Self_report/phase1/runs/20260424_091500_phase1_report/Phase1Tests_20260424_091500.xcresult",
  "xcodebuildLogPath": "Self_report/phase1/runs/20260424_091500_phase1_report/xcodebuild_20260424_091500.log",
  "testCases": [
    {
      "id": "TC-01",
      "feature": "F1/F2/F3",
      "priority": "P0",
      "testType": "UI",
      "description": "Start session from New Session screen",
      "preconditions": "Fresh app data; UI_TESTING mode for automated run",
      "steps": "Home -> Start Parking; enter Lot A; Start",
      "expected": "Active session appears on Home; location name shown; countdown visible",
      "automation": {
        "coveredBy": ["Phase1UITests.test_TC01_StartSession_ShowsActiveSessionAndCountdown"],
        "result": "PASS",
        "failureHighlight": "",
        "advice": ""
      },
      "manualOnly": false
    }
  ]
}
```

For failed cases:

- `failureHighlight` must state the concrete failure, for example `home.activeSessionCard not found after tapping Start`.
- `advice` must state the likely code area and next debugging action.
- Include screenshots/log paths in `failureHighlight` or `advice` when available.

---

## Generate Final Reports

After `PHASE1_TEST_REPORT_DATA.json` is complete, run:

```bash
node scripts/generate_phase1_report.mjs "Self_report/phase1/runs/<timestamp>_phase1_report"
```

Expected output in the same timestamped report folder:

- `PHASE1_TEST_REPORT.md`
- `PHASE1_TEST_REPORT.xlsx`

The Markdown report is the conclusion report. The Excel file is the overall test matrix. Keep the raw xcodebuild log and `.xcresult` bundle saved even when all tests pass.

---

## Final Review Checklist

Before declaring Phase 1 ready:

- [ ] `xcodebuild` log is saved.
- [ ] `.xcresult` bundle is saved.
- [ ] `PHASE1_TEST_REPORT_DATA.json` includes all `TC-01` through `TC-14`.
- [ ] `PHASE1_TEST_REPORT.md` includes readiness and failure reasons.
- [ ] `PHASE1_TEST_REPORT.xlsx` includes Summary, Detailed Results, and Open Issues sheets.
- [ ] All P0 cases are `PASS`, including manual-only cases with evidence.
- [ ] All P1 cases are `PASS` or explicitly risk-accepted.
- [ ] Manual-only OS/device checks are not silently skipped.
