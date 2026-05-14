import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var store: ParkingSessionStore
    let locationService: LocationServiceProtocol
    let modeTransitionNamespace: Namespace.ID

    var body: some View {
        NavigationStack {
            HistoryMapView(
                sessions: store.sessions,
                now: store.now,
                locationService: locationService,
                modeTransitionNamespace: modeTransitionNamespace
            )
                .ignoresSafeArea(edges: .bottom)
                .navigationTitle("Map")
                .navigationBarTitleDisplayMode(.inline)
        }
    }
}
