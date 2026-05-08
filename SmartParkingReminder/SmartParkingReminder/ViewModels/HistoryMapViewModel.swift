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

    static func closest(to distance: CLLocationDistance) -> HistorySearchRadius {
        allCases.min {
            abs($0.distance - distance) < abs($1.distance - distance)
        } ?? .oneKilometer
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
    static let torontoFallbackCoordinate = CLLocationCoordinate2D(latitude: 43.6532, longitude: -79.3832)
    static let defaultMapSpan = MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
    private static let specificResultCameraMeters: CLLocationDistance = 700
    private static let markerCameraMeters: CLLocationDistance = 160

    @Published private(set) var groups: [ParkingSpotGroup] = []
    @Published private(set) var visibleGroups: [ParkingSpotGroup] = []
    @Published private(set) var searchResults: [HistoryMapSearchResult] = []
    @Published private(set) var searchCenter: CLLocationCoordinate2D? = nil
    @Published private(set) var statusText: String? = nil
    @Published var searchText: String = ""
    @Published var selectedRangeMeters: CLLocationDistance {
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
    private let filteringService: HistoryMapFilteringService
    private let searchProvider: MapSearchProviding
    private let metadataStorage: SavedParkingSpotMetadataStorageServiceProtocol
    private var metadataBySpotID: [String: SavedParkingSpotMetadata] = [:]
    private var selectedSearchName: String? = nil

    var searchRadius: HistorySearchRadius {
        get { HistorySearchRadius.closest(to: selectedRangeMeters) }
        set { selectedRangeMeters = newValue.distance }
    }

    var selectedRangeLabel: String {
        searchRadius.label
    }

    init(
        groupingService: ParkingSpotGroupingService = ParkingSpotGroupingService(thresholdMeters: 30),
        filteringService: HistoryMapFilteringService = HistoryMapFilteringService(),
        searchProvider: MapSearchProviding = MapKitSearchProvider(),
        metadataStorage: SavedParkingSpotMetadataStorageServiceProtocol = SavedParkingSpotMetadataStorageService(),
        initialSearchRadius: HistorySearchRadius = .oneKilometer
    ) {
        self.groupingService = groupingService
        self.filteringService = filteringService
        self.searchProvider = searchProvider
        self.metadataStorage = metadataStorage
        self.selectedRangeMeters = initialSearchRadius.distance
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

    func relocateToCurrentLocation(_ coordinate: CLLocationCoordinate2D) {
        searchText = ""
        searchResults = []
        searchCenter = coordinate
        selectedSearchName = "current location"
        applySearchFilter(searchName: "current location")
        clearSelection()
    }

    func relocateToTorontoFallback() {
        searchText = ""
        searchResults = []
        searchCenter = Self.torontoFallbackCoordinate
        selectedSearchName = "Toronto fallback"
        applySearchFilter(searchName: "Toronto fallback")
        statusText = "Using Toronto fallback. Address search is still available."
        clearSelection()
    }

    func searchThisMapArea(center: CLLocationCoordinate2D) {
        searchText = ""
        searchResults = []
        searchCenter = center
        selectedSearchName = "this map area"
        applySearchFilter(searchName: "this map area")
        clearSelection()
    }

    var personalHistoryMarkers: [HistoryMapMarkerItem] {
        visibleGroups.map(HistoryMapMarkerItem.personalHistory)
    }

    var searchAreaMarker: HistoryMapMarkerItem? {
        searchCenter.map(HistoryMapMarkerItem.searchArea)
    }

    func defaultCameraPosition() -> MapCameraPosition {
        guard let first = visibleGroups.first else {
            return Self.torontoFallbackCameraPosition()
        }

        return .region(MKCoordinateRegion(
            center: first.coordinate,
            span: Self.defaultMapSpan
        ))
    }

    func cameraPosition(centeredOn coordinate: CLLocationCoordinate2D) -> MapCameraPosition {
        .region(MKCoordinateRegion(
            center: coordinate,
            span: Self.defaultMapSpan
        ))
    }

    func cameraPositionForSelectedRange(fallbackCenter: CLLocationCoordinate2D? = nil) -> MapCameraPosition {
        .region(cameraRegionForSelectedRange(fallbackCenter: fallbackCenter))
    }

    func cameraRegionForSelectedRange(fallbackCenter: CLLocationCoordinate2D? = nil) -> MKCoordinateRegion {
        let center = searchCenter ?? fallbackCenter ?? Self.torontoFallbackCoordinate
        return MKCoordinateRegion(
            center: center,
            latitudinalMeters: selectedRangeMeters * 2.4,
            longitudinalMeters: selectedRangeMeters * 2.4
        )
    }

    func cameraPosition(for result: HistoryMapSearchResult) -> MapCameraPosition {
        .rect(cameraMapRect(for: result))
    }

    func cameraMapRect(for result: HistoryMapSearchResult) -> MKMapRect {
        let resultRect: MKMapRect
        if let suggestedRegion = result.suggestedRegion {
            resultRect = mapRect(for: suggestedRegion)
                .union(mapRect(centeredOn: result.coordinate, meters: Self.specificResultCameraMeters))
        } else {
            resultRect = mapRect(centeredOn: result.coordinate, meters: Self.specificResultCameraMeters)
        }

        let combinedRect = visibleGroups.reduce(resultRect) { partial, group in
            partial.union(mapRect(centeredOn: group.coordinate, meters: Self.markerCameraMeters))
        }

        return padded(combinedRect, factor: 1.25)
    }

    static func torontoFallbackCameraPosition() -> MapCameraPosition {
        .region(MKCoordinateRegion(
            center: torontoFallbackCoordinate,
            span: defaultMapSpan
        ))
    }

    static func userLocationCameraPosition() -> MapCameraPosition {
        .userLocation(followsHeading: true, fallback: torontoFallbackCameraPosition())
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
            visibleGroups = filteringService.filterMetadata(groups: groups, metadataFilter: metadataFilter)
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

            visibleGroups = filteringService.filterMetadata(groups: groups, metadataFilter: metadataFilter)
            statusText = "\(results.count) result\(results.count == 1 ? "" : "s") for \"\(query)\"."
            return results
        } catch {
            searchResults = []
            searchCenter = nil
            selectedSearchName = nil
            applyLocalHistoryFilter(query: query)
            if visibleGroups.isEmpty {
                visibleGroups = filteringService.filterMetadata(groups: groups, metadataFilter: metadataFilter)
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
        visibleGroups = filteringService.filterMetadata(groups: groups, metadataFilter: metadataFilter)
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
            visibleGroups = filteringService.filterMetadata(groups: groups, metadataFilter: metadataFilter)
            if searchCenter == nil {
                statusText = metadataFilter == .all
                    ? nil
                    : filterStatusText(count: visibleGroups.count)
            }
            return
        }

        visibleGroups = filteringService.filterLocalHistory(
            groups: groups,
            query: trimmedQuery,
            metadataFilter: metadataFilter
        )

        if visibleGroups.isEmpty {
            statusText = "No saved parking history matching \"\(trimmedQuery)\". Search an address to check nearby saved spots."
        } else {
            statusText = "\(visibleGroups.count) saved parking spot\(visibleGroups.count == 1 ? "" : "s") matching \"\(trimmedQuery)\"\(metadataFilterSuffix)."
        }
    }

    private func applySearchFilter(searchName: String? = nil) {
        guard let searchCenter else {
            visibleGroups = filteringService.filterMetadata(groups: groups, metadataFilter: metadataFilter)
            return
        }

        visibleGroups = filteringService.filterNearby(
            groups: groups,
            center: searchCenter,
            radiusMeters: selectedRangeMeters,
            metadataFilter: metadataFilter
        )

        let place = searchName ?? "this address"
        if visibleGroups.isEmpty {
            statusText = "No saved parking history\(metadataFilterSuffix) within \(selectedRangeLabel) of \(place)."
        } else {
            statusText = "\(visibleGroups.count) saved parking spot\(visibleGroups.count == 1 ? "" : "s")\(metadataFilterSuffix) within \(selectedRangeLabel) of \(place)."
        }
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

    private func mapRect(centeredOn coordinate: CLLocationCoordinate2D, meters: CLLocationDistance) -> MKMapRect {
        let center = MKMapPoint(coordinate)
        let metersPerMapPoint = max(MKMetersPerMapPointAtLatitude(coordinate.latitude), 0.000_001)
        let side = max(meters / metersPerMapPoint, 1)
        return MKMapRect(
            x: center.x - side / 2,
            y: center.y - side / 2,
            width: side,
            height: side
        )
    }

    private func mapRect(for region: MKCoordinateRegion) -> MKMapRect {
        let halfLatitudeDelta = max(region.span.latitudeDelta, 0.000_5) / 2
        let halfLongitudeDelta = max(region.span.longitudeDelta, 0.000_5) / 2
        let northWest = CLLocationCoordinate2D(
            latitude: region.center.latitude + halfLatitudeDelta,
            longitude: region.center.longitude - halfLongitudeDelta
        )
        let southEast = CLLocationCoordinate2D(
            latitude: region.center.latitude - halfLatitudeDelta,
            longitude: region.center.longitude + halfLongitudeDelta
        )
        let a = MKMapPoint(northWest)
        let b = MKMapPoint(southEast)
        return MKMapRect(
            x: min(a.x, b.x),
            y: min(a.y, b.y),
            width: max(abs(a.x - b.x), 1),
            height: max(abs(a.y - b.y), 1)
        )
    }

    private func padded(_ rect: MKMapRect, factor: Double) -> MKMapRect {
        let xPadding = rect.width * max(factor - 1, 0) / 2
        let yPadding = rect.height * max(factor - 1, 0) / 2
        return rect.insetBy(dx: -xPadding, dy: -yPadding)
    }
}
