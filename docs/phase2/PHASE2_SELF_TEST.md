# Phase 2 Self-Test Runbook

This file is the authoritative Phase 2 self-test instruction for Clawdbot. It covers Phase 2 work completed so far and keeps Phase 1 behavior frozen.

Phase 2 sign-off for a checkpoint is allowed only when every P0 and P1 case is `PASS`, or a manual-only item is explicitly marked `NOT RUN` with accepted risk and evidence notes. Any `FAIL` or `BLOCKED` means **NOT READY** for the next Phase 2 slice.

## Test-Only Maintenance

The Phase 2 Test / QA thread may update this runbook when design, roadmap, architecture, or handoff notes change test expectations.

Allowed QA-thread edits:

- add or revise test cases
- clarify expected behavior
- add automated test names
- add manual evidence requirements
- update report/data instructions
- add blocked/not-run guidance

Not allowed in this runbook:

- redesign features
- change product scope or phase boundaries
- add implementation instructions beyond what is needed for validation
- introduce backend, login, cloud sync, analytics, ML, continuous background location, old History list, public/community map, payment, or production Green P requirements

## Scope Boundary

Phase 2 must remain local-only during this checkpoint:

- no backend
- no login
- no cloud sync
- no analytics
- no machine learning
- no continuous background location tracking
- no old History list screen

Current Phase 2 checkpoint includes:

- persistence schema versioning
- active session `Remaining` / `Due Soon` / `Overdue` status
- defensive timer formatting with no negative countdown
- improved Home active-session card
- Apple Maps-style Map bottom sheet
- map-only History workflow
- local saved-history search by spot/session name and notes
- adjustable nearby-history search radius: 500 m, 1 km, 2 km
- pure History map filtering service for local text, metadata, and nearby filtering
- marker layer model for personal-history markers and search-area marker identity
- dormant public parking / Green P data models with no production layer or availability claim
- Phase 2 privacy/data-boundary and widget shared-state decisions
- completed-late History timing accuracy
- ActivityKit-backed Live Activity first implementation
- ActivityKit lifecycle verification with debug-only seeded start/update/end evidence
- date-driven Live Activity content state that is not dependent on app foreground timers
- Quick Start parking first implementation
- Quick Start fixed session name: `Quick Start`, not the previous saved spot name
- Quick Start recent-duration suggestion from local completed history
- Manual Start precise duration picker with presets plus hour/minute custom control
- Map search camera fitting for specific and broad results while keeping nearby Personal History visible
- Map initial user-location behavior with Toronto fallback
- Map relocate button using one-shot current location only
- Map `Search This Area` button after manual pan/zoom, using the visible map center for local saved-history filtering
- Bounded UI redesign for Home, active-session card, New Session, Map sheet, and spot detail visual polish
- Floating Home/Map mode switch replacing the standard tab bar
- Personal spot metadata first implementation: favorite, rating, tags, and spot-level note in the Map detail workflow
- Personal spot display-name editing in the Map detail workflow
- Personal metadata filter chips in the Map bottom sheet: All, Favorites, 4+ Stars, and supported tags

The real ActivityKit/widget extension now exists. ActivityKit creation, update, and dismissal have simulator log evidence, but Lock Screen and Dynamic Island visual presentation still require final screenshot or video evidence on a supported simulator or physical device.

## Required Deliverables

Save all outputs under one timestamped Phase 2 report folder:

`Self_report/phase2/runs/<timestamp>_phase2_report/`

Required files:

1. `PHASE2_TEST_REPORT.md`
   - Conclusion report.
   - Must include readiness, failed-case reasons, likely failing area, and recommended next action.
2. `PHASE2_TEST_REPORT.xlsx`
   - Excel overview of all `P2-TC-01` through `P2-TC-18`.
   - Must include summary counts, detailed rows, and open issues.
3. `PHASE2_TEST_REPORT_DATA.json`
   - Structured source data used to create the Markdown and Excel report.
4. `xcodebuild_<timestamp>.log`
   - Full raw automated test log.
5. `Phase2Tests_<timestamp>.xcresult`
   - Xcode result bundle from the automated run.
6. Manual evidence, when applicable:
   - screenshots, screen recordings, or short notes under `attachments_manual/`.

Use one timestamp for a full run, for example `20260429_113000`.

## Standard Setup

1. Use the latest workspace state.
2. Record git branch and commit SHA.
3. Record Xcode version.
4. Record simulator/device name and OS version.
5. Reset app data before manual UI checks.
6. Confirm Phase 1 core loop still works:
   - Start parking -> countdown -> reminder scheduling -> end session -> save history -> find saved spot on map.

Recommended automated destination:

```bash
platform=iOS Simulator,name=iPhone 17,OS=26.2
```

If that exact simulator is unavailable, use the newest available iPhone simulator and record the exact destination.

## Automated Test Commands

From the project root:

