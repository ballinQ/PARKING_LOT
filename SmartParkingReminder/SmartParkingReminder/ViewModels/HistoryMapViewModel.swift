import Foundation
import MapKit
import SwiftUI

enum HistorySearchRadius: String, CaseIterable, Identifiable, Equatable {
    case meters500
    case oneKilometer
    case twoKilometers

    var id: String { rawValue }

    var label: String {
        switch self {
        case .meters500:
            return "500 m"
        case .oneKilometer:
            return "1 km"
        case .twoKilometers:
            return "2 km"
        }
    }

    var distance: CLLocationDistance {
        switch self {
        case .meters500:
            return 500
        case .oneKilometer:
            return 1_000
        case .twoKilometers:
            return 2_000
        }
    }
}

enum HistorySpotMetadataFilter: String, CaseIterable, Identifiable, Equatable {
    case all
    case favorites
    case fourPlus
    case safe
    case cheap
    case covered
    case street
    case garage
    case ev
    case accessible

    var id: String { rawValue }

    var label: String {
        switch self {
        case .all:
            return "All"
        case .favorites:
            return "Favorites"
        case .fourPlus:
            return "4+ Stars"
        case .safe:
            return "Safe"
        case .cheap:
            return "Cheap"
        case .covered:
            return "Covered"
        case .street:
            return "Street"
        case .garage:
            return "Garage"
        case .ev:
            return "EV"
        case .accessible:
            return "Accessible"
        }
    }

    func matches(_ group: ParkingSpotGroup) -> Bool {
        guard self != .all else { return true }
        guard let metadata = group.metadata else { return false }

        switch self {
        case .all:
            return true
        case .favorites:
            return metadata.isFavorite
        case .fourPlus:
            return (metadata.rating ?? 0) >= 4
        case .safe, .cheap, .covered, .street, .garage, .ev, .accessible:
            return metadata.tags.contains { $0.caseInsensitiveCompare(label) == .orderedSame }
        }
    }
}

@MainActor
final class HistoryMapViewModel: ObservableObject {
    @Published private(set) var groups: [ParkingSpotGroup] = []
    @Published private(set) var visibleGroups: [ParkingSpotGroup] = []
    @Published private(set) var searchResults: [HistoryMapSearchResult] = []
    @Published private(set) var searchCenter: CLLocationCoordinate2D? = nil
    @Published private(set) var statusText: String? = nil
    @Published var searchText: String = ""
    @Published var searchRadius: HistorySearchRadius = .oneKilometer {
        didSet {
            guard searchCenter != nil else { return }
            applySearchFilter(searchName: selectedSearchName)
        }
    }
    @Published var metadataFilter: HistorySpotMetadataFilter = .all {
        didSet {
            applyCurrentHistoryFilter()
            if let selectedGroupID,
               !visibleGroups.contains(where: { $0.id == selectedGroupID }) {
                clearSelection()
            }
        }
    }
    @Published var isSearching = false

    /// Selected marker id from the Map selection binding.
    @Published var selectedGroupID: ParkingSpotGroup.ID? = nil {
        didSet {
            guard let id = selectedGroupID,
                  let group = visibleGroups.first(where: { $0.id == id })
            else { return }

            selectedGroup = group
        }
    }

    /// Drives the detail sheet.
    @Published var selectedGroup: ParkingSpotGroup? = nil {
        didSet {
            if selectedGroup == nil, selectedGroupID != nil {
                selectedGroupID = nil
            }
        }
    }

    private let groupingService: ParkingSpotGroupingService
    private let searchProvider: MapSearchProviding
    private let metadataStorage: SavedParkingSpotMetadataStorageServiceProtocol
    private var metadataBySpotID: [String: SavedParkingSpotMetadata] = [:]
    private var selectedSearchName: String? = nil

