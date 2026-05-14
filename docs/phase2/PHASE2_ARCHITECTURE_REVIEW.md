# Phase 2 Architecture Review

Status: Phase 2 architecture review is active. Phase 2A foundation, the first ActivityKit/widget pass, the first Quick Start pass, and the first personal metadata/filtering slices are implemented.

Related planning document: `PHASE2_ROADMAP.md`

## Phase 2 Architecture Decision

Recommended first implementation sequence:

1. Add persistence schema versioning and migration safety.
2. Extract active-session display/status formatting into pure, testable logic.
3. Audit notification lifecycle behavior for start, end, replacement, and relaunch.
4. Fix Swift 6 isolation/sendability warnings that may block extension or map work.
5. Improve active-session UI states.
6. Add the Live Activity / Dynamic Island app-side readiness seam and first widget/ActivityKit target.
7. Add the first Quick Start pass on the shared session creation path.

Personal spot metadata and advanced map filtering should build on the stable active-session, persistence, and quick-start foundations.

## Review Boundary

Phase 1 remains frozen:

- local-only app
- no backend
- no login
- no cloud sync
- no analytics
- no machine learning
- no continuous background location tracking
- History remains map-only, not list-based

This review evaluates whether the current Phase 1 architecture can support future releases, especially:

- Live Activities / Dynamic Island
- widgets
- quick start
- richer active-session UI
- personal spot metadata
- future cloud sync
- future map layers

## Current Architecture Snapshot

| Area | Current implementation | Phase 1 fit | Phase 2 concern |
|---|---|---|---|
| Session model | `ParkingSession` is a single `Codable` record with id, location name, optional coordinate, times, note, and persisted status | Good simple local record | Will need schema versioning and possibly a separate spot model |
| Session state | `ParkingSessionStore` owns sessions, active session, persistence, notifications, countdown status, and the activity lifecycle seam | Good single source of truth | Still too broad for quick start and future sync; ActivityKit stays behind the lifecycle protocol |
| Persistence | `ParkingSessionStorageService` writes a versioned local envelope and still reads legacy Phase 1 bare arrays; `SavedParkingSpotMetadataStorageService` stores local spot metadata in a separate envelope | Good local MVP | Future metadata/conflict/tombstone fields still need careful migration design |
| Notifications | `ParkingNotificationService` schedules T-15 and expiry local notifications | Good Phase 1 reminder path | Needs final coordination with real ActivityKit behavior and relaunch recovery |
| Location | `LocationService` captures current location once with `requestLocation()` | Correct for privacy scope | Keep one-shot; do not add background location for Phase 2 |
| Home UI | `HomeView` and `ActiveSessionCardView` render store-derived active, due-soon, and overdue display state | Simple and testable | Future Live Activity/widget UI should reuse the same status vocabulary |
| New session UI | `NewSessionView` builds a `.fullForm` `ParkingSessionDraft` and calls `store.startNewSession(from:)` | Works for full flow | Future quick-start polish should keep sharing this creation path |
| Map history | `HistoryMapView` and `HistoryMapViewModel` handle grouping, search orchestration, selection, and status text; address lookup goes through `MapSearchProviding`; pure saved-history filtering goes through `HistoryMapFilteringService`; marker presentation uses `HistoryMapMarkerItem` | Works for map-only Phase 1 | Grouping/layer composition should keep moving into testable services before advanced map layers |
| Grouping | `ParkingSpotGroupingService` greedily groups sessions within 30 m and spot metadata attaches by stable bucket ID | Adequate for personal history | Not enough for garages, public lots, favorites, or external provider layers |
| Map handoff | `MapHandoffService` opens Apple Maps / Google Maps | Works with tests | Swift 6 isolation/sendability warnings have been cleaned; keep this stable before provider integrations |

## Architecture Decision Record

Current decisions to preserve:

- Keep a single active parking session.
- Keep all saved history local in Phase 2.
- Keep History as a map surface.
- Keep location capture one-shot and user initiated.
- Keep local notifications as the baseline reminder mechanism.
- Keep location-derived assistant behavior governed by `PHASE2_PRIVACY_DATA_BOUNDARY.md`.

Decisions needed before implementation:

