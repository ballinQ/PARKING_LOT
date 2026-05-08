import SwiftUI

struct ParkingSpotDetailSheetView: View {
    let group: ParkingSpotGroup
    let metadata: SavedParkingSpotMetadata
    let now: Date

    let onBack: () -> Void
    let onMetadataChange: (SavedParkingSpotMetadata) -> Void
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
                Text(group.displayName)
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

            PersonalSpotMetadataView(
                metadata: metadata,
                onMetadataChange: onMetadataChange
            )

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
                Button {
                    onOpenAppleMaps()
                } label: {
                    Label("Apple Maps", systemImage: "map")
                }
                .accessibilityIdentifier(A11y.detailOpenAppleMaps)
                .buttonStyle(.borderedProminent)

                Button {
                    onOpenGoogleMaps()
                } label: {
                    Label("Google Maps", systemImage: "arrow.triangle.turn.up.right.diamond")
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

private struct PersonalSpotMetadataView: View {
    let metadata: SavedParkingSpotMetadata
    let onMetadataChange: (SavedParkingSpotMetadata) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Saved spot")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Spacer()

                Button {
                    update { $0.isFavorite.toggle() }
                } label: {
                    Image(systemName: metadata.isFavorite ? "heart.fill" : "heart")
                        .foregroundStyle(metadata.isFavorite ? .red : .secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(metadata.isFavorite ? "Remove favorite" : "Mark favorite")
                .accessibilityIdentifier(A11y.detailFavoriteButton)
            }

            HStack(spacing: 4) {
                Text("Rating")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                ForEach(1...5, id: \.self) { value in
                    Button {
                        update {
                            $0.rating = metadata.rating == value ? nil : value
                        }
                    } label: {
                        Image(systemName: (metadata.rating ?? 0) >= value ? "star.fill" : "star")
                            .font(.caption)
                            .foregroundStyle((metadata.rating ?? 0) >= value ? .yellow : .secondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Rating \(value)")
                    .accessibilityIdentifier("\(A11y.detailRatingPrefix).\(value)")
                }

                Spacer()
            }

            tagChips

            TextField(
                "Spot name",
                text: Binding(
                    get: { metadata.displayName ?? "" },
                    set: { displayName in
                        update {
                            let trimmed = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
                            $0.displayName = trimmed.isEmpty ? nil : displayName
                        }
                    }
                )
            )
            .font(.footnote)
            .textInputAutocapitalization(.words)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color(.separator).opacity(0.45), lineWidth: 0.5)
            )
            .accessibilityIdentifier(A11y.detailSpotDisplayNameField)

            TextField(
                "Spot note",
                text: Binding(
                    get: { metadata.note },
                    set: { note in
                        update { $0.note = note }
                    }
                ),
                axis: .vertical
            )
            .font(.footnote)
            .lineLimit(2...4)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color(.separator).opacity(0.45), lineWidth: 0.5)
            )
            .accessibilityIdentifier(A11y.detailSpotNoteField)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .accessibilityIdentifier(A11y.detailPersonalMetadata)
    }

    private var tagChips: some View {
        let columns = [
            GridItem(.adaptive(minimum: 74), spacing: 6)
        ]

        return LazyVGrid(columns: columns, alignment: .leading, spacing: 6) {
            ForEach(SavedParkingSpotMetadata.defaultTags, id: \.self) { tag in
                Button {
                    update { metadata in
                        if metadata.tags.contains(tag) {
                            metadata.tags.removeAll { $0 == tag }
                        } else {
                            metadata.tags.append(tag)
                            metadata.tags.sort()
                        }
                    }
                } label: {
                    Text(tag)
                        .font(.caption.weight(.semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .foregroundStyle(metadata.tags.contains(tag) ? .white : .primary)
                        .background(
                            Capsule(style: .continuous)
                                .fill(metadata.tags.contains(tag) ? Color.blue : Color(.secondarySystemFill))
                        )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("\(A11y.detailTagPrefix).\(tag)")
            }
        }
    }

    private func update(_ mutate: (inout SavedParkingSpotMetadata) -> Void) {
        var next = metadata
        mutate(&next)
        onMetadataChange(next)
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