```bash
TS=$(date +%Y%m%d_%H%M%S)
REPORT_DIR="Self_report/phase2/runs/${TS}_phase2_report"
mkdir -p "${REPORT_DIR}"
xcodebuild test \
  -project "SmartParkingReminder/SmartParkingReminder.xcodeproj" \
  -scheme SmartParkingReminder \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2' \
  -resultBundlePath "${REPORT_DIR}/Phase2Tests_${TS}.xcresult" \
  2>&1 | tee "${REPORT_DIR}/xcodebuild_${TS}.log"
```

If the full run is blocked by simulator availability, preserve the failed log and run the focused checks below.

Focused unit check:

```bash
xcodebuild test \
  -project SmartParkingReminder/SmartParkingReminder.xcodeproj \
  -scheme SmartParkingReminder \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:SmartParkingReminderTests \
  -derivedDataPath /tmp/SmartParkingReminderPhase2UnitTests
```

Focused active-session UI check:

```bash
xcodebuild test \
  -project SmartParkingReminder/SmartParkingReminder.xcodeproj \
  -scheme SmartParkingReminder \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:SmartParkingReminderUITests/Phase1UITests/test_Phase2ActiveSession_DueSoonStateIsVisible \
  -only-testing:SmartParkingReminderUITests/Phase1UITests/test_Phase2ActiveSession_OverdueStateIsVisibleWithoutAutoEnding \
  -derivedDataPath /tmp/SmartParkingReminderPhase2ActiveSessionUITests
```

Focused Map bottom-sheet UI check:

```bash
xcodebuild test \
  -project SmartParkingReminder/SmartParkingReminder.xcodeproj \
  -scheme SmartParkingReminder \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:SmartParkingReminderUITests/Phase1UITests/test_TC07_TC08_EndSession_AppearsInHistoryMapDetail \
  -only-testing:SmartParkingReminderUITests/Phase1UITests/test_TC11_TC12_MapDetailSheet_ShowsSpotInfoAndActions \
  -only-testing:SmartParkingReminderUITests/Phase1UITests/test_Phase1HistoryDetail_BackReturnsToHistoryPanel \
  -only-testing:SmartParkingReminderUITests/Phase1UITests/test_Phase2HistoryMapSearch_LocalNoteSearchOpensMatchingSpotDetail \
  -derivedDataPath /tmp/SmartParkingReminderPhase2MapUITests
```

Focused Quick Start UI check:

```bash
xcodebuild test \
  -project SmartParkingReminder/SmartParkingReminder.xcodeproj \
  -scheme SmartParkingReminder \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:SmartParkingReminderUITests/Phase1UITests/test_Phase2QuickStart_ThirtyMinutesStartsActiveSession \
  -derivedDataPath /tmp/SmartParkingReminderPhase2QuickStartUITests
```

Focused floating mode switch UI check:

```bash
xcodebuild test \
  -project SmartParkingReminder/SmartParkingReminder.xcodeproj \
  -scheme SmartParkingReminder \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:SmartParkingReminderUITests/Phase1UITests/test_Phase2ModeSwitch_TogglesBetweenHomeAndMapWithoutTabBar \
  -derivedDataPath /tmp/SmartParkingReminderPhase2ModeSwitchUITests
```

## Test Case Matrix

| ID | Priority | Area | Coverage |
|---|---:|---|---|
| P2-TC-01 | P0 | Phase 1 regression/core loop | Full automated suite + manual smoke |
| P2-TC-02 | P0 | Versioned persistence envelope | Unit automated |
| P2-TC-03 | P0 | Legacy Phase 1 storage compatibility | Unit automated |
| P2-TC-04 | P0 | Unsupported future schema rejection | Unit automated |
| P2-TC-05 | P0 | Notification replacement lifecycle | Unit automated |
| P2-TC-06 | P0 | Remaining / Due Soon / Overdue timer states | Unit automated |
| P2-TC-07 | P0 | No negative timer and overdue stays active | Unit + UI automated |
| P2-TC-08 | P1 | Home active-session visual states | UI automated + manual visual |
| P2-TC-09 | P1 | Map bottom sheet, filtering, and marker-layer workflow | UI automated + manual visual |
| P2-TC-10 | P0 | History completed-late timing accuracy | Unit automated + UI smoke |
| P2-TC-11 | P1 | Live Activity / Dynamic Island | Build + unit automated + manual visual |
| P2-TC-12 | P0 | Scope freeze / no forbidden features | Manual code/product review |
| P2-TC-13 | P1 | Quick Start parking | Unit + UI automated + manual visual |
| P2-TC-14 | P1 | Personal spot metadata and display name | Unit automated + manual visual |
| P2-TC-15 | P1 | Manual Start precise duration | Unit + UI automated + manual visual |
| P2-TC-16 | P1 | Map current location and relocate | Manual visual |
| P2-TC-17 | P1 | Map Search This Area | Unit automated + manual visual |
| P2-TC-18 | P1 | Bounded UI redesign and floating mode switch | UI automated + manual visual |

## Detailed Test Cases

### P2-TC-01 Phase 1 Regression/Core Loop

Expected:

