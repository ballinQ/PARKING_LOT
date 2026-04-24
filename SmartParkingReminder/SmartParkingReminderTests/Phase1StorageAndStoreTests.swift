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
