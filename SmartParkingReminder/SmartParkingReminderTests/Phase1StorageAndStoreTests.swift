import XCTest
@testable import SmartParkingReminder

@MainActor
final class Phase1StorageAndStoreTests: XCTestCase {

    // TC-14 (P0) Persistence after relaunch (logic-level)
    func test_TC14_PersistenceRoundTrip_LoadsActiveAndCompleted() async throws {
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent("parking_sessions_\(UUID().uuidString).json")

        let storage = ParkingSessionStorageService(fileURL: tmp)
        let notifications = RecordingNotificationService()

        var fixedNow = ISO8601DateFormatter().date(from: "2026-04-22T15:00:00Z")!
        let store1 = ParkingSessionStore(storage: storage, notifications: notifications, nowProvider: { fixedNow })

        await store1.startNewSession(locationName: "Completed Lot", duration: 60, note: "old session", coordinate: nil)
        XCTAssertNotNil(store1.activeSession)

        fixedNow = fixedNow.addingTimeInterval(10)
        await store1.endActiveSession()
        XCTAssertNil(store1.activeSession)
        XCTAssertEqual(store1.sessions.count, 1)
        XCTAssertEqual(store1.sessions.first?.persistedStatus, .completed)

        fixedNow = fixedNow.addingTimeInterval(10)
        await store1.startNewSession(locationName: "Active Lot", duration: 120, note: "current session", coordinate: nil)
        XCTAssertEqual(store1.sessions.count, 2)
        XCTAssertEqual(store1.activeSession?.locationName, "Active Lot")

        // Create a new store to simulate relaunch.
        let store2 = ParkingSessionStore(storage: storage, notifications: notifications, nowProvider: { fixedNow })
        store2.start()

        XCTAssertEqual(store2.sessions.count, 2)
        XCTAssertEqual(store2.activeSession?.locationName, "Active Lot")
        XCTAssertTrue(store2.sessions.contains(where: {
            $0.locationName == "Completed Lot" && $0.persistedStatus == .completed
        }))
    }

    func test_Phase2PersonalSpotMetadataStorage_RoundTripsLocalMetadata() throws {
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent("saved_spot_metadata_\(UUID().uuidString).json")

        let storage = SavedParkingSpotMetadataStorageService(fileURL: tmp)
        let createdAt = ISO8601DateFormatter().date(from: "2026-04-22T15:00:00Z")!
        let metadata = SavedParkingSpotMetadata(
            spotID: "spot_test",
            displayName: "Work Garage",
            note: "level two",
            rating: 5,
            tags: ["Safe", "Covered"],
            isFavorite: true,
            createdAt: createdAt,
            updatedAt: createdAt
        )

        try storage.save([metadata.spotID: metadata])

        let restored = try storage.load()

        XCTAssertEqual(restored[metadata.spotID], metadata)
    }

    func test_Phase2Countdown_FutureEndTimeShowsRemaining() async throws {
        let storage = InMemoryStorage()
        let notifications = RecordingNotificationService()

        let fixedNow = ISO8601DateFormatter().date(from: "2026-04-22T15:00:00Z")!
        let store = ParkingSessionStore(storage: storage, notifications: notifications, nowProvider: { fixedNow })

        await store.startNewSession(locationName: "Future Lot", duration: 1800, note: "", coordinate: nil)
        let active = try XCTUnwrap(store.activeSession)
        let display = store.timerDisplay(for: active)

        XCTAssertFalse(store.isActiveSessionOverdue(active))
        XCTAssertFalse(store.isActiveSessionOverdue)
        XCTAssertEqual(display.status, .active)
        XCTAssertEqual(display.label, "Remaining")
        XCTAssertEqual(display.displayTime, 1800)
        XCTAssertEqual(display.timeText, "30m 0s")
        XCTAssertEqual(store.remainingTimeInterval(for: active), 1800)
        XCTAssertEqual(store.remainingTimeString(for: active), "30m 0s")
    }

