import SwiftUI

@main
struct SmartParkingReminderApp: App {
    @StateObject private var store = ParkingSessionStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}
