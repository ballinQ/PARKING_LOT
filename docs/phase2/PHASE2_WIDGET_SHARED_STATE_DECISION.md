# Phase 2 Widget Shared-State Decision

Status: Phase 2 design decision. This document defines whether Live Activities and future widgets should use an App Group shared container.

Related documents:

- `PHASE2_ROADMAP.md`
- `PHASE2_ARCHITECTURE_REVIEW.md`
- `PHASE2_LIVE_ACTIVITY_SPIKE.md`
- `PHASE2_PRIVACY_DATA_BOUNDARY.md`

## Decision

Do not add an App Group shared container for the current Phase 2 Live Activity implementation.

The current Live Activity should continue to use the ActivityKit attributes/content-state payload as its extension boundary. The widget can derive visible status, color, countdown, due-soon, and overdue presentation from the `expectedEndTime` already present in the ActivityKit state.

This keeps the current feature smaller, avoids duplicating session persistence into a shared container, and preserves the Phase 2 privacy boundary.

## Why App Group Is Not Needed Yet

The current Live Activity needs only:

- parking session ID
- display location name
- expected end time
- current status vocabulary
- display text when the app publishes an update

The extension does not need to read:

- full parking history
- saved spot metadata
- session notes
- local JSON storage
- map search state
- public parking models

Because the Dynamic Island and Lock Screen can render the timer from `expectedEndTime`, the extension does not need a shared app database just to keep the countdown moving.

## Future Trigger For App Group Review

Revisit App Group storage only if Phase 2 or a later phase adds one of these:

- a normal Home Screen / Lock Screen widget that must show active parking state when no Live Activity exists
- widget controls that need to start or end parking from outside the app
- a widget that displays personal saved spots or favorite spots
- a widget that needs persisted user preferences
- an extension that must read public parking provider cache data

Any App Group review must also update `PHASE2_PRIVACY_DATA_BOUNDARY.md`.

## If App Group Is Added Later

Use a new minimal extension-safe store instead of sharing the full app session store.

Allowed shared shape:

```swift
struct SharedActiveParkingSnapshot: Codable {
    var sessionID: UUID
    var locationName: String
    var expectedEndTime: Date
    var updatedAt: Date
}
```

Do not put these in shared storage without a new design review:

- completed parking history
- session notes
- saved spot metadata
- precise history coordinates beyond the active session
- map search history
- analytics or behavioral summaries
- Green P/public parking cache data

## Lifecycle Rules

If a future App Group snapshot is introduced:

- Write it only when a session starts, updates, restores, or ends.
- Remove it when the active session ends.
- Treat the app store as the writer and the extension as a read-only consumer.
- Keep local notifications as the fallback reminder path.
- Do not use shared storage to simulate background execution.
- Do not add background location to keep widget data fresh.

## Current Implementation Boundary

Current Phase 2 implementation remains:

- ActivityKit Live Activity for active parking presence.
- ActivityKit content state as the extension data boundary.
- Local app storage for sessions and personal metadata.
- No App Group entitlement.
- No shared JSON database.
- No backend, cloud sync, analytics, ML, or continuous background location.

## Test/QA Meaning

This is a design decision, not a behavior change. Test/QA should continue validating the Live Activity behavior through ActivityKit lifecycle evidence and visual checks, not App Group storage.

