import Foundation
import MapKit
import UIKit

protocol URLLaunching {
    func canOpenURL(_ url: URL) -> Bool
    func open(_ url: URL, options: [UIApplication.OpenExternalURLOptionsKey: Any], completionHandler: ((Bool) -> Void)?)
}

extension UIApplication: URLLaunching {}

/// Opens external map apps for navigation handoff.
/// Phase 1: Apple Maps always available; Google Maps supported when installed.
@MainActor
final class MapHandoffService {
    enum Provider {
        case appleMaps
        case googleMaps
    }

    private let launcher: URLLaunching

    init(launcher: URLLaunching = UIApplication.shared) {
        self.launcher = launcher
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

    // MARK: - URL builders (testable)

    func googleMapsDirectionsURL(to coordinate: CLLocationCoordinate2D) -> URL? {
        let lat = coordinate.latitude
        let lon = coordinate.longitude
        let urlString = "comgooglemaps://?daddr=\(lat),\(lon)&directionsmode=driving"
        return URL(string: urlString)
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
            guard let schemeURL = URL(string: "comgooglemaps://") else { return false }
            guard launcher.canOpenURL(schemeURL) else {
                return false
            }

            guard let url = googleMapsDirectionsURL(to: coordinate) else { return false }
            launcher.open(url, options: [:], completionHandler: nil)
            return true
        }
    }
}
