import SwiftUI

struct ActiveSessionCardView: View {
    let session: ParkingSession
    let remainingText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(session.locationName)
                .font(.title2)
                .fontWeight(.semibold)

            HStack {
                Text("Remaining")
                    .foregroundStyle(.secondary)
                Spacer()
                Text(remainingText)
                    .monospacedDigit()
                    .fontWeight(.medium)
            }

            if !session.note.isEmpty {
                Text(session.note)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            if let lat = session.latitude, let lon = session.longitude {
                Label("\(lat, specifier: "%.4f"), \(lon, specifier: "%.4f")", systemImage: "location")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                Label("No location saved", systemImage: "location.slash")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
