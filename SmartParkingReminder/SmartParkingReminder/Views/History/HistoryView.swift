import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var store: ParkingSessionStore
    let locationService: LocationServiceProtocol

    var body: some View {
        NavigationStack {
            HistoryMapView(
                sessions: store.sessions,
                now: store.now,
                locationService: locationService
            )
                .ignoresSafeArea(edges: .bottom)
                .navigationTitle("Map")
                .navigationBarTitleDisplayMode(.inline)
        }
    }
}
