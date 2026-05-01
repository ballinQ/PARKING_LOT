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
    private var selectedSearchName: String? = nil

    init(
        groupingService: ParkingSpotGroupingService = ParkingSpotGroupingService(thresholdMeters: 30),
        searchProvider: MapSearchProviding = MapKitSearchProvider(),
        initialSearchRadius: HistorySearchRadius = .oneKilometer
    ) {
        self.groupingService = groupingService
        self.searchProvider = searchProvider
        self.searchRadius = initialSearchRadius
    }

    func updateSessions(_ sessions: [ParkingSession]) {
        // Preserve current selection by id when possible.
        let currentID = selectedGroupID

        groups = groupingService.groupSessions(sessions)
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
            visibleGroups = groups
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
                visibleGroups = groups
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
        visibleGroups = groups
        clearSelection()
    }

    private func applyCurrentHistoryFilter() {
        if searchCenter == nil {
            applyLocalHistoryFilter(query: searchText)
        } else {
            applySearchFilter(searchName: selectedSearchName)
        }
    }

    private func applyLocalHistoryFilter(query: String) {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            visibleGroups = groups
            if searchCenter == nil {
                statusText = nil
            }
            return
        }

        visibleGroups = groups.filter { group in
            group.matchesLocalHistorySearch(trimmedQuery)
        }

        if visibleGroups.isEmpty {
            statusText = "No saved parking history matching \"\(trimmedQuery)\". Search an address to check nearby saved spots."
        } else {
            statusText = "\(visibleGroups.count) saved parking spot\(visibleGroups.count == 1 ? "" : "s") matching \"\(trimmedQuery)\"."
        }
    }

    private func applySearchFilter(searchName: String? = nil) {
        guard let searchCenter else {
            visibleGroups = groups
            return
        }

        let centerLocation = CLLocation(latitude: searchCenter.latitude, longitude: searchCenter.longitude)
        visibleGroups = groups.filter { group in
            let groupLocation = CLLocation(latitude: group.coordinate.latitude, longitude: group.coordinate.longitude)
            return centerLocation.distance(from: groupLocation) <= searchRadius.distance
        }

        let place = searchName ?? "this address"
        if visibleGroups.isEmpty {
            statusText = "No saved parking history within \(searchRadius.label) of \(place)."
        } else {
            statusText = "\(visibleGroups.count) saved parking spot\(visibleGroups.count == 1 ? "" : "s") within \(searchRadius.label) of \(place)."
        }
    }
}

private extension ParkingSpotGroup {
    func matchesLocalHistorySearch(_ query: String) -> Bool {
        if name.localizedCaseInsensitiveContains(query) {
            return true
        }

        return sessions.contains { session in
            session.locationName.localizedCaseInsensitiveContains(query)
            || session.note.localizedCaseInsensitiveContains(query)
        }
    }
}
