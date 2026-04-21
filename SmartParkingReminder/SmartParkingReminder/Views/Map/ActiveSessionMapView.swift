import MapKit
import SwiftUI

struct ActiveSessionMapView: View {
    let session: ParkingSession

    @State private var camera: MapCameraPosition = .automatic

    var body: some View {
        Group {
            if let coordinate {
                Map(position: $camera) {
                    Marker(session.locationName, coordinate: coordinate)
                }
                .mapStyle(.standard)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .onAppear {
                    // Center the camera on the saved parking coordinate.
                    camera = .region(MKCoordinateRegion(
                        center: coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    ))
                }
            } else {
                ContentUnavailableView(
                    "No Location Saved",
                    systemImage: "map",
                    description: Text("Location permission may be off, or the location could not be determined.")
                )
            }
        }
    }

    private var coordinate: CLLocationCoordinate2D? {
        guard let lat = session.latitude, let lon = session.longitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
}