    func test_Phase2Countdown_EndTimeWithin15MinutesShowsDueSoon() async throws {
        let storage = InMemoryStorage()
        let notifications = RecordingNotificationService()

        let fixedNow = ISO8601DateFormatter().date(from: "2026-04-22T15:00:00Z")!
        let store = ParkingSessionStore(storage: storage, notifications: notifications, nowProvider: { fixedNow })

        await store.startNewSession(locationName: "Due Soon Lot", duration: 125, note: "", coordinate: nil)
        let active = try XCTUnwrap(store.activeSession)
        let display = store.timerDisplay(for: active)

        XCTAssertFalse(store.isActiveSessionOverdue(active))
        XCTAssertEqual(display.status, .dueSoon)
        XCTAssertEqual(display.label, "Due Soon")
        XCTAssertEqual(display.displayTime, 125)
        XCTAssertEqual(display.timeText, "2m 5s")
        XCTAssertEqual(store.remainingTimeString(for: active), "2m 5s")
    }

    func test_Phase2Countdown_PastActiveSessionShowsOverdueWithoutAutoEnding() throws {
        let storage = InMemoryStorage()
        let notifications = RecordingNotificationService()

        let start = ISO8601DateFormatter().date(from: "2026-04-22T15:00:00Z")!
        let overdueSession = makeActiveSession(
            locationName: "Overdue Lot",
            start: start,
            expectedEnd: start.addingTimeInterval(60)
        )
        try storage.save([overdueSession])

        let store = ParkingSessionStore(
            storage: storage,
            notifications: notifications,
            nowProvider: { start.addingTimeInterval(90) }
        )
        store.start()
        let active = try XCTUnwrap(store.activeSession)
        let display = store.timerDisplay(for: active)

        XCTAssertEqual(active.persistedStatus, .active)
        XCTAssertTrue(store.isActiveSessionOverdue(active))
        XCTAssertTrue(store.isActiveSessionOverdue)
        XCTAssertEqual(display.status, .overdue)
        XCTAssertEqual(display.label, "Overdue")
        XCTAssertEqual(display.displayTime, 30)
        XCTAssertEqual(display.timeText, "0m 30s")
        XCTAssertEqual(store.remainingTimeInterval(for: active), 0)
        XCTAssertEqual(store.remainingTimeString(for: active), "0m 30s")
        XCTAssertNil(active.actualEndTime)
        XCTAssertTrue(notifications.canceledSessionIDs.isEmpty)
    }

    func test_Phase2Countdown_RelaunchRestoresPastActiveSessionAsOverdue() async throws {
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent("parking_sessions_\(UUID().uuidString).json")

        let storage = ParkingSessionStorageService(fileURL: tmp)
        let notifications = RecordingNotificationService()

        let start = ISO8601DateFormatter().date(from: "2026-04-22T15:00:00Z")!
        var fixedNow = start
        let store1 = ParkingSessionStore(storage: storage, notifications: notifications, nowProvider: { fixedNow })

        await store1.startNewSession(locationName: "Overdue Relaunch Lot", duration: 60, note: "", coordinate: nil)

        fixedNow = start.addingTimeInterval(90)
        let store2 = ParkingSessionStore(storage: storage, notifications: notifications, nowProvider: { fixedNow })
        store2.start()
        let restored = try XCTUnwrap(store2.activeSession)
        let display = store2.timerDisplay(for: restored)

        XCTAssertEqual(restored.locationName, "Overdue Relaunch Lot")
        XCTAssertEqual(restored.persistedStatus, .active)
        XCTAssertTrue(store2.isActiveSessionOverdue(restored))
        XCTAssertEqual(display.status, .overdue)
        XCTAssertEqual(display.label, "Overdue")
        XCTAssertEqual(display.displayTime, 30)
        XCTAssertEqual(display.timeText, "0m 30s")
        XCTAssertEqual(store2.remainingTimeInterval(for: restored), 0)
        XCTAssertEqual(store2.remainingTimeString(for: restored), "0m 30s")
        XCTAssertNil(restored.actualEndTime)
        XCTAssertTrue(notifications.canceledSessionIDs.isEmpty)
    }

    // TC-07 (P0) End parking manually => finalized + moved to history
    func test_TC07_EndSession_FinalizesAndCancelsNotifications() async throws {
        let storage = InMemoryStorage()
        let notifications = RecordingNotificationService()

        var fixedNow = ISO8601DateFormatter().date(from: "2026-04-22T15:00:00Z")!
        let store = ParkingSessionStore(storage: storage, notifications: notifications, nowProvider: { fixedNow })

        await store.startNewSession(locationName: "Lot A", duration: 60, note: "note", coordinate: nil)
        let activeID = try XCTUnwrap(store.activeSession?.id)

        XCTAssertEqual(notifications.scheduledSessionIDs, [activeID])

        fixedNow = fixedNow.addingTimeInterval(10)
        await store.endActiveSession()

        XCTAssertNil(store.activeSession)
        XCTAssertEqual(store.sessions.count, 1)
        XCTAssertEqual(store.sessions[0].persistedStatus, .completed)
        XCTAssertNotNil(store.sessions[0].actualEndTime)
        XCTAssertEqual(notifications.canceledSessionIDs, [activeID])
    }

