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
                        locationName: store.quickStartLocationName,
                        durationOptions: store.quickStartDurationOptions,
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
            durationMinutes: minutes,
            coordinate: coordTuple
        ))
    }
}

private struct QuickStartParkingView: View {
    let locationName: String
    let durationOptions: [Int]
    let inFlightMinutes: Int?
    let start: (Int) -> Void

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

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(durationOptions, id: \.self) { minutes in
                        quickStartButton(minutes: minutes)
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func quickStartButton(minutes: Int) -> some View {
        Button {
            start(minutes)
        } label: {
            HStack(spacing: 6) {
                if inFlightMinutes == minutes {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Image(systemName: "play.fill")
                        .font(.caption.weight(.semibold))
                }

                Text(durationLabel(for: minutes))
                    .fontWeight(.semibold)
            }
            .frame(minWidth: 82)
        }
        .buttonStyle(.bordered)
        .buttonBorderShape(.capsule)
        .disabled(inFlightMinutes != nil)
        .accessibilityIdentifier(A11y.homeQuickStartButton(minutes: minutes))
    }

    private func durationLabel(for minutes: Int) -> String {
        switch minutes {
        case ..<60:
            return "\(minutes)m"
        default:
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes == 0 { return "\(hours)h" }
            return "\(hours)h \(remainingMinutes)m"
        }
    }
}
