import MapKit
import SwiftUI

struct HistoryMapView: View {
    let sessions: [ParkingSession]
    let now: Date

    @StateObject private var vm = HistoryMapViewModel()
    private let mapHandoff = MapHandoffService()

    @State private var camera: MapCameraPosition = .automatic
    @State private var sheetState: MapSheetState = .collapsed
    @State private var detailReturnState: MapSheetState?
    @GestureState private var sheetDragOffset: CGFloat = 0
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .bottom) {
                mapContent
                    .ignoresSafeArea(edges: .bottom)

                uiTestDetailHook

                bottomSheet(in: proxy)
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
        .onChange(of: vm.selectedGroup?.id) { _, newValue in
            guard newValue != nil, let group = vm.selectedGroup else { return }
            if detailReturnState == nil {
                detailReturnState = vm.searchCenter == nil && vm.searchResults.isEmpty ? .collapsed : .expanded
            }
            camera = vm.cameraPosition(centeredOn: group.coordinate)
            withAnimation(.snappy) {
                sheetState = .expanded
            }
        }
        .onChange(of: isSearchFocused) { _, focused in
            guard focused else { return }
            withAnimation(.snappy) {
                sheetState = .expanded
            }
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
        }
    }

    @ViewBuilder
    private var uiTestDetailHook: some View {
        if ProcessInfo.processInfo.arguments.contains("UI_TESTING") {
            VStack {
                HStack {
                    Button("Open First Spot Detail") {
                        detailReturnState = .expanded
                        vm.selectFirstVisibleGroup()
                        withAnimation(.snappy) {
                            sheetState = .expanded
                        }
                    }
                    .accessibilityIdentifier(A11y.uiTestOpenFirstSpotDetail)
                    .frame(width: 180, height: 44)
                    .foregroundStyle(.clear)
                    .background(.clear)

                    Spacer()
                }
                Spacer()
            }
            .padding(.top, 52)
            .padding(.leading, 12)
        }
    }

    private func bottomSheet(in proxy: GeometryProxy) -> some View {
        let baseHeight = sheetHeight(for: sheetState, in: proxy)
        let height = min(
            sheetHeight(for: .expanded, in: proxy),
            max(sheetHeight(for: .collapsed, in: proxy), baseHeight - sheetDragOffset)
        )

        return VStack(spacing: 0) {
            dragHandle
                .padding(.top, 8)
                .padding(.bottom, 6)

            VStack(spacing: 12) {
                searchControls

                if sheetState != .collapsed {
                    sheetBody
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, max(proxy.safeAreaInsets.bottom, 12))
        }
        .frame(maxWidth: .infinity)
        .frame(height: height, alignment: .top)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.22), radius: 18, y: -4)
        .padding(.horizontal, 8)
        .padding(.bottom, 6)
        .gesture(sheetDragGesture)
        .animation(.snappy, value: sheetState)
    }

    private var dragHandle: some View {
        Capsule()
            .fill(.secondary.opacity(0.35))
            .frame(width: 38, height: 5)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.snappy) {
                    sheetState = sheetState == .collapsed ? .medium : .collapsed
                }
            }
    }

    @ViewBuilder
    private var sheetBody: some View {
        if let selectedGroup = vm.selectedGroup {
            ScrollView {
                ParkingSpotDetailSheetView(
                    group: selectedGroup,
                    now: now,
                    onBack: {
                        returnFromDetail()
                    },
                    onOpenAppleMaps: {
                        mapHandoff.openDirections(to: selectedGroup.coordinate, placeName: selectedGroup.name, preferred: .appleMaps)
                    },
                    onOpenGoogleMaps: {
                        mapHandoff.openDirections(to: selectedGroup.coordinate, placeName: selectedGroup.name, preferred: .googleMaps)
                    }
                )
                .padding(.horizontal, -16)
                .padding(.top, 2)
            }
        } else {
            switch sheetState {
            case .collapsed:
                EmptyView()
            case .medium:
                mediumContent
            case .expanded:
                expandedContent
            }
        }
    }

    private var mediumContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            accessibilityPanelMarker(identifier: A11y.historyPreviewPanel, label: "History preview panel")

            statusTextView

            radiusPicker

            personalHistoryHeader

            if vm.visibleGroups.isEmpty {
                emptyHistoryText
            } else {
                VStack(spacing: 8) {
                    ForEach(vm.visibleGroups.prefix(3)) { group in
                        personalHistorySpotButton(for: group)
                    }
                }
            }
        }
    }

    private var expandedContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                accessibilityPanelMarker(identifier: A11y.historySearchPanel, label: "History search panel")

                statusTextView

                radiusPicker

                if !vm.searchResults.isEmpty {
                    searchResultsSection
                }

                personalHistoryHeader

                if vm.visibleGroups.isEmpty {
                    emptyHistoryText
                } else {
                    VStack(spacing: 8) {
                        ForEach(vm.visibleGroups) { group in
                            personalHistorySpotButton(for: group)
                        }
                    }
                }
            }
            .padding(.bottom, 18)
        }
    }

    private func accessibilityPanelMarker(identifier: String, label: String) -> some View {
        Color.clear
            .frame(width: 1, height: 1)
            .accessibilityElement()
            .accessibilityLabel(label)
            .accessibilityIdentifier(identifier)
    }

    @ViewBuilder
    private var statusTextView: some View {
        if let statusText = vm.statusText {
            Text(statusText)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityIdentifier(A11y.historySearchStatus)
        }
    }

    @ViewBuilder
    private var radiusPicker: some View {
        if vm.searchCenter != nil {
            HStack(spacing: 6) {
                ForEach(HistorySearchRadius.allCases) { radius in
                    Button {
                        vm.searchRadius = radius
                    } label: {
                        Text(radius.label)
                            .font(.caption.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 7)
                            .foregroundStyle(vm.searchRadius == radius ? .white : .primary)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(vm.searchRadius == radius ? Color.blue : Color(.secondarySystemFill))
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Search radius \(radius.label)")
                }
            }
            .accessibilityIdentifier(A11y.historySearchRadiusPicker)
        }
    }

    private var personalHistoryHeader: some View {
        HStack(spacing: 10) {
            Image(systemName: "clock.arrow.circlepath")
                .foregroundStyle(.blue)

            VStack(alignment: .leading, spacing: 2) {
                Text("Personal History")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(personalHistorySummaryText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if sheetState == .medium {
                Button {
                    withAnimation(.snappy) {
                        sheetState = .expanded
                    }
                } label: {
                    Image(systemName: "chevron.up")
                        .font(.footnote.weight(.semibold))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .accessibilityIdentifier(A11y.historyPersonalHistoryToggle)
                .accessibilityLabel("Expand personal history")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var emptyHistoryText: some View {
        Text(vm.searchCenter == nil ? "No saved spots yet" : "No saved spots nearby")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 4)
    }

    private var searchResultsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Address Results")
                .font(.footnote)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            ForEach(vm.searchResults.prefix(8)) { result in
                Button {
                    vm.selectSearchResult(result)
                    camera = vm.cameraPosition(centeredOn: result.coordinate)
                    isSearchFocused = false
                    withAnimation(.snappy) {
                        sheetState = .expanded
                    }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass.circle.fill")
                            .foregroundStyle(.blue)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(result.title)
                                .font(.footnote)
                                .fontWeight(.semibold)
                                .lineLimit(1)

                            if !result.subtitle.isEmpty {
                                Text(result.subtitle)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }

                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 10)
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func personalHistorySpotButton(for group: ParkingSpotGroup) -> some View {
        Button {
            detailReturnState = sheetState == .collapsed ? .medium : sheetState
            vm.selectGroup(group)
            camera = vm.cameraPosition(centeredOn: group.coordinate)
            isSearchFocused = false
            withAnimation(.snappy) {
                sheetState = .expanded
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "mappin.circle.fill")
                    .foregroundStyle(.blue)

                VStack(alignment: .leading, spacing: 2) {
                    Text(group.name)
                        .font(.footnote)
                        .fontWeight(.semibold)
                        .lineLimit(1)

                    Text("\(group.count) session\(group.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(A11y.historyPersonalSpotButton)
    }

    private var searchControls: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField(
                "Search address or saved spot",
                text: Binding(
                    get: { vm.searchText },
                    set: { vm.updateSearchText($0) }
                )
            )
                .focused($isSearchFocused)
                .textInputAutocapitalization(.words)
                .submitLabel(.search)
                .accessibilityIdentifier(A11y.historySearchField)
                .onTapGesture {
                    withAnimation(.snappy) {
                        sheetState = .expanded
                    }
                }
                .onSubmit {
                    runSearch()
                }

            if vm.isSearching {
                ProgressView()
            } else if !vm.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || vm.searchCenter != nil || !vm.searchResults.isEmpty {
                Button {
                    vm.clearSearch()
                    detailReturnState = nil
                    camera = vm.defaultCameraPosition()
                    withAnimation(.snappy) {
                        sheetState = .collapsed
                    }
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
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var sheetDragGesture: some Gesture {
        DragGesture(minimumDistance: 8)
            .updating($sheetDragOffset) { value, state, _ in
                state = value.translation.height
            }
            .onEnded { value in
                let translation = value.translation.height
                withAnimation(.snappy) {
                    if translation < -45 {
                        sheetState = sheetState.expanded()
                    } else if translation > 45 {
                        sheetState = sheetState.collapsed()
                    }
                }
            }
    }

    private func runSearch() {
        vm.clearSelection()
        detailReturnState = nil
        withAnimation(.snappy) {
            sheetState = .expanded
        }

        Task {
            let results = await vm.searchAddressResults()
            if results.count == 1, let result = results.first {
                vm.selectSearchResult(result)
                camera = vm.cameraPosition(centeredOn: result.coordinate)
            }
        }
    }

    private func returnFromDetail() {
        let nextState = detailReturnState ?? .collapsed
        detailReturnState = nil
        vm.clearSelection()
        isSearchFocused = false

        withAnimation(.snappy) {
            sheetState = nextState
        }
    }

    private func sheetHeight(for state: MapSheetState, in proxy: GeometryProxy) -> CGFloat {
        let availableHeight = proxy.size.height
        switch state {
        case .collapsed:
            return 118 + max(proxy.safeAreaInsets.bottom, 8)
        case .medium:
            return min(320, availableHeight * 0.42)
        case .expanded:
            return max(360, availableHeight * 0.78)
        }
    }

    private var personalHistorySummaryText: String {
        if vm.isSearching {
            return "Searching address..."
        }

        let count = vm.visibleGroups.count
        if count == 0 {
            return vm.searchCenter == nil ? "No saved spots yet" : "No saved spots nearby"
        }

        return "\(count) saved spot\(count == 1 ? "" : "s") nearby"
    }

    private func markerTitle(for group: ParkingSpotGroup) -> String {
        group.count <= 1 ? group.name : "\(group.name) (\(group.count))"
    }
}

private enum MapSheetState {
    case collapsed
    case medium
    case expanded

    func expanded() -> MapSheetState {
        switch self {
        case .collapsed:
            return .medium
        case .medium, .expanded:
            return .expanded
        }
    }

    func collapsed() -> MapSheetState {
        switch self {
        case .collapsed, .medium:
            return .collapsed
        case .expanded:
            return .medium
        }
    }
}
