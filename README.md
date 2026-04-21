# PARKING_LOT
# Smart Parking Reminder

## Overview

Smart Parking Reminder is a local-only iOS app built in **Swift** and **SwiftUI** to help users remember where they parked, track parking time, and get reminders before parking expires.

The goal is to first build a reliable **Phase 1 MVP** with a clean parking workflow, then move on to smarter analysis in later phases.

---

## Project Goal

Build a mobile app that helps users:

- start a parking session
- save the parking location
- track the remaining parking time
- receive reminders before and at parking expiry
- end the session manually
- review past parking sessions in both **list** and **map** views

This app is **local-only** for now. There is:

- no backend
- no login
- no cloud sync
- no machine learning yet

---

## Tech Stack

- **Swift**
- **SwiftUI**
- **MVVM architecture**
- **MapKit** for map display
- **Core Location** for current location capture
- **UserNotifications** for local reminders
- local persistence only

---

## Development Strategy

We are using **Codex / ClawDBot as a coding assistant** to help scaffold and build the app incrementally.

The project should be built in small steps rather than one giant prompt.

General rule:

- Phase 1 = core workflow works reliably
- Phase 2 = make it smarter and more useful
- Phase 3 = add ML prediction

---

## Phase 1 Scope

Phase 1 is focused on building a **working MVP**.

### Core features

1. Start a parking session
2. Save:
   - location name
   - optional latitude / longitude
   - start time
   - expected parking duration
   - note
3. Show active parking session on the home screen
4. Show a remaining time countdown
5. Schedule local notifications:
   - 15 minutes before expiry
   - at expiry
6. End a parking session manually
7. Save completed sessions into parking history
8. Show history in:
   - list view
   - map view

---

## Map Support

We decided that map support belongs in **Phase 1**.

### Why

Parking is naturally location-based, so the app should not only store time-related information, but also make it easy to remember and revisit parking spots visually.

### Phase 1 map behavior

- when a user starts a parking session, the app should request the **current location once**
- the app saves the coordinate with the parking session
- the active parking session can be shown on a map
- parking history can be displayed on a map

### Important constraint

We only want a **one-time current location request** when starting a parking session.

We do **not** want continuous background tracking in Phase 1.

---

## History Map Design

We discussed that raw session pins may create a poor user experience if the user parks in the same place multiple times.

### Decision

The history map should **not** show duplicate pins for the same or nearly same spot.

Instead, it should:

- group nearby parking sessions into one map marker
- show one marker per grouped parking spot
- let the user inspect the sessions attached to that spot

This keeps the map clean and readable.

### Phase 1 rule

Use a **simple grouping rule** for nearby coordinates.

### Deferred to Phase 2

Do not add advanced map intelligence yet, such as:

- clustering
- heatmaps
- complex filtering
- favorite spot ranking
- advanced GPS drift correction

---

## Navigation to a Saved Parking Spot

We discussed whether navigation should be part of Phase 1.

### Decision

Basic navigation handoff belongs in **Phase 1**.

### What this means

The app does **not** build navigation itself.

Instead, from a saved parking spot, the user should be able to:

- open the destination in **Apple Maps**
- optionally open it in **Google Maps**

This is a handoff flow only.

---

## Correct Marker Interaction Flow

We refined the marker interaction design after noticing that direct navigation from the pin was not the right UX.

### Final interaction flow

When the user taps a history marker:

1. select the marker
2. show a **detail sheet / bottom sheet**
3. display parking spot details
4. allow the user to choose navigation from there

### Important UX rule

- **tap pin = show details**
- **tap button in detail sheet = navigate**

Navigation should **not** happen immediately when tapping the map pin.

---

## Detail Sheet Requirements

When a grouped parking spot is selected, the detail sheet should show:

- parking spot name
- latitude / longitude
- recent parking sessions at this spot
- note/comments from those sessions
- status summary
- count of total sessions at this spot

### Actions inside the detail sheet

- Open in Apple Maps
- Open in Google Maps

This sheet is the main interaction point for history markers.

---

## Proposed Main Screens

### 1. Home Screen
- active parking session
- remaining time countdown
- start parking button
- end parking button
- optional small map preview

### 2. New Session Screen
- location name input
- duration picker
- optional note
- optional current location capture
- save/start button

### 3. History Screen
- list view
- map view with grouped parking markers

### 4. Parking Spot Detail Sheet
- grouped spot information
- recent sessions
- note history
- navigation actions

---

## Data Model Direction

### ParkingSession
Represents one actual parking event.

Suggested fields:

- id
- locationName
- latitude
- longitude
- startTime
- expectedEndTime
- actualEndTime
- note
- status

### ParkingSpotGroup
Represents one grouped location on the history map.

Used to:

- avoid duplicate pins
- group repeated parking events at the same place
- show a cleaner history map

---

## When to Move to Phase 2

We agreed that we should only move to Phase 2 when Phase 1 is **boringly reliable**.

### Phase 1 completion checklist

We should not move on until the app can reliably do all of the following:

1. User starts a parking session
2. App gets current location and saves it
3. Countdown shows correctly
4. Reminder fires correctly
5. User can end the session
6. Session appears in history
7. App restart does not lose the active session

### Additional readiness signs

- core flow works multiple times in a row
- no major crash or blocking bug
- notifications behave as expected
- map pins display correctly
- active session state stays in sync
- some real sample parking history exists

### Why not move early

Phase 2 depends on stable data and a reliable workflow.

If Phase 1 is unstable, any “smart” feature added on top will be weak and misleading.

---

## Planned Future Phases

### Phase 2
Make the app smarter and more useful.

Possible ideas:
- parking pattern summaries
- frequent parking spot insights
- smarter history visualization
- risk scoring
- personalized reminder suggestions

### Phase 3
Add machine learning.

Possible direction:
- predict whether the user is likely to forget the car at a certain time/place
- use historical parking patterns to classify risk level

---

## Non-Goals for Phase 1

Do **not** add these yet:

- backend APIs
- user accounts
- cloud sync
- analytics
- machine learning
- continuous background location tracking
- advanced clustering or heatmaps
- in-app turn-by-turn navigation

---

## Build Philosophy

This project should stay focused.

Phase 1 should solve one simple problem well:

> Help the user remember where they parked and remind them before parking expires.

Everything else should support that goal, not distract from it.
