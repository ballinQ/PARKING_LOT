# Phase 2 Release-Candidate Checklist

Date: 2026-05-06
Owner: Development thread records this checklist; Test/QA owns formal verification and reports.

## Release-Candidate Position

Phase 2 is now in release-candidate polish. Development should not add large new features. Remaining development work should be limited to small polish items and confirmed Test/Debug findings.

Estimated development progress after this polish pass: about 90%.

## Feature Scope Frozen For RC

- Local-only active parking reminder.
- Home active-session states: Remaining, Due Soon, Overdue.
- Live Activity / Dynamic Island: local ActivityKit only, Dynamic Island icon plus timer.
- Quick Start: 30 min, 1 hr, 2 hr, plus local recent-duration option when useful.
- Map-only History workflow with Apple Maps-style bottom sheet.
- Address search, local saved-history search, radius filtering, metadata filters, recenter, and Search This Area.
- Personal saved-spot metadata: display name, favorite, rating, tags, and note.

## Development Must Not Add

- Backend, login, cloud sync, analytics, ML, public/community map, production Green P layer, real-time parking availability claims, payment integration, server push, continuous background location, or old History list.

## Final Development Checklist

- [x] Map bottom-sheet release-candidate polish completed.
- [x] Personal saved-spot metadata polish completed.
- [x] Quick Start visual polish completed.
- [x] Live Activity code-side presentation polish completed.
- [x] README work log updated.
- [x] Roadmap status updated to release-candidate polish.
- [x] Test handoff created for the RC polish slice.
- [ ] Wait for Test/QA final report.
- [ ] Fix only release-blocking defects from Test/Debug.
- [ ] Update this checklist when final release blockers are closed.

## Test/QA Focus Areas

- Map search, radius, metadata filters, recenter, Search This Area, marker detail, back behavior, keyboard, and small-screen safe area.
- Home Quick Start and full Start Parking relationship.
- Active-session states and End Parking behavior.
- Live Activity / Dynamic Island visual evidence on supported simulator or device.
- Personal spot metadata persistence and map-only detail flow.

## Release Decision Rule

Phase 2 can move from release candidate to complete when Test/QA reports no release-blocking failures, Live Activity visual evidence is captured or explicitly accepted as a manual risk, and Debug has closed or deferred all confirmed blockers.
