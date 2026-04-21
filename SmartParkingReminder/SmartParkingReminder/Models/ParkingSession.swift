import Foundation

struct ParkingSession: Identifiable, Codable, Equatable {
    enum PersistedStatus: String, Codable {
        case active
        case completed
    }

    let id: UUID
    var locationName: String
    var latitude: Double?
    var longitude: Double?

    var startTime: Date
    var expectedEndTime: Date
    var actualEndTime: Date?

    var note: String

    /// Persisted status is kept simple for Phase 1.
    /// Overdue is derived at runtime when active & time has passed.
    var persistedStatus: PersistedStatus

    init(
        id: UUID = UUID(),
        locationName: String,
        latitude: Double? = nil,
        longitude: Double? = nil,
        startTime: Date,
        expectedEndTime: Date,
        actualEndTime: Date? = nil,
        note: String,
        persistedStatus: PersistedStatus
    ) {
        self.id = id
        self.locationName = locationName
        self.latitude = latitude
        self.longitude = longitude
        self.startTime = startTime
        self.expectedEndTime = expectedEndTime
        self.actualEndTime = actualEndTime
        self.note = note
        self.persistedStatus = persistedStatus
    }
}

extension ParkingSession {
    enum DisplayStatus: String {
        case active
        case overdue
        case completed
    }

    func displayStatus(now: Date = Date()) -> DisplayStatus {
        switch persistedStatus {
        case .completed:
            return .completed
        case .active:
            return now >= expectedEndTime ? .overdue : .active
        }
    }

    func remainingTimeInterval(now: Date = Date()) -> TimeInterval {
        expectedEndTime.timeIntervalSince(now)
    }
}
