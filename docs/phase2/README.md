# Phase 2 Documents

Phase 2 is the personal smart parking assistant phase.

Current authoritative files:

- `PHASE2_ROADMAP.md` - product direction and implementation order.
- `PHASE2_ARCHITECTURE_REVIEW.md` - architecture risks, sequencing, and preparation notes.
- `PHASE2_DEVELOPMENT_THREAD_RESPONSIBILITY.md` - development-only thread responsibility, required design/implementation records, and Test handoff summary template.
- `PHASE2_TEST_QA_THREAD.md` - Test/QA thread responsibility, test-case maintenance rules, validation rules, report format, and Debug-thread handoff format.
- `PHASE2_DEBUG_THREAD_RESPONSIBILITY.md` - Debug thread responsibility, bug investigation format, and fix recommendation template.
- `PHASE2_SELF_TEST.md` - Clawdbot Phase 2 self-test runbook and reporting instructions.
- `PHASE2_NOTIFICATION_LIFECYCLE_AUDIT.md` - local-notification lifecycle audit for Live Activity coordination.
- `PHASE2_LIVE_ACTIVITY_SPIKE.md` - Live Activity implementation notes and remaining verification steps.
- `PHASE2_PRIVACY_DATA_BOUNDARY.md` - local-only privacy rules for location-derived Phase 2 assistant behavior.
- `PHASE2_WIDGET_SHARED_STATE_DECISION.md` - decision record for App Group/shared-state boundaries around Live Activities and future widgets.

Implementation should start with Phase 2A foundation:

1. persistence schema versioning
2. pure active-session display/status formatter
3. notification lifecycle audit
4. Swift 6 warning cleanup
5. improved active-session UI
6. Live Activity / Dynamic Island first implementation pass

Do not add backend, login, cloud sync, analytics, ML, continuous background location, or the old History list.

## Next Phase

Phase 2.5 planning now lives in `../phase2_5/`. It is limited to Toronto static Green P / public parking discovery with verified static data only. Backend, Supabase, real-time availability, payment, cloud sync, and community features remain out of scope.
