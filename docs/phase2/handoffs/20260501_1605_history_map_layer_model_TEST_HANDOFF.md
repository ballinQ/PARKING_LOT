# Test Handoff: History Map Layer Marker Model

Date: 2026-05-01
Phase: Phase 2
Development thread owner: Codex
Test owner: Test/QA thread / Clawdbot

## Development Summary

Introduced a small map marker layer model so the Map screen no longer renders personal-history markers directly from raw `ParkingSpotGroup` data. Current behavior remains personal-history-only, but marker source/layer identity is now explicit for future public/Green P layers.

## Goal

Prepare the map architecture for future distinct marker layers without changing Phase 1 behavior or adding public parking data.

## Files Changed

- `SmartParkingReminder/SmartParkingReminder/Services/Maps/HistoryMapMarkerItem.swift` - new marker item and layer-kind model.
- `SmartParkingReminder/SmartParkingReminder/ViewModels/HistoryMapViewModel.swift` - exposes personal-history markers and search-area marker as marker items.
- `SmartParkingReminder/SmartParkingReminder/Views/Map/HistoryMapView.swift` - renders marker items instead of deriving marker titles directly from groups.
- `SmartParkingReminder/SmartParkingReminder.xcodeproj/project.pbxproj` - regenerated with XcodeGen so the new Swift file is included.
- `README.md` - development log and compile verification.
- `docs/phase2/PHASE2_ROADMAP.md` - records map-layer preparation.
- `docs/phase2/PHASE2_ARCHITECTURE_REVIEW.md` - updates map-layer architecture notes.

## Functions / Types Changed

- `HistoryMapLayerKind` - new enum with `personalHistory` and `searchArea`.
- `HistoryMapMarkerItem` - new marker presentation model with id, title, coordinate, layer, and optional source ID.
- `HistoryMapMarkerItem.personalHistory(_:)` - creates a personal-history marker from a `ParkingSpotGroup`.
- `HistoryMapMarkerItem.searchArea(coordinate:)` - creates a search-area marker.
- `HistoryMapViewModel.personalHistoryMarkers` - exposes visible personal-history markers.
- `HistoryMapViewModel.searchAreaMarker` - exposes the current search-area marker.
- `HistoryMapView.mapContent` - renders `HistoryMapMarkerItem` values.

## New Logic Introduced

- Personal history marker title formatting moved out of the SwiftUI view and into `HistoryMapMarkerItem.personalHistory(_:)`.
- Personal history markers now carry explicit `layer: .personalHistory`.
- Search-area marker now carries explicit `layer: .searchArea`.
- Personal marker selection still uses the source group ID, preserving existing detail-sheet selection behavior.

## Expected Behavior Summary

- Map personal-history markers look and behave the same as before.
- Tapping a personal-history marker still opens the same saved spot detail workflow.
- Searching an address still shows the same blue search-area marker.
- No public, Green P, provider, backend, cloud, analytics, ML, or community layer is introduced.

## Behavior Intentionally Not Changed

- Phase 1 core loop remains unchanged.
- App remains local-only.
- History remains map-only.
- Old History list is not restored.
- Search, filtering, bottom sheet, and detail sheet behavior should remain unchanged.

## Known Risks

- This is mostly architecture preparation; visual regressions would likely come from marker selection/tag behavior.
- Future public parking layers still need a separate model and visual distinction before implementation.

## Known Limitations

- Only `personalHistory` and `searchArea` layer kinds exist right now.
- There is no production public parking layer.
- No Green P data is loaded or displayed.

## Notes For Test/QA

- Treat this as no intended user-visible behavior change.
- When creating verification coverage, focus on marker selection behavior, search-area marker display, and ensuring the old History list does not return.
- Confirm personal history and search markers remain visually distinct.
- Future Green P/public parking tests should wait until a real public marker model or prototype is implemented.