    init(
        groupingService: ParkingSpotGroupingService = ParkingSpotGroupingService(thresholdMeters: 30),
        searchProvider: MapSearchProviding = MapKitSearchProvider(),
        metadataStorage: SavedParkingSpotMetadataStorageServiceProtocol = SavedParkingSpotMetadataStorageService(),
        initialSearchRadius: HistorySearchRadius = .oneKilometer
    ) {
        self.groupingService = groupingService
        self.searchProvider = searchProvider
        self.metadataStorage = metadataStorage
        self.searchRadius = initialSearchRadius
        self.metadataBySpotID = (try? metadataStorage.load()) ?? [:]
    }

    func updateSessions(_ sessions: [ParkingSession]) {
        // Preserve current selection by id when possible.
        let currentID = selectedGroupID

        groups = groupingService.groupSessions(sessions).map(applyingMetadata)
        applyCurrentHistoryFilter()

        if let currentID {
            if let group = visibleGroups.first(where: { $0.id == currentID }) {
                selectGroup(group)
            } else {
                clearSelection()
            }
        }
    }

    func selectGroup(_ group: ParkingSpotGroup) {
        selectedGroupID = group.id
        selectedGroup = group
    }

    func selectFirstVisibleGroup() {
        guard let group = visibleGroups.first else { return }
        selectGroup(group)
    }

    func clearSelection() {
        selectedGroup = nil
        selectedGroupID = nil
    }

    func metadata(for group: ParkingSpotGroup) -> SavedParkingSpotMetadata {
        metadataBySpotID[group.id]
        ?? SavedParkingSpotMetadata(spotID: group.id)
    }

    func updateMetadata(_ metadata: SavedParkingSpotMetadata, for group: ParkingSpotGroup) {
        var next = metadata
        next.updatedAt = now()
        metadataBySpotID[group.id] = next

        do {
            try metadataStorage.save(metadataBySpotID)
        } catch {
            // Phase 2 local metadata is best-effort; keep the in-memory edit visible.
        }

        groups = groups.map { $0.id == group.id ? $0.withMetadata(next) : $0 }
        applyCurrentHistoryFilter()

        if selectedGroup?.id == group.id {
            selectedGroup = selectedGroup?.withMetadata(next)
        }
    }

    func updateSearchText(_ text: String) {
        searchText = text
        searchResults = []
        searchCenter = nil
        selectedSearchName = nil
        applyLocalHistoryFilter(query: text)
        clearSelection()
    }

    func selectSearchResult(_ result: HistoryMapSearchResult) {
        searchText = result.title
        searchCenter = result.coordinate
        selectedSearchName = result.title
        applySearchFilter(searchName: result.title)
        clearSelection()
    }

    func defaultCameraPosition() -> MapCameraPosition {
        guard let first = visibleGroups.first else {
            return .automatic
        }

        return .region(MKCoordinateRegion(
            center: first.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        ))
    }

