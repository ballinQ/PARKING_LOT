# Phase 2 Roadmap

Status: Phase 2 is in release-candidate polish. Phase 2A foundation, active-session presence, the first Live Activity pass, Quick Start, map search/filtering polish, and personal spot metadata/filtering slices are implemented. Remaining work should be validation, small polish, and Test/Debug findings only.

## Phase 2 Decision

Phase 2 should be an assistant upgrade, not a platform expansion.

Chosen first implementation target:

1. Phase 2A foundation:
   - persistence schema versioning
   - active-session display/status formatter
   - lifecycle cleanup around notifications and ended sessions
   - Swift 6 warning cleanup that could block later extension work
2. Phase 2B active-session presence:
   - improved active/due-soon/overdue UI
   - Live Activity / Dynamic Island app-side readiness seam
   - real ActivityKit / widget extension first pass
   - local notifications kept as the fallback reminder path
3. Phase 2C quick start:
   - shared `ParkingSessionDraft` for full-form and quick-start creation
   - compact Home quick-start controls for 30 min, 1 hr, and 2 hr starts
   - local recent-duration suggestion based on the most recent completed session
   - one-shot location only, local-only persistence, and no new session model

Personal spot metadata and richer map filtering should follow only after the active-session and quick-start foundations are stable.

Current personal spot metadata slice:

- Saved spots can store local-only display name, favorite, 1-5 rating, tags, and a spot-level note.
- Metadata is edited inside the existing Map spot detail sheet, not in a separate History list.
- Metadata persists in a separate local JSON envelope keyed by stable spot ID.
- Local Map search now matches spot metadata notes and tags in addition to saved spot/session text.
- The release-candidate polish pass keeps the metadata editor lightweight inside the detail sheet instead of turning it into a heavy form.
- No backend, cloud sync, analytics, ML, account, public/community map, or old History list was added.

Current map filtering slice:

- Address search is routed through the injectable `MapSearchProviding` seam.
- Pure saved-history filtering is now routed through `HistoryMapFilteringService`.
- Map marker presentation is now routed through `HistoryMapMarkerItem`, which gives personal-history markers and the search-area marker explicit layer/source identity.
- Map now opens as a real map even without saved history, shows the user location dot, uses user-location camera with heading and Toronto fallback, and has a one-shot relocate button that reuses nearby saved-history filtering.
- Nearby saved-history filtering now supports user-selectable local radius options: 500 m, 1 km, and 2 km.
- Radius changes recompute visible saved spots without performing another address lookup.
- The same Map search field also filters saved parking history locally by spot/session name and notes while the user types.
- Local metadata filter chips now support All, Favorites, 4+ Stars, and supported tag filters.
- Metadata filters compose with local saved-history text search and nearby address radius filtering.
- Tapping search now expands the bottom sheet so local saved-history results can be selected while the keyboard is visible.
- Panning or zooming the map now exposes a compact `Search This Area` control when appropriate.
- `Search This Area` uses the visible map center as the local nearby-history center, clears address result rows, preserves the selected radius and metadata filters, and keeps History map-only.
- The release-candidate polish pass tightened bottom-sheet heights, medium preview density, and floating-control visibility so the map remains the main visual focus.

Current Quick Start polish slice:

- Home keeps the default 30 min, 1 hr, and 2 hr Quick Start options.
- If the most recent completed session used a different planned duration, Home adds that rounded recent duration as another local Quick Start option.
- The extra duration option remains local-only and uses the same `ParkingSessionDraft.quickStart(...)` path as the default options.
- Quick Start controls scroll horizontally when needed so Home remains compact.
- The release-candidate polish pass keeps Quick Start visually compact and secondary to the full Start Parking flow.

## Scope Freeze

Phase 1 behavior must remain frozen while this roadmap is reviewed:

- local-only app
- no backend
- no login
- no cloud sync
- no analytics
- no machine learning
- no continuous background location tracking
- History remains map-only, not list-based

Phase 1 core loop:

Start parking -> show countdown -> send reminder -> end session -> save history -> find saved spot on map.

## Release Direction

| Phase | Product theme | Scope |
|---|---|---|
| Phase 1 | Local parking reminder | Reliable local session, countdown, local reminders, map-only history |
| Phase 2 | Personal smart parking assistant | Better personal workflows, Live Activity, quick start, richer local history |
| Phase 3 | Cloud/community parking intelligence | Account/cloud/community concepts after local experience is proven |
| Phase 4 | Parking data / Green P or public parking integration research | Public data, municipal/provider integrations, Green P research |
| Phase 5 | ML prediction and smart recommendations | Prediction/recommendation layer after enough structured data exists |

