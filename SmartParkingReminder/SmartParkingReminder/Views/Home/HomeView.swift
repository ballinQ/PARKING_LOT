import SwiftUI

struct HomeView: View {
    @EnvironmentObject var store: ParkingSessionStore

    @State private var showingNewSession = false

    let locationService: LocationServiceProtocol

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                if let active = store.activeSession {
                    ActiveSessionCardView(
                        session: active,
                        remainingText: store.remainingTimeString(for: active)
                    )

                    // Map preview of the active parking location (if available).
                    ActiveSessionMapView(session: active)
                        .frame(height: 220)

                    Button(role: .destructive) {
                        Task { await store.endActiveSession() }
                    } label: {
                        Text("End Parking")
                            .frame(maxWidth: .infinity)
                    }
                    .accessibilityIdentifier(A11y.homeEndParkingButton)
                    .buttonStyle(.borderedProminent)
                } else {
                    ContentUnavailableView(
                        "No Active Session",
                        systemImage: "parkingsign",
                        description: Text("Start a parking session to see the countdown and reminders.")
                    )
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier(A11y.homeNoActiveSessionView)
                }

                Spacer()

                Button {
                    showingNewSession = true
                } label: {
                    Text("Start Parking")
                        .frame(maxWidth: .infinity)
                }
                .accessibilityIdentifier(A11y.homeStartParkingButton)
                .buttonStyle(.borderedProminent)
                .sheet(isPresented: $showingNewSession) {
                    NewSessionView(locationService: locationService)
                }
            }
            .padding()
            .navigationTitle("Smart Parking")
        }
    }
}