- Whether ActivityKit/widget state uses an App Group shared container.
- Whether local JSON gets wrapped in a versioned envelope or replaced with a new persistence layer.
- Whether the first metadata slice needs full `SavedSpot` records or can use separate local metadata keyed by grouped spot ID.
- Whether quick start stores explicit reusable presets or derives suggestions from recent sessions.
- Whether map search gets a protocol abstraction around `MKLocalSearch`.

Resolved sequencing decision:

- Phase 2 starts with local persistence/display/lifecycle preparation.
- The first user-visible feature should be improved active-session UI.
- The first platform feature should be Live Activity / Dynamic Island, after the active-session display model exists.
- Quick Start now uses the reusable draft/value object and shared store creation path.
- Personal spot metadata uses a separate local metadata envelope keyed by stable grouped spot ID for the first Phase 2 slice.

## Risk Register

| Risk | Severity | Area | Why it matters | Recommended mitigation |
|---|---:|---|---|---|
| App-only timer drives active countdown | High | Live Activity/widgets | Extensions cannot depend on foreground `Timer` updates | Pure status/display logic and an app-side activity snapshot now exist; real ActivityKit still needs extension-safe state |
| Bare JSON array has no schema version | Mitigated for Phase 2A | Migration/cloud sync | New fields can break old installs or make migration fragile | Versioned storage envelope added; keep migration tests with every data-model expansion |
| `ParkingSessionStore` has broad responsibilities | Medium | Growth | Store mixes state, persistence, notification side effects, formatting, creation, and timer | Introduce small services/view models around creation, display formatting, and lifecycle |
| `ParkingSession` doubles as spot identity | Partially mitigated | Personal spots/map layers | Ratings/tags/favorites need stable spot metadata beyond a single session | First local metadata slice is separate from sessions; still consider full `SavedSpot` model before sync/community phases |
| Direct `MKLocalSearch` in view model | Medium | Testing/search | Search/filter tests can be flaky or hard to isolate | Introduce `MapSearchProviding` protocol before richer search |
| Greedy 30 m grouping | Medium | Map layers | External parking lots/floors/entrances may need richer identity | Keep for Phase 2 personal history; do not use for public/provider data |
| Silent persistence errors | Medium | Reliability/sync | User will not know if a save fails | Add nonintrusive error state before larger local data model |
| Notification and future Live Activity lifecycle can drift | Medium | Reminders | End/restart/relaunch behavior must cancel/update everything consistently | Centralize session lifecycle side effects |
| `MapHandoffService` warnings | Mitigated | Swift 6 readiness | Prior warnings could have become errors under stricter settings | Keep the main-actor/sendable launcher abstraction intact |

## Privacy And Data Boundary

Current status:

- `PHASE2_PRIVACY_DATA_BOUNDARY.md` now defines how Phase 2 treats local parking sessions, one-shot location, saved spot metadata, Quick Start suggestions, Live Activity payloads, map search state, and future public parking source metadata.
- The rule remains local-only for all personal parking history and location-derived behavior.
- Future features that store search history, frequent-place summaries, favorite spots as first-class models, App Group shared widget state, or provider/public parking caches require a design review before implementation.

Do not do yet:

- Do not add backend, cloud sync, analytics, ML, continuous background location, or community sharing.
- Do not persist location-derived summaries unless the field is documented and still local-only.
- Do not claim real-time public parking availability unless an official source supports it.

## Live Activities / Widgets Readiness

Current status:

- ActivityKit/widget target exists.
- Shared ActivityKit attributes exist.
- Store-owned timer remains foreground-only, but ActivityKit state is updated through throttled lifecycle events.
- Persistence path is app Documents, not shared with extensions.
- `PHASE2_WIDGET_SHARED_STATE_DECISION.md` records that the current Phase 2 Live Activity does not need an App Group shared container. ActivityKit content state is the extension boundary for now.
- The ActivityKit-backed manager exists and uses local activities with `pushType: nil`.

Minimum safe preparation:

1. Extract a pure `ParkingSessionDisplayFormatter`. Done.
2. Define a privacy-safe app-side activity snapshot. Done.
3. Add a widget extension and ActivityKit-backed manager. Done.
4. Persist active session fields needed by extensions, if future widget features need shared storage:
   - id
   - location name
   - expected end time
   - status source fields