## Phase 2 Goals

Phase 2 should make the existing local app feel faster, smarter, and more personal without changing its privacy posture.

1. Make the active parking session more reliable, visible, and clear.
2. Prepare the local data model for safe Phase 2 growth.
3. Add better active-session presence outside the app.
4. Reduce friction when starting common parking sessions.
5. Improve map-only history search/filtering.
6. Make saved spots more useful through personal-only metadata.
7. Research nearby parking discovery without committing to cloud/community features.

## Proposed Phase 2 Workstreams

### 0. Phase 2A Foundation

Intent:

- Prepare the Phase 1 codebase for Phase 2 without changing the user-facing product shape.
- Make future Live Activity, quick start, and map filtering work easier to test.

Scope:

- Add lightweight persistence schema versioning.
- Extract active-session status/display formatting out of `ParkingSessionStore`.
- Add tests for active, due-soon, overdue, and completed display states.
- Audit notification scheduling for start, end, replacement, and relaunch behavior.
- Fix known Swift 6 isolation/sendability warnings in `MapHandoffService`.

Acceptance criteria:

- Existing Phase 1 tests still pass.
- No backend, cloud, login, analytics, ML, or History list is added.
- Existing saved sessions continue to load.
- Active-session display logic is testable without SwiftUI.

### 1. Improved Active Session UI

Intent:

- Make active, warning, overdue, and completed states clearer.
- Improve urgency without adding complexity.

Possible improvements:

- Stronger overdue visual state.
- Clear expected end time.
- Warning window label, such as "Due Soon".
- Better note/location presentation.
- Larger end-session affordance that remains hard to tap accidentally.

Preparation:

- Keep status derived from `ParkingSession.displayStatus(now:)`.
- Use the new pure display model/formatter from Phase 2A.
- Add snapshot/UI tests around active and overdue states before changing visuals.

Acceptance criteria:

- Countdown remains accurate.
- Overdue state is obvious.
- End Parking still works and persists history.
- Local notifications still schedule and cancel correctly.

### 2. Live Activity / Dynamic Island Countdown

Intent:

- Show current parking countdown on Lock Screen and Dynamic Island.
- Show active/overdue state without requiring the user to reopen the app.

Preparation:

- Add an ActivityKit capability only after Phase 2A display/lifecycle preparation is complete.
- Use the existing `ParkingActivitySnapshot` and `ParkingActivityLifecycleManaging` seam as the app-side boundary.
- Keep local notifications as the fallback reminder path.
- Define a small `ParkingActivityAttributes` payload that avoids storing full history or private notes.
- Decide whether the activity starts only after a successful session save.

Acceptance criteria:

- Live Activity starts when a parking session starts. Verified by ActivityKit simulator logs.
- Live Activity updates countdown/overdue state. Verified by ActivityKit simulator logs.
- Live Activity ends when parking is manually ended. Verified by ActivityKit simulator logs.
- Existing local notification tests still pass.
- Final visual Lock Screen and Dynamic Island screenshots or video are still required before calling this feature fully release-ready.

Risks:

- `ParkingSessionStore` currently owns timing through an in-app `Timer`; Live Activities/widgets need state that can be recreated outside the foreground app.
- ActivityKit updates should not depend on continuous location or long-running background execution.

### 3. Quick Start Parking Flow

Intent:

- Let users start common sessions with fewer taps.
- Keep the full New Session flow available.

Current first pass:

- Home shows Quick Start controls only when there is no active parking session.
- Presets are 30 min, 1 hr, and 2 hr.
- A recent-duration option is added from local completed history when it differs from the default presets.
- Quick Start uses `ParkingSessionDraft.quickStart(...)` and the same store creation path as the full New Session flow.
- Suggested location defaults to `Current Location`, or the most recent completed session location when available.
- Coordinate capture remains one-shot and user-initiated through the existing location service.

Possible future polish:

- Quick duration chips on Home, such as 30 min, 1 hr, 2 hr.
- Additional last-used location/duration polish beyond the first local suggestion.
- Start from last saved nearby spot when location is available once.

Preparation:

- Extract session creation input into a small value type, for example `ParkingSessionDraft`. Done.
- Keep `NewSessionView` behavior unchanged for Phase 1. Done.
- Add recent-duration suggestion from local completed history. Done.
- Add test seams so quick start and full start use the same store path. Done.

