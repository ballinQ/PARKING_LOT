import CoreLocation
import Foundation

protocol LocationServiceProtocol: AnyObject {
    func currentCoordinateOnce() async -> CLLocationCoordinate2D?
}

/// One-shot location capture helper (no continuous/background tracking).
class LocationService: NSObject, ObservableObject, CLLocationManagerDelegate, LocationServiceProtocol {
    @Published private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined

    private let manager = CLLocationManager()
    private var oneShotCompletion: ((CLLocationCoordinate2D?) -> Void)?

    override init() {
        super.init()
        manager.delegate = self
        authorizationStatus = manager.authorizationStatus
    }

    func requestWhenInUseAuthorization() {
        manager.requestWhenInUseAuthorization()
    }

    /// Callback-based one-shot location capture.
    func captureCurrentLocation(completion: @escaping (CLLocationCoordinate2D?) -> Void) {
        oneShotCompletion = completion

        if authorizationStatus == .notDetermined {
            requestWhenInUseAuthorization()
        }

        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        manager.requestLocation()
    }

    /// Async wrapper for one-shot location capture.
    /// Returns nil if permission is denied/restricted or if location fails.
    func currentCoordinateOnce() async -> CLLocationCoordinate2D? {
        // If denied/restricted, don't even request.
        if authorizationStatus == .denied || authorizationStatus == .restricted {
            return nil
        }

        return await withCheckedContinuation { continuation in
            captureCurrentLocation { coordinate in
                continuation.resume(returning: coordinate)
            }
        }
    }

    // MARK: - CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        oneShotCompletion?(locations.last?.coordinate)
        oneShotCompletion = nil
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        oneShotCompletion?(nil)
        oneShotCompletion = nil
    }
}
