# Phase 1 Self-Test (Execution Checklist)

This checklist is a **manual QA self-test** for all Phase 1 scope items in `README.md`.

## How to use this file

- Run each test case in order (TC-01 → TC-14).
- Mark each case as ✅ Pass / ❌ Fail / ⚠️ Blocked.
- Attach evidence for fails (screenshot, log, or short repro note).
- A build is **Phase 1-ready** only when all P0/P1 tests pass.

---

## 1) Scope Traceability Matrix

| Feature ID | Phase 1 requirement | Priority | Test cases |
|---|---|---|---|
| F1 | Start parking session | P0 | TC-01 |
| F2 | Save location name + duration + start time + optional note + optional lat/lon | P0 | TC-01, TC-02, TC-03 |
| F3 | Show active session on Home | P0 | TC-01 |
| F4 | Remaining time countdown works | P0 | TC-04 |
| F5 | Notifications at T-15 and at expiry | P0 | TC-05, TC-06 |
| F6 | End session manually | P0 | TC-07 |
| F7 | Completed sessions saved to history | P0 | TC-07, TC-08 |
| F8 | History list + history map views | P0 | TC-08, TC-09 |
| F9 | One-shot location capture (no continuous tracking) | P1 | TC-02, TC-03 |
| F10 | Nearby sessions grouped into one map marker | P1 | TC-10 |
| F11 | Tap marker opens detail sheet (no auto-navigation) | P1 | TC-11 |
| F12 | Detail sheet shows required grouped-spot details | P1 | TC-12 |
| F13 | Navigation handoff via Apple Maps / Google Maps | P1 | TC-13 |
| F14 | Sessions restored after app relaunch | P0 | TC-14 |

---

## 2) Standard Test Setup

Use this setup unless a case says otherwise:

1. Build and run latest app build.
2. Device time set automatically.
3. App data reset (fresh install) for first full pass.
4. Notification permission = Allowed (except denied-flow checks).
5. Location permission = While Using (except denied-flow checks).

**Recommended devices**
- iOS Simulator for fast iteration.
- Real iPhone for reliable notification/location behavior.

---

## 3) Detailed Test Cases

### TC-01 (P0) Start session from New Session screen
- [ ] **Steps**
  1. Home → Start Parking.
  2. Set location name: `Lot A`.
  3. Set duration: `30 min`.
  4. Leave note empty.
  5. Tap Start.
- [ ] **Expected**
  - Active session appears on Home.
  - Location name is `Lot A`.
  - Countdown starts immediately.

### TC-02 (P1) Start with one-time current location capture
- [ ] **Steps**
  1. Start new session.
  2. Enter location `GPS Spot`.
  3. Tap Use Current Location and grant permission.
  4. Tap Start.
- [ ] **Expected**
  - Session starts successfully.
  - Coordinates are saved for this session.
  - No ongoing background tracking behavior is visible after capture.

### TC-03 (P1) Location denied flow
- [ ] **Steps**
  1. iOS Settings → App → Location = Denied.
  2. Start new session and tap Use Current Location.
  3. Complete session start.
- [ ] **Expected**
  - App does not crash.
  - Session can still start without coordinates.
  - User gets clear denied/unavailable feedback.

### TC-04 (P0) Countdown and overdue transition
- [ ] **Steps**
  1. Start session with 2–3 minute duration.
  2. Observe countdown until expiry.
- [ ] **Expected**
  - Countdown decrements over time.
  - UI transitions correctly at/after expiry.

### TC-05 (P0) T-15 notification
- [ ] **Steps**
  1. Notifications allowed.
  2. Start session with 16-minute duration.
  3. Wait about 1 minute.
- [ ] **Expected**
  - “15 minutes remaining” local notification is delivered.

### TC-06 (P0) Expiry notification
- [ ] **Steps**
  1. Notifications allowed.
  2. Start session with short duration (e.g., 2 minutes).
  3. Wait for expected end time.
- [ ] **Expected**
  - Expiry local notification is delivered at expiry.

### TC-07 (P0) End parking manually
- [ ] **Steps**
  1. Ensure an active session exists.
  2. Tap End Parking.
- [ ] **Expected**
  - Active session is removed from Home.
  - Session is finalized and moved to history.

### TC-08 (P0) History list integrity
- [ ] **Steps**
  1. Create at least three sessions (including one with note).
  2. Open History list.
- [ ] **Expected**
  - All sessions visible.
  - Statuses and session fields are correct.

### TC-09 (P0) History map rendering
- [ ] **Steps**
  1. Ensure at least two sessions have coordinates.
  2. Open History map view.
- [ ] **Expected**
  - Map loads.
  - Markers render for saved spots/groups.

### TC-10 (P1) Group nearby sessions into one marker
- [ ] **Steps**
  1. Create multiple sessions at same/nearby coordinates.
  2. Open History map.
- [ ] **Expected**
  - Nearby sessions appear as one grouped marker.

### TC-11 (P1) Marker interaction flow
- [ ] **Steps**
  1. Tap a history marker.
- [ ] **Expected**
  - Detail sheet opens.
  - App does not auto-launch navigation on marker tap.

### TC-12 (P1) Detail sheet content
- [ ] **Steps**
  1. Open detail sheet from a grouped marker.
- [ ] **Expected**
  - Shows spot name.
  - Shows coordinates.
  - Shows recent sessions.
  - Shows notes/status summary.
  - Shows total grouped-session count.

### TC-13 (P1) Navigation handoff actions
- [ ] **Steps**
  1. In detail sheet, tap Open in Apple Maps.
  2. Tap Open in Google Maps.
- [ ] **Expected**
  - Apple Maps handoff succeeds.
  - Google Maps handoff succeeds when available; if unavailable, app fails gracefully.

### TC-14 (P0) Persistence after relaunch
- [ ] **Steps**
  1. Create one active + one completed session.
  2. Force-close app.
  3. Reopen app.
- [ ] **Expected**
  - Active session is restored on Home.
  - Completed session remains in history.

---

## 4) Fast Regression Smoke Run

Run before every release candidate:

- [ ] TC-01 Start session
- [ ] TC-04 Countdown
- [ ] TC-05 T-15 notification
- [ ] TC-07 End parking
- [ ] TC-08 History list
- [ ] TC-11 Marker → detail sheet
- [ ] TC-13 Navigation handoff
- [ ] TC-14 Relaunch restore

---

## 5) Execution Report Template

| Build | Device/OS | Tester | Date |
|---|---|---|---|
|  |  |  |  |

| Test Case | Result (✅/❌/⚠️) | Evidence / Notes |
|---|---|---|
| TC-01 |  |  |
| TC-02 |  |  |
| TC-03 |  |  |
| TC-04 |  |  |
| TC-05 |  |  |
| TC-06 |  |  |
| TC-07 |  |  |
| TC-08 |  |  |
| TC-09 |  |  |
| TC-10 |  |  |
| TC-11 |  |  |
| TC-12 |  |  |
| TC-13 |  |  |
| TC-14 |  |  |

**Release recommendation:**
- [ ] ✅ Ready for Phase 1 sign-off
- [ ] ❌ Not ready (blocking failures present)
