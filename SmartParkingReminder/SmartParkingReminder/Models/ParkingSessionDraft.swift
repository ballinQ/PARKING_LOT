import Foundation

struct ParkingSessionDraft {
    static let quickStartLocationName = "Quick Start"

    enum Source: String {
        case fullForm
        case quickStart
    }

    let locationName: String
    let duration: TimeInterval
    let note: String
    let coordinate: (lat: Double, lon: Double)?
    let source: Source

    static func quickStart(
        durationMinutes: Int,
        coordinate: (lat: Double, lon: Double)?
    ) -> ParkingSessionDraft {
        ParkingSessionDraft(
            locationName: quickStartLocationName,
            duration: TimeInterval(max(durationMinutes, 1) * 60),
            note: "",
            coordinate: coordinate,
            source: .quickStart
        )
    }

    static func fullForm(
        locationName: String,
        durationMinutes: Int,
        note: String,
        coordinate: (lat: Double, lon: Double)?
    ) -> ParkingSessionDraft {
        ParkingSessionDraft(
            locationName: locationName,
            duration: TimeInterval(max(durationMinutes, 1) * 60),
            note: note,
            coordinate: coordinate,
            source: .fullForm
        )
    }
}
