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

    func timingSummary(now: Date) -> ParkingSpotTimingSummary {
        sessions.reduce(into: ParkingSpotTimingSummary()) { summary, session in
            let outcome = session.timingOutcome(now: now)
            switch (outcome.lifecycle, outcome.result) {
            case (.completed, .onTime), (.completed, .dueSoon):
                summary.onTime += 1
            case (.active, .onTime), (.active, .dueSoon):
                summary.active += 1
            case (_, .overdue):
                summary.overdue += 1
            }
        }
    }
}

struct ParkingSpotTimingSummary: Equatable {
    var onTime = 0
    var active = 0
    var overdue = 0
}
