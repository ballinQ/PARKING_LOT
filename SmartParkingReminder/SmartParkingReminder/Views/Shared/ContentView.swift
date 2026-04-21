import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: ParkingSessionStore
    @StateObject private var locationService = LocationService()

    var body: some View {
        TabView {
            HomeView(locationService: locationService)
                .tabItem { Label("Home", systemImage: "house") }

            HistoryView()
                .tabItem { Label("History", systemImage: "clock") }
        }
        .onAppear {
            store.start()
        }
    }
}
