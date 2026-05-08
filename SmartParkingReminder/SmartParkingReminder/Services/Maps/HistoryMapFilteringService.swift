import CoreLocation
import Foundation

struct HistoryMapFilteringService {
    func filterMetadata(
        groups: [ParkingSpotGroup],
        metadataFilter: HistorySpotMetadataFilter
    ) -> [ParkingSpotGroup] {
        groups.filter { metadataFilter.matches($0) }
    }

    func filterLocalHistory(
        groups: [ParkingSpotGroup],
        query: String,
        metadataFilter: HistorySpotMetadataFilter
    ) -> [ParkingSpotGroup] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            return filterMetadata(groups: groups, metadataFilter: metadataFilter)
        }

        let matchingGroups = groups.filter { group in
            group.matchesLocalHistorySearch(trimmedQuery)
        }

        return filterMetadata(groups: matchingGroups, metadataFilter: metadataFilter)
    }

    func filterNearby(
        groups: [ParkingSpotGroup],
        center: CLLocationCoordinate2D,
        radiusMeters: CLLocationDistance,
        metadataFilter: HistorySpotMetadataFilter
    ) -> [ParkingSpotGroup] {
        let centerLocation = CLLocation(latitude: center.latitude, longitude: center.longitude)

        return groups.compactMap { group -> (group: ParkingSpotGroup, distance: CLLocationDistance)? in
            let groupLocation = CLLocation(latitude: group.coordinate.latitude, longitude: group.coordinate.longitude)
            let distance = centerLocation.distance(from: groupLocation)
            guard distance <= radiusMeters, metadataFilter.matches(group) else { return nil }
            return (group, distance)
        }
        .sorted { $0.distance < $1.distance }
        .map(\.group)
    }
}

private extension ParkingSpotGroup {
    func matchesLocalHistorySearch(_ query: String) -> Bool {
        if displayName.localizedCaseInsensitiveContains(query) || name.localizedCaseInsensitiveContains(query) {
            return true
        }

        if metadata?.matchesSearch(query) == true {
            return true
        }

        return sessions.contains { session in
            session.locationName.localizedCaseInsensitiveContains(query)
            || session.note.localizedCaseInsensitiveContains(query)
        }
    }
}
