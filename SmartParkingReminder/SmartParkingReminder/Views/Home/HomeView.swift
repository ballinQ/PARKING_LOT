import SwiftUI

struct HomeView: View {
    @EnvironmentObject var store: ParkingSessionStore

    @State private var showingNewSession = false
    @State private var quickStartMinutesInFlight: Int?

    let locationService: LocationServiceProtocol

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                if let active = store.activeSession {
                    ActiveSessionCardView(
                        session: active,
                        timerDisplay: store.timerDisplay(for: active)
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

                    QuickStartParkingView(
                        locationName: store.suggestedQuickStartLocationName,
                        inFlightMinutes: quickStartMinutesInFlight,
                        start: { minutes in
                            Task { await quickStart(minutes: minutes) }
                        }
                    )
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

    private func quickStart(minutes: Int) async {
        guard quickStartMinutesInFlight == nil else { return }
        quickStartMinutesInFlight = minutes
        defer { quickStartMinutesInFlight = nil }

        let coordinate = await locationService.currentCoordinateOnce()
        let coordTuple = coordinate.map { (lat: $0.latitude, lon: $0.longitude) }

        await store.startNewSession(from: .quickStart(
            locationName: store.suggestedQuickStartLocationName,
            durationMinutes: minutes,
            coordinate: coordTuple
        ))
    }
}

private struct QuickStartParkingView: View {
    let locationName: String
    let inFlightMinutes: Int?
    let start: (Int) -> Void

    private let durations = [30, 60, 120]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Quick Start", systemImage: "timer")
                    .font(.headline)
                    .accessibilityIdentifier(A11y.homeQuickStartPanel)
                Spacer()
                Text(locationName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            HStack(spacing: 10) {
                ForEach(durations, id: \.self) { minutes in
                    Button {
                        start(minutes)
                    } label: {
                        Label(durationLabel(for: minutes), systemImage: "play.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(inFlightMinutes != nil)
                    .accessibilityIdentifier(A11y.homeQuickStartButton(minutes: minutes))
                }
            }
        }
    }

    private func durationLabel(for minutes: Int) -> String {
        if minutes < 60 { return "\(minutes)m" }
        return "\(minutes / 60)h"
    }
}
