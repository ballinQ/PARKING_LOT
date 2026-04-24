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
                .tabItem { Label("History", systemImage: "clock") }
                .accessibilityIdentifier(A11y.tabHistory)
        }
        .onAppear {
            store.start()
        }
    }
}
