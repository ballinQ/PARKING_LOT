import ActivityKit
import SwiftUI
import WidgetKit

@main
struct SmartParkingReminderWidgetBundle: WidgetBundle {
    var body: some Widget {
        ParkingReminderLiveActivityWidget()
    }
}

struct ParkingReminderLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ParkingReminderActivityAttributes.self) { context in
            ParkingReminderLockScreenView(context: context)
                .activityBackgroundTint(Color(.systemBackground))
                .activitySystemActionForegroundColor(.primary)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    TimelineView(.periodic(from: .now, by: 15)) { timeline in
                        let status = liveStatus(context: context, now: timeline.date)
                        Image(systemName: "parkingsign.circle.fill")
                            .font(.caption)
                            .foregroundStyle(statusColor(status))
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    liveIslandTimerView(context: context)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    EmptyView()
                }
            } compactLeading: {
                TimelineView(.periodic(from: .now, by: 15)) { timeline in
                    Image(systemName: "parkingsign.circle.fill")
                        .font(.caption2)
                        .foregroundStyle(statusColor(liveStatus(context: context, now: timeline.date)))
                }
            } compactTrailing: {
                liveIslandTimerView(context: context)
            } minimal: {
                TimelineView(.periodic(from: .now, by: 15)) { timeline in
                    Image(systemName: "parkingsign.circle.fill")
                        .font(.caption2)
                        .foregroundStyle(statusColor(liveStatus(context: context, now: timeline.date)))
                }
            }
        }
    }
}

private struct ParkingReminderLockScreenView: View {
    let context: ActivityViewContext<ParkingReminderActivityAttributes>

    var body: some View {
        TimelineView(.periodic(from: .now, by: 15)) { timeline in
            let status = liveStatus(context: context, now: timeline.date)
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline) {
                    Label("Parking", systemImage: "parkingsign.circle.fill")
                        .font(.headline)
                        .foregroundStyle(statusColor(status))
                    Spacer()
                    Text(status.label)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(statusColor(status))
                }

                Text(context.state.locationName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                activityTimeView(context: context, status: status, includesOverduePrefix: true)
                    .font(.system(.title2, design: .rounded).weight(.bold))
                    .monospacedDigit()
            }
            .padding()
        }
    }
}

@ViewBuilder
private func liveIslandTimerView(context: ActivityViewContext<ParkingReminderActivityAttributes>) -> some View {
    TimelineView(.periodic(from: .now, by: 15)) { timeline in
        let status = liveStatus(context: context, now: timeline.date)
        activityTimeView(context: context, status: status, includesOverduePrefix: false)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(statusColor(status))
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .frame(maxWidth: 40, alignment: .trailing)
    }
}

@ViewBuilder
private func activityTimeView(
    context: ActivityViewContext<ParkingReminderActivityAttributes>,
    status: ParkingReminderActivityStatus,
    includesOverduePrefix: Bool
) -> some View {
    if status == .overdue {
        HStack(spacing: 3) {
            if includesOverduePrefix {
                Text("Overdue by")
            }
            liveOverdueTimerText(from: context.state.scheduledEndDate)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.75)
    } else {
        liveCountdownTimerText(until: context.state.scheduledEndDate)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
    }
}

private func liveCountdownTimerText(until endDate: Date) -> Text {
    let now = Date.now
    return Text(timerInterval: now...max(now, endDate), countsDown: true)
}

private func liveOverdueTimerText(from endDate: Date) -> Text {
    let now = Date.now
    return Text(timerInterval: min(now, endDate)...Date.distantFuture, countsDown: false)
}

private func liveStatus(
    context: ActivityViewContext<ParkingReminderActivityAttributes>,
    now: Date
) -> ParkingReminderActivityStatus {
    let remaining = context.state.scheduledEndDate.timeIntervalSince(now)
    if remaining <= 0 {
        return .overdue
    }
    if remaining <= 15 * 60 {
        return .dueSoon
    }
    return .active
}

private func statusColor(_ status: ParkingReminderActivityStatus) -> Color {
    switch status {
    case .active:
        return .blue
    case .dueSoon:
        return .orange
    case .overdue:
        return .red
    }
}
