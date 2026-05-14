# Phase 2 Notification Lifecycle Audit

Status: Phase 2A audit complete. Live Activity and Quick Start now build on this lifecycle path. No backend, push notification service, cloud sync, analytics, ML, or background location behavior is introduced here.

## Current Lifecycle

| Event | Current behavior | Audit result |
|---|---|---|
| Start new session | `ParkingSessionStore.startNewSession` saves the active session, then calls `scheduleNotifications(for:)` | Good. `ParkingNotificationService` cancels same-session pending requests before adding new warning/expiry requests. |
| End active session | `ParkingSessionStore.endActiveSession` marks the session completed, persists it, then calls `cancelNotifications(for:)` | Good. Covered by existing unit test. |
| Replace active session | `startNewSession` ends the existing active session before creating the new one | Good after Phase 2A test coverage. New test verifies old notification cancel and new notification schedule. |
| App relaunch | `ParkingSessionStore.start()` loads persisted sessions and restores active state | Accept for now. Local notifications should remain scheduled by iOS after relaunch. Do not auto-reschedule until Live Activity/widget policy is designed. |
| Past warning time | Warning notification is skipped when the warning time is already past | Good. Covered by existing unit test. |
| Past expiry time | Expiry notification is skipped when the expiry time is already past | Accept for now. Prevents stale notification delivery. |

## Phase 2 Decision

Do not change relaunch notification scheduling yet.

Reason:

- Local notifications are already OS-managed after scheduling.
- Automatic relaunch rescheduling could duplicate or unexpectedly cancel pending requests unless coordinated with ActivityKit state.
- Live Activity / Dynamic Island work needs one shared lifecycle policy for session start, update, end, expiration, and relaunch recovery.

## Added Coverage

- `Phase1StorageAndStoreTests.test_Phase2NotificationLifecycle_ReplacingActiveSessionCancelsOldAndSchedulesNew`

This test pins replacement behavior for any future flow that can start a session while another session is active. The first Quick Start pass is hidden during active sessions, so it does not currently trigger replacement.

## Follow-Up For Live Activity Spike

ActivityKit implementation has started. `ParkingSessionStore` emits privacy-safe lifecycle snapshots through `ParkingActivityLifecycleManaging`; normal app startup uses `ActivityKitParkingActivityLifecycleManager`, while test/unsupported paths can still use the no-op manager.

When Live Activity work begins, define a single lifecycle coordinator or policy for:

1. session started
2. session replaced
3. session manually ended
4. session becomes overdue
5. app relaunched with active session
6. app relaunched with overdue active session

That policy should update/cancel local notifications and Live Activity state together.
