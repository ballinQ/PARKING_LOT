import SwiftUI

struct ParkingSpotDetailSheetView: View {
    let group: ParkingSpotGroup
    let now: Date

    let onOpenAppleMaps: () -> Void
    let onOpenGoogleMaps: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(group.name)
                    .font(.title3)
                    .fontWeight(.semibold)

                Text("\(group.count) session\(group.count == 1 ? "" : "s")")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Text("Lat/Lon: \(group.coordinate.latitude, specifier: "%.5f"), \(group.coordinate.longitude, specifier: "%.5f")")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            StatusSummaryView(group: group, now: now)

            VStack(alignment: .leading, spacing: 8) {
                Text("Recent sessions")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                ForEach(group.sessions.prefix(5)) { s in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(s.startTime.formatted(date: .abbreviated, time: .shortened))
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(s.displayStatus(now: now).rawValue.capitalized)
                                .font(.caption)
                                .fontWeight(.semibold)
                        }

                        Text("Expected end: \(s.expectedEndTime.formatted(date: .abbreviated, time: .shortened))")
                            .font(.footnote)

                        if !s.note.isEmpty {
                            Text(s.note)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .lineLimit(3)
                        }

                        Divider()
                    }
                }
            }

            HStack {
                Button("Open in Apple Maps") {
                    onOpenAppleMaps()
                }
                .buttonStyle(.borderedProminent)

                Button("Open in Google Maps") {
                    onOpenGoogleMaps()
                }
                .buttonStyle(.bordered)

                Spacer()
            }
        }
        .padding()
        .presentationDragIndicator(.visible)
    }
}

private struct StatusSummaryView: View {
    let group: ParkingSpotGroup
    let now: Date

    var body: some View {
        let summary = computeSummary()

        return HStack(spacing: 12) {
            SummaryPill(title: "Completed", value: summary.completed, color: .green)
            SummaryPill(title: "Active", value: summary.active, color: .blue)
            SummaryPill(title: "Overdue", value: summary.overdue, color: .red)
            Spacer()
        }
    }

    private func computeSummary() -> (completed: Int, active: Int, overdue: Int) {
        var completed = 0
        var active = 0
        var overdue = 0

        for s in group.sessions {
            switch s.displayStatus(now: now) {
            case .completed: completed += 1
            case .active: active += 1
            case .overdue: overdue += 1
            }
        }

        return (completed, active, overdue)
    }
}

private struct SummaryPill: View {
    let title: String
    let value: Int
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("\(value)")
                .font(.headline)
                .foregroundStyle(color)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(color.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}
