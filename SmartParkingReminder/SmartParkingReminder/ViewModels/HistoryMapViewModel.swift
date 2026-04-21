import Foundation
import MapKit
import SwiftUI

@MainActor
final class HistoryMapViewModel: ObservableObject {
    @Published private(set) var groups: [ParkingSpotGroup] = []

    /// Selected marker id from the Map selection binding.
    @Published var selectedGroupID: ParkingSpotGroup.ID? = nil {
        didSet {
            if let id = selectedGroupID {
                selectedGroup = groups.first(where: { $0.id == id })
            } else {
                selectedGroup = nil
            }
        }
    }

    /// Drives the detail sheet.
    @Published var selectedGroup: ParkingSpotGroup? = nil

    private let groupingService: ParkingSpotGroupingService

    init(groupingService: ParkingSpotGroupingService = ParkingSpotGroupingService(thresholdMeters: 30)) {
        self.groupingService = groupingService
    }

    func updateSessions(_ sessions: [ParkingSession]) {
        // Preserve current selection by id when possible.
        let currentID = selectedGroupID

        groups = groupingService.groupSessions(sessions)

        if let currentID {
            selectedGroupID = groups.contains(where: { $0.id == currentID }) ? currentID : nil
        }
    }

    func defaultCameraPosition() -> MapCameraPosition {
        guard let first = groups.first else {
            return .automatic
        }

        return .region(MKCoordinateRegion(
            center: first.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        ))
    }
}