- Existing Phase 1 automated tests still pass.
- Start/end/history/map workflow remains intact.
- History remains map-only.

Fail reason guidance:

- Any failure here is a release blocker. Inspect the changed Phase 2 area first, then verify Phase 1 assumptions were not broken.

### P2-TC-02 Versioned Persistence Envelope

Automated coverage:

- `Phase1StorageAndStoreTests.test_Phase2Storage_SaveWritesVersionedEnvelope`

Expected:

- New saves include `schemaVersion`, `savedAt`, and `sessions`.
- Saved sessions reload correctly.

### P2-TC-03 Legacy Phase 1 Storage Compatibility

Automated coverage:

- `Phase1StorageAndStoreTests.test_Phase2Storage_LoadsLegacyPhase1BareArray`

Expected:

- Old Phase 1 bare `[ParkingSession]` JSON still loads.

### P2-TC-04 Unsupported Future Schema Rejection

Automated coverage:

- `Phase1StorageAndStoreTests.test_Phase2Storage_RejectsUnsupportedFutureSchemaVersion`

Expected:

- Unsupported future schema versions fail explicitly.
- The app must not silently reinterpret future data as current data.

### P2-TC-05 Notification Replacement Lifecycle

Automated coverage:

- `Phase1StorageAndStoreTests.test_Phase2NotificationLifecycle_ReplacingActiveSessionCancelsOldAndSchedulesNew`

Expected:

- Starting a new session while another is active completes/cancels the old session path.
- New local notifications are scheduled for the new session.

### P2-TC-06 Remaining / Due Soon / Overdue Timer States

Automated coverage:

- `Phase1StorageAndStoreTests.test_Phase2Countdown_FutureEndTimeShowsRemaining`
- `Phase1StorageAndStoreTests.test_Phase2Countdown_EndTimeWithin15MinutesShowsDueSoon`
- `Phase1StorageAndStoreTests.test_Phase2Countdown_PastActiveSessionShowsOverdueWithoutAutoEnding`
- `Phase1StorageAndStoreTests.test_Phase2Countdown_RelaunchRestoresPastActiveSessionAsOverdue`

Expected:

- More than 15 minutes remaining shows `Remaining`.
- 0 to 15 minutes remaining shows `Due Soon`.
- Past expected end time shows `Overdue`.
- Overdue display time is positive elapsed time.

### P2-TC-07 No Negative Timer And Overdue Stays Active

Automated coverage:

- `Phase1ModelAndLogicTests.test_Phase2DisplayFormatter_NeverFormatsNegativeIntervals`
- `Phase1UITests.test_Phase2ActiveSession_OverdueStateIsVisibleWithoutAutoEnding`

Expected:

- No UI or formatter path displays negative time.
- Overdue session remains active until the user taps End Parking.
- End Parking still saves history and cancels notifications.

### P2-TC-08 Home Active-Session Visual States

Automated coverage:

- `Phase1UITests.test_Phase2ActiveSession_DueSoonStateIsVisible`
- `Phase1UITests.test_Phase2ActiveSession_OverdueStateIsVisibleWithoutAutoEnding`

Manual visual confirmation:

1. Launch seeded due-soon and overdue UI states if possible.
2. Confirm status label, time text, progress treatment, and helper copy are readable.
3. Confirm no text overlap on the target simulator.

Expected:

- `Due Soon` and `Overdue` are visually distinct.
- Overdue copy reads as positive elapsed overdue time.

### P2-TC-09 Map Bottom Sheet, Filtering, And Marker-Layer Workflow

Automated coverage:

- `Phase1ModelAndLogicTests.test_Phase2HistoryMapSearch_UsesInjectedProviderAndFiltersNearbyHistory`
- `Phase1ModelAndLogicTests.test_Phase2HistoryMapSearch_SearchFailureKeepsHistoryVisible`
- `Phase1ModelAndLogicTests.test_Phase2HistoryMapSearch_LocalQueryFiltersSavedSpotNamesAndNotes`
- `Phase1ModelAndLogicTests.test_Phase2HistoryMapSearch_NoAddressResultKeepsLocalHistoryMatches`
- `Phase1ModelAndLogicTests.test_Phase2HistoryMapSearch_AdjustingRadiusRecomputesNearbyHistory`
- `Phase1ModelAndLogicTests.test_Phase2HistoryMapFilteringService_LocalQueryIncludesMetadataFields`
- `Phase1ModelAndLogicTests.test_Phase2HistoryMapFilteringService_NearbyFilterComposesWithMetadataFilter`
- `Phase1ModelAndLogicTests.test_Phase1MapSearch_AddressResultsDoNotHidePersonalHistoryBeforeSelection`
- `Phase1ModelAndLogicTests.test_Phase1MapSearch_SelectedAddressRanksNearbyHistoryByDistance`
- `Phase1ModelAndLogicTests.test_Phase1MapSearch_CameraUsesBroadResultRegionWhenProvided`
- `Phase1ModelAndLogicTests.test_Phase1MapSearch_CameraFramesSelectedResultAndNearbyHistory`
- `Phase1ModelAndLogicTests.test_Phase1MapSearch_SelectedRangeControlsCameraScale`
- `Phase1ModelAndLogicTests.test_Phase1MapSearch_SelectedRangeCameraCentersOnSearchResult`
- `Phase1UITests.test_TC07_TC08_EndSession_AppearsInHistoryMapDetail`
- `Phase1UITests.test_TC11_TC12_MapDetailSheet_ShowsSpotInfoAndActions`
- `Phase1UITests.test_Phase1HistoryDetail_BackReturnsToHistoryPanel`
- `Phase1UITests.test_Phase2HistoryMapSearch_LocalNoteSearchOpensMatchingSpotDetail`

