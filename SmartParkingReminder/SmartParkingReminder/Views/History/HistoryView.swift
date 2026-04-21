import SwiftUI

struct HistoryView: View {
    enum Mode: String, CaseIterable {
        case list = "List"
        case map = "Map"
    }

    @EnvironmentObject var store: ParkingSessionStore
    @State private var mode: Mode = .list

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Mode", selection: $mode) {
                    ForEach(Mode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding([.horizontal, .top])

                Group {
                    switch mode {
                    case .list:
                        listView
                    case .map:
                        HistoryMapView(sessions: store.sessions, now: store.now)
                            .padding(.top, 8)
                    }
                }
                .animation(.default, value: mode)
            }
            .navigationTitle("History")
        }
    }

    private var listView: some View {
        List {
            if store.sessions.isEmpty {
                ContentUnavailableView(
                    "No History Yet",
                    systemImage: "clock",
                    description: Text("Start and end a parking session to see it here.")
                )
                .listRowSeparator(.hidden)
            } else {
                ForEach(store.sessions) { session in
                    SessionRowView(session: session, now: store.now)
                }
            }
        }
    }
}
