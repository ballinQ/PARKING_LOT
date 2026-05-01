import Foundation

#if canImport(ActivityKit)
import ActivityKit

@available(iOS 16.2, *)
final class ActivityKitParkingActivityLifecycleManager: ParkingActivityLifecycleManaging {
    private var lastUpdateBySessionID: [String: Date] = [:]
    private var lastStatusBySessionID: [String: ParkingSessionStatus] = [:]
    private let minimumUpdateInterval: TimeInterval

    init(minimumUpdateInterval: TimeInterval = 60) {
        self.minimumUpdateInterval = minimumUpdateInterval
    }

    func sessionStarted(_ snapshot: ParkingActivitySnapshot) {
        Task {
            await startOrUpdateActivity(for: snapshot, forceUpdate: true)
        }
    }

    func activeSessionRestored(_ snapshot: ParkingActivitySnapshot) {
        Task {
            await startOrUpdateActivity(for: snapshot, forceUpdate: true)
        }
    }

    func activeSessionUpdated(_ snapshot: ParkingActivitySnapshot) {
        guard shouldPublishUpdate(for: snapshot) else { return }
        Task {
            await startOrUpdateActivity(for: snapshot, forceUpdate: false)
        }
    }

    func sessionEnded(sessionID: UUID) {
        Task {
            await endActivity(sessionID: sessionID.uuidString)
        }
    }

    private func startOrUpdateActivity(for snapshot: ParkingActivitySnapshot, forceUpdate: Bool) async {
        let sessionID = snapshot.sessionID.uuidString

        if let existing = activity(for: sessionID) {
            await update(existing, with: snapshot)
            recordPublished(snapshot)
            return
        }

        guard forceUpdate else { return }

        let attributes = ParkingReminderActivityAttributes(snapshot: snapshot)
        let content = ActivityContent(
            state: ParkingReminderActivityAttributes.ContentState(snapshot: snapshot),
            staleDate: snapshot.expectedEndTime.addingTimeInterval(60 * 60)
        )

        do {
            _ = try Activity<ParkingReminderActivityAttributes>.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
            recordPublished(snapshot)
            #if DEBUG
            print("Live Activity requested for session \(sessionID) with status \(snapshot.status.label)")
            #endif
        } catch {
            // ActivityKit can be unavailable or disabled. Local notifications remain the fallback.
            #if DEBUG
            print("Live Activity request failed for session \(sessionID): \(error.localizedDescription)")
            #endif
        }
    }

    private func update(
        _ activity: Activity<ParkingReminderActivityAttributes>,
        with snapshot: ParkingActivitySnapshot
    ) async {
        let content = ActivityContent(
            state: ParkingReminderActivityAttributes.ContentState(snapshot: snapshot),
            staleDate: snapshot.expectedEndTime.addingTimeInterval(60 * 60)
        )
        await activity.update(content)
        #if DEBUG
        print("Live Activity updated for session \(activity.attributes.sessionID) with status \(snapshot.status.label)")
        #endif
    }

    private func endActivity(sessionID: String) async {
        guard let existing = activity(for: sessionID) else { return }
        await existing.end(nil, dismissalPolicy: .immediate)
        lastUpdateBySessionID[sessionID] = nil
        lastStatusBySessionID[sessionID] = nil
        #if DEBUG
        print("Live Activity ended for session \(sessionID)")
        #endif
    }

    private func activity(for sessionID: String) -> Activity<ParkingReminderActivityAttributes>? {
        Activity<ParkingReminderActivityAttributes>.activities.first {
            $0.attributes.sessionID == sessionID
        }
    }

    private func shouldPublishUpdate(for snapshot: ParkingActivitySnapshot) -> Bool {
        let sessionID = snapshot.sessionID.uuidString
        if lastStatusBySessionID[sessionID] != snapshot.status {
            return true
        }
        guard let lastUpdate = lastUpdateBySessionID[sessionID] else {
            return true
        }
        return snapshot.updatedAt.timeIntervalSince(lastUpdate) >= minimumUpdateInterval
    }

    private func recordPublished(_ snapshot: ParkingActivitySnapshot) {
        let sessionID = snapshot.sessionID.uuidString
        lastUpdateBySessionID[sessionID] = snapshot.updatedAt
        lastStatusBySessionID[sessionID] = snapshot.status
    }
}

@available(iOS 16.2, *)
extension ParkingReminderActivityAttributes {
    init(snapshot: ParkingActivitySnapshot) {
        self.init(
            sessionID: snapshot.sessionID.uuidString,
            locationName: snapshot.locationName,
            expectedEndTime: snapshot.expectedEndTime
        )
    }
}

@available(iOS 16.2, *)
extension ParkingReminderActivityAttributes.ContentState {
    init(snapshot: ParkingActivitySnapshot) {
        self.init(
            status: ParkingReminderActivityStatus(snapshot.status),
            displayTime: snapshot.displayTime,
            timeText: snapshot.timeText,
            updatedAt: snapshot.updatedAt
        )
    }
}

extension ParkingReminderActivityStatus {
    init(_ status: ParkingSessionStatus) {
        switch status {
        case .active:
            self = .active
        case .dueSoon:
            self = .dueSoon
        case .overdue:
            self = .overdue
        }
    }
}
#endif
