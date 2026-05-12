import SwiftUI

struct ActiveSessionCardView: View {
    let session: ParkingSession
    let timerDisplay: ParkingSessionTimerDisplay

    private var statusColor: Color {
        switch timerDisplay.status {
        case .active:
            return .secondary
        case .dueSoon:
            return .orange
        case .overdue:
            return .red
        }
    }

    private var statusIcon: String {
        switch timerDisplay.status {
        case .active:
            return "timer"
        case .dueSoon:
            return "exclamationmark.triangle.fill"
        case .overdue:
            return "clock.badge.exclamationmark.fill"
        }
    }

    private var statusMessage: String {
        switch timerDisplay.status {
        case .active:
            return "Reminder is scheduled before your parking ends."
        case .dueSoon:
            return "Your parking time is almost up."
        case .overdue:
            return "Session stays active until you end parking."
        }
    }

    private var displayTimeText: String {
        switch timerDisplay.status {
        case .active, .dueSoon:
            return timerDisplay.timeText
        case .overdue:
            return "Overdue by \(timerDisplay.timeText)"
        }
    }

    private var progressValue: Double {
        let duration = max(session.expectedEndTime.timeIntervalSince(session.startTime), 1)
        let remaining = timerDisplay.status == .overdue ? 0 : min(timerDisplay.displayTime, duration)
        return min(max((duration - remaining) / duration, 0), 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.locationName)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .lineLimit(2)

                    Text(statusMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Label(timerDisplay.label, systemImage: statusIcon)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(statusColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(statusColor.opacity(0.12))
                    .clipShape(Capsule())
                    .accessibilityIdentifier(A11y.homeSessionStatusLabel)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(displayTimeText)
                    .font(.system(.largeTitle, design: .rounded))
                    .fontWeight(.bold)
                    .monospacedDigit()
                    .foregroundStyle(statusColor)
                    .minimumScaleFactor(0.75)
                    .lineLimit(1)
                    .accessibilityIdentifier(A11y.homeRemainingTimeLabel)

                ProgressView(value: progressValue)
                    .tint(statusColor)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(statusColor.opacity(timerDisplay.status == .active ? 0.06 : 0.10))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            if !session.note.isEmpty {
                Label {
                    Text(session.note)
                        .lineLimit(2)
                } icon: {
                    Image(systemName: "note.text")
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
            }

            HStack {
                if let lat = session.latitude, let lon = session.longitude {
                    Label("\(lat, specifier: "%.4f"), \(lon, specifier: "%.4f")", systemImage: "location")
                } else {
                    Label("No location saved", systemImage: "location.slash")
                }
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(Color(.tertiarySystemGroupedBackground))
            .clipShape(Capsule(style: .continuous))
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(timerDisplay.status == .active ? Color(.separator).opacity(0.35) : statusColor.opacity(0.35), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(A11y.homeActiveSessionCard)
    }
}