Manual visual confirmation:

1. Open Map.
2. Confirm collapsed state shows compact search only.
3. Tap search and confirm the sheet expands enough for keyboard-safe saved-history selection.
4. Type a saved spot name or note and confirm Personal History filters inside the sheet.
5. Tap `Done` above the keyboard and confirm the keyboard hides without clearing the search text.
6. Tap the map/background and confirm the keyboard hides.
7. Submit a search and confirm the keyboard hides while the map/search workflow remains usable.
8. Open a saved spot detail sheet and confirm Apple Maps / Google Maps buttons are fully visible, tappable, and not covered by the floating tab bar or home indicator.
9. On a smaller iPhone simulator/device, scroll the expanded detail sheet and confirm the last controls remain reachable above the bottom safe area.
10. Search an address and confirm map relocation.
11. Select a specific address result and confirm the camera zooms close enough to inspect the selected area.
12. Select a landmark, neighborhood, or broad result and confirm the camera uses a wider range instead of a random/default zoom.
13. Confirm nearby Personal History remains visible after address search and is ranked by distance from the searched coordinate.
14. If multiple nearby saved markers exist, confirm the map frames the selected search result and nearby history markers together.
15. If no nearby saved history exists, confirm the sheet shows a clear nearby-history empty state without hiding the selected search result.
16. Tap 500 m and confirm the map zooms closer around the searched coordinate.
17. Tap 1 km and confirm the map uses a medium range around the same coordinate.
18. Tap 2 km and confirm the map zooms out around the same coordinate.
19. Confirm changing the nearby-history radius also updates saved spots in the sheet/map.
20. After an address search, change the range again and confirm the camera scale updates around the searched coordinate.
21. Tap saved marker and confirm details stay in the bottom-sheet workflow.
22. Confirm personal-history markers still open saved spot detail.
23. Confirm address search still shows the search-area marker.
24. Confirm personal-history markers and search-area marker remain visually distinct.
25. Confirm no public, Green P, provider, backend, cloud, analytics, ML, or community marker layer appears.

Expected:

- Map remains the main visual focus.
- No separate old History list screen appears.
- Search/history rows remain selectable while the keyboard is visible.
- Detail sheet bottom actions remain above the floating tab bar and home indicator.
- Search must not hide Personal History; it may filter/rank nearby saved spots by selected result distance.
- Search result selection must update map range deterministically for address and broad results.
- Selected range must control both nearby-history filtering and map camera scale.
- Personal-history marker behavior is unchanged after marker layer model extraction.
- Search-area marker behavior is unchanged after marker layer model extraction.
- Marker layer identity is internal architecture preparation only; it must not expose a new public parking layer.

### P2-TC-10 History Completed-Late Timing Accuracy

Automated coverage:

- `Phase1ModelAndLogicTests.test_Phase1HistoryTimingSummary_CompletedOnTimeSessionCountsOnTime`
- `Phase1ModelAndLogicTests.test_Phase1HistoryTimingSummary_CompletedOverdueSessionCountsOverdue`
- `Phase1ModelAndLogicTests.test_Phase1HistoryTimingSummary_ActiveOverdueSessionCountsOverdue`
- `Phase1ModelAndLogicTests.test_Phase1HistoryRecentSessionRowText_ShowsOverdueDuration`
- `Phase1StorageAndStoreTests.test_Phase1HistoryTiming_RestoredCompletedOverdueSessionStillCountsOverdue`

Expected:

- Completed on-time sessions count under `On Time`.
- Completed-late sessions count under `Overdue`.
- Recent rows show expected end, actual end, and overdue duration.

### P2-TC-11 Live Activity / Dynamic Island

Automated coverage:

- `xcodebuild build-for-testing` with `SmartParkingReminderWidgetExtension.appex` embedded
- `Phase1StorageAndStoreTests.test_Phase2ActivityKitPayload_MapsPrivacySafeSnapshot`
- `Phase1StorageAndStoreTests.test_Phase2ActivityLifecycle_StartSessionPublishesPrivacySafeSnapshot`
- `Phase1StorageAndStoreTests.test_Phase2ActivityLifecycle_EndSessionEndsActivity`
- `Phase1StorageAndStoreTests.test_Phase2ActivityLifecycle_RestoreActiveSessionPublishesRestoredSnapshot`
- `Phase1StorageAndStoreTests.test_Phase2ActivityLifecycle_AddTimePublishesDateDrivenUpdateAndReschedulesNotifications`
- `Phase1StorageAndStoreTests.test_Phase2ActivityLifecycle_RestoreWithoutActiveSessionEndsOrphanedActivities`

