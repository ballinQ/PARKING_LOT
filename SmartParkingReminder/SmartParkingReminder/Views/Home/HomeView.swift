import SwiftUI

struct HomeView: View {
    @EnvironmentObject var store: ParkingSessionStore

    @State private var showingNewSession = false
    @State private var quickStartMinutesInFlight: Int?

    let locationService: LocationServiceProtocol

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        if let active = store.activeSession {
                            Text("Current Session")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .textCase(.uppercase)
                                .tracking(0.5)

                            ActiveSessionCardView(
                                session: active,
                                timerDisplay: store.timerDisplay(for: active)
                            )

                            VStack(alignment: .leading, spacing: 10) {
                                Label("Parked Location", systemImage: "map")
                                    .font(.subheadline.weight(.semibold))

                                ActiveSessionMapView(session: active)
                                    .frame(height: 220)
                                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                                            .stroke(Color(.separator).opacity(0.35), lineWidth: 0.5)
                                    }
                            }

                            Button(role: .destructive) {
                                Task { await store.endActiveSession() }
                            } label: {
                                Label("End Parking", systemImage: "stop.circle.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .accessibilityIdentifier(A11y.homeEndParkingButton)
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                        } else {
                            NoActiveSessionPanel()

                            QuickStartParkingView(
                                locationName: store.quickStartLocationName,
                                durationOptions: store.quickStartDurationOptions,
                                inFlightMinutes: quickStartMinutesInFlight,
                                start: { minutes in
                                    Task { await quickStart(minutes: minutes) }
                                }
                            )

                            startParkingButton
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Smart Parking")
            .toolbar {
                if store.activeSession != nil {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showingNewSession = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                        }
                        .accessibilityLabel("Start Parking")
                        .accessibilityIdentifier(A11y.homeStartParkingButton)
                    }
                }
            }
            .sheet(isPresented: $showingNewSession) {
                NewSessionView(locationService: locationService)
            }
        }
    }

    private var startParkingButton: some View {
        Button {
            showingNewSession = true
        } label: {
            Label("Start Parking", systemImage: "plus.circle.fill")
                .frame(maxWidth: .infinity)
        }
        .accessibilityIdentifier(A11y.homeStartParkingButton)
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
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

private struct NoActiveSessionPanel: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Image(systemName: "parkingsign.circle.fill")
                .font(.system(size: 44))
                .foregroundStyle(.blue)

            VStack(alignment: .leading, spacing: 5) {
                Text("No Active Session")
                    .font(.title3.weight(.semibold))

                Text("Start parking to save your spot, track time, and get local reminders.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color(.separator).opacity(0.35), lineWidth: 0.5)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(A11y.homeNoActiveSessionView)
    }
}

private struct QuickStartParkingView: View {
    let locationName: String
    let durationOptions: [Int]
    let inFlightMinutes: Int?
    let start: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Label("Quick Start", systemImage: "timer")
                    .font(.headline.weight(.semibold))
                    .accessibilityIdentifier(A11y.homeQuickStartPanel)

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
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color(.separator).opacity(0.35), lineWidth: 0.5)
        }
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
        .controlSize(.regular)
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
