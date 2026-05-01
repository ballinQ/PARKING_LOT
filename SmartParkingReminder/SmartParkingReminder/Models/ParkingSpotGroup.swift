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

    /// Local-only personal metadata attached to this saved spot.
    var metadata: SavedParkingSpotMetadata? = nil

    var count: Int { sessions.count }

    var displayName: String {
        guard let metadataName = metadata?.displayName?.trimmingCharacters(in: .whitespacesAndNewlines),
              !metadataName.isEmpty
        else {
            return name
        }

        return metadataName
    }

    func withMetadata(_ metadata: SavedParkingSpotMetadata?) -> ParkingSpotGroup {
        var copy = self
        copy.metadata = metadata
        return copy
    }

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

struct SavedParkingSpotMetadata: Codable, Equatable, Identifiable {
    static let defaultTags = [
        "Safe",
        "Cheap",
        "Covered",
        "Street",
        "Garage",
        "EV",
        "Accessible"
    ]

    let spotID: String
    var displayName: String?
    var note: String
    var rating: Int?
    var tags: [String]
    var isFavorite: Bool
    var createdAt: Date
    var updatedAt: Date

    var id: String { spotID }

    init(
        spotID: String,
        displayName: String? = nil,
        note: String = "",
        rating: Int? = nil,
        tags: [String] = [],
        isFavorite: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.spotID = spotID
        self.displayName = displayName
        self.note = note
        self.rating = rating.map { min(5, max(1, $0)) }
        self.tags = Array(Set(tags)).sorted()
        self.isFavorite = isFavorite
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var hasUserContent: Bool {
        isFavorite
        || rating != nil
        || !tags.isEmpty
        || !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        || !(displayName?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
    }

    func matchesSearch(_ query: String) -> Bool {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return true }

        if displayName?.localizedCaseInsensitiveContains(query) == true {
            return true
        }
        if note.localizedCaseInsensitiveContains(query) {
            return true
        }
        if tags.contains(where: { $0.localizedCaseInsensitiveContains(query) }) {
            return true
        }
        if isFavorite && "favorite".localizedCaseInsensitiveContains(query) {
            return true
        }
        if let rating, "\(rating) star".localizedCaseInsensitiveContains(query) {
            return true
        }

        return false
    }
}
