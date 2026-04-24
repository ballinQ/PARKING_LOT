import MapKit
import SwiftUI

struct HistoryMapView: View {
    let sessions: [ParkingSession]
    let now: Date

    @StateObject private var vm = HistoryMapViewModel()
    private let mapHandoff = MapHandoffService()

    @State private var camera: MapCameraPosition = .automatic

    var body: some View {
        ZStack {
            if vm.groups.isEmpty && vm.searchCenter == nil {
                ContentUnavailableView(
                    "No Locations Yet",
                    systemImage: "map",
                    description: Text("Start sessions with location permission enabled, or search an address to check nearby history.")
                )
            } else {
                Map(position: $camera, selection: $vm.selectedGroupID) {
                    ForEach(vm.visibleGroups) { group in
                        Marker(markerTitle(for: group), coordinate: group.coordinate)
                            .tag(group.id)
                    }

                    if let searchCenter = vm.searchCenter {
                        Marker("Search Area", systemImage: "scope", coordinate: searchCenter)
                            .tint(.blue)
                    }
                }
                .accessibilityIdentifier(A11y.historyMap)
                .mapStyle(.standard)

                // UI tests: SwiftUI Map annotations are not consistently hittable.
                // Provide a deterministic hook that opens the first spot detail sheet.
                if ProcessInfo.processInfo.arguments.contains("UI_TESTING") {
                    Button("Open First Spot Detail") {
                        vm.selectedGroupID = vm.visibleGroups.first?.id
                    }
                    .accessibilityIdentifier(A11y.uiTestOpenFirstSpotDetail)
                    .opacity(0.01)
                }
            }

            VStack(spacing: 10) {
                searchControls

                if let statusText = vm.statusText {
                    Text(statusText)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .accessibilityIdentifier(A11y.historySearchStatus)
                }

                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 10)
        }
        .onAppear {
            vm.updateSessions(sessions)
            camera = vm.defaultCameraPosition()
        }
        .onChange(of: sessions.count) { _, _ in
            vm.updateSessions(sessions)
        }
        .onChange(of: vm.visibleGroups.map(\.id)) { _, _ in
            if vm.searchCenter == nil {
                camera = vm.defaultCameraPosition()
            }
        }
        // UX rule: marker tap => show details; navigation only from buttons inside the sheet.
        .sheet(item: $vm.selectedGroup) { group in
            ParkingSpotDetailSheetView(
                group: group,
                now: now,
                onOpenAppleMaps: {
                    mapHandoff.openDirections(to: group.coordinate, placeName: group.name, preferred: .appleMaps)
                },
                onOpenGoogleMaps: {
                    mapHandoff.openDirections(to: group.coordinate, placeName: group.name, preferred: .googleMaps)
                }
            )
            .presentationDetents([.medium, .large])
        }
    }

    private var searchControls: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Search address", text: $vm.searchText)
                .textInputAutocapitalization(.words)
                .submitLabel(.search)
                .accessibilityIdentifier(A11y.historySearchField)
                .onSubmit {
                    runSearch()
                }

            if vm.isSearching {
                ProgressView()
            } else if vm.searchCenter != nil {
                Button {
                    vm.clearSearch()
                    camera = vm.defaultCameraPosition()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .accessibilityLabel("Clear search")
                .accessibilityIdentifier(A11y.historyClearSearchButton)
            }

            Button {
                runSearch()
            } label: {
                Image(systemName: "arrow.forward.circle.fill")
                    .font(.title3)
            }
            .disabled(vm.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || vm.isSearching)
            .accessibilityLabel("Search address")
            .accessibilityIdentifier(A11y.historySearchButton)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 8, y: 3)
    }

    private func runSearch() {
        Task {
            if let coordinate = await vm.searchAddress() {
                camera = vm.cameraPosition(centeredOn: coordinate)
            }
        }
    }

    private func markerTitle(for group: ParkingSpotGroup) -> String {
        group.count <= 1 ? group.name : "\(group.name) (\(group.count))"
    }
}