Manual visual confirmation:

1. Use a supported iPhone simulator or physical device.
2. Start a parking session.
3. Confirm a Live Activity appears on the Lock Screen when available.
4. On a Dynamic Island-capable device, confirm compact and expanded Dynamic Island states show parking status and time.
5. Start a 2-minute session, lock the device, and confirm the Lock Screen / Dynamic Island timer does not freeze while the app is not foregrounded.
6. Let the short session become overdue while locked and confirm the Live Activity uses overdue wording without requiring the app to reopen.
7. If an Add Time control is available in the build under test, add time and confirm the Live Activity scheduled end date/timer updates immediately.
8. End parking and confirm the Live Activity dismisses.
9. Reopen the app after expiry and confirm the active session reconciles to overdue state, or orphaned Live Activities are ended if no active session exists.

Expected:

- Live Activity display is driven by absolute dates, not preformatted remaining-time strings.
- App foreground timer suspension must not freeze the Lock Screen or Dynamic Island countdown/status.
- `Activity.update` should happen on real events only: start, add time, end, launch reconciliation, or session data changes.
- Guaranteed background/server-driven status pushes are not part of Phase 2. Future research should use official ActivityKit push updates through APNs.

Optional deterministic simulator evidence command:

1. Build the app for the target simulator.
2. Install the built app.
3. Launch with `LIVE_ACTIVITY_TESTING` and these environment variables:
   - `LIVE_ACTIVITY_SESSION_OFFSET_SECONDS`
   - `LIVE_ACTIVITY_SESSION_LOCATION`
   - `LIVE_ACTIVITY_STORAGE_FILE`
   - `LIVE_ACTIVITY_AUTO_END_AFTER_SECONDS`
4. Save an ActivityKit log excerpt with:

```bash
xcrun simctl spawn booted log show --last 5m --style compact --predicate 'process == "SmartParkingReminder" AND subsystem == "com.apple.activitykit"'
```

5. Confirm the log contains `Requesting an activity`, `Received new activity`, `Creating activity`, `Updating activity`, `Ending activity`, and `Activity dismissed`.

Current evidence reference:

- `Self_report/phase2/runs/20260430_152900_live_activity_verification/LIVE_ACTIVITY_VERIFICATION_REPORT.md`
- `Self_report/phase2/runs/20260430_152900_live_activity_verification/activitykit_auto_end_log_excerpt.txt`
- `Self_report/phase2/runs/20260430_152900_live_activity_verification/attachments_manual/05_app_after_auto_end.png`

Expected:

- Store publishes start, restore, update, and end lifecycle events through `ParkingActivityLifecycleManaging`.
- Snapshot is privacy-safe: no note, coordinate, full history, account, backend, or analytics payload.
- Normal app startup uses the ActivityKit manager.
- UI-test startup still uses no-op support so automated UI tests are not blocked by system services.
- The app target declares `NSSupportsLiveActivities`.

### P2-TC-12 Scope Freeze / Forbidden Features

Manual code/product review:

1. Confirm no backend, login, cloud sync, analytics, ML, or continuous background location was added.
2. Confirm no old History list screen or list-based History replacement was added.
3. Confirm Live Activity uses local ActivityKit only, with no server push or backend service.
4. Confirm dormant public parking / Green P models are not connected to Map UI, storage, networking, search, or production data.
5. Confirm no real-time Green P/public parking availability claim is visible.
6. Confirm no App Group entitlement or shared JSON store was added for the current Live Activity/widget path.
7. For future location-derived features, confirm handoffs identify privacy category and persistence location.

Expected:

- Scope remains local-only.
- Map remains the only History surface.
- Public parking models remain architecture-only until a future disabled/static prototype or production layer handoff exists.
- Widget shared state remains ActivityKit content state only unless a future handoff explicitly changes the decision.

### P2-TC-13 Quick Start Parking

Automated coverage:

- `Phase1StorageAndStoreTests.test_Phase2QuickStartDraft_UsesSameSessionCreationPath`
- `Phase1StorageAndStoreTests.test_Phase1QuickStartName_DoesNotReuseMostRecentSessionLocation`
- `Phase1StorageAndStoreTests.test_Phase2QuickStartDurationOptions_IncludeRecentNonDefaultDuration`
- `Phase1UITests.test_Phase2QuickStart_ThirtyMinutesStartsActiveSession`

Manual visual confirmation:

1. Launch with no active session.
2. Confirm the Home screen shows compact Quick Start controls for 30 min, 1 hr, and 2 hr.
3. If local completed history has a non-default planned duration, confirm the additional rounded recent-duration option appears without crowding the Home screen.
4. Tap 30 min and confirm an active session starts with location name `Quick Start`, `Remaining` state, and no negative timer.
5. Confirm Quick Start does not reuse the most recent completed spot name, such as `Work` or `Home`.
6. End parking and confirm the completed session appears in the Map workflow.
7. Start a normal full New Session and confirm that flow still works and still allows a manually typed location/spot name.

