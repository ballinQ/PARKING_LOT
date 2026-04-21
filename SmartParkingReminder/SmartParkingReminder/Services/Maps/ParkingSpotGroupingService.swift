import CoreLocation
import Foundation

/// Groups parking sessions that are within a distance threshold.
/// Phase 1: simple greedy grouping; no clustering/tiling.
struct ParkingSpotGroupingService {
    /// Default grouping radius.
    /// 30m groups "same parking lot" pretty well without being too aggressive.
    var thresholdMeters: CLLocationDistance = 30

    func groupSessions(_ sessions: [ParkingSession]) -> [ParkingSpotGroup] {
        let candidates: [(session: ParkingSession, coordinate: CLLocationCoordinate2D)] = sessions.compactMap { s in
            guard let lat = s.latitude, let lon = s.longitude else { return nil }
            return (s, CLLocationCoordinate2D(latitude: lat, longitude: lon))
        }

        // Sort most recent first so the group's name comes from the most recent session.
        let sorted = candidates.sorted { $0.session.startTime > $1.session.startTime }

        var groups: [ParkingSpotGroup] = []

        for item in sorted {
            if let idx = groups.firstIndex(where: { isWithinThreshold(item.coordinate, $0.coordinate) }) {
                // Append session and keep sorted.
                let existing = groups[idx]
                var newSessions = existing.sessions
                newSessions.append(item.session)
                newSessions.sort { $0.startTime > $1.startTime }

                groups[idx] = ParkingSpotGroup(
                    id: existing.id,
                    coordinate: existing.coordinate,
                    name: existing.name, // Keep stable name (already from most recent)
                    sessions: newSessions
                )
            } else {
                groups.append(ParkingSpotGroup(
                    id: stableID(for: item.coordinate),
                    coordinate: item.coordinate,
                    name: item.session.locationName,
                    sessions: [item.session]
                ))
            }
        }

        return groups
    }

    private func isWithinThreshold(_ a: CLLocationCoordinate2D, _ b: CLLocationCoordinate2D) -> Bool {
        let la = CLLocation(latitude: a.latitude, longitude: a.longitude)
        let lb = CLLocation(latitude: b.latitude, longitude: b.longitude)
        return la.distance(from: lb) <= thresholdMeters
    }

    /// A stable ID derived from a simple lat/lon bucket.
    /// This keeps marker selection stable across SwiftUI refreshes.
    private func stableID(for coordinate: CLLocationCoordinate2D) -> String {
        // Approx conversions: ~111km per degree latitude.
        let latBucketSize = thresholdMeters / 111_000

        // Longitude degrees vary by latitude.
        let cosLat = max(0.2, abs(cos(coordinate.latitude * .pi / 180)))
        let lonBucketSize = thresholdMeters / (111_000 * cosLat)

        let latBucket = Int((coordinate.latitude / latBucketSize).rounded(.down))
        let lonBucket = Int((coordinate.longitude / lonBucketSize).rounded(.down))

        return "spot_\(latBucket)_\(lonBucket)"
    }
}
