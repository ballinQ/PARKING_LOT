# Phase 2 Live Activity / Dynamic Island Spike

Status: first ActivityKit-backed implementation pass added. No backend, push service, cloud sync, ML, or continuous background location behavior has been introduced.

## What Was Added

The app now has a lifecycle boundary that `ParkingSessionStore` uses to publish active-session state. Normal app startup uses an ActivityKit-backed implementation; UI tests and unsupported paths can still use the no-op manager.

Code entry points:

- `ParkingActivitySnapshot`
- `ParkingActivityLifecycleManaging`
- `NoopParkingActivityLifecycleManager`
- `ActivityKitParkingActivityLifecycleManager`
- `ParkingReminderActivityAttributes`
- `SmartParkingReminderWidgetExtension`
- `ParkingSessionStore.activitySnapshot(for:)`

Lifecycle events now covered:

1. `sessionStarted(_:)`
2. `activeSessionRestored(_:)`
3. `activeSessionUpdated(_:)`
4. `sessionEnded(sessionID:)`

The ActivityKit implementation starts/restores, throttles updates, and ends local Live Activities with `pushType: nil`. Local notifications remain the fallback reminder path.

## Snapshot Boundary

`ParkingActivitySnapshot` includes only the minimum display data needed for a future Live Activity:

- `sessionID`
- `locationName`
- `expectedEndTime`
- `status`
- `displayTime`
- `timeText`
- `updatedAt`

It intentionally does not include notes, coordinates, full history, analytics payloads, user identity, or cloud identifiers.

## Why This Comes First

The active-session card, overdue status, relaunch restore behavior, and notification lifecycle are now stable enough to define one shared session lifecycle. This seam lets the future ActivityKit implementation consume store-owned state instead of duplicating countdown, due-soon, or overdue logic in a widget extension.

## Tests Added

- Starting a session publishes a privacy-safe activity snapshot.
- Ending a session publishes the activity end event.
- Relaunching with an overdue active session publishes an overdue restored snapshot.
- ActivityKit attributes/content state map only the privacy-safe snapshot fields.
- Build-for-testing succeeds with the widget extension embedded.

Latest focused unit result:

- Command: `xcodebuild test -project SmartParkingReminder/SmartParkingReminder.xcodeproj -scheme SmartParkingReminder -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:SmartParkingReminderTests -derivedDataPath /tmp/SmartParkingReminderLiveActivityUnitTests2`
- Result: `** TEST SUCCEEDED **`
- Unit tests: 27 passed, 0 failed.

Latest build result:

- Command: `xcodebuild build-for-testing -project SmartParkingReminder/SmartParkingReminder.xcodeproj -scheme SmartParkingReminder -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/SmartParkingReminderLiveActivityBuild2`
- Result: `** TEST BUILD SUCCEEDED **`

## Remaining ActivityKit Steps

1. Manually verify Lock Screen and Dynamic Island presentation on supported simulator/device configurations.
2. Confirm whether an App Group is needed for any future shared resources. Done for the current Live Activity: no App Group is needed because ActivityKit content state is the extension boundary. See `PHASE2_WIDGET_SHARED_STATE_DECISION.md`.
3. Decide what stale/overdue Live Activity state should show if the app is relaunched long after expiry.
4. Add UI/self-test evidence to the Phase 2 report.

## Do Not Implement Yet

- Backend session service
- Cloud sync
- Push notification updates
- User login
- Analytics
- ML recommendations
- Community parking map
- Green P/payment automation
- Continuous background location tracking
- Old History list screen
- App Group shared storage for the current Live Activity
