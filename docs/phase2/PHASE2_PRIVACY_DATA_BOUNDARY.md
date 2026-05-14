# Phase 2 Privacy And Data Boundary

Status: Phase 2 design note. This document records the privacy rules for local-only, location-derived assistant behavior before future Phase 2 polish adds smarter suggestions.

Related documents:

- `PHASE2_ROADMAP.md`
- `PHASE2_ARCHITECTURE_REVIEW.md`
- `PHASE2_DEVELOPMENT_THREAD_RESPONSIBILITY.md`

## Product Boundary

Phase 2 remains a personal smart parking assistant, not a platform or data product.

The app may use local parking history, one-shot location, user-entered spot metadata, and local search state to make the personal workflow faster. It must not upload, share, analyze remotely, or continuously collect location-derived behavior during Phase 2.

## Hard Rules

- Keep all parking sessions, saved spot metadata, and assistant suggestions local-only.
- Keep location capture one-shot and user initiated.
- Do not add background location monitoring.
- Do not add backend, cloud sync, login, analytics, ML, or community/public user data.
- Do not infer a user's intent from continuous movement.
- Do not expose public/community parking claims from personal saved history.
- Do not claim real-time public parking availability unless a future official source explicitly supports it.

## Data Categories

| Category | Examples | Phase 2 handling |
|---|---|---|
| Parking session event | location name, coordinate, start time, expected end time, actual end time, note | Store locally in the versioned session envelope |
| Active session display | status, expected end time, timer text, overdue state | Derive locally from active session data |
| Live Activity payload | session ID, location name, expected end time, status text | Keep minimal and privacy-safe; no history list or private spot metadata |
| Personal spot metadata | favorite, rating, tags, spot note | Store locally in the separate saved-spot metadata envelope |
| Quick Start suggestion | recent duration, recent location label | Derive locally from completed sessions; do not create a remote profile |
| Map search state | typed query, selected address result, nearby radius | Runtime/view-model state only unless a future feature explicitly stores local preferences |
| Public parking source metadata | source name, URL, update date, availability kind | Dormant model only until reliable source research is complete |

## Location-Derived Behavior Rules

### Allowed In Phase 2

- Use one-shot current location to start a parking session.
- Use saved local coordinates to place personal history markers.
- Use a searched address coordinate to filter nearby saved history.
- Use local completed history to suggest a recent Quick Start duration.
- Use personal metadata to filter saved spots inside the Map workflow.

### Requires A New Design Review

- Persisting search history.
- Storing frequent-place summaries.
- Adding "near me" saved-spot suggestions.
- Adding reusable favorite spots as first-class models.
- Adding App Group shared storage for widgets beyond ActivityKit payload state.
- Adding any provider/public parking data cache.

### Not Allowed In Phase 2

- Continuous background location tracking.
- Server-side location processing.
- Cloud sync of parking sessions or saved spots.
- Account-based profiles.
- Analytics events derived from location, search, or parking behavior.
- ML prediction or automated recommendations.
- Public/community sharing of personal spot metadata.

## Suggested Privacy Classification

Future fields should be reviewed with this simple classification before implementation:

| Classification | Meaning | Examples |
|---|---|---|
| `localPublicUI` | Visible in app UI but still local-only | display name, tag labels, rating stars |
| `localPrivate` | User-entered or personal behavior data that should not leave device | notes, saved spot metadata, completed sessions |
| `localSensitiveLocation` | Coordinates or derived place patterns | parking coordinate, searched coordinate, frequent spot |
| `externalReference` | Public/provider data not owned by the user | Green P lot ID, provider source URL |
| `futureCloudBlocked` | Must not be synced/shared without Phase 3+ design | personal history, spot ratings, behavior summaries |

## Implementation Guidance

- Prefer derived values over persisted summaries when the source data is local and cheap to compute.
- If a new field stores location-derived behavior, document why it is needed and where it is persisted.
- Keep Live Activity state small and reconstructable from the current active session.
- Keep public parking models separate from personal history models.
- Add source/update/license metadata before any public parking data becomes visible.
- Make user-facing copy conservative: "nearby options" is acceptable for public data; "available spaces" is not unless official live data exists.

## Current Decision

No code behavior changes are required for this note. It closes the Phase 2 preparation item to define privacy notes for future location-derived fields.