Expected:

- Quick Start uses the same store creation path as the full New Session flow.
- Quick Start session name is always `Quick Start` at creation time.
- Quick Start does not appear while a session is already active.
- Quick Start remains local-only and uses one-shot location only.
- Recent-duration suggestion is derived only from local completed history and does not use analytics, ML, backend, or cloud.

### P2-TC-14 Personal Spot Metadata And Display Name

Automated coverage:

- `Phase1StorageAndStoreTests.test_Phase2PersonalSpotMetadataStorage_RoundTripsLocalMetadata`
- `Phase1ModelAndLogicTests.test_Phase2PersonalSpotMetadata_LocalQueryFiltersTagsAndSpotNote`
- `Phase1ModelAndLogicTests.test_Phase2PersonalSpotMetadata_UpdatePersistsAndKeepsSelectionVisible`
- `Phase1ModelAndLogicTests.test_Phase2PersonalSpotMetadataFilter_FavoritesFiltersVisibleMapGroups`
- `Phase1ModelAndLogicTests.test_Phase2PersonalSpotMetadataFilter_ComposesWithAddressRadius`

Manual visual confirmation:

1. Open Map.
2. Open an existing saved spot detail sheet.
3. Confirm the detail sheet includes `Personal details`.
4. Toggle favorite, choose a rating, select one or more tags, and add a spot note.
5. Leave the detail sheet and reopen the same spot.
6. Confirm metadata remains visible.
7. Search by the spot note or selected tag from the Map search field.
8. Confirm matching saved spots stay inside the Map workflow, with no old History list screen.
9. In the Map bottom sheet, select `Favorites`, `4+ Stars`, and at least one tag filter.
10. Confirm the map markers and Personal History rows narrow to matching saved spots.
11. Search an address, change the radius if needed, then apply a metadata filter.
12. Confirm the visible saved spots satisfy both the address/radius result and the metadata filter.
13. Enter a custom `Spot name` in Personal Details.
14. Close and reopen the same saved spot detail.
15. Confirm the custom display name appears as the saved spot title.
16. Clear the custom spot name with a whitespace-only or empty value.
17. Confirm the title returns to the derived saved-history name.

Expected:

- Metadata is local-only.
- Metadata is attached to a saved map spot, not to a public/community layer.
- Custom display name remains local-only and map-first.
- Clearing display name falls back to derived saved-history naming.
- Map remains the only History surface.
- Search can match metadata notes and tags.
- Metadata filters compose with local search and address-radius filtering.
- No backend, login, cloud sync, analytics, ML, continuous background location, public/community map, or marketplace is introduced.

### P2-TC-15 Manual Start Precise Duration

Automated coverage:

- `Phase1StorageAndStoreTests.test_Phase1ManualStartCustomDuration_UsesSelectedDurationForScheduleAndActivity`
- `Phase1StorageAndStoreTests.test_Phase1ManualStartInvalidZeroDuration_DoesNotCreateSession`
- `Phase1UITests.test_TC01_StartSession_ShowsActiveSessionAndCountdown`

Manual visual confirmation:

1. Launch app with no active session.
2. Tap `Start Parking`.
3. Confirm duration presets are visible for 15 min, 30 min, 1 hr, and 2 hr.
4. Use the custom hour/minute pickers to select a non-default duration, such as 1 hr 25 min.
5. Enter a manually typed location name and start parking.
6. Confirm Home shows the active session with the selected location name and a countdown based on the selected custom duration.
7. End parking and confirm the saved history expected end time matches the selected duration.
8. Confirm the UI prevents or normalizes an invalid 0 minute duration.

Expected:

- Manual Start supports precise duration selection without removing quick presets.
- Default duration remains 1 hour.
- Session scheduled end date, notifications, Home countdown, and Live Activity content state all use the selected duration.
- The store rejects invalid zero-duration drafts.
- No backend, cloud, analytics, ML, community behavior, or old History list is added.

### P2-TC-16 Map Current Location And Relocate

Manual visual confirmation:

1. Fresh install or reset app location permission state if possible.
2. Open the Map tab with no saved history.
3. Confirm the SwiftUI Map still renders, rather than showing an empty/non-map state.
4. Grant When In Use permission and confirm the map centers on user location when available.
5. Confirm the user location dot appears when permission/location is available.
6. Pan away and confirm the camera is not continuously overridden.
7. Tap the relocate button and confirm it requests current location once and recenters.
8. Confirm nearby saved history is filtered using the active radius after relocation.
9. Deny or simulate unavailable location.
10. Confirm the map still opens at Toronto fallback around latitude `43.6532`, longitude `-79.3832`.
11. Confirm address search remains usable after denied/unavailable location.
12. Confirm the relocate button shows progress while in flight and a visible failure message if location fails.
13. Confirm no continuous/background location tracking starts.