5. Decide whether an App Group container is needed. Done for the current Live Activity: not needed yet.
6. Define lifecycle events:
   - session started
   - session extended, if Phase 2 adds extension
   - session ended
   - session becomes overdue
   - session restored after relaunch
7. Keep local notifications active even when Live Activity is present.

Implementation priority:

- The formatter, lifecycle audit, app-side seam, widget extension, and ActivityKit manager are now in place.
- Next ActivityKit work should be manual Lock Screen / Dynamic Island verification and stale-state tuning.

Do not do yet:

- Do not add background location.
- Do not add server push.
- Do not add account sync for Live Activity.
- Do not add App Group shared storage unless a future widget feature needs extension-readable persisted state.

## Quick Start Readiness

Current status:

- `ParkingSessionDraft` exists with `fullForm` and `quickStart` sources.
- `NewSessionView` and Home Quick Start both call `ParkingSessionStore.startNewSession(from:)`.
- Home Quick Start is hidden while a session is active, so the current one-tap path does not replace an active session.
- Home Quick Start can now add a local recent-duration option derived from completed session history without creating a separate preset store.
- First presets are 30 min, 1 hr, and 2 hr.

Minimum safe preparation:

1. Add a `ParkingSessionDraft` design before code:
   - location name
   - duration
   - note
   - coordinate
   - source
2. Make full start and quick start use the same validation rules. Done.
3. Decide UX for any future active-session replacement:
   - confirm before replacing
   - disallow quick start while active
   - auto-end current session only after explicit user confirmation

Remaining risks:

- Quick Start currently derives its suggested location and first recent-duration option from local history. Future smarter suggestions should stay local-only unless Phase 3 changes the privacy model.
- If Quick Start later appears while active, it must not silently replace the active session.

Do not do yet:

- Do not add "smart" ML suggestions.
- Do not infer user intent from continuous location.
- Do not add remote presets or account-based favorites.

## Active Session UI Readiness

Current status:

- `ActiveSessionCardView` distinguishes `Remaining`, `Due Soon`, and `Overdue` states.
- Countdown status is calculated in `ParkingSessionStore` and formatted through `ParkingSessionDisplayFormatter`.
- Focused unit and UI tests cover the due-soon and overdue behavior.

Minimum safe preparation:

1. Define display states:
   - active
   - due soon
   - overdue
   - completed
2. Keep `ParkingSessionStore.timerDisplay(for:)` as the active-session source of truth.
3. Keep a display model:
   - title
   - subtitle
   - remaining text
   - expected end text
   - severity
4. Add tests for state boundaries before changing UI.

Implementation priority:

- This is the first user-visible Phase 2 feature after foundation work.
- It should remain local-only and should not depend on Live Activity being available.

Do not do yet:

- Do not redesign Home around Phase 3/4 data.
- Do not add analytics to measure engagement.

## Personal Spot Metadata Readiness

Current blockers:

- First-pass metadata exists, but no full `SavedSpot`/`ParkingSpot` model exists yet.
- Group identity is coordinate-bucket-derived, not an editable user concept.
- Notes now exist at both session level and first-pass spot metadata level.
- Metadata filters are still view-model owned; a future saved-spot search/filter service would make richer layer composition cleaner.

Minimum safe preparation:

1. Keep the first-pass metadata envelope local-only:
   - favorite
   - rating
   - tags
   - spot-level note
2. Introduce a future model design before sync/community:
   - `SavedSpot`
   - `ParkingSession.spotID`
3. Decide whether to backfill spots from completed sessions during migration.
4. Keep spot metadata personal and local.
5. Keep map-only detail as the main surface.
6. Keep metadata filters local and composable with address/radius filtering.

Do not do yet:

- Do not create public spots.
- Do not share ratings/tags.
- Do not add community visibility flags.

## History Map / Future Map Layers Readiness

Current blockers:

- `HistoryMapViewModel` still owns selection, status text, sheet state, and search orchestration, but direct address lookup has been extracted behind `MapSearchProviding` and pure saved-history filtering has been extracted into `HistoryMapFilteringService`.
- `HistoryMapMarkerItem` now gives personal-history and search-area markers explicit layer/source identity.
- Dormant `ParkingSource`, `PublicParkingLot`, and `GreenPParkingLot` models now exist for future public parking research.
- Search radius is now user-selectable for 500 m, 1 km, and 2 km.
- Metadata filters now narrow visible saved spots by favorites, rating, and tags.
- Search provider is injected through `MapSearchProviding`, with `MapKitSearchProvider` as the production adapter.
- Saved personal markers and search marker are the only layer concepts.
- There is still no production public/provider marker model.
- There is still no provider ingestion pipeline, public marker rendering, or public lot detail sheet.