Acceptance criteria:

- Quick start creates the same persisted session shape as the full flow.
- User can still open the full flow to edit location/name/note before starting when needed.
- No backend or account dependency.

### 4. Personal Spot Rating, Tags, And Notes

Intent:

- Make personal saved spots more useful without any public/community layer.

Possible fields:

- rating, such as 1-5 personal score
- tags, such as safe, cheap, covered, street, garage, EV, accessible
- favorite flag
- richer notes at spot level and session level
- last-used metadata

Preparation:

- Separate `ParkingSession` from a future `ParkingSpot` or `SavedSpot` concept.
- Avoid exposing new fields in Phase 1 UI.
- Add schema versioning before writing new persisted fields.

Acceptance criteria:

- Ratings/tags remain local-only.
- Map stays map-only.
- Detail sheet can show personal metadata without becoming a list replacement.

Current first pass:

- Display name, favorite, rating, predefined tags, and spot-level note are available in the existing detail sheet.
- Metadata is stored separately from sessions so the session event log remains intact.
- Search can find saved spots by metadata note or tag.
- Metadata filters can narrow visible saved spots by favorite, rating, or tag without leaving the Map workflow.

### 5. Better History Map Search And Filtering

Intent:

- Keep History as Map, but make it easier to find relevant saved spots.

Possible improvements:

- Filter by favorites/tags/rating.
- Search saved spot names and notes. First local pass done.
- Search address/landmark and show nearby saved spots.
- Adjustable radius, for example 500 m, 1 km, 2 km. First pass done.
- "Near me" search using one-shot location only. First pass done through the Map relocate button.
- Search this visible map area after manual pan/zoom. First pass done.

Preparation:

- Continue extracting map filtering/search logic out of `HistoryMapViewModel` into testable services. First pure filtering service is done.
- Use the new mockable `MapSearchProviding` seam for address search; `MapKitSearchProvider` is now the production `MKLocalSearch` adapter.
- Keep all filtering local.

Acceptance criteria:

- Search relocation and nearby filtering remain clear.
- No old History list returns.
- Tests cover filtering without relying on live MapKit network behavior.
- Tests cover metadata filters both alone and composed with address-radius results.
- Tests cover the pure filtering service directly.
- Tests cover `Search This Area` filtering, address-result clearing, and metadata-filter preservation.
- Marker rendering has a small layer/source model so future public parking markers can be introduced without using raw personal-history groups directly.
- Dormant public parking model types now exist for future `ParkingSource`, `PublicParkingLot`, and `GreenPParkingLot` work, but they are not wired into Map UI or data loading.

### 6. Toronto Green P / Nearby Parking Discovery Research

Intent:

- Explore whether nearby parking discovery is feasible without prematurely building a cloud product.
- Focus the first research pass on Toronto and Green P because the initial product target is Toronto.
- Keep a strict distinction between nearby Green P options and real-time availability.
- Detailed research notebook: `TORONTO_GREENP_PUBLIC_PARKING_RESEARCH_NOTE.md`.

Allowed in Phase 2:

- Research notes for official Green P, Toronto Parking Authority, and Toronto Open Data sources.
- Static Green P marker prototype only if an official or clearly reliable dataset is available.
- Data model planning for `ParkingSource`, `PublicParkingLot`, and `GreenPParkingLot`. Dormant model types now exist for compile-time architecture only.
- Manual review of public data availability and API constraints.
- Do not implement visible Green P markers or bundled production data until source reliability and licensing are explicitly approved.

Not allowed in Phase 2:

- Production Green P map layer.
- Real-time availability claims unless an official live occupancy source exists.
- Green P payment automation.
- Public/community parking map.
- User-to-user marketplace.
- Production backend ingestion.

Research questions:

- Which official Green P / Toronto Parking Authority / Toronto Open Data sources exist?
- Which fields are available: lot ID, name, address, lat/lon, facility type, capacity, rates, max prices, EV charging, height restriction, source URL, and last updated date?
- Is the data static, periodically updated, or officially live?
- Does the license allow in-app display and cached/static marker use?
- What license, rate limit, and reliability constraints apply?
- Can MapKit search surface useful nearby parking POIs without custom backend data?
- What privacy implications exist if saved parking coordinates are later synced?

Recommended phase placement:

- Phase 2: research and optional disabled/static marker prototype only.
- Phase 3: production Green P data layer with an update pipeline, if official/static data is reliable enough.
- Phase 4: real-time availability, payment, or deeper Green P integration only with an official API or partnership.

