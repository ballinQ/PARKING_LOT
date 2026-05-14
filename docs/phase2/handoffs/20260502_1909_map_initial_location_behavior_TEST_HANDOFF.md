# Test Handoff: Map Initial Location Behavior

Date: 2026-05-02
Phase: Phase 2
Development thread owner: Codex
Test owner: Test/QA thread / Clawdbot

## Development Summary

Improved the Map tab's real-device startup behavior. The Map now opens as an actual map even when there is no saved history, shows the user location dot, starts with a user-location camera using Toronto fallback, and waits for When In Use permission before requesting the one-shot coordinate.

## Goal

Make the Map tab feel closer to Apple Maps while keeping History map-only and preserving the local-only Phase 1/Phase 2 scope.

## Files Changed

- `SmartParkingReminder/SmartParkingReminder/Services/Location/LocationService.swift` - one-shot location capture now waits for authorization before requesting location.
- `SmartParkingReminder/SmartParkingReminder/ViewModels/HistoryMapViewModel.swift` - added Toronto fallback coordinate/camera helpers and default map span.
- `SmartParkingReminder/SmartParkingReminder/Views/Map/HistoryMapView.swift` - always renders the SwiftUI Map, adds `UserAnnotation()`, initializes to user-location camera, and falls back to Toronto when location is unavailable.
- `README.md` - development log and verification notes updated.
- `docs/phase2/PHASE2_ROADMAP.md` - Map search/filtering notes updated.

## Functions / Types Changed

- `LocationService.captureCurrentLocation(completion:)` - now returns after requesting permission when authorization is not determined.
- `LocationService.locationManagerDidChangeAuthorization(_:)` - now continues or fails a pending one-shot request after permission changes.
- `LocationService.requestOneShotLocation()` - new helper for one-shot `requestLocation()`.
- `HistoryMapViewModel.torontoFallbackCoordinate` - Toronto fallback coordinate.
- `HistoryMapViewModel.defaultMapSpan` - default map zoom/range.
- `HistoryMapViewModel.torontoFallbackCameraPosition()` - fallback map camera.
- `HistoryMapViewModel.userLocationCameraPosition()` - user-location camera with heading and Toronto fallback.
- `HistoryMapView.requestInitialLocationFocusIfNeeded()` - initial Map-tab location behavior.
- `HistoryMapView.mapContent` - now always renders `Map` with `UserAnnotation()`.

## New Logic Introduced

- Opening the Map tab sets the camera to `.userLocation(followsHeading: true, fallback: Toronto)`.
- A fresh install permission prompt is triggered through the existing one-shot location service.
- If permission is granted and location succeeds, nearby saved history is filtered around current location.
- If permission is denied or location fails, the map uses Toronto fallback at latitude `43.6532`, longitude `-79.3832`, span `0.03` by `0.03`.
- Recenter also uses user-location camera first, then Toronto fallback if unavailable.

## Expected Behavior Summary

- Fresh install: opening Map can request When In Use permission.
- Granted permission: Map centers on user location and shows the user dot.
- Denied/unavailable permission: Map still opens at Toronto fallback and address search remains available.
- Panning away should not be continuously overridden.
- Recenter returns to current location when available or Toronto fallback when unavailable.

## Behavior Intentionally Not Changed

- Phase 1 core loop remains unchanged.
- History remains map-only.
- The old History list is not restored.
- No backend, login, cloud sync, analytics, ML, community behavior, public parking layer, or continuous background location added.
- No new formal test cases or QA runbook changes were created by the development thread.

## Known Risks

- Real-device heading behavior depends on iOS MapKit and device sensors.
- Fresh-install permission flow needs real-device or simulator manual evidence because permission prompts are system UI.
- The current implementation applies nearby saved-history filtering after location succeeds, which is consistent with the Map assistant workflow but should be visually reviewed.

## Known Limitations

- No custom permission explainer screen was added.
- No continuous follow mode was added.
- No manual visual evidence was captured by this development thread.

## Notes For Test/QA

- This should be validated on a fresh install and on denied-permission state.
- Suggested validation area: grant permission, verify current location centering and user dot, pan away, tap recenter, verify current location returns.
- Also deny permission and verify Toronto fallback plus address search.

