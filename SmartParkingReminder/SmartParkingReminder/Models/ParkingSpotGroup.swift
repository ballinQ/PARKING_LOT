import CoreLocation
import Foundation

/// A simple grouping of sessions by proximity.
/// Phase 1: greedy grouping (not advanced clustering).
struct ParkingSpotGroup: Identifiable {
    /// Stable identifier derived from coordinate bucketing (so selection survives SwiftUI refresh).
    let id: String

    /// Representative coordinate for the group (currently the first session's coordinate).
    let coordinate: CLLocationCoordinate2D

    /// Display name for the spot (derived from the most recent session).
    let name: String

    /// Sessions in this group, sorted by most recent startTime.
    let sessions: [ParkingSession]

    var count: Int { sessions.count }
}
