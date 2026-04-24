import Foundation

@MainActor
final class ParkingSessionStore: ObservableObject {
    @Published private(set) var sessions: [ParkingSession] = []
    @Published private(set) var now: Date = Date()

    private let storage: ParkingSessionStorageServiceProtocol
    private let notifications: ParkingNotificationServiceProtocol
    private let nowProvider: () -> Date

    private var timer: Timer?
    private var hasLoadedFromDisk = false

    init(
        storage: ParkingSessionStorageServiceProtocol = ParkingSessionStorageService(),
        notifications: ParkingNotificationServiceProtocol = ParkingNotificationService(),
        nowProvider: @escaping () -> Date = { Date() }
    ) {
        self.storage = storage
        self.notifications = notifications
        self.nowProvider = nowProvider
    }

    func start() {
        if !hasLoadedFromDisk {
            loadFromDisk()
            hasLoadedFromDisk = true
        }
        startClock()
    }

    var activeSession: ParkingSession? {
        sessions.first(where: { $0.persistedStatus == .active })
    }

    func startNewSession(
        locationName: String,
        duration: TimeInterval,
        note: String,
        coordinate: (lat: Double, lon: Double)?
    ) async {
        // Phase 1 assumption: only one active session at a time.
        if let active = activeSession {
            await endSession(id: active.id)
        }

        let start = nowProvider()
        let expectedEnd = start.addingTimeInterval(duration)

        let new = ParkingSession(
            locationName: locationName,
            latitude: coordinate?.lat,
            longitude: coordinate?.lon,
            startTime: start,
            expectedEndTime: expectedEnd,
            actualEndTime: nil,
            note: note,
            persistedStatus: .active
        )

        sessions.insert(new, at: 0)
        persist()

        await notifications.scheduleNotifications(for: new)
    }

    func endActiveSession() async {
        guard let active = activeSession else { return }
        await endSession(id: active.id)
    }

    func endSession(id: UUID) async {
        guard let idx = sessions.firstIndex(where: { $0.id == id }) else { return }
        var s = sessions[idx]
        s.actualEndTime = nowProvider()
        s.persistedStatus = .completed
        sessions[idx] = s

        persist()
        await notifications.cancelNotifications(for: id)
    }

    func remainingTimeString(for session: ParkingSession) -> String {
        formatTimeInterval(session.remainingTimeInterval(now: now))
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

    private func startClock() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.now = self?.nowProvider() ?? Date()
            }
        }
    }

    private func formatTimeInterval(_ interval: TimeInterval) -> String {
        let clamped = Int(interval.rounded(.down))
        let isNegative = clamped < 0
        let seconds = abs(clamped)

        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60

        if h > 0 {
            return "\(isNegative ? "-" : "")\(h)h \(m)m \(s)s"
        } else {
            return "\(isNegative ? "-" : "")\(m)m \(s)s"
        }
    }
}
