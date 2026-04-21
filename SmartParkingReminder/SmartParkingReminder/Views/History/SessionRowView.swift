import CoreLocation
import SwiftUI

struct SessionRowView: View {
    let session: ParkingSession
    let now: Date

    private let mapHandoff = MapHandoffService()

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(session.locationName)
                    .font(.headline)
                Spacer()
                statusPill
            }

            Text(subtitle)
                .font(.footnote)
                .foregroundStyle(.secondary)

            if !session.note.isEmpty {
                Text(session.note)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
        .contextMenu {
            if let coordinate {
                Button("Open in Apple Maps") {
                    mapHandoff.openDirections(to: coordinate, placeName: session.locationName, preferred: .appleMaps)
                }
                Button("Open in Google Maps") {
                    mapHandoff.openDirections(to: coordinate, placeName: session.locationName, preferred: .googleMaps)
                }
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            if let coordinate {
                Button("Maps") {
                    mapHandoff.openDirections(to: coordinate, placeName: session.locationName, preferred: nil)
                }
                .tint(.blue)
            }
        }
    }

    private var coordinate: CLLocationCoordinate2D? {
        guard let lat = session.latitude, let lon = session.longitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    private var subtitle: String {
        let start = session.startTime.formatted(date: .abbreviated, time: .shortened)
        let expected = session.expectedEndTime.formatted(date: .abbreviated, time: .shortened)
        return "Start: \(start) • Expected end: \(expected)"
    }

    @ViewBuilder
    private var statusPill: some View {
        let status = session.displayStatus(now: now)
        Text(status.rawValue.capitalized)
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(background(for: status))
            .foregroundStyle(foreground(for: status))
            .clipShape(Capsule())
    }

    private func background(for status: ParkingSession.DisplayStatus) -> Color {
        switch status {
        case .active: return Color.blue.opacity(0.15)
        case .overdue: return Color.red.opacity(0.15)
        case .completed: return Color.green.opacity(0.15)
        }
    }

    private func foreground(for status: ParkingSession.DisplayStatus) -> Color {
        switch status {
        case .active: return .blue
        case .overdue: return .red
        case .completed: return .green
        }
    }
}
