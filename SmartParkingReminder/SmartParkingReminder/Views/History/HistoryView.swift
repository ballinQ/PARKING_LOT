import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var store: ParkingSessionStore

    var body: some View {
        NavigationStack {
            HistoryMapView(sessions: store.sessions, now: store.now)
                .ignoresSafeArea(edges: .bottom)
                .navigationTitle("Map")
                .navigationBarTitleDisplayMode(.inline)
        }
    }
}
