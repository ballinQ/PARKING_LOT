import Foundation

#if canImport(ActivityKit)
import ActivityKit

@available(iOS 16.2, *)
final class ActivityKitParkingActivityLifecycleManager: ParkingActivityLifecycleManaging {
    init(minimumUpdateInterval: TimeInterval = 60) {}

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
        Task {
            await startOrUpdateActivity(for: snapshot, forceUpdate: true)
        }
    }

    func sessionEnded(sessionID: UUID) {
        Task {
            await endActivity(sessionID: sessionID.uuidString)
        }
    }

    func noActiveSessionRestored() {
        Task {
            await endOrphanedActivities(activeSessionID: nil)
        }
    }

    private func startOrUpdateActivity(for snapshot: ParkingActivitySnapshot, forceUpdate: Bool) async {
        let sessionID = snapshot.sessionID.uuidString

        if let existing = activity(for: sessionID) {
            await update(existing, with: snapshot)
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
            await endOrphanedActivities(activeSessionID: sessionID)
            #if DEBUG
            print("Live Activity requested for session \(sessionID)")
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
            staleDate: snapshot.scheduledEndDate.addingTimeInterval(60 * 60)
        )
        await activity.update(content)
        await endOrphanedActivities(activeSessionID: activity.attributes.sessionID)
        #if DEBUG
        print("Live Activity updated for session \(activity.attributes.sessionID)")
        #endif
    }

    private func endActivity(sessionID: String) async {
        guard let existing = activity(for: sessionID) else { return }
        await existing.end(nil, dismissalPolicy: .immediate)
        #if DEBUG
        print("Live Activity ended for session \(sessionID)")
        #endif
    }

    private func activity(for sessionID: String) -> Activity<ParkingReminderActivityAttributes>? {
        Activity<ParkingReminderActivityAttributes>.activities.first {
            $0.attributes.sessionID == sessionID
        }
    }

    private func endOrphanedActivities(activeSessionID: String?) async {
        for activity in Activity<ParkingReminderActivityAttributes>.activities
        where activity.attributes.sessionID != activeSessionID {
            await activity.end(nil, dismissalPolicy: .immediate)
            #if DEBUG
            print("Live Activity orphan ended for session \(activity.attributes.sessionID)")
            #endif
        }
    }
}

@available(iOS 16.2, *)
extension ParkingReminderActivityAttributes {
    init(snapshot: ParkingActivitySnapshot) {
        self.init(
            sessionID: snapshot.sessionID.uuidString,
            locationName: snapshot.locationName,
            startDate: snapshot.startDate
        )
    }
}

@available(iOS 16.2, *)
extension ParkingReminderActivityAttributes.ContentState {
    init(snapshot: ParkingActivitySnapshot) {
        self.init(
            sessionID: snapshot.sessionID.uuidString,
            locationName: snapshot.locationName,
            startDate: snapshot.startDate,
            scheduledEndDate: snapshot.scheduledEndDate,
            lastUpdatedDate: snapshot.lastUpdatedDate
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
