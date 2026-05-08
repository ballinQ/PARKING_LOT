import CoreLocation
import Foundation

enum HistoryMapLayerKind: String {
    case personalHistory
    case searchArea
}

struct HistoryMapMarkerItem: Identifiable {
    let id: String
    let title: String
    let coordinate: CLLocationCoordinate2D
    let layer: HistoryMapLayerKind
    let sourceID: String?

    static func personalHistory(_ group: ParkingSpotGroup) -> HistoryMapMarkerItem {
        HistoryMapMarkerItem(
            id: group.id,
            title: group.count <= 1 ? group.displayName : "\(group.displayName) (\(group.count))",
            coordinate: group.coordinate,
            layer: .personalHistory,
            sourceID: group.id
        )
    }

    static func searchArea(coordinate: CLLocationCoordinate2D) -> HistoryMapMarkerItem {
        HistoryMapMarkerItem(
            id: "search_area",
            title: "Search Area",
            coordinate: coordinate,
            layer: .searchArea,
            sourceID: nil
        )
    }
}