    func test_Phase2NotificationLifecycle_ReplacingActiveSessionCancelsOldAndSchedulesNew() async throws {
        let storage = InMemoryStorage()
        let notifications = RecordingNotificationService()

        var fixedNow = ISO8601DateFormatter().date(from: "2026-04-22T15:00:00Z")!
        let store = ParkingSessionStore(storage: storage, notifications: notifications, nowProvider: { fixedNow })

        await store.startNewSession(locationName: "Lot A", duration: 60, note: "first", coordinate: nil)
        let firstID = try XCTUnwrap(store.activeSession?.id)

        fixedNow = fixedNow.addingTimeInterval(10)
        await store.startNewSession(locationName: "Lot B", duration: 120, note: "second", coordinate: nil)
        let secondID = try XCTUnwrap(store.activeSession?.id)

        XCTAssertNotEqual(firstID, secondID)
        XCTAssertEqual(notifications.scheduledSessionIDs, [firstID, secondID])
        XCTAssertEqual(notifications.canceledSessionIDs, [firstID])
        XCTAssertEqual(store.activeSession?.locationName, "Lot B")
        XCTAssertTrue(store.sessions.contains(where: {
            $0.id == firstID && $0.persistedStatus == .completed && $0.actualEndTime == fixedNow
        }))
    }

    func test_Phase2QuickStartDraft_UsesSameSessionCreationPath() async throws {
        let storage = InMemoryStorage()
        let notifications = RecordingNotificationService()
        let fixedNow = ISO8601DateFormatter().date(from: "2026-04-22T15:00:00Z")!
        let store = ParkingSessionStore(storage: storage, notifications: notifications, nowProvider: { fixedNow })

        await store.startNewSession(from: .quickStart(
            durationMinutes: 30,
            coordinate: (lat: 43.6532, lon: -79.3832)
        ))

        let active = try XCTUnwrap(store.activeSession)
        XCTAssertEqual(active.locationName, "Quick Start")
        XCTAssertEqual(active.expectedEndTime, fixedNow.addingTimeInterval(30 * 60))
        XCTAssertEqual(active.note, "")
        XCTAssertEqual(active.latitude, 43.6532)
        XCTAssertEqual(active.longitude, -79.3832)
        XCTAssertEqual(active.persistedStatus, .active)
        XCTAssertEqual(notifications.scheduledSessionIDs, [active.id])
    }

    func test_Phase1QuickStartName_DoesNotReuseMostRecentSessionLocation() async throws {
        let storage = InMemoryStorage()
        let notifications = RecordingNotificationService()
        var fixedNow = ISO8601DateFormatter().date(from: "2026-04-22T15:00:00Z")!
        let store = ParkingSessionStore(storage: storage, notifications: notifications, nowProvider: { fixedNow })

        await store.startNewSession(locationName: "Office Garage", duration: 60, note: "", coordinate: nil)
        fixedNow = fixedNow.addingTimeInterval(10)
        await store.endActiveSession()

        XCTAssertEqual(store.quickStartLocationName, "Quick Start")

        fixedNow = fixedNow.addingTimeInterval(10)
        await store.startNewSession(from: .quickStart(
            durationMinutes: 60,
            coordinate: nil
        ))

        XCTAssertEqual(store.activeSession?.locationName, "Quick Start")
        XCTAssertEqual(store.activeSession?.expectedEndTime, fixedNow.addingTimeInterval(60 * 60))
    }