    func cameraPosition(centeredOn coordinate: CLLocationCoordinate2D) -> MapCameraPosition {
        .region(MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.025, longitudeDelta: 0.025)
        ))
    }

    @discardableResult
    func searchAddress() async -> CLLocationCoordinate2D? {
        await searchAddressResults()
        guard let first = searchResults.first else { return nil }
        selectSearchResult(first)
        return first.coordinate
    }

    @discardableResult
    func searchAddressResults() async -> [HistoryMapSearchResult] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            searchResults = []
            searchCenter = nil
            selectedSearchName = nil
            statusText = nil
            visibleGroups = applyMetadataFilter(to: groups)
            return []
        }

        isSearching = true
        searchResults = []
        statusText = nil
        defer { isSearching = false }

        do {
            let results = try await searchProvider.searchAddress(query: query)
            searchResults = results

            guard !results.isEmpty else {
                searchCenter = nil
                selectedSearchName = nil
                applyLocalHistoryFilter(query: query)
                statusText = visibleGroups.isEmpty
                    ? "No address or saved parking history found for \"\(query)\"."
                    : "No address found for \"\(query)\". Showing saved history matches."
                return []
            }

            statusText = "\(results.count) result\(results.count == 1 ? "" : "s") for \"\(query)\"."
            return results
        } catch {
            searchResults = []
            searchCenter = nil
            selectedSearchName = nil
            applyLocalHistoryFilter(query: query)
            if visibleGroups.isEmpty {
                visibleGroups = applyMetadataFilter(to: groups)
                statusText = "Could not search that address. Check the spelling or try a nearby landmark."
            } else {
                statusText = "Could not search that address. Showing saved history matches."
            }
            return []
        }
    }

    func clearSearch() {
        searchText = ""
        searchResults = []
        searchCenter = nil
        selectedSearchName = nil
        statusText = nil
        visibleGroups = applyMetadataFilter(to: groups)
        clearSelection()
    }

    private func applyCurrentHistoryFilter() {
        if searchCenter == nil {
            applyLocalHistoryFilter(query: searchText)
        } else {
            applySearchFilter(searchName: selectedSearchName)
        }
    }

    private func applyingMetadata(to group: ParkingSpotGroup) -> ParkingSpotGroup {
        group.withMetadata(metadataBySpotID[group.id])
    }

    private func now() -> Date {
        Date()
    }

    private func applyLocalHistoryFilter(query: String) {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            visibleGroups = applyMetadataFilter(to: groups)
            if searchCenter == nil {
                statusText = metadataFilter == .all
                    ? nil
                    : filterStatusText(count: visibleGroups.count)
            }
            return
        }

        let matchingGroups = groups.filter { group in
            group.matchesLocalHistorySearch(trimmedQuery)
        }
        visibleGroups = applyMetadataFilter(to: matchingGroups)

        if visibleGroups.isEmpty {
            statusText = "No saved parking history matching \"\(trimmedQuery)\". Search an address to check nearby saved spots."
        } else {
            statusText = "\(visibleGroups.count) saved parking spot\(visibleGroups.count == 1 ? "" : "s") matching \"\(trimmedQuery)\"\(metadataFilterSuffix)."
        }
    }

    private func applySearchFilter(searchName: String? = nil) {
        guard let searchCenter else {
            visibleGroups = applyMetadataFilter(to: groups)
            return
        }

        let centerLocation = CLLocation(latitude: searchCenter.latitude, longitude: searchCenter.longitude)
        let nearbyGroups = groups.filter { group in
            let groupLocation = CLLocation(latitude: group.coordinate.latitude, longitude: group.coordinate.longitude)
            return centerLocation.distance(from: groupLocation) <= searchRadius.distance
        }
        visibleGroups = applyMetadataFilter(to: nearbyGroups)

        let place = searchName ?? "this address"
        if visibleGroups.isEmpty {
            statusText = "No saved parking history\(metadataFilterSuffix) within \(searchRadius.label) of \(place)."
        } else {
            statusText = "\(visibleGroups.count) saved parking spot\(visibleGroups.count == 1 ? "" : "s")\(metadataFilterSuffix) within \(searchRadius.label) of \(place)."
        }
    }

    private func applyMetadataFilter(to groups: [ParkingSpotGroup]) -> [ParkingSpotGroup] {
        groups.filter { metadataFilter.matches($0) }
    }

    private var metadataFilterSuffix: String {
        metadataFilter == .all ? "" : " matching \(metadataFilter.label)"
    }

    private func filterStatusText(count: Int) -> String {
        guard metadataFilter != .all else { return "" }
        if count == 0 {
            return "No saved parking spots matching \(metadataFilter.label)."
        }
        return "\(count) saved parking spot\(count == 1 ? "" : "s") matching \(metadataFilter.label)."
    }
}

private extension ParkingSpotGroup {
    func matchesLocalHistorySearch(_ query: String) -> Bool {
        if displayName.localizedCaseInsensitiveContains(query) || name.localizedCaseInsensitiveContains(query) {
            return true
        }

        if metadata?.matchesSearch(query) == true {
            return true
        }

        return sessions.contains { session in
            session.locationName.localizedCaseInsensitiveContains(query)
            || session.note.localizedCaseInsensitiveContains(query)
        }
    }
}
