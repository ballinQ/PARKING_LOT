# Test Handoff: Dormant Public Parking Data Models

Date: 2026-05-02
Phase: Phase 2
Development thread owner: Codex
Test owner: Test/QA thread / Clawdbot

## Development Summary

Added dormant model types for future public parking and Toronto Green P work. These models are architecture-only and are not connected to Map UI, storage, networking, search, or any production Green P data source.

## Goal

Prepare a clean data shape for future public parking research while preventing accidental real-time availability claims.

## Files Changed

- `SmartParkingReminder/SmartParkingReminder/Models/PublicParkingLot.swift` - new dormant model definitions for public parking sources, lots, rates, availability, and Green P-specific wrapper data.
- `SmartParkingReminder/SmartParkingReminder.xcodeproj/project.pbxproj` - regenerated with XcodeGen so the new model file is included.
- `README.md` - development log and compile verification.
- `docs/phase2/PHASE2_ROADMAP.md` - records dormant public parking model preparation.
- `docs/phase2/PHASE2_ARCHITECTURE_REVIEW.md` - records public parking model boundaries and risks.

## Functions / Types Changed

- `ParkingSourceKind` - categorizes source type such as Green P, Toronto Open Data, Toronto Parking Authority, MapKit, static prototype, or unknown.
- `ParkingSource` - records source identity, organization, URL, license/update metadata, official-source flag, and whether real-time availability is supported.
- `PublicParkingFacilityType` - categorizes lot shape such as surface lot, garage, underground garage, street, mixed, or unknown.
- `PublicParkingAvailabilityKind` - distinguishes unavailable/static/historical/official real-time availability.
- `PublicParkingAvailabilityInfo` - stores availability wording and source update timestamp.
- `PublicParkingRateInfo` - stores rate descriptions including hourly, day max, night max, weekend, and max-time fields.
- `PublicParkingLot` - general public parking lot shape with source, ID, address, coordinate, facility, capacity, rates, EV charging, height restriction, and source metadata.
- `PublicParkingLot.canClaimRealTimeAvailability` - returns true only if source and availability both explicitly indicate official real-time availability.
- `GreenPParkingLot` - Green P wrapper around `PublicParkingLot`, with car park number and Green P facility type description.

## New Logic Introduced

- Public parking availability defaults to not provided.
- Green P research placeholder explicitly has `isOfficial: false` and `supportsRealTimeAvailability: false`.
- Real-time availability can only be claimed when both the source supports real time and the lot availability kind is `realTimeOfficial`.

## Expected Behavior Summary

- No user-visible behavior change.
- No Green P lots appear on the Map.
- No public parking layer appears.
- No static data is bundled or loaded.
- No network calls, backend, cloud sync, analytics, ML, payment, or live availability feature is added.

## Behavior Intentionally Not Changed

- Phase 1 core loop remains unchanged.
- App remains local-only.
- History remains map-only.
- Personal History markers remain the only saved parking markers.
- The old History list is not restored.

## Known Risks

- These are dormant models, so their field names may need adjustment after official Toronto/Green P source research.
- Rate fields are strings/descriptions for now to avoid premature assumptions about source formats and currency rules.
- The Green P placeholder is not official data and must not be displayed as production content.

## Known Limitations

- No provider ingestion pipeline exists.
- No map rendering exists for public lots.
- No detail sheet exists for public lots.
- No official source URL/license/update date has been verified in this implementation slice.
- No real-time availability source has been verified.

## Notes For Test/QA

- Treat this as compile/build-only architecture preparation.
- Do not create user-facing Green P validation cases yet.
- Future Green P/public parking test cases should wait until a handoff explicitly introduces a disabled/static prototype or production data layer.
- If Test/QA reviews this slice, focus on confirming no public parking UI became visible and no real-time availability claim was introduced.