    func test_Phase2QuickStartDurationOptions_IncludeRecentNonDefaultDuration() async throws {
        let storage = InMemoryStorage()
        let notifications = RecordingNotificationService()
        var fixedNow = ISO8601DateFormatter().date(from: "2026-04-22T15:00:00Z")!
        let store = ParkingSessionStore(storage: storage, notifications: notifications, nowProvider: { fixedNow })

        XCTAssertEqual(store.quickStartDurationOptions, [30, 60, 120])

        await store.startNewSession(locationName: "Evening Class", duration: 45 * 60, note: "", coordinate: nil)
        fixedNow = fixedNow.addingTimeInterval(30 * 60)
        await store.endActiveSession()

        XCTAssertEqual(store.quickStartDurationOptions, [30, 60, 120, 45])

        fixedNow = fixedNow.addingTimeInterval(60)
        await store.startNewSession(from: .quickStart(
            durationMinutes: 45,
            coordinate: nil
        ))

        XCTAssertEqual(store.activeSession?.locationName, "Quick Start")
        XCTAssertEqual(store.activeSession?.expectedEndTime, fixedNow.addingTimeInterval(45 * 60))
    }

    func test_Phase1ManualStartCustomDuration_UsesSelectedDurationForScheduleAndActivity() async throws {
        let storage = InMemoryStorage()
        let notifications = RecordingNotificationService()
        let activityLifecycle = RecordingActivityLifecycleManager()
        let fixedNow = ISO8601DateFormatter().date(from: "2026-04-22T15:00:00Z")!
        let store = ParkingSessionStore(
            storage: storage,
            notifications: notifications,
            activityLifecycle: activityLifecycle,
            nowProvider: { fixedNow }
        )

        await store.startNewSession(from: .fullForm(
            locationName: "Custom Duration Lot",
            durationMinutes: 85,
            note: "",
            coordinate: nil
        ))

        let active = try XCTUnwrap(store.activeSession)
        let snapshot = try XCTUnwrap(activityLifecycle.startedSnapshots.first)

        XCTAssertEqual(active.expectedEndTime, fixedNow.addingTimeInterval(85 * 60))
        XCTAssertEqual(snapshot.scheduledEndDate, active.expectedEndTime)
        XCTAssertEqual(notifications.scheduledSessionIDs, [active.id])
    }

    func test_Phase1ManualStartInvalidZeroDuration_DoesNotCreateSession() async throws {
        let storage = InMemoryStorage()
        let notifications = RecordingNotificationService()
        let activityLifecycle = RecordingActivityLifecycleManager()
        let fixedNow = ISO8601DateFormatter().date(from: "2026-04-22T15:00:00Z")!
        let store = ParkingSessionStore(
            storage: storage,
            notifications: notifications,
            activityLifecycle: activityLifecycle,
            nowProvider: { fixedNow }
        )

        await store.startNewSession(from: ParkingSessionDraft(
            locationName: "Invalid Lot",
            duration: 0,
            note: "",
            coordinate: nil,
            source: .fullForm
        ))

        XCTAssertNil(store.activeSession)
        XCTAssertTrue(notifications.scheduledSessionIDs.isEmpty)
        XCTAssertTrue(activityLifecycle.startedSnapshots.isEmpty)
    }

    func test_Phase2ActivityLifecycle_StartSessionPublishesPrivacySafeSnapshot() async throws {
        let storage = InMemoryStorage()
        let notifications = RecordingNotificationService()
        let activityLifecycle = RecordingActivityLifecycleManager()

        let fixedNow = ISO8601DateFormatter().date(from: "2026-04-22T15:00:00Z")!
        let store = ParkingSessionStore(
            storage: storage,
            notifications: notifications,
            activityLifecycle: activityLifecycle,
            nowProvider: { fixedNow }
        )

        await store.startNewSession(
            locationName: "Activity Lot",
            duration: 1800,
            note: "private note should not be in activity payload",
            coordinate: (lat: 43.6532, lon: -79.3832)
        )

        let snapshot = try XCTUnwrap(activityLifecycle.startedSnapshots.first)
        let active = try XCTUnwrap(store.activeSession)

        XCTAssertEqual(snapshot.sessionID, active.id)
        XCTAssertEqual(snapshot.locationName, "Activity Lot")
        XCTAssertEqual(snapshot.startDate, fixedNow)
        XCTAssertEqual(snapshot.scheduledEndDate, fixedNow.addingTimeInterval(1800))
        XCTAssertEqual(snapshot.lastUpdatedDate, fixedNow)
    }

