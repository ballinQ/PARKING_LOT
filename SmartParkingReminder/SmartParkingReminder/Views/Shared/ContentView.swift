import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: ParkingSessionStore
    @StateObject private var locationService: LocationService
    @State private var selectedMode: AppMode = .home

    init(locationService: LocationService = LocationService()) {
        _locationService = StateObject(wrappedValue: locationService)
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            switch selectedMode {
            case .home:
                HomeView(locationService: locationService)
                    .accessibilityIdentifier(A11y.tabHome)
                    .transition(.opacity)

            case .map:
                HistoryView(locationService: locationService)
                    .accessibilityIdentifier(A11y.tabHistory)
                    .transition(.opacity)
            }

            FloatingModeSwitchButton(mode: selectedMode) {
                withAnimation(.snappy) {
                    selectedMode = selectedMode.toggled()
                }
            }
            .padding(.leading, 16)
            .padding(.bottom, selectedMode.switchBottomPadding)
        }
        .onAppear {
            store.start()
            seedActiveSessionForUITestingIfNeeded()
        }
    }

    private func seedActiveSessionForUITestingIfNeeded() {
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        let environment = ProcessInfo.processInfo.environment
        guard arguments.contains("UI_TESTING") || arguments.contains("LIVE_ACTIVITY_TESTING"),
              let offsetText = environment["UITEST_ACTIVE_SESSION_OFFSET_SECONDS"] ?? environment["LIVE_ACTIVITY_SESSION_OFFSET_SECONDS"],
              let offset = TimeInterval(offsetText),
              store.activeSession == nil
        else { return }

        let locationName = environment["UITEST_ACTIVE_SESSION_LOCATION"]
            ?? environment["LIVE_ACTIVITY_SESSION_LOCATION"]
            ?? "UI Test Parking"
        let note = arguments.contains("LIVE_ACTIVITY_TESTING")
            ? "Seeded by Live Activity verification"
            : "Seeded by UI test"
        Task {
            await store.startNewSession(
                locationName: locationName,
                duration: offset,
                note: note,
                coordinate: (lat: 43.6532, lon: -79.3832)
            )

            if arguments.contains("LIVE_ACTIVITY_TESTING"),
               let autoEndText = environment["LIVE_ACTIVITY_AUTO_END_AFTER_SECONDS"],
               let autoEndDelay = TimeInterval(autoEndText),
               autoEndDelay > 0 {
                try? await Task.sleep(nanoseconds: UInt64(autoEndDelay * 1_000_000_000))
                await store.endActiveSession()
            }
        }
        #endif
    }
}

private enum AppMode {
    case home
    case map

    var switchSystemImage: String {
        switch self {
        case .home:
            return "map.fill"
        case .map:
            return "house.fill"
        }
    }

    var switchAccessibilityLabel: String {
        switch self {
        case .home:
            return "Switch to Map"
        case .map:
            return "Switch to Home"
        }
    }

    var switchAccessibilityIdentifier: String {
        switch self {
        case .home:
            return A11y.modeSwitchMapButton
        case .map:
            return A11y.modeSwitchHomeButton
        }
    }

    var switchBottomPadding: CGFloat {
        switch self {
        case .home:
            return 92
        case .map:
            return 138
        }
    }

    func toggled() -> AppMode {
        switch self {
        case .home:
            return .map
        case .map:
            return .home
        }
    }
}

private struct FloatingModeSwitchButton: View {
    let mode: AppMode
    let toggle: () -> Void

    var body: some View {
        Button(action: toggle) {
            Image(systemName: mode.switchSystemImage)
                .font(.title3.weight(.semibold))
                .frame(width: 52, height: 52)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.primary)
        .background(.ultraThinMaterial)
        .clipShape(Circle())
        .overlay {
            Circle()
                .stroke(Color(.separator).opacity(0.32), lineWidth: 0.5)
        }
        .shadow(color: .black.opacity(0.20), radius: 14, y: 6)
        .accessibilityLabel(mode.switchAccessibilityLabel)
        .accessibilityIdentifier(mode.switchAccessibilityIdentifier)
    }
}
