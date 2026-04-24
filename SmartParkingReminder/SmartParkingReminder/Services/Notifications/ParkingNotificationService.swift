import Foundation
import UserNotifications

protocol ParkingNotificationServiceProtocol {
    func requestAuthorizationIfNeeded() async -> Bool
    func scheduleNotifications(for session: ParkingSession) async
    func cancelNotifications(for sessionID: UUID) async
}

// MARK: - Testable UNUserNotificationCenter wrapper

protocol UserNotificationCenterProtocol {
    func notificationSettings() async -> UNNotificationSettings
    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool
    func add(_ request: UNNotificationRequest) async throws
    func removePendingNotificationRequests(withIdentifiers identifiers: [String])
}

extension UNUserNotificationCenter: UserNotificationCenterProtocol {
    func add(_ request: UNNotificationRequest) async throws {
        let _: Void = try await withCheckedThrowingContinuation { continuation in
            add(request) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
}

final class ParkingNotificationService: ParkingNotificationServiceProtocol {
    private let center: UserNotificationCenterProtocol
    private let nowProvider: () -> Date

    init(
        center: UserNotificationCenterProtocol = UNUserNotificationCenter.current(),
        nowProvider: @escaping () -> Date = { Date() }
    ) {
        self.center = center
        self.nowProvider = nowProvider
    }

    func requestAuthorizationIfNeeded() async -> Bool {
        do {
            let settings = await center.notificationSettings()
            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                return true
            case .denied:
                return false
            case .notDetermined:
                return try await center.requestAuthorization(options: [.alert, .sound, .badge])
            @unknown default:
                return false
            }
        } catch {
            return false
        }
    }

    func scheduleNotifications(for session: ParkingSession) async {
        // Avoid stacking duplicates.
        await cancelNotifications(for: session.id)

        _ = await requestAuthorizationIfNeeded()

        let expiryDate = session.expectedEndTime
        let warningDate = expiryDate.addingTimeInterval(-15 * 60)
        let now = nowProvider()

        // If warning time is already in the past, skip it.
        if warningDate > now {
            let warning = makeRequest(
                id: warningID(for: session.id),
                title: "Parking expires soon",
                body: "\(session.locationName) expires in 15 minutes.",
                fireDate: warningDate
            )
            try? await center.add(warning)
        }

        // If expiry is already in the past, skip it.
        if expiryDate > now {
            let expiry = makeRequest(
                id: expiryID(for: session.id),
                title: "Parking expired",
                body: "\(session.locationName) has expired.",
                fireDate: expiryDate
            )
            try? await center.add(expiry)
        }
    }

    func cancelNotifications(for sessionID: UUID) async {
        let ids = [warningID(for: sessionID), expiryID(for: sessionID)]
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }

    // MARK: - Helpers

    private func makeRequest(id: String, title: String, body: String, fireDate: Date) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        return UNNotificationRequest(identifier: id, content: content, trigger: trigger)
    }

    func warningID(for id: UUID) -> String { "parking_warning_\(id.uuidString)" }
    func expiryID(for id: UUID) -> String { "parking_expiry_\(id.uuidString)" }
}
