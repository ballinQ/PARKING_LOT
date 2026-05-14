# Test Handoff: History Map Filtering Service Extraction

Date: 2026-05-01
Phase: Phase 2
Development thread owner: Codex
Test owner: Test thread / Clawdbot

## Summary

Extracted pure saved-history filtering rules from `HistoryMapViewModel` into `HistoryMapFilteringService`. This is architecture preparation for future map layers while preserving current map-first behavior.

## Files Changed

- `SmartParkingReminder/SmartParkingReminder/Services/Maps/HistoryMapFilteringService.swift` - new service for local text, metadata, and nearby-distance filtering.
- `SmartParkingReminder/SmartParkingReminder/ViewModels/HistoryMapViewModel.swift` - delegates pure filtering to `HistoryMapFilteringService`; keeps selection, status text, address search, and sheet state ownership.
- `SmartParkingReminder/SmartParkingReminderTests/Phase1ModelAndLogicTests.swift` - adds direct service coverage for metadata text search and nearby metadata-filter composition.
- `SmartParkingReminder/SmartParkingReminder.xcodeproj/project.pbxproj` - regenerated with XcodeGen so the new service is included.
- `README.md` - records the feature and verification.
- `docs/phase2/PHASE2_ROADMAP.md` - records the service-extraction progress.
- `docs/phase2/PHASE2_ARCHITECTURE_REVIEW.md` - updates map-layer readiness notes.
- `docs/phase2/PHASE2_SELF_TEST.md` - adds test coverage and expected behavior.

## Functions / Types Changed

- `HistoryMapFilteringService.filterMetadata(groups:metadataFilter:)` - filters saved spot groups by personal metadata filter.
- `HistoryMapFilteringService.filterLocalHistory(groups:query:metadataFilter:)` - filters by saved spot/session text plus metadata note/tag/rating/favorite match.
- `HistoryMapFilteringService.filterNearby(groups:center:radiusMeters:metadataFilter:)` - filters by distance and composes metadata filtering.
- `HistoryMapViewModel.applyLocalHistoryFilter(query:)` - now delegates pure filtering to the service.
- `HistoryMapViewModel.applySearchFilter(searchName:)` - now delegates distance and metadata filtering to the service.
- `HistoryMapViewModel.clearSearch()` and `searchAddressResults()` empty/error paths - now use the same metadata-filter service path.

## New Behavior

- No intended user-visible behavior change.
- The same Map search/filter results are now produced through a testable service.
- Local text, metadata chips, and address-radius filters share one filtering implementation.

## Expected Behavior

- History remains map-only.
- Searching saved spot/session text still narrows visible personal history markers.
- Metadata filters still narrow by Favorites, 4+ Stars, and supported tags.
- Address search radius still composes with metadata filters.
- Clearing search still restores saved history according to the active metadata filter.

## Behavior Not Changed

- Phase 1 core loop remains unchanged.
- App remains local-only.
- History remains map-only.
- No backend, login, cloud sync, analytics, ML, public parking layer, Green P layer, or continuous background location added.
- Selected marker detail behavior is unchanged.

## Automated Tests Added / Updated

- `Phase1ModelAndLogicTests.test_Phase2HistoryMapFilteringService_LocalQueryIncludesMetadataFields` - verifies pure local filtering can match spot metadata and compose with metadata tag filters.
- `Phase1ModelAndLogicTests.test_Phase2HistoryMapFilteringService_NearbyFilterComposesWithMetadataFilter` - verifies distance filtering composes with metadata filters.
- Existing tests retained:
  - `Phase1ModelAndLogicTests.test_Phase2HistoryMapSearch_LocalQueryFiltersSavedSpotNamesAndNotes`
  - `Phase1ModelAndLogicTests.test_Phase2PersonalSpotMetadataFilter_ComposesWithAddressRadius`

## Focused Verification Already Run

- Command: `xcodebuild test -project SmartParkingReminder/SmartParkingReminder.xcodeproj -scheme SmartParkingReminder -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SmartParkingReminderTests/Phase1ModelAndLogicTests/test_Phase2HistoryMapFilteringService_LocalQueryIncludesMetadataFields -only-testing:SmartParkingReminderTests/Phase1ModelAndLogicTests/test_Phase2HistoryMapFilteringService_NearbyFilterComposesWithMetadataFilter -only-testing:SmartParkingReminderTests/Phase1ModelAndLogicTests/test_Phase2PersonalSpotMetadataFilter_ComposesWithAddressRadius -only-testing:SmartParkingReminderTests/Phase1ModelAndLogicTests/test_Phase2HistoryMapSearch_LocalQueryFiltersSavedSpotNamesAndNotes -derivedDataPath /tmp/SmartParkingReminderHistoryFilterServiceTests`
- Result: `** TEST SUCCEEDED **`
- Tests: 4 passed, 0 failed.

## Broader Verification Already Run

- Command: `xcodebuild test -project SmartParkingReminder/SmartParkingReminder.xcodeproj -scheme SmartParkingReminder -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SmartParkingReminderTests -derivedDataPath /tmp/SmartParkingReminderHistoryFilterServiceUnitTests`
- Result: `** TEST SUCCEEDED **`
- Tests: 42 passed, 0 failed.

## Recommended Test Thread Checks

- Run full Phase 2 unit tests.
- Manually verify Map search still filters saved spot names/notes.
- Manually verify metadata filter chips still narrow visible markers.
- Manually verify address search plus radius plus metadata filter still shows the expected nearby saved spots.
- Confirm the old History list screen does not return.

## Risks / Notes

- This is an architecture slice, so visual behavior should remain unchanged.
- `HistoryMapViewModel` still owns status text, selected marker state, sheet state, and address search orchestration.
- Future map-layer work should continue separating provider/public layers from personal saved history before adding any production Green P layer.

## Report Instructions

- Save test logs and reports under `Self_report/phase2/runs/<timestamp>_phase2_report/`.
- Include Markdown conclusion, Excel overview, raw JSON data, xcodebuild log, xcresult bundle, and manual evidence when applicable.