Minimum safe preparation:

1. Split map logic into testable parts:
   - grouping
   - address search/geocoding
   - local saved-spot filtering
   - layer composition
   - provider/public marker adapters
2. Preserve map-only History.
3. Add unit tests for:
   - empty map state
   - radius filtering
   - metadata filter composition
   - grouped vs separate spot behavior
   - search clear behavior
4. Keep public/provider data in research docs until Phase 4.

Do not do yet:

- Do not bring back a list.
- Do not add public parking layer in production.
- Do not mix provider parking with personal history without a layer model.
- Do not display Green P/public parking lots until source reliability, licensing, and update semantics are verified.

## Future Cloud Sync Readiness

Cloud sync is not a Phase 2 goal, but Phase 2 should avoid making it harder.

Current blockers:

- No schema version.
- No created/updated timestamps.
- No tombstones.
- No remote identity.
- No conflict rules.
- No user/account concept by design.

Minimum safe preparation:

1. Add local schema versioning before adding more fields.
2. Add local `createdAt` and `updatedAt` only if migration is planned and tested.
3. Keep future sync metadata hidden and optional.
4. Avoid storing derived-only values that will conflict later.

Do not do yet:

- Do not add CloudKit.
- Do not add login.
- Do not add sync status UI.
- Do not add remote IDs unless needed by a local migration design.

## Suggested Data Model Direction

Phase 2 should consider this shape, but should not expose fields until a feature needs them.

```swift
struct ParkingSession {
    let id: UUID
    var spotID: UUID?
    var locationName: String
    var latitude: Double?
    var longitude: Double?
    var startTime: Date
    var expectedEndTime: Date
    var actualEndTime: Date?
    var note: String
    var persistedStatus: PersistedStatus
    var createdAt: Date
    var updatedAt: Date
    var source: SessionSource
    var schemaVersion: Int
}

struct SavedSpot {
    let id: UUID
    var displayName: String
    var latitude: Double
    var longitude: Double
    var note: String
    var tags: [String]
    var rating: Int?
    var isFavorite: Bool
    var firstUsedAt: Date
    var lastUsedAt: Date
    var visitCount: Int
    var createdAt: Date
    var updatedAt: Date
}

struct PublicParkingLot {
    let id: String
    var source: ParkingSource
    var sourceLotID: String?
    var name: String
    var address: String
    var latitude: Double
    var longitude: Double
    var facilityType: PublicParkingFacilityType
    var capacity: Int?
    var rateInfo: PublicParkingRateInfo
    var availabilityInfo: PublicParkingAvailabilityInfo
    var hasEVCharging: Bool?
    var heightRestrictionDescription: String?
    var sourceURL: URL?
    var sourceLastUpdated: Date?
}
```

Migration warning:

- Do not add non-optional `Codable` fields to `ParkingSession` without a migration plan. Existing local JSON will not contain those keys.

## Recommended Preparation Sequence

1. Finish Phase 1 manual evidence and tag the baseline.
2. Add persistence versioning with tests.
3. Extract pure display/status formatting.
4. Audit notification lifecycle and relaunch behavior.
5. Fix Swift 6 warnings in `MapHandoffService`.
6. Improve active-session UI states.
7. Decide ActivityKit/shared container strategy.
8. Start Live Activity spike on a separate branch.
9. Extract session draft/input type before Quick Start. Done.
10. Add map search provider protocol before advanced filtering.
11. Add map filtering unit tests.

## Review Conclusion

The current Phase 1 architecture is appropriate for a local MVP. It is intentionally simple and should not be overbuilt before Phase 1 sign-off.

The main Phase 2 preparation need is separation of concerns:

- separate persisted record shape from display formatting
- separate session creation input from New Session UI
- separate personal saved spot identity from raw session history
- separate map search/filter/grouping from the SwiftUI view model
- separate Live Activity/widget state from foreground-only store timing

None of these require backend, cloud sync, analytics, ML, or a History list.
