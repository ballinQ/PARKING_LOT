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
    enum Lifecycle: String {
        case active
        case completed

        var displayTitle: String {
            switch self {
            case .active:
                return "Active"
            case .completed:
                return "Completed"
            }
        }
    }

    enum TimingResult: String {
        case onTime
        case dueSoon
        case overdue

        func displayTitle(for lifecycle: Lifecycle) -> String {
            switch self {
            case .onTime:
                return lifecycle == .active ? "Remaining" : "On time"
            case .dueSoon:
                return "Due soon"
            case .overdue:
                return "Overdue"
            }
        }
    }

    struct TimingOutcome: Equatable {
        let lifecycle: Lifecycle
        let result: TimingResult
        let remainingDuration: TimeInterval?
        let overdueDuration: TimeInterval?

        var statusLine: String {
            "\(lifecycle.displayTitle) · \(result.displayTitle(for: lifecycle))"
        }
    }

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

    func isActiveExpired(now: Date = Date()) -> Bool {
        persistedStatus == .active && now >= expectedEndTime
    }

    func remainingTimeInterval(now: Date = Date()) -> TimeInterval {
        max(0, expectedEndTime.timeIntervalSince(now))
    }

    func timingOutcome(now: Date = Date(), dueSoonThreshold: TimeInterval = 15 * 60) -> TimingOutcome {
        switch persistedStatus {
        case .completed:
            let endedAt = actualEndTime ?? expectedEndTime
            let overdueDuration = endedAt > expectedEndTime ? endedAt.timeIntervalSince(expectedEndTime) : nil
            return TimingOutcome(
                lifecycle: .completed,
                result: overdueDuration == nil ? .onTime : .overdue,
                remainingDuration: nil,
                overdueDuration: overdueDuration
            )
        case .active:
            let rawRemaining = expectedEndTime.timeIntervalSince(now)
            if rawRemaining < 0 {
                return TimingOutcome(
                    lifecycle: .active,
                    result: .overdue,
                    remainingDuration: nil,
                    overdueDuration: abs(rawRemaining)
                )
            }

            return TimingOutcome(
                lifecycle: .active,
                result: rawRemaining <= dueSoonThreshold ? .dueSoon : .onTime,
                remainingDuration: rawRemaining,
                overdueDuration: nil
            )
        }
    }

    func historyStatusLine(now: Date = Date()) -> String {
        timingOutcome(now: now).statusLine
    }

    func historyOverdueLine(now: Date = Date(), formatter: ParkingSessionDisplayFormatter = ParkingSessionDisplayFormatter()) -> String? {
        guard let overdueDuration = timingOutcome(now: now).overdueDuration else { return nil }
        return "Overdue by \(formatter.formatTimeInterval(overdueDuration))"
    }
}

struct ParkingSessionDisplayFormatter {
    func formatTimeInterval(_ interval: TimeInterval) -> String {
        let seconds = max(0, Int(interval.rounded(.down)))

        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60

        if h > 0 {
            return "\(h)h \(m)m \(s)s"
        } else {
            return "\(m)m \(s)s"
        }
    }
}
