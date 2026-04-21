# SmartParkingReminder (Phase 1)

Local-only MVP to record a parking session, show a countdown, and schedule reminders.

## Features
- Start a parking session (location name, duration, optional note, optional lat/lon)
- Home screen shows active session + remaining time countdown
- Local notifications:
  - 15 minutes before expiry
  - at expiry
- End session manually
- History list with status: Active / Overdue / Completed
- Restores sessions (including active) from disk on app launch

## Tech
- Swift
- SwiftUI
- MVVM-ish separation with a single source of truth `ParkingSessionStore`
- Local JSON storage (Documents directory)
- Local notifications (UNUserNotificationCenter)
- Optional one-shot location capture (CoreLocation)

## Setup
1. Run XcodeGen to generate the Xcode project:

```bash
cd "/Users/bolinqu/Library/Mobile Documents/com~apple~CloudDocs/MacMini/小六/01-Projects/Parking alarm/SmartParkingReminder"
xcodegen generate
```

2. Open `SmartParkingReminder.xcodeproj` in Xcode.
3. Select an iPhone simulator or a real device.
4. Build & Run.

## Permissions
- Notifications are requested when starting a session (scheduling notifications).
- Location permission is requested when tapping “Use Current Location”.

## Quick test
1. Home → **Start Parking**
2. Enter a location name
3. Pick a duration
4. Tap **Start**
5. Verify countdown on Home
6. Tap **End Parking**
7. History tab shows Completed

## Testing notifications quickly
- Start a session with **16 minutes** duration.
- You should get the “15 minutes remaining” notification about 1 minute later.
