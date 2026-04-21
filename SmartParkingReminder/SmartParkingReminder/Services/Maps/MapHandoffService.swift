import Foundation
import MapKit
import UIKit

/// Opens external map apps for navigation handoff.
/// Phase 1: Apple Maps always available; Google Maps supported when installed.
@MainActor
final class MapHandoffService {
    enum Provider {
        case appleMaps
        case googleMaps
    }

    func openDirections(to coordinate: CLLocationCoordinate2D, placeName: String, preferred: Provider? = nil) {
        // If a preferred provider is specified, try it first.
        if let preferred {
            if tryOpen(preferred, coordinate: coordinate, placeName: placeName) {
                return
            }
            // Fallback to Apple Maps.
            _ = tryOpen(.appleMaps, coordinate: coordinate, placeName: placeName)
            return
        }

        // Default behavior: prefer Google Maps if installed, else Apple Maps.
        if tryOpen(.googleMaps, coordinate: coordinate, placeName: placeName) {
            return
        }
        _ = tryOpen(.appleMaps, coordinate: coordinate, placeName: placeName)
    }

    // MARK: - Private

    private func tryOpen(_ provider: Provider, coordinate: CLLocationCoordinate2D, placeName: String) -> Bool {
        switch provider {
        case .appleMaps:
            // Use MKMapItem to open Apple Maps.
            let placemark = MKPlacemark(coordinate: coordinate)
            let item = MKMapItem(placemark: placemark)
            item.name = placeName
            return item.openInMaps(launchOptions: [
                MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
            ])

        case .googleMaps:
            // Prefer the Google Maps URL scheme when installed.
            // Requires LSApplicationQueriesSchemes entry for canOpenURL("comgooglemaps://").
            guard let schemeURL = URL(string: "comgooglemaps://") else { return false }
            guard UIApplication.shared.canOpenURL(schemeURL) else {
                return false
            }

            let lat = coordinate.latitude
            let lon = coordinate.longitude

            // directionsmode=driving, daddr=lat,lon
            let urlString = "comgooglemaps://?daddr=\(lat),\(lon)&directionsmode=driving"
            guard let url = URL(string: urlString) else { return false }
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            return true
        }
    }
}
