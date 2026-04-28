import Foundation
import MapKit
import SwiftUI

@MainActor
final class HistoryMapViewModel: ObservableObject {
    @Published private(set) var groups: [ParkingSpotGroup] = []
    @Published private(set) var visibleGroups: [ParkingSpotGroup] = []
    @Published private(set) var searchCenter: CLLocationCoordinate2D? = nil
    @Published private(set) var statusText: String? = nil
    @Published var searchText: String = ""
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
    private let searchRadiusMeters: CLLocationDistance

    init(
        groupingService: ParkingSpotGroupingService = ParkingSpotGroupingService(thresholdMeters: 30),
        searchRadiusMeters: CLLocationDistance = 1_000
    ) {
        self.groupingService = groupingService
        self.searchRadiusMeters = searchRadiusMeters
    }

    func updateSessions(_ sessions: [ParkingSession]) {
        // Preserve current selection by id when possible.
        let currentID = selectedGroupID

        groups = groupingService.groupSessions(sessions)
        applySearchFilter()

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
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return nil }

        isSearching = true
        statusText = nil
        defer { isSearching = false }

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query

        do {
            let response = try await MKLocalSearch(request: request).start()
            guard let item = response.mapItems.first else {
                searchCenter = nil
                visibleGroups = groups
                statusText = "No address found for \"\(query)\"."
                return nil
            }

            let coordinate = item.placemark.coordinate
            searchCenter = coordinate
            applySearchFilter(searchName: item.name ?? query)
            clearSelection()
            return coordinate
        } catch {
            statusText = "Could not search that address. Check the spelling or try a nearby landmark."
            return nil
        }
    }

    func clearSearch() {
        searchText = ""
        searchCenter = nil
        statusText = nil
        visibleGroups = groups
        clearSelection()
    }

    private func applySearchFilter(searchName: String? = nil) {
        guard let searchCenter else {
            visibleGroups = groups
            return
        }

        let centerLocation = CLLocation(latitude: searchCenter.latitude, longitude: searchCenter.longitude)
        visibleGroups = groups.filter { group in
            let groupLocation = CLLocation(latitude: group.coordinate.latitude, longitude: group.coordinate.longitude)
            return centerLocation.distance(from: groupLocation) <= searchRadiusMeters
        }

        let place = searchName ?? "this address"
        if visibleGroups.isEmpty {
            statusText = "No saved parking history within 1 km of \(place)."
        } else {
            statusText = "\(visibleGroups.count) saved parking spot\(visibleGroups.count == 1 ? "" : "s") within 1 km of \(place)."
        }
    }
}