    func test_Phase2ActivityLifecycle_EndSessionEndsActivity() async throws {
        let storage = InMemoryStorage()
        let notifications = RecordingNotificationService()
        let activityLifecycle = RecordingActivityLifecycleManager()

        var fixedNow = ISO8601DateFormatter().date(from: "2026-04-22T15:00:00Z")!
        let store = ParkingSessionStore(
            storage: storage,
            notifications: notifications,
            activityLifecycle: activityLifecycle,
            nowProvider: { fixedNow }
        )

        await store.startNewSession(locationName: "Activity Lot", duration: 60, note: "", coordinate: nil)
        let activeID = try XCTUnwrap(store.activeSession?.id)

        fixedNow = fixedNow.addingTimeInterval(10)
        await store.endActiveSession()

        XCTAssertEqual(activityLifecycle.endedSessionIDs, [activeID])
        XCTAssertNil(store.activeSession)
    }

    func test_Phase2ActivityLifecycle_RestoreActiveSessionPublishesRestoredSnapshot() throws {
        let storage = InMemoryStorage()
        let notifications = RecordingNotificationService()
        let activityLifecycle = RecordingActivityLifecycleManager()

        let start = ISO8601DateFormatter().date(from: "2026-04-22T15:00:00Z")!
        let overdueSession = makeActiveSession(
            locationName: "Restored Activity Lot",
            start: start,
            expectedEnd: start.addingTimeInterval(60)
        )
        try storage.save([overdueSession])

        let store = ParkingSessionStore(
            storage: storage,
            notifications: notifications,
            activityLifecycle: activityLifecycle,
            nowProvider: { start.addingTimeInterval(90) }
        )

        store.start()

        let snapshot = try XCTUnwrap(activityLifecycle.restoredSnapshots.first)
        XCTAssertEqual(snapshot.sessionID, overdueSession.id)
        XCTAssertEqual(snapshot.locationName, "Restored Activity Lot")
        XCTAssertEqual(snapshot.startDate, start)
        XCTAssertEqual(snapshot.scheduledEndDate, start.addingTimeInterval(60))
        XCTAssertEqual(snapshot.lastUpdatedDate, start.addingTimeInterval(90))
    }

    func test_Phase2ActivityLifecycle_RestoreWithoutActiveSessionEndsOrphanedActivities() throws {
        let storage = InMemoryStorage()
        let notifications = RecordingNotificationService()
        let activityLifecycle = RecordingActivityLifecycleManager()

        let store = ParkingSessionStore(
            storage: storage,
            notifications: notifications,
            activityLifecycle: activityLifecycle
        )

        store.start()

        XCTAssertEqual(activityLifecycle.noActiveSessionRestoreCount, 1)
        XCTAssertTrue(activityLifecycle.restoredSnapshots.isEmpty)
    }

    func test_Phase2ActivityLifecycle_AddTimePublishesDateDrivenUpdateAndReschedulesNotifications() async throws {
        let storage = InMemoryStorage()
        let notifications = RecordingNotificationService()
        let activityLifecycle = RecordingActivityLifecycleManager()

        var fixedNow = ISO8601DateFormatter().date(from: "2026-04-22T15:00:00Z")!
        let store = ParkingSessionStore(
            storage: storage,
            notifications: notifications,
            activityLifecycle: activityLifecycle,
            nowProvider: { fixedNow }
        )

        await store.startNewSession(locationName: "Activity Lot", duration: 120, note: "", coordinate: nil)
        let active = try XCTUnwrap(store.activeSession)

        fixedNow = fixedNow.addingTimeInterval(30)
        await store.addTimeToActiveSession(minutes: 15)

        let updated = try XCTUnwrap(store.activeSession)
        let updateSnapshot = try XCTUnwrap(activityLifecycle.updatedSnapshots.last)

        XCTAssertEqual(updated.id, active.id)
        XCTAssertEqual(updated.expectedEndTime, active.expectedEndTime.addingTimeInterval(15 * 60))
        XCTAssertEqual(updateSnapshot.sessionID, active.id)
        XCTAssertEqual(updateSnapshot.startDate, active.startTime)
        XCTAssertEqual(updateSnapshot.scheduledEndDate, updated.expectedEndTime)
        XCTAssertEqual(updateSnapshot.lastUpdatedDate, fixedNow)
        XCTAssertEqual(notifications.canceledSessionIDs, [active.id])
        XCTAssertEqual(notifications.scheduledSessionIDs, [active.id, active.id])
    }

