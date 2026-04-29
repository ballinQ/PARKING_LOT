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
                    Label("Parking", systemImage: "parkingsign.circle.fill")
                        .font(.headline)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.status.label)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(statusColor(context.state.status))
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(context.attributes.locationName)
                            .font(.caption)
                            .lineLimit(1)
                        Text(activityTimeText(context: context))
                            .font(.title3.weight(.semibold))
                            .monospacedDigit()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            } compactLeading: {
                Image(systemName: "parkingsign.circle.fill")
                    .foregroundStyle(statusColor(context.state.status))
            } compactTrailing: {
                Text(context.state.timeText)
                    .font(.caption2.weight(.semibold))
                    .monospacedDigit()
            } minimal: {
                Image(systemName: "parkingsign.circle.fill")
                    .foregroundStyle(statusColor(context.state.status))
            }
        }
    }
}

private struct ParkingReminderLockScreenView: View {
    let context: ActivityViewContext<ParkingReminderActivityAttributes>

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Label("Parking", systemImage: "parkingsign.circle.fill")
                    .font(.headline)
                Spacer()
                Text(context.state.status.label)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(statusColor(context.state.status))
            }

            Text(context.attributes.locationName)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Text(activityTimeText(context: context))
                .font(.system(.title2, design: .rounded).weight(.bold))
                .monospacedDigit()
        }
        .padding()
    }
}

private func activityTimeText(context: ActivityViewContext<ParkingReminderActivityAttributes>) -> String {
    if context.state.status == .overdue {
        return "Overdue by \(context.state.timeText)"
    }
    return context.state.timeText
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
