import ActivityKit
import Foundation

enum ParkingReminderActivityStatus: String, Codable, Hashable {
    case active
    case dueSoon
    case overdue

    var label: String {
        switch self {
        case .active:
            return "Remaining"
        case .dueSoon:
            return "Due Soon"
        case .overdue:
            return "Overdue"
        }
    }
}

struct ParkingReminderActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        let sessionID: String
        let locationName: String
        let startDate: Date
        let scheduledEndDate: Date
        let lastUpdatedDate: Date
    }

    let sessionID: String
    let locationName: String
    let startDate: Date
}
