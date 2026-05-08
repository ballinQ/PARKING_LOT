import Foundation

enum ParkingSessionStatus: String, Equatable {
    case active
    case dueSoon
    case overdue

    var label: String {
        switch self {
        case .active:
            return "Remaining"
        case .dueSoon:
            return "Due Soon"
        case .overdue:
            return "Overdue"
        }
    }
}

struct ParkingSessionTimerDisplay: Equatable {
    let status: ParkingSessionStatus
    let label: String
    let displayTime: TimeInterval
    let timeText: String
}

struct ParkingActivitySnapshot: Equatable {
    let sessionID: UUID
    let locationName: String
    let startDate: Date
    let scheduledEndDate: Date
    let lastUpdatedDate: Date

    var expectedEndTime: Date { scheduledEndDate }
}

protocol ParkingActivityLifecycleManaging {
    func sessionStarted(_ snapshot: ParkingActivitySnapshot)
    func activeSessionRestored(_ snapshot: ParkingActivitySnapshot)
    func activeSessionUpdated(_ snapshot: ParkingActivitySnapshot)
    func sessionEnded(sessionID: UUID)
    func noActiveSessionRestored()
}

struct NoopParkingActivityLifecycleManager: ParkingActivityLifecycleManaging {
    func sessionStarted(_ snapshot: ParkingActivitySnapshot) {}
    func activeSessionRestored(_ snapshot: ParkingActivitySnapshot) {}
    func activeSessionUpdated(_ snapshot: ParkingActivitySnapshot) {}
    func sessionEnded(sessionID: UUID) {}
    func noActiveSessionRestored() {}
}

@MainActor
final class ParkingSessionStore: ObservableObject {
    @Published private(set) var sessions: [ParkingSession] = []
    @Published private(set) var now: Date = Date()

    private let storage: ParkingSessionStorageServiceProtocol
    private let notifications: ParkingNotificationServiceProtocol
    private let activityLifecycle: ParkingActivityLifecycleManaging
    private let nowProvider: () -> Date
    private let displayFormatter = ParkingSessionDisplayFormatter()
    private let dueSoonThreshold: TimeInterval = 15 * 60

    private var timer: Timer?
    private var hasLoadedFromDisk = false

    init(
        storage: ParkingSessionStorageServiceProtocol = ParkingSessionStorageService(),
        notifications: ParkingNotificationServiceProtocol = ParkingNotificationService(),
        activityLifecycle: ParkingActivityLifecycleManaging = NoopParkingActivityLifecycleManager(),
        nowProvider: @escaping () -> Date = { Date() }
    ) {
        self.storage = storage
        self.notifications = notifications
        self.activityLifecycle = activityLifecycle
        self.nowProvider = nowProvider
        self.now = nowProvider()
    }

    func start() {
        if !hasLoadedFromDisk {
            loadFromDisk()
            hasLoadedFromDisk = true
            if let activeSession {
                activityLifecycle.activeSessionRestored(activitySnapshot(for: activeSession))
            } else {
                activityLifecycle.noActiveSessionRestored()
            }
        }
        startClock()
    }

    var activeSession: ParkingSession? {
        sessions.first(where: { $0.persistedStatus == .active })
    }

    var quickStartLocationName: String {
        ParkingSessionDraft.quickStartLocationName
    }

    var quickStartDurationOptions: [Int] {
        let defaultOptions = [30, 60, 120]
        guard let recent = mostRecentCompletedSessionDurationMinutes() else {
            return defaultOptions
        }
        guard !defaultOptions.contains(recent) else {
            return defaultOptions
        }
        return defaultOptions + [recent]
    }

    var isActiveSessionExpired: Bool {
        isActiveSessionOverdue
    }

    var isActiveSessionOverdue: Bool {
        guard let activeSession else { return false }
        return isActiveSessionOverdue(activeSession)
    }

    func isActiveSessionExpired(_ session: ParkingSession) -> Bool {
        isActiveSessionOverdue(session)
    }

    func isActiveSessionOverdue(_ session: ParkingSession) -> Bool {
        status(for: session) == .overdue
    }

    func remainingTimeInterval(for session: ParkingSession) -> TimeInterval {
        max(0, session.expectedEndTime.timeIntervalSince(now))
    }

    func status(for session: ParkingSession) -> ParkingSessionStatus {
        let rawRemaining = session.expectedEndTime.timeIntervalSince(now)

        if rawRemaining > dueSoonThreshold {
            return .active
        }
        if rawRemaining > 0 {
            return .dueSoon
        }
        return .overdue
    }

