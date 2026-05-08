import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: ParkingSessionStore
    @StateObject private var locationService: LocationService

    init(locationService: LocationService = LocationService()) {
        _locationService = StateObject(wrappedValue: locationService)
    }

    var body: some View {
        TabView {
            HomeView(locationService: locationService)
                .tabItem { Label("Home", systemImage: "house") }
                .accessibilityIdentifier(A11y.tabHome)

            HistoryView(locationService: locationService)
                .tabItem { Label("Map", systemImage: "map") }
                .accessibilityIdentifier(A11y.tabHistory)
        }
        .onAppear {
            store.start()
            seedActiveSessionForUITestingIfNeeded()
        }
    }

    private func seedActiveSessionForUITestingIfNeeded() {
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        let environment = ProcessInfo.processInfo.environment
        guard arguments.contains("UI_TESTING") || arguments.contains("LIVE_ACTIVITY_TESTING"),
              let offsetText = environment["UITEST_ACTIVE_SESSION_OFFSET_SECONDS"] ?? environment["LIVE_ACTIVITY_SESSION_OFFSET_SECONDS"],
              let offset = TimeInterval(offsetText),
              store.activeSession == nil
        else { return }

        let locationName = environment["UITEST_ACTIVE_SESSION_LOCATION"]
            ?? environment["LIVE_ACTIVITY_SESSION_LOCATION"]
            ?? "UI Test Parking"
        let note = arguments.contains("LIVE_ACTIVITY_TESTING")
            ? "Seeded by Live Activity verification"
            : "Seeded by UI test"
        Task {
            await store.startNewSession(
                locationName: locationName,
                duration: offset,
                note: note,
                coordinate: (lat: 43.6532, lon: -79.3832)
            )

            if arguments.contains("LIVE_ACTIVITY_TESTING"),
               let autoEndText = environment["LIVE_ACTIVITY_AUTO_END_AFTER_SECONDS"],
               let autoEndDelay = TimeInterval(autoEndText),
               autoEndDelay > 0 {
                try? await Task.sleep(nanoseconds: UInt64(autoEndDelay * 1_000_000_000))
                await store.endActiveSession()
            }
        }
        #endif
    }
}