    func test_Phase2ActivityKitPayload_MapsPrivacySafeSnapshot() throws {
        guard #available(iOS 16.2, *) else {
            throw XCTSkip("ActivityKit payload requires iOS 16.2 or newer.")
        }

        let sessionID = UUID(uuidString: "11111111-2222-3333-4444-555555555555")!
        let expectedEnd = ISO8601DateFormatter().date(from: "2026-04-22T15:30:00Z")!
        let updatedAt = ISO8601DateFormatter().date(from: "2026-04-22T15:15:00Z")!
        let snapshot = ParkingActivitySnapshot(
            sessionID: sessionID,
            locationName: "Activity Lot",
            startDate: ISO8601DateFormatter().date(from: "2026-04-22T15:00:00Z")!,
            scheduledEndDate: expectedEnd,
            lastUpdatedDate: updatedAt
        )

        let attributes = ParkingReminderActivityAttributes(snapshot: snapshot)
        let state = ParkingReminderActivityAttributes.ContentState(snapshot: snapshot)

        XCTAssertEqual(attributes.sessionID, sessionID.uuidString)
        XCTAssertEqual(attributes.locationName, "Activity Lot")
        XCTAssertEqual(attributes.startDate, snapshot.startDate)
        XCTAssertEqual(state.sessionID, sessionID.uuidString)
        XCTAssertEqual(state.locationName, "Activity Lot")
        XCTAssertEqual(state.startDate, snapshot.startDate)
        XCTAssertEqual(state.scheduledEndDate, expectedEnd)
        XCTAssertEqual(state.lastUpdatedDate, updatedAt)
    }

    // TC-08 (P0) History map detail integrity (persistence fields)
    func test_TC08_NotePersistence_RoundTrip() throws {
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent("parking_sessions_\(UUID().uuidString).json")
        let storage = ParkingSessionStorageService(fileURL: tmp)

        let start = ISO8601DateFormatter().date(from: "2026-04-22T15:00:00Z")!
        let s = ParkingSession(
            locationName: "Lot A",
            latitude: 1,
            longitude: 2,
            startTime: start,
            expectedEndTime: start.addingTimeInterval(60),
            actualEndTime: start.addingTimeInterval(30),
            note: "remember pillar B",
            persistedStatus: .completed
        )

        try storage.save([s])
        let loaded = try storage.load()

        XCTAssertEqual(loaded, [s])
        XCTAssertEqual(loaded.first?.note, "remember pillar B")
    }

    func test_Phase1HistoryTiming_RestoredCompletedOverdueSessionStillCountsOverdue() throws {
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent("parking_sessions_\(UUID().uuidString).json")
        let storage = ParkingSessionStorageService(fileURL: tmp)
        let notifications = RecordingNotificationService()

        let start = ISO8601DateFormatter().date(from: "2026-04-22T15:00:00Z")!
        let session = ParkingSession(
            locationName: "Restored Late Lot",
            latitude: 43.6532,
            longitude: -79.3832,
            startTime: start,
            expectedEndTime: start.addingTimeInterval(60),
            actualEndTime: start.addingTimeInterval(210),
            note: "",
            persistedStatus: .completed
        )

        try storage.save([session])

        let store = ParkingSessionStore(
            storage: storage,
            notifications: notifications,
            nowProvider: { start.addingTimeInterval(300) }
        )
        store.start()
        let restored = try XCTUnwrap(store.sessions.first)
        let group = ParkingSpotGroup(
            id: "restored-late-lot",
            coordinate: .init(latitude: 43.6532, longitude: -79.3832),
            name: "Restored Late Lot",
            sessions: [restored]
        )
        let summary = group.timingSummary(now: start.addingTimeInterval(300))

        XCTAssertEqual(restored.persistedStatus, .completed)
        XCTAssertEqual(restored.timingOutcome(now: start.addingTimeInterval(300)).result, .overdue)
        XCTAssertEqual(restored.timingOutcome(now: start.addingTimeInterval(300)).overdueDuration, 150)
        XCTAssertEqual(summary.onTime, 0)
        XCTAssertEqual(summary.active, 0)
        XCTAssertEqual(summary.overdue, 1)
    }

    func test_Phase2Storage_SaveWritesVersionedEnvelope() throws {
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent("parking_sessions_\(UUID().uuidString).json")
        let storage = ParkingSessionStorageService(fileURL: tmp)
        let session = makeSession(locationName: "Versioned Lot")

        try storage.save([session])

        let raw = try Data(contentsOf: tmp)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: raw) as? [String: Any])
        XCTAssertEqual(object["schemaVersion"] as? Int, ParkingSessionStorageService.currentSchemaVersion)
        XCTAssertNotNil(object["savedAt"])

        let rawSessions = try XCTUnwrap(object["sessions"] as? [[String: Any]])
        XCTAssertEqual(rawSessions.count, 1)
        XCTAssertEqual(rawSessions.first?["locationName"] as? String, "Versioned Lot")

        let loaded = try storage.load()
        XCTAssertEqual(loaded, [session])
    }

    func test_Phase2Storage_LoadsLegacyPhase1BareArray() throws {
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent("parking_sessions_\(UUID().uuidString).json")
        let storage = ParkingSessionStorageService(fileURL: tmp)
        let session = makeSession(locationName: "Legacy Lot")

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        try encoder.encode([session]).write(to: tmp, options: [.atomic])

        let loaded = try storage.load()
        XCTAssertEqual(loaded, [session])
    }

    func test_Phase2Storage_RejectsUnsupportedFutureSchemaVersion() throws {
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent("parking_sessions_\(UUID().uuidString).json")
        let storage = ParkingSessionStorageService(fileURL: tmp)
        let json = """
        {
          "savedAt": "2026-04-28T18:00:00Z",
          "schemaVersion": 999,
          "sessions": []
        }
        """
        try Data(json.utf8).write(to: tmp, options: [.atomic])

        XCTAssertThrowsError(try storage.load()) { error in
            XCTAssertEqual(error as? ParkingSessionStorageError, .unsupportedSchemaVersion(999))
        }
    }

    private func makeSession(locationName: String) -> ParkingSession {
        let start = ISO8601DateFormatter().date(from: "2026-04-22T15:00:00Z")!
        return ParkingSession(
            locationName: locationName,
            latitude: 1,
            longitude: 2,
            startTime: start,
            expectedEndTime: start.addingTimeInterval(60),
            actualEndTime: start.addingTimeInterval(30),
            note: "remember pillar B",
            persistedStatus: .completed
        )
    }

    private func makeActiveSession(locationName: String, start: Date, expectedEnd: Date) -> ParkingSession {
        ParkingSession(
            locationName: locationName,
            latitude: nil,
            longitude: nil,
            startTime: start,
            expectedEndTime: expectedEnd,
            actualEndTime: nil,
            note: "",
            persistedStatus: .active
        )
    }
}