Expected:

- Map tab opens as a real map even with no saved history.
- Initial location behavior uses user-location camera with Toronto fallback.
- Relocate uses one-shot location only.
- Denied/unavailable location does not block map search or map display.
- Personal History remains map-only.
- No backend, cloud, analytics, ML, public parking layer, or continuous background location is added.

### P2-TC-17 Map Search This Area

Automated coverage:

- `Phase1ModelAndLogicTests.test_Phase2HistoryMapSearch_SearchThisAreaFiltersNearbyHistory`
- `Phase1ModelAndLogicTests.test_Phase2HistoryMapSearch_SearchThisAreaPreservesMetadataFilter`
- `Phase1ModelAndLogicTests.test_Phase2HistoryMapSearch_SearchThisAreaClearsAddressResults`

Manual visual confirmation:

1. Open the Map tab.
2. Confirm the map still opens at current location when available, or Toronto fallback when unavailable.
3. Pan or zoom the map manually.
4. Confirm a compact `Search This Area` button appears only after manual map movement.
5. Tap `Search This Area`.
6. Confirm nearby Personal History markers refresh around the visible map center.
7. Confirm status text refers to `this map area`.
8. Confirm address search text/results are cleared after using `Search This Area`.
9. Change radius between 500 m, 1 km, and 2 km and confirm results continue to use the searched map area.
10. Apply Favorites, 4+ Stars, or tag filters, then pan and use `Search This Area`; confirm filters remain active.
11. Tap a marker/detail and confirm the detail flow stays inside the Map bottom-sheet workflow.
12. Confirm the button is hidden or does not block interaction while a detail is open or the bottom sheet is expanded.
13. Tap relocate and confirm it remains separate from `Search This Area`, using current location or Toronto fallback instead of the visible map center.
14. Watch for unwanted `Search This Area` flashes after initial location focus, address search selection, detail selection, and relocate.

Expected:

- `Search This Area` is a local saved-history filter only.
- The visible map center becomes the nearby-history search center after the user taps the button.
- Selected radius and metadata filters remain applied.
- Address result rows are cleared when searching the visible map area.
- Personal History remains map-only.
- No public, Green P, backend, cloud, analytics, ML, community, payment, or continuous/background location behavior is introduced.

### P2-TC-18 Bounded UI Redesign And Floating Mode Switch

Automated coverage:

- `Phase1UITests.test_Phase2ModeSwitch_TogglesBetweenHomeAndMapWithoutTabBar`
- Existing UI smoke coverage through:
  - `Phase1UITests.test_TC01_StartSession_ShowsActiveSessionAndCountdown`
  - `Phase1UITests.test_Phase2QuickStart_ThirtyMinutesStartsActiveSession`
  - `Phase1UITests.test_TC11_TC12_MapDetailSheet_ShowsSpotInfoAndActions`
  - `Phase1UITests.test_Phase1HistoryDetail_BackReturnsToHistoryPanel`

Manual visual confirmation:

1. Launch the app on Home.
2. Confirm no standard system tab bar is visible.
3. Confirm Home shows a compact circular Map mode switch near the lower-left with accessibility ID `modeSwitch.mapButton`.
4. Confirm the floating switch does not block Home primary actions, Quick Start buttons, or active-session controls.
5. Tap the Map mode switch and confirm Map opens.
6. Confirm Map shows a compact circular Home mode switch near the lower-left with accessibility ID `modeSwitch.homeButton`.
7. Confirm the Map switch is positioned above the collapsed search sheet and does not block the search field, Personal History preview, marker detail sheet, relocate button, or Search This Area button.
8. Tap the Home mode switch and confirm Home returns.
9. Confirm bounded UI polish did not change business behavior:
   - Start Parking still opens New Session.
   - New Session still requires a location name before Start.
   - Quick Start still starts through the same shared store path.
   - Active-session timer/status values remain store-driven.
   - End Parking still saves the completed session.
   - Spot detail Back still returns to the map/history panel.
10. Check smaller-screen comfort for the active-session map preview, End Parking button, Map collapsed/medium/expanded sheet, and spot detail action buttons.

Expected:

- The old standard Home/Map tab bar is absent.
- The floating mode switch toggles Home and Map reliably.
- The switch is compact, circular, material/glass-like, and does not obscure critical controls.
- Bounded UI polish changes visual hierarchy only; it must not change parking-session lifecycle, timer, notification, storage, search/filtering, or map-only History behavior.
- No backend, login, cloud sync, analytics, ML, public/community map, payment, old History list, or continuous/background location behavior is introduced.

## Report Data Template

Create `PHASE2_TEST_REPORT_DATA.json` with this shape:

