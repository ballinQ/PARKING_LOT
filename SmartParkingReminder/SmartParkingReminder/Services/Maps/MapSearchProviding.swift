import CoreLocation
import Foundation
import MapKit

struct HistoryMapSearchResult: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let coordinate: CLLocationCoordinate2D
}

protocol MapSearchProviding {
    func searchAddress(query: String) async throws -> [HistoryMapSearchResult]
}

struct MapKitSearchProvider: MapSearchProviding {
    func searchAddress(query: String) async throws -> [HistoryMapSearchResult] {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query

        let response = try await MKLocalSearch(request: request).start()
        return response.mapItems.map { item in
            HistoryMapSearchResult(
                title: item.name ?? query,
                subtitle: item.placemark.title ?? "",
                coordinate: item.placemark.coordinate
            )
        }
    }
}