// MARK: - Test fakes

private final class InMemoryStorage: ParkingSessionStorageServiceProtocol {
    private(set) var saved: [ParkingSession] = []
    func load() throws -> [ParkingSession] { saved }
    func save(_ sessions: [ParkingSession]) throws { saved = sessions }
}

private final class RecordingNotificationService: ParkingNotificationServiceProtocol {
    private(set) var scheduledSessionIDs: [UUID] = []
    private(set) var canceledSessionIDs: [UUID] = []

    func requestAuthorizationIfNeeded() async -> Bool { true }

    func scheduleNotifications(for session: ParkingSession) async {
        scheduledSessionIDs.append(session.id)
    }

    func cancelNotifications(for sessionID: UUID) async {
        canceledSessionIDs.append(sessionID)
    }
}

private final class RecordingActivityLifecycleManager: ParkingActivityLifecycleManaging {
    private(set) var startedSnapshots: [ParkingActivitySnapshot] = []
    private(set) var restoredSnapshots: [ParkingActivitySnapshot] = []
    private(set) var updatedSnapshots: [ParkingActivitySnapshot] = []
    private(set) var endedSessionIDs: [UUID] = []
    private(set) var noActiveSessionRestoreCount = 0

    func sessionStarted(_ snapshot: ParkingActivitySnapshot) {
        startedSnapshots.append(snapshot)
    }

    func activeSessionRestored(_ snapshot: ParkingActivitySnapshot) {
        restoredSnapshots.append(snapshot)
    }

    func activeSessionUpdated(_ snapshot: ParkingActivitySnapshot) {
        updatedSnapshots.append(snapshot)
    }

    func sessionEnded(sessionID: UUID) {
        endedSessionIDs.append(sessionID)
    }

    func noActiveSessionRestored() {
        noActiveSessionRestoreCount += 1
    }
}