## Technical Preparation Checklist

Before writing Phase 2 user-facing feature code:

- [ ] Close Phase 1 manual checks or explicitly record accepted risk.
- [ ] Create a Phase 2 branch after Phase 1 is committed/tagged.
- [x] Add a lightweight persistence schema version. This is the first implementation task.
- [x] Decide whether to migrate local JSON in place or introduce a versioned storage envelope.
- [x] Extract active-session display/status formatting. This is the second implementation task.
- [x] Add unit tests for active/due-soon/overdue/completed display formatting.
- [x] Add unit tests around map filtering and grouping edge cases.
- [x] Add a mockable address search/geocoding abstraction.
- [x] Audit notification scheduling around app relaunch and ended sessions.
- [x] Fix `MapHandoffService` Swift 6 isolation/sendability warnings.
- [x] Add an app-side Live Activity lifecycle seam with a privacy-safe snapshot.
- [x] Decide if Live Activities require a shared App Group container. Current decision: no App Group for the Phase 2 Live Activity; ActivityKit content state is enough. See `PHASE2_WIDGET_SHARED_STATE_DECISION.md`.
- [x] Decide target iOS versions for ActivityKit/WidgetKit support. Current target remains iOS 17+.
- [x] Add the real ActivityKit-backed widget extension and lifecycle manager.
- [x] Verify ActivityKit create, update, end, and dismiss lifecycle through simulator logs.
- [ ] Capture final Lock Screen and Dynamic Island visual presentation on supported device/simulator.
- [x] Extract session creation input into a draft/value object before Quick Start.
- [x] Implement first local-only Quick Start pass on the shared session creation path.
- [x] Define privacy notes for any future fields that store location-derived behavior. See `PHASE2_PRIVACY_DATA_BOUNDARY.md`.
- [x] Prepare a Phase 2 release-candidate checklist for final Test/QA and Debug handoff. See `PHASE2_RELEASE_CANDIDATE_CHECKLIST.md`.
- [ ] Keep `docs/phase1/PHASE1_SELF_TEST.md` unchanged except for clearly labeled Phase 2 references, if needed.

## Architecture Risks And Blockers

### Live Activities / Widgets

- `ParkingSessionStore` is an app-only `@MainActor ObservableObject` with an in-memory timer. Widgets and Live Activities need reconstructable state, not only foreground timer state.
- Countdown status/display logic is now store-owned and uses a defensive formatter, with a privacy-safe activity snapshot for future Live Activity use.
- ActivityKit target, widget extension, shared attributes, and lifecycle manager now exist.
- Notification scheduling and Live Activity updates now share store lifecycle events.
- The app target now declares `NSSupportsLiveActivities`.
- Simulator logs verify ActivityKit creation, update, end, and dismissal. Final visual presentation capture is still required.

### Future Cloud Sync

- Local JSON now stores a versioned envelope and still reads legacy bare `[ParkingSession]` arrays. Future sync still needs sync status, tombstones, conflict resolution, and updated timestamps.
- `ParkingSession.id` is a UUID and can work as a future record ID, but there is no separation between local ID, remote ID, and stable spot ID.
- The store assumes one active session and local-only writes. Future sync must define conflict behavior for active sessions across devices.
- Error handling in persistence is intentionally silent for Phase 1. Cloud/sync work will need visible error states and retry policy.

### Future Map Layers

- `HistoryMapViewModel` currently owns grouping, visible filtering, selection state, and user-facing status text. Address search now goes through `MapSearchProviding`; future map layers will benefit from more separate services for filtering, grouping, and layer composition.
- `ParkingSpotGroupingService` uses a greedy 30 m grouping threshold and coordinate bucket IDs. This is acceptable for Phase 1 but may not be enough for favorite spots, garages, public lots, or multiple floors/entrances.
- The current map supports saved personal spots and a search marker. Future public parking layers should be separate data sources with explicit layer toggles, not merged into personal history.

### Data Model Growth

- `ParkingSession` is both the event record and the source for spot identity. Phase 2 personal spot metadata will likely need a separate `SavedSpot` model.
- Notes are session-level only. Phase 2 may need both session notes and spot-level notes.
- No created/updated timestamps exist beyond parking times, which will matter for migrations, sync, and sorting user-edited metadata.
- No field-level privacy classification exists. This will matter before cloud/community phases.

### Permissions And Platform Services

