import MapKit
import SwiftUI

struct HistoryMapView: View {
    let sessions: [ParkingSession]
    let now: Date

    @StateObject private var vm = HistoryMapViewModel()
    private let mapHandoff = MapHandoffService()

    @State private var camera: MapCameraPosition = .automatic
    @State private var showsPersonalHistory = true

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                mapContent
                topSearchOverlay
                personalHistoryOverlay(maxWidth: min(proxy.size.width * 0.72, 280))
            }
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

    @ViewBuilder
    private var mapContent: some View {
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
                    vm.selectFirstVisibleGroup()
                }
                .accessibilityIdentifier(A11y.uiTestOpenFirstSpotDetail)
                .opacity(0.01)
            }
        }
    }

    private var topSearchOverlay: some View {
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

    private func personalHistoryOverlay(maxWidth: CGFloat) -> some View {
        HStack(spacing: 0) {
            if showsPersonalHistory {
                personalHistoryPanel(maxWidth: maxWidth)
                    .transition(.move(edge: .leading).combined(with: .opacity))
            }

            Button {
                withAnimation(.snappy) {
                    showsPersonalHistory.toggle()
                }
            } label: {
                Image(systemName: showsPersonalHistory ? "chevron.left" : "chevron.right")
                    .font(.headline)
                    .frame(width: 34, height: 54)
                    .background(.regularMaterial)
                    .clipShape(UnevenRoundedRectangle(
                        topLeadingRadius: showsPersonalHistory ? 0 : 8,
                        bottomLeadingRadius: showsPersonalHistory ? 0 : 8,
                        bottomTrailingRadius: 8,
                        topTrailingRadius: 8
                    ))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(showsPersonalHistory ? "Hide personal history" : "Show personal history")

            Spacer()
        }
        .padding(.top, 86)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func personalHistoryPanel(maxWidth: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Personal History", systemImage: "clock.arrow.circlepath")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                Text("\(vm.visibleGroups.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()

            if vm.visibleGroups.isEmpty {
                Text("No saved spots nearby")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 6)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(vm.visibleGroups.prefix(8)) { group in
                            Button {
                                vm.selectGroup(group)
                                camera = vm.cameraPosition(centeredOn: group.coordinate)
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "mappin.circle.fill")
                                            .foregroundStyle(.blue)
                                        Text(group.name)
                                            .font(.footnote)
                                            .fontWeight(.semibold)
                                            .lineLimit(1)
                                        Spacer(minLength: 0)
                                    }

                                    Text("\(group.count) session\(group.count == 1 ? "" : "s")")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 7)
                                .padding(.horizontal, 8)
                                .background(.thinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier(A11y.historyPersonalSpotButton)
                        }
                    }
                }
                .frame(maxHeight: 280)
            }
        }
        .padding(12)
        .frame(width: maxWidth)
        .background(.regularMaterial)
        .clipShape(UnevenRoundedRectangle(
            topLeadingRadius: 0,
            bottomLeadingRadius: 0,
            bottomTrailingRadius: 8,
            topTrailingRadius: 8
        ))
        .shadow(color: .black.opacity(0.14), radius: 8, y: 3)
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
