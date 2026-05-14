import MapKit
import SwiftUI
import UIKit

struct HistoryMapView: View {
    let sessions: [ParkingSession]
    let now: Date
    let locationService: LocationServiceProtocol
    let modeTransitionNamespace: Namespace.ID

    @StateObject private var vm = HistoryMapViewModel()
    private let mapHandoff = MapHandoffService()

    @State private var camera: MapCameraPosition = .automatic
    @State private var sheetState: MapSheetState = .collapsed
    @State private var detailReturnState: MapSheetState?
    @State private var isRelocating = false
    @State private var hasRequestedInitialLocationFocus = false
    @State private var lastKnownUserCoordinate: CLLocationCoordinate2D?
    @State private var keyboardHeight: CGFloat = 0
    @State private var visibleMapCenter: CLLocationCoordinate2D?
    @State private var shouldShowSearchThisArea = false
    @State private var ignoreCameraChangesUntil = Date.distantPast
    @GestureState private var sheetDragOffset: CGFloat = 0
    @FocusState private var isSearchFocused: Bool

    private let sheetBottomReservedSpace: CGFloat = 116
    private let sheetCompactBottomPadding: CGFloat = 16

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .bottom) {
                mapContent
                    .ignoresSafeArea(edges: .bottom)
                    .simultaneousGesture(
                        TapGesture().onEnded {
                            dismissKeyboard()
                        }
                    )

                uiTestDetailHook

                searchThisAreaButton(in: proxy)

                if shouldDisplayRelocateButton {
                    relocateButton(in: proxy)
                }

                bottomSheet(in: proxy)
            }
        }
        .onAppear {
            vm.updateSessions(sessions)
            requestInitialLocationFocusIfNeeded()
        }
        .onChange(of: sessions.count) { _, _ in
            vm.updateSessions(sessions)
        }
        .onChange(of: vm.visibleGroups.map(\.id)) { _, _ in
            if vm.searchCenter == nil && !hasRequestedInitialLocationFocus {
                setMapCamera(vm.defaultCameraPosition())
            }
        }
        .onChange(of: vm.selectedGroup?.id) { _, newValue in
            guard newValue != nil, let group = vm.selectedGroup else { return }
            if detailReturnState == nil {
                detailReturnState = vm.searchCenter == nil && vm.searchResults.isEmpty ? .collapsed : .expanded
            }
            setMapCamera(vm.cameraPosition(centeredOn: group.coordinate))
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
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)) { notification in
            updateKeyboardHeight(from: notification)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            withAnimation(.snappy) {
                keyboardHeight = 0
            }
        }
    }

    @ViewBuilder
    private var mapContent: some View {
        Map(position: $camera, selection: $vm.selectedGroupID) {
            UserAnnotation()

            ForEach(vm.personalHistoryMarkers) { marker in
                Marker(marker.title, coordinate: marker.coordinate)
                    .tag(marker.sourceID)
            }

            if let marker = vm.searchAreaMarker {
                Marker(marker.title, systemImage: "scope", coordinate: marker.coordinate)
                    .tint(.blue)
            }
        }
        .accessibilityIdentifier(A11y.historyMap)
        .mapStyle(.standard)
        .onMapCameraChange(frequency: .onEnd) { context in
            handleMapCameraChange(context)
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
        let keyboardLift = max(0, keyboardHeight - proxy.safeAreaInsets.bottom)
        let baseHeight = sheetHeight(for: sheetState, in: proxy)
        let height = min(
            max(sheetHeight(for: .collapsed, in: proxy), proxy.size.height - keyboardLift - 20),
            sheetHeight(for: .expanded, in: proxy),
            max(sheetHeight(for: .collapsed, in: proxy), baseHeight - sheetDragOffset)
        )

        return VStack(spacing: 0) {
            if sheetState != .collapsed {
                dragHandle
                    .padding(.top, 8)
                    .padding(.bottom, 6)
            }

            VStack(spacing: 12) {
                searchControls

                if sheetState != .collapsed {
                    sheetBody
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            .padding(.horizontal, 16)
            .padding(.trailing, sheetState == .collapsed ? 70 : 0)
            .padding(.bottom, max(proxy.safeAreaInsets.bottom, sheetCompactBottomPadding))
        }
        .frame(maxWidth: .infinity)
        .frame(height: height, alignment: .top)
        .background(sheetBackground)
        .clipShape(sheetShape)
        .overlay(alignment: .top) {
            if sheetState != .collapsed {
                sheetShape
                    .stroke(Color(.separator).opacity(0.25), lineWidth: 0.5)
            }
        }
        .shadow(color: .black.opacity(sheetState == .collapsed ? 0 : 0.22), radius: 18, y: -4)
        .padding(.horizontal, 8)
        .padding(.bottom, keyboardLift + (sheetState == .collapsed ? 0 : 6))
        .gesture(sheetDragGesture)
        .animation(.snappy, value: sheetState)
        .animation(.snappy, value: keyboardHeight)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    dismissKeyboard()
                }
            }
        }
    }

    @ViewBuilder
    private var sheetBackground: some View {
        if sheetState == .collapsed {
            Color.clear
        } else {
            Rectangle()
                .fill(.regularMaterial)
        }
    }

    private var sheetShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: sheetState == .collapsed ? 0 : 24, style: .continuous)
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
                    metadata: vm.metadata(for: selectedGroup),
                    now: now,
                    onBack: {
                        returnFromDetail()
                    },
                    onMetadataChange: { metadata in
                        vm.updateMetadata(metadata, for: selectedGroup)
                    },
                    onOpenAppleMaps: {
                        mapHandoff.openDirections(to: selectedGroup.coordinate, placeName: selectedGroup.displayName, preferred: .appleMaps)
                    },
                    onOpenGoogleMaps: {
                        mapHandoff.openDirections(to: selectedGroup.coordinate, placeName: selectedGroup.displayName, preferred: .googleMaps)
                    }
                )
                .padding(.horizontal, -16)
                .padding(.top, 2)
                .padding(.bottom, sheetBottomReservedSpace)
            }
            .scrollDismissesKeyboard(.interactively)
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

            mediumFilterControls

            personalHistoryHeader

            if vm.visibleGroups.isEmpty {
                emptyHistoryText
            } else {
                VStack(spacing: 8) {
                    ForEach(vm.visibleGroups.prefix(2)) { group in
                        personalHistorySpotButton(for: group)
                    }
                }
            }
        }
        .contentShape(Rectangle())
        .simultaneousGesture(
            TapGesture().onEnded {
                dismissKeyboard()
            }
        )
    }

    @ViewBuilder
    private var mediumFilterControls: some View {
        if vm.searchCenter != nil {
            radiusPicker
        }

        if vm.metadataFilter != .all || !vm.visibleGroups.isEmpty {
            metadataFilterPicker
        }
    }

    private var expandedContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                accessibilityPanelMarker(identifier: A11y.historySearchPanel, label: "History search panel")

                statusTextView

                radiusPicker

                metadataFilterPicker

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
            .padding(.bottom, sheetBottomReservedSpace)
            .contentShape(Rectangle())
            .simultaneousGesture(
                TapGesture().onEnded {
                    dismissKeyboard()
                }
            )
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
                        selectSearchRadius(radius)
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

    private var metadataFilterPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(HistorySpotMetadataFilter.allCases) { filter in
                    Button {
                        vm.metadataFilter = filter
                    } label: {
                        Text(filter.label)
                            .font(.caption.weight(.semibold))
                            .lineLimit(1)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .foregroundStyle(vm.metadataFilter == filter ? .white : .primary)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(vm.metadataFilter == filter ? Color.blue : Color(.secondarySystemFill))
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("History filter \(filter.label)")
                }
            }
        }
        .accessibilityIdentifier(A11y.historyMetadataFilterPicker)
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
                    selectSearchResult(result)
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
                    .overlay {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color(.separator).opacity(0.25), lineWidth: 0.5)
                    }
                }
                .buttonStyle(.plain)
                .highPriorityGesture(
                    TapGesture().onEnded {
                        selectSearchResult(result)
                    }
                )
            }
        }
    }

    private func personalHistorySpotButton(for group: ParkingSpotGroup) -> some View {
        Button {
            openSpotDetail(group)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "mappin.circle.fill")
                    .foregroundStyle(.blue)

                VStack(alignment: .leading, spacing: 2) {
                    Text(group.displayName)
                        .font(.footnote)
                        .fontWeight(.semibold)
                        .lineLimit(1)

                    HStack(spacing: 4) {
                        if group.metadata?.isFavorite == true {
                            Image(systemName: "heart.fill")
                                .font(.caption2)
                                .foregroundStyle(.red)
                        }

                        if let rating = group.metadata?.rating {
                            Text("\(rating) star")
                        }

                        Text("\(group.count) session\(group.count == 1 ? "" : "s")")
                    }
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
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color(.separator).opacity(0.25), lineWidth: 0.5)
            }
        }
        .buttonStyle(.plain)
        .highPriorityGesture(
            TapGesture().onEnded {
                openSpotDetail(group)
            }
        )
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
                    dismissKeyboard()
                    setMapCamera(HistoryMapViewModel.userLocationCameraPosition())
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
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.thinMaterial)
                .matchedGeometryEffect(
                    id: "modeSwitch.mapSearchMorph",
                    in: modeTransitionNamespace,
                    properties: .frame,
                    isSource: false
                )
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(.separator).opacity(0.25), lineWidth: 0.5)
        }
    }

    @ViewBuilder
    private func searchThisAreaButton(in proxy: GeometryProxy) -> some View {
        if shouldDisplaySearchThisAreaButton {
            VStack {
                HStack {
                    Spacer()

                    Button {
                        searchThisMapArea()
                    } label: {
                        Label("Search This Area", systemImage: "magnifyingglass")
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 9)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.primary)
                    .background(.regularMaterial)
                    .clipShape(Capsule(style: .continuous))
                    .shadow(color: .black.opacity(0.18), radius: 10, y: 4)
                    .accessibilityIdentifier(A11y.historySearchThisAreaButton)

                    Spacer()
                }
                .padding(.top, max(proxy.safeAreaInsets.top, 10))

                Spacer()
            }
            .transition(.opacity.combined(with: .move(edge: .top)))
            .animation(.snappy, value: shouldDisplaySearchThisAreaButton)
        }
    }

    private func relocateButton(in proxy: GeometryProxy) -> some View {
        VStack {
            Spacer()

            HStack {
                Spacer()

                Button {
                    relocateToCurrentLocation()
                } label: {
                    ZStack {
                        Image(systemName: "location.fill")
                            .font(.title3.weight(.semibold))
                            .opacity(isRelocating ? 0 : 1)

                        if isRelocating {
                            ProgressView()
                        }
                    }
                    .frame(width: 46, height: 46)
                }
                .disabled(isRelocating)
                .foregroundStyle(.blue)
                .background(.regularMaterial)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.18), radius: 10, y: 4)
                .accessibilityLabel("Relocate to current location")
                .accessibilityIdentifier(A11y.historyRelocateButton)
            }
            .padding(.trailing, 18)
            .padding(.bottom, sheetHeight(for: sheetState, in: proxy) + 18)
        }
        .animation(.snappy, value: sheetState)
    }

    private var sheetDragGesture: some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { _ in
                dismissKeyboard()
            }
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
        dismissKeyboard()
        vm.clearSelection()
        detailReturnState = nil
        shouldShowSearchThisArea = false
        withAnimation(.snappy) {
            sheetState = .expanded
        }

        Task {
            let results = await vm.searchAddressResults()
            if results.count == 1, let result = results.first {
                vm.selectSearchResult(result)
                withAnimation(.snappy) {
                    setMapCamera(vm.cameraPositionForSelectedRange(fallbackCenter: lastKnownUserCoordinate))
                }
            }
        }
    }

    private func selectSearchResult(_ result: HistoryMapSearchResult) {
        vm.selectSearchResult(result)
        shouldShowSearchThisArea = false
        withAnimation(.snappy) {
            setMapCamera(vm.cameraPositionForSelectedRange(fallbackCenter: lastKnownUserCoordinate))
        }
        dismissKeyboard()

        withAnimation(.snappy) {
            sheetState = .expanded
        }
    }

    private func selectSearchRadius(_ radius: HistorySearchRadius) {
        withAnimation(.snappy) {
            vm.selectedRangeMeters = radius.distance
            setMapCamera(vm.cameraPositionForSelectedRange(fallbackCenter: lastKnownUserCoordinate))
        }
    }

    private func openSpotDetail(_ group: ParkingSpotGroup) {
        detailReturnState = sheetState == .collapsed ? .medium : sheetState
        vm.selectGroup(group)
        shouldShowSearchThisArea = false
        setMapCamera(vm.cameraPosition(centeredOn: group.coordinate))
        dismissKeyboard()

        withAnimation(.snappy) {
            sheetState = .expanded
        }
    }

    private func relocateToCurrentLocation() {
        guard !isRelocating else { return }
        isRelocating = true
        dismissKeyboard()
        detailReturnState = nil
        shouldShowSearchThisArea = false
        setMapCamera(HistoryMapViewModel.userLocationCameraPosition())

        Task {
            defer { isRelocating = false }

            guard let coordinate = await locationService.currentCoordinateOnce() else {
                lastKnownUserCoordinate = nil
                vm.relocateToTorontoFallback()
                setMapCamera(vm.cameraPositionForSelectedRange(fallbackCenter: nil))
                withAnimation(.snappy) {
                    sheetState = .medium
                }
                return
            }

            lastKnownUserCoordinate = coordinate
            vm.relocateToCurrentLocation(coordinate)
            setMapCamera(vm.cameraPositionForSelectedRange(fallbackCenter: coordinate))

            withAnimation(.snappy) {
                sheetState = .medium
            }
        }
    }

    private func requestInitialLocationFocusIfNeeded() {
        guard !hasRequestedInitialLocationFocus else { return }
        hasRequestedInitialLocationFocus = true
        setMapCamera(HistoryMapViewModel.userLocationCameraPosition())

        Task {
            guard let coordinate = await locationService.currentCoordinateOnce() else {
                setMapCamera(HistoryMapViewModel.torontoFallbackCameraPosition())
                return
            }

            lastKnownUserCoordinate = coordinate
            vm.relocateToCurrentLocation(coordinate)
        }
    }

    private func returnFromDetail() {
        let nextState = detailReturnState ?? .collapsed
        detailReturnState = nil
        vm.clearSelection()
        dismissKeyboard()

        withAnimation(.snappy) {
            sheetState = nextState
        }
    }

    private func searchThisMapArea() {
        guard let center = visibleMapCenter else { return }
        vm.searchThisMapArea(center: center)
        shouldShowSearchThisArea = false
        dismissKeyboard()

        withAnimation(.snappy) {
            sheetState = .medium
        }
    }

    private func handleMapCameraChange(_ context: MapCameraUpdateContext) {
        let center = context.region.center
        visibleMapCenter = center

        guard Date() >= ignoreCameraChangesUntil else { return }
        guard vm.selectedGroup == nil else { return }
        guard isMeaningfullyAwayFromReference(center) else {
            shouldShowSearchThisArea = false
            return
        }

        shouldShowSearchThisArea = true
    }

    private func isMeaningfullyAwayFromReference(_ coordinate: CLLocationCoordinate2D) -> Bool {
        let reference = vm.searchCenter ?? lastKnownUserCoordinate ?? HistoryMapViewModel.torontoFallbackCoordinate
        let currentLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let referenceLocation = CLLocation(latitude: reference.latitude, longitude: reference.longitude)
        return currentLocation.distance(from: referenceLocation) > 75
    }

    private func setMapCamera(_ position: MapCameraPosition) {
        ignoreCameraChangesUntil = Date().addingTimeInterval(1.2)
        shouldShowSearchThisArea = false
        camera = position
    }

    private func dismissKeyboard() {
        isSearchFocused = false
    }

    private func updateKeyboardHeight(from notification: Notification) {
        guard let endFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
            return
        }

        let nextHeight = max(0, UIScreen.main.bounds.height - endFrame.minY)
        withAnimation(.snappy) {
            keyboardHeight = nextHeight
        }
    }

    private func sheetHeight(for state: MapSheetState, in proxy: GeometryProxy) -> CGFloat {
        let availableHeight = proxy.size.height
        let safeBottom = max(proxy.safeAreaInsets.bottom, 8)

        switch state {
        case .collapsed:
            return 106 + safeBottom
        case .medium:
            return min(max(286, availableHeight * 0.38), availableHeight * 0.52)
        case .expanded:
            return min(max(380, availableHeight * 0.78), availableHeight - 14)
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

    private var shouldDisplaySearchThisAreaButton: Bool {
        shouldShowSearchThisArea
        && vm.selectedGroup == nil
        && sheetState != .expanded
        && !isRelocating
    }

    private var shouldDisplayRelocateButton: Bool {
        sheetState != .expanded
        && !isSearchFocused
        && vm.selectedGroup == nil
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
