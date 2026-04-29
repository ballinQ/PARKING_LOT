import SwiftUI

struct ParkingSpotDetailSheetView: View {
    let group: ParkingSpotGroup
    let now: Date

    let onBack: () -> Void
    let onOpenAppleMaps: () -> Void
    let onOpenGoogleMaps: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Button {
                onBack()
            } label: {
                Text("< Personal History")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.blue)
            .accessibilityIdentifier(A11y.detailBackButton)

            VStack(alignment: .leading, spacing: 4) {
                Text(group.name)
                    .accessibilityIdentifier(A11y.detailSpotName)
                    .font(.title3)
                    .fontWeight(.semibold)

                Text("\(group.count) session\(group.count == 1 ? "" : "s")")
                    .accessibilityIdentifier(A11y.detailSpotCount)
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Text("Lat/Lon: \(group.coordinate.latitude, specifier: "%.5f"), \(group.coordinate.longitude, specifier: "%.5f")")
                    .accessibilityIdentifier(A11y.detailSpotLatLon)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            StatusSummaryView(group: group, now: now)

            VStack(alignment: .leading, spacing: 8) {
                Text("Recent sessions")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                ForEach(group.sessions.prefix(5)) { s in
                    let timing = s.timingOutcome(now: now)

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(s.startTime.formatted(date: .abbreviated, time: .shortened))
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(timing.statusLine)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(timing.result == .overdue ? .red : .secondary)
                        }

                        Text("Expected end: \(s.expectedEndTime.formatted(date: .abbreviated, time: .shortened))")
                            .font(.footnote)

                        if let actualEndTime = s.actualEndTime {
                            Text("Ended: \(actualEndTime.formatted(date: .abbreviated, time: .shortened))")
                                .font(.footnote)
                        }

                        if let overdueLine = s.historyOverdueLine(now: now) {
                            Text(overdueLine)
                                .font(.footnote)
                                .fontWeight(.semibold)
                                .foregroundStyle(.red)
                        }

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
                .accessibilityIdentifier(A11y.detailOpenAppleMaps)
                .buttonStyle(.borderedProminent)

                Button("Open in Google Maps") {
                    onOpenGoogleMaps()
                }
                .accessibilityIdentifier(A11y.detailOpenGoogleMaps)
                .buttonStyle(.bordered)

                Spacer()
            }
        }
        .padding()
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(A11y.detailSheet)
        .presentationDragIndicator(.visible)
    }
}

private struct StatusSummaryView: View {
    let group: ParkingSpotGroup
    let now: Date

    var body: some View {
        let summary = group.timingSummary(now: now)

        return HStack(spacing: 12) {
            SummaryPill(title: "On Time", value: summary.onTime, color: .green)
            SummaryPill(title: "Active", value: summary.active, color: .blue)
            SummaryPill(title: "Overdue", value: summary.overdue, color: .red)
            Spacer()
        }
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
