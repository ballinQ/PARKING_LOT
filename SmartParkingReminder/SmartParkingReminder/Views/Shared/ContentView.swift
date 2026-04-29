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

            HistoryView()
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
        let environment = ProcessInfo.processInfo.environment
        guard ProcessInfo.processInfo.arguments.contains("UI_TESTING"),
              let offsetText = environment["UITEST_ACTIVE_SESSION_OFFSET_SECONDS"],
              let offset = TimeInterval(offsetText),
              store.activeSession == nil
        else { return }

        let locationName = environment["UITEST_ACTIVE_SESSION_LOCATION"] ?? "UI Test Parking"
        Task {
            await store.startNewSession(
                locationName: locationName,
                duration: offset,
                note: "Seeded by UI test",
                coordinate: (lat: 43.6532, lon: -79.3832)
            )
        }
        #endif
    }
}
