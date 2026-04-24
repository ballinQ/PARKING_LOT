import XCTest
import CoreLocation
import UserNotifications
@testable import SmartParkingReminder

final class Phase1NotificationAndHandoffTests: XCTestCase {

    // TC-05 (P0) T-15 scheduling request (request-level)
    // TC-06 (P0) Expiry scheduling request (request-level)
    func test_TC05_TC06_NotificationRequestsScheduled_WhenFutureTimes() async throws {
        let fakeCenter = RecordingUserNotificationCenter(authorizationStatus: .authorized)

        let now = ISO8601DateFormatter().date(from: "2026-04-22T15:00:00Z")!
        let service = ParkingNotificationService(center: fakeCenter, nowProvider: { now })

        let expiry = now.addingTimeInterval(16 * 60)
        let s = ParkingSession(
            locationName: "Lot A",
            latitude: nil,
            longitude: nil,
            startTime: now,
            expectedEndTime: expiry,
            actualEndTime: nil,
            note: "",
            persistedStatus: .active
        )

        await service.scheduleNotifications(for: s)

        // Should cancel first to avoid duplicates
        XCTAssertEqual(fakeCenter.removedIdentifiers.count, 1)

        // Should schedule 2 notifications: warning + expiry
        XCTAssertEqual(fakeCenter.addedRequests.count, 2)
        XCTAssertTrue(fakeCenter.addedRequests.contains(where: { $0.identifier.hasPrefix("parking_warning_") }))
        XCTAssertTrue(fakeCenter.addedRequests.contains(where: { $0.identifier.hasPrefix("parking_expiry_") }))
    }

    func test_TC05_WarningSkipped_WhenAlreadyPast() async throws {
        let fakeCenter = RecordingUserNotificationCenter(authorizationStatus: .authorized)

        let now = ISO8601DateFormatter().date(from: "2026-04-22T15:00:00Z")!
        let service = ParkingNotificationService(center: fakeCenter, nowProvider: { now })

        // Expiry in 10 minutes => warning date (expiry-15) is in the past.
        let expiry = now.addingTimeInterval(10 * 60)
        let s = ParkingSession(
            locationName: "Lot A",
            latitude: nil,
            longitude: nil,
            startTime: now,
            expectedEndTime: expiry,
            actualEndTime: nil,
            note: "",
            persistedStatus: .active
        )

        await service.scheduleNotifications(for: s)
        XCTAssertEqual(fakeCenter.addedRequests.count, 1)
        XCTAssertTrue(fakeCenter.addedRequests[0].identifier.hasPrefix("parking_expiry_"))
    }

    // TC-13 (P1) Navigation handoff actions (URL generation + graceful behavior)
    @MainActor
    func test_TC13_GoogleMapsURLGeneration() throws {
        let service = MapHandoffService(launcher: FakeURLLauncher(canOpen: true))
        let coord = CLLocationCoordinate2D(latitude: 43.6532, longitude: -79.3832)
        let url = try XCTUnwrap(service.googleMapsDirectionsURL(to: coord))
        XCTAssertTrue(url.absoluteString.hasPrefix("comgooglemaps://?daddr=43.6532,-79.3832"))
        XCTAssertTrue(url.absoluteString.contains("directionsmode=driving"))
    }
}

// MARK: - Fakes

private final class RecordingUserNotificationCenter: UserNotificationCenterProtocol {
    private let authorizationStatus: UNAuthorizationStatus

    init(authorizationStatus: UNAuthorizationStatus) {
        self.authorizationStatus = authorizationStatus
    }

    private(set) var addedRequests: [UNNotificationRequest] = []
    private(set) var removedIdentifiers: [[String]] = []
    private(set) var didRequestAuthorization = false

    func notificationSettings() async -> UNNotificationSettings {
        // UNNotificationSettings has no public initializer.
        // Use the real center's settings as a base, but we still record scheduling deterministically.
        // This means this test is *request-level* deterministic, not OS-settings deterministic.
        await UNUserNotificationCenter.current().notificationSettings()
    }

    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool {
        didRequestAuthorization = true
        return authorizationStatus == .authorized
    }

    func add(_ request: UNNotificationRequest) async throws {
        addedRequests.append(request)
    }

    func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
        removedIdentifiers.append(identifiers)
    }
}

private final class FakeURLLauncher: URLLaunching {
    private let canOpen: Bool
    init(canOpen: Bool) { self.canOpen = canOpen }

    func canOpenURL(_ url: URL) -> Bool { canOpen }
    func open(_ url: URL, options: [UIApplication.OpenExternalURLOptionsKey : Any], completionHandler: ((Bool) -> Void)?) {
        completionHandler?(true)
    }
}
