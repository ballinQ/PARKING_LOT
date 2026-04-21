import MapKit
import SwiftUI

struct HistoryMapView: View {
    let sessions: [ParkingSession]
    let now: Date

    @StateObject private var vm = HistoryMapViewModel()
    private let mapHandoff = MapHandoffService()

    @State private var camera: MapCameraPosition = .automatic

    var body: some View {
        ZStack {
            if vm.groups.isEmpty {
                ContentUnavailableView(
                    "No Locations Yet",
                    systemImage: "map",
                    description: Text("Start sessions with location permission enabled to see them on the map.")
                )
            } else {
                Map(position: $camera, selection: $vm.selectedGroupID) {
                    ForEach(vm.groups) { group in
                        Marker(markerTitle(for: group), coordinate: group.coordinate)
                            .tag(group.id)
                    }
                }
                .mapStyle(.standard)
            }
        }
        .onAppear {
            vm.updateSessions(sessions)
            camera = vm.defaultCameraPosition()
        }
        .onChange(of: sessions.count) { _, _ in
            vm.updateSessions(sessions)
        }
        // UX rule: marker tap => show details; navigation only from buttons inside the sheet.
        .sheet(item: $vm.selectedGroup) { group in
            ParkingSpotDetailSheetView(
                group: group,
                now: now,
                onOpenAppleMaps: {
                    mapHandoff.openDirections(to: group.coordinate, placeName: group.name, preferred: .appleMaps)
                },
                onOpenGoogleMaps: {
                    mapHandoff.openDirections(to: group.coordinate, placeName: group.name, preferred: .googleMaps)
                }
            )
            .presentationDetents([.medium, .large])
        }
    }

    private func markerTitle(for group: ParkingSpotGroup) -> String {
        group.count <= 1 ? group.name : "\(group.name) (\(group.count))"
    }
}