- `LocationService` correctly uses one-shot location for Phase 1. Phase 2 should preserve this and avoid background location.
- Notification permission status is handled simply. More explicit user feedback may be needed before richer reminders or Live Activities.
- External map handoff works through UIKit/MapKit, and the prior Swift 6 warnings have been cleaned. Keep that abstraction stable before building more map integrations.

## Suggested Future Data Model Fields

Do not expose these in the Phase 1 UI unless a migration requires hidden defaults.

### ParkingSession additions

| Field | Type | Why |
|---|---|---|
| `schemaVersion` | Int | Supports future migration from local JSON |
| `createdAt` | Date | Record creation/audit |
| `updatedAt` | Date | Future sync conflict detection |
| `source` | String/enum | full form, quick start, imported, restored |
| `durationMinutes` | Int | Easier summaries and quick-start suggestions |
| `timezoneIdentifier` | String | Safer display after travel/time-zone changes |
| `endedReason` | enum | manual, expired, replacedByNewSession, migrated |
| `notificationWarningID` | String? | Debugging/rescheduling trace |
| `notificationExpiryID` | String? | Debugging/rescheduling trace |
| `spotID` | UUID/String? | Link session to future personal spot record |
| `privacyLevel` | enum | localOnly now; useful before sync/community |

### SavedSpot / ParkingSpot future model

| Field | Type | Why |
|---|---|---|
| `id` | UUID/String | Stable personal spot identity |
| `displayName` | String | User-facing spot name |
| `latitude` / `longitude` | Double | Map placement |
| `createdAt` / `updatedAt` | Date | Local edits and future sync |
| `firstUsedAt` / `lastUsedAt` | Date | Personal history summaries |
| `visitCount` | Int | Frequent-spot intelligence |
| `rating` | Int? | Personal-only quality score |
| `tags` | [String] | Personal filters |
| `note` | String | Spot-level note separate from session note |
| `isFavorite` | Bool | Fast filtering/quick start |
| `providerIDs` | Dictionary/String map | Future external data mapping |
| `source` | enum | userSaved, sessionDerived, publicDataCandidate |
| `isArchived` | Bool | Hide stale spots without deleting history |

### Future sync metadata

Only for Phase 3 or later:

| Field | Type | Why |
|---|---|---|
| `remoteID` | String? | Cloud record identity |
| `syncState` | enum | localOnly, pendingCreate, pendingUpdate, synced, conflict |
| `deletedAt` | Date? | Tombstones |
| `lastSyncedAt` | Date? | Sync status |
| `ownerUserID` | String? | Account/cloud phase only |

## Do Not Implement Yet

Do not implement these during Phase 2 planning or Phase 1 stabilization:

- Backend services.
- Login/account creation.
- Cloud sync.
- Public/community parking map.
- Analytics/event tracking.
- Machine learning or prediction.
- Continuous background location tracking.
- Old History list or list-based History replacement.
- Green P payment automation.
- Public parking payment integrations.
- User-to-user parking marketplace.
- Risk scoring or personalized recommendation engine.
- Production ingestion of municipal/provider parking datasets.
- Push notifications from a server.
- Social sharing or public saved spots.

## Recommended Phase 2 Order

1. Tag/freeze Phase 1 and create the Phase 2 branch.
2. Add persistence schema version and migration safety.
3. Extract active-session display/status formatting with tests.
4. Audit notification lifecycle and fix Swift 6 map handoff warnings.
5. Improve active-session UI, especially due-soon and overdue states.
6. Implement the real ActivityKit-backed Live Activity manager and widget extension.
7. Build Quick Start on the same session creation path. First pass done.
8. Improve map-only search/filtering with mockable search. Address radius, local text search, and metadata filter composition are now implemented.
9. Add personal spot metadata only after storage versioning is stable. First pass and local metadata filters are done.
10. Freeze Phase 2 feature scope after release-candidate polish and let Test/Debug drive remaining release blockers.
11. Keep nearby parking discovery as research documentation.

## Phase 2 Exit Criteria

Phase 2 is complete when:

- Phase 1 core loop still passes automated and manual checks.
- Live Activity or equivalent active-session presence is reliable, including ActivityKit lifecycle evidence and final visual presentation evidence, or a documented technical blocker exists.
- Quick start reduces taps without creating a second session model.
- Active/overdue state is visually clear.
- Personal spot metadata is local-only and test-covered.
- Map remains the single History surface.
- No backend/cloud/ML/community feature has leaked into production scope.