```json
{
  "project": "Smart Parking Reminder",
  "phase": "Phase 2",
  "generatedAt": "2026-04-29T11:30:00-04:00",
  "gitRef": "branch-or-sha",
  "xcodeVersion": "recorded Xcode version",
  "destination": "platform=iOS Simulator,name=iPhone 17,OS=26.2",
  "xcresultPath": "Self_report/phase2/runs/<timestamp>_phase2_report/Phase2Tests_<timestamp>.xcresult",
  "xcodebuildLogPath": "Self_report/phase2/runs/<timestamp>_phase2_report/xcodebuild_<timestamp>.log",
  "testCases": [
    {
      "id": "P2-TC-01",
      "feature": "Phase 1 regression/core loop",
      "priority": "P0",
      "testType": "Automated + Manual",
      "description": "Phase 1 behavior remains intact after Phase 2 changes.",
      "expected": "Core loop passes and History remains map-only.",
      "status": "PASS",
      "coveredBy": ["full xcodebuild test"],
      "failureHighlight": "",
      "advice": "",
      "evidence": ""
    }
  ]
}
```

Allowed statuses:

- `PASS`
- `FAIL`
- `BLOCKED`
- `NOT RUN`

## Markdown Report Requirements

`PHASE2_TEST_REPORT.md` must include:

1. Final readiness:
   - `READY FOR NEXT PHASE 2 SLICE`
   - `NOT READY`
   - `READY WITH ACCEPTED MANUAL RISK`
2. Summary counts:
   - total
   - passed
   - failed
   - blocked
   - not run
3. Failed or blocked case details.
4. Manual-only evidence notes.
5. Recommendation:
   - proceed to next feature
   - fix specific issue first
   - rerun full simulator suite

## Excel Report Requirements

`PHASE2_TEST_REPORT.xlsx` must include at least three sheets:

1. `Summary`
   - project, phase, timestamp, git ref, destination, pass/fail counts, final readiness
2. `Detailed Results`
   - one row for each `P2-TC-01` through `P2-TC-18`
3. `Open Issues`
   - one row for each `FAIL` or `BLOCKED` case

## Current Phase 2 Progress Estimate

As of this runbook, Phase 2 is roughly **82% complete**.

Completed or mostly complete:

- Phase 2A foundation: versioned storage, formatter/status logic, notification audit, Swift 6 warning cleanup.
- Active-session UI: due-soon/overdue states and UI tests.
- Map bottom-sheet redesign.
- History timing accuracy fix.
- Live Activity app-side lifecycle seam.
- First ActivityKit-backed widget extension and lifecycle manager.
- ActivityKit simulator lifecycle evidence for create, update, end, and dismissal.
- Live Activity date-driven content state fix for locked/background stale status.
- First Quick Start implementation on the shared session creation path.
- Quick Start fixed-name regression: new Quick Start sessions start as `Quick Start`, not the most recent saved spot name.
- First Quick Start polish pass: local recent-duration suggestion from completed history.
- Manual Start precise duration selection with quick presets and hour/minute custom control.
- First map search provider abstraction with deterministic search/filtering unit tests.
- First pure History map filtering service with direct unit tests for local text, metadata, and nearby composition.
- First marker layer model for personal-history and search-area markers without adding public/Green P data.
- Dormant public parking / Green P model definitions with explicit no-real-time-availability guard and no UI/data-source connection.
- Phase 2 privacy/data-boundary and widget shared-state decision notes.
- First adjustable nearby-history radius control with deterministic recompute coverage.
- First local saved-history text search by saved spot/session name and notes.
- Map address search preserves nearby Personal History, ranks by distance, and fits camera range to selected result plus nearby saved markers.
- Map initial user-location/Toronto fallback behavior and one-shot relocate button.
- Map search now expands to a keyboard-safe sheet state and has UI coverage for local note search into spot detail.
- Map `Search This Area` now has focused unit coverage and needs manual pan/zoom placement validation.
- Bounded UI redesign and floating mode switch now have focused UI coverage and need manual visual/small-screen validation.
- First personal spot metadata slice: local-only favorite, rating, tags, display name, and spot-level note in the Map detail sheet.
- First personal metadata filter slice: local Map filter chips for favorites, 4+ stars, and supported tags, with unit coverage for standalone and address-radius composition.

Not complete yet:

- Final visual Live Activity presentation capture on supported device/simulator.
- Quick Start polish beyond default presets and first recent-duration suggestion.
- Deeper map layer composition beyond personal-history/search-area marker identity, address search, local text search, metadata filters, the first radius control, `Search This Area`, and the first pure filtering service.
- Personal spot metadata polish beyond the first detail-sheet editing and filter slices.
- Toronto Green P / nearby parking discovery research. Phase 2 should research official sources and may only create a disabled/static prototype if data is reliable; production layer belongs in Phase 3, and real-time/payment/deeper integration belongs in Phase 4 only with an official API or partnership.
- Full Phase 2 self-test report run after the new bounded UI/floating mode switch design.

## Recommended Next Step

Next implementation step: run or schedule a managed Phase 2 report after visual metadata review, while Clawdbot should still capture visual Lock Screen and Dynamic Island evidence during the next full Phase 2 report run.

Clawdbot should save the first Phase 2 report under `Self_report/phase2/runs/`.
