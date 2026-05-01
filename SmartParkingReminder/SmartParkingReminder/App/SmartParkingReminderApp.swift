import SwiftUI

@main
struct SmartParkingReminderApp: App {
    @StateObject private var store: ParkingSessionStore

    init() {
        let arguments = ProcessInfo.processInfo.arguments

        // UI tests should not be blocked by system permission prompts.
        #if DEBUG
        if arguments.contains("UI_TESTING") {
            let filename = ProcessInfo.processInfo.environment["UITEST_STORAGE_FILE"] ?? "parking_sessions_uitest.json"
            let storage = ParkingSessionStorageService(filename: filename)
            let notifications = ParkingNotificationService(center: NoopUserNotificationCenter())
            _store = StateObject(wrappedValue: ParkingSessionStore(storage: storage, notifications: notifications))
            return
        } else if arguments.contains("LIVE_ACTIVITY_TESTING") {
            let filename = ProcessInfo.processInfo.environment["LIVE_ACTIVITY_STORAGE_FILE"] ?? "parking_sessions_live_activity_test.json"
            let storage = ParkingSessionStorageService(filename: filename)
            let notifications = ParkingNotificationService(center: NoopUserNotificationCenter())
            let activityLifecycle: ParkingActivityLifecycleManaging
            if #available(iOS 16.2, *) {
                activityLifecycle = ActivityKitParkingActivityLifecycleManager(minimumUpdateInterval: 1)
            } else {
                activityLifecycle = NoopParkingActivityLifecycleManager()
            }
            _store = StateObject(wrappedValue: ParkingSessionStore(
                storage: storage,
                notifications: notifications,
                activityLifecycle: activityLifecycle
            ))
            return
        }
        #endif

        let activityLifecycle: ParkingActivityLifecycleManaging
        if #available(iOS 16.2, *) {
            activityLifecycle = ActivityKitParkingActivityLifecycleManager()
        } else {
            activityLifecycle = NoopParkingActivityLifecycleManager()
        }
        _store = StateObject(wrappedValue: ParkingSessionStore(activityLifecycle: activityLifecycle))
    }

    var body: some Scene {
        WindowGroup {
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("UI_TESTING")
                || ProcessInfo.processInfo.arguments.contains("LIVE_ACTIVITY_TESTING") {
                ContentView(locationService: UITestLocationService())
                    .environmentObject(store)
            } else {
                ContentView()
                    .environmentObject(store)
            }
            #else
            ContentView()
                .environmentObject(store)
            #endif
        }
    }
}

// MARK: - UI test helpers (DEBUG only)

#if DEBUG
import CoreLocation
import UserNotifications

/// A location service that returns a deterministic coordinate without prompting.
final class UITestLocationService: LocationService {
    override func currentCoordinateOnce() async -> CLLocationCoordinate2D? {
        CLLocationCoordinate2D(latitude: 43.6532, longitude: -79.3832) // Toronto-ish
    }
}

/// A notification center that records nothing and never prompts.
final class NoopUserNotificationCenter: UserNotificationCenterProtocol {
    func notificationSettings() async -> UNNotificationSettings {
        await UNUserNotificationCenter.current().notificationSettings()
    }

    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool { false }
    func add(_ request: UNNotificationRequest) async throws {}
    func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {}
}
#endif
