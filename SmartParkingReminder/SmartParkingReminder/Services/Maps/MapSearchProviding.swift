import CoreLocation
import Foundation
import MapKit

struct HistoryMapSearchResult: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let coordinate: CLLocationCoordinate2D
    let suggestedRegion: MKCoordinateRegion?

    init(
        title: String,
        subtitle: String,
        coordinate: CLLocationCoordinate2D,
        suggestedRegion: MKCoordinateRegion? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.coordinate = coordinate
        self.suggestedRegion = suggestedRegion
    }
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
                coordinate: item.placemark.coordinate,
                suggestedRegion: suggestedRegion(for: item)
            )
        }
    }

    private func suggestedRegion(for item: MKMapItem) -> MKCoordinateRegion? {
        if let circularRegion = item.placemark.region as? CLCircularRegion {
            let radiusMeters = max(circularRegion.radius, 250)
            let latitudeDelta = metersToLatitudeDelta(radiusMeters * 2)
            let longitudeDelta = metersToLongitudeDelta(radiusMeters * 2, latitude: item.placemark.coordinate.latitude)
            return MKCoordinateRegion(
                center: item.placemark.coordinate,
                span: MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
            )
        }

        return nil
    }

    private func metersToLatitudeDelta(_ meters: CLLocationDistance) -> CLLocationDegrees {
        meters / 111_000
    }

    private func metersToLongitudeDelta(_ meters: CLLocationDistance, latitude: CLLocationDegrees) -> CLLocationDegrees {
        let latitudeRadians = latitude * .pi / 180
        let metersPerDegree = max(111_000 * cos(latitudeRadians), 1)
        return meters / metersPerDegree
    }
}