    func displayTimeInterval(for session: ParkingSession) -> TimeInterval {
        abs(session.expectedEndTime.timeIntervalSince(now))
    }

    func timerDisplay(for session: ParkingSession) -> ParkingSessionTimerDisplay {
        let status = status(for: session)
        let displayTime = displayTimeInterval(for: session)
        let timeText = displayFormatter.formatTimeInterval(displayTime)
        return ParkingSessionTimerDisplay(
            status: status,
            label: status.label,
            displayTime: displayTime,
            timeText: timeText
        )
    }

    func startNewSession(
        locationName: String,
        duration: TimeInterval,
        note: String,
        coordinate: (lat: Double, lon: Double)?
    ) async {
        await startNewSession(
            from: ParkingSessionDraft(
                locationName: locationName,
                duration: duration,
                note: note,
                coordinate: coordinate,
                source: .fullForm
            )
        )
    }

    func startNewSession(from draft: ParkingSessionDraft) async {
        guard draft.duration > 0 else { return }

        // Phase 1 assumption: only one active session at a time.
        if let active = activeSession {
            await endSession(id: active.id)
        }

        let start = nowProvider()
        let expectedEnd = start.addingTimeInterval(draft.duration)

        let new = ParkingSession(
            locationName: draft.locationName,
            latitude: draft.coordinate?.lat,
            longitude: draft.coordinate?.lon,
            startTime: start,
            expectedEndTime: expectedEnd,
            actualEndTime: nil,
            note: draft.note,
            persistedStatus: .active
        )

        sessions.insert(new, at: 0)
        persist()

        await notifications.scheduleNotifications(for: new)
        activityLifecycle.sessionStarted(activitySnapshot(for: new))
    }

    func endActiveSession() async {
        guard let active = activeSession else { return }
        await endSession(id: active.id)
    }

    func addTimeToActiveSession(minutes: Int) async {
        guard minutes > 0, let active = activeSession else { return }
        await addTime(to: active.id, minutes: minutes)
    }

    func addTime(to sessionID: UUID, minutes: Int) async {
        guard minutes > 0,
              let idx = sessions.firstIndex(where: { $0.id == sessionID && $0.persistedStatus == .active })
        else { return }

        sessions[idx].expectedEndTime = sessions[idx].expectedEndTime.addingTimeInterval(TimeInterval(minutes * 60))
        let updated = sessions[idx]

        persist()
        await notifications.cancelNotifications(for: sessionID)
        await notifications.scheduleNotifications(for: updated)
        activityLifecycle.activeSessionUpdated(activitySnapshot(for: updated))
    }

    func endSession(id: UUID) async {
        guard let idx = sessions.firstIndex(where: { $0.id == id }) else { return }
        var s = sessions[idx]
        s.actualEndTime = nowProvider()
        s.persistedStatus = .completed
        sessions[idx] = s

        persist()
        await notifications.cancelNotifications(for: id)
        activityLifecycle.sessionEnded(sessionID: id)
    }

    func remainingTimeString(for session: ParkingSession) -> String {
        timerDisplay(for: session).timeText
    }

    func activitySnapshot(for session: ParkingSession) -> ParkingActivitySnapshot {
        ParkingActivitySnapshot(
            sessionID: session.id,
            locationName: session.locationName,
            startDate: session.startTime,
            scheduledEndDate: session.expectedEndTime,
            lastUpdatedDate: nowProvider()
        )
    }

    // MARK: - Private

    private func loadFromDisk() {
        do {
            sessions = try storage.load()
        } catch {
            sessions = []
        }
    }

    private func persist() {
        do {
            try storage.save(sessions)
        } catch {
            // MVP: ignore; in production we would surface an error state.
        }
    }

    private func mostRecentCompletedSessionDurationMinutes() -> Int? {
        let completed = sessions
            .filter { $0.persistedStatus == .completed }
            .sorted {
                ($0.actualEndTime ?? $0.startTime) > ($1.actualEndTime ?? $1.startTime)
            }

        guard let recent = completed.first else { return nil }

        let rawMinutes = recent.expectedEndTime.timeIntervalSince(recent.startTime) / 60
        guard rawMinutes.isFinite, rawMinutes > 0 else { return nil }

        let roundedToFive = Int((rawMinutes / 5).rounded() * 5)
        return min(max(roundedToFive, 15), 240)
    }

    private func startClock() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.now = self.nowProvider()
            }
        }
    }

}
