import XCTest
import CoreLocation
@testable import SmartParkingReminder

final class Phase1ModelAndLogicTests: XCTestCase {

    // TC-04 (P0) Countdown and overdue transition
    func test_TC04_CountdownAndOverdueTransition() throws {
        let start = ISO8601DateFormatter().date(from: "2026-04-22T15:00:00Z")!
        let expectedEnd = start.addingTimeInterval(60) // +1 min

        let s = ParkingSession(
            locationName: "Lot A",
            latitude: nil,
            longitude: nil,
            startTime: start,
            expectedEndTime: expectedEnd,
            actualEndTime: nil,
            note: "",
            persistedStatus: .active
        )

        XCTAssertEqual(s.displayStatus(now: start), .active)
        XCTAssertGreaterThan(s.remainingTimeInterval(now: start), 0)

        XCTAssertEqual(s.displayStatus(now: expectedEnd), .overdue)
        XCTAssertLessThanOrEqual(s.remainingTimeInterval(now: expectedEnd), 0)

        XCTAssertEqual(s.displayStatus(now: expectedEnd.addingTimeInterval(5)), .overdue)
    }

    // TC-10 (P1) Group nearby sessions into one marker
    func test_TC10_GroupNearbySessions() throws {
        let svc = ParkingSpotGroupingService(thresholdMeters: 30)

        // Two coordinates within a few meters.
        let a = CLLocationCoordinate2D(latitude: 43.653200, longitude: -79.383200)
        let b = CLLocationCoordinate2D(latitude: 43.653205, longitude: -79.383205)

        let t0 = ISO8601DateFormatter().date(from: "2026-04-22T15:00:00Z")!
        let t1 = t0.addingTimeInterval(60)

        let s0 = ParkingSession(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            locationName: "Spot 1",
            latitude: a.latitude,
            longitude: a.longitude,
            startTime: t0,
            expectedEndTime: t0.addingTimeInterval(600),
            actualEndTime: nil,
            note: "",
            persistedStatus: .completed
        )

        let s1 = ParkingSession(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
            locationName: "Spot 2",
            latitude: b.latitude,
            longitude: b.longitude,
            startTime: t1,
            expectedEndTime: t1.addingTimeInterval(600),
            actualEndTime: nil,
            note: "",
            persistedStatus: .completed
        )

        let groups = svc.groupSessions([s0, s1])
        XCTAssertEqual(groups.count, 1)
        XCTAssertEqual(groups.first?.count, 2)

        // Name should come from most recent session (s1)
        XCTAssertEqual(groups.first?.name, "Spot 2")
    }

    func test_TC10_GroupingThreshold_BeyondThresholdCreatesSeparateGroups() throws {
        let svc = ParkingSpotGroupingService(thresholdMeters: 30)

        let a = CLLocationCoordinate2D(latitude: 43.653200, longitude: -79.383200)
        // ~60m north-ish (roughly 0.00054 deg lat ~ 60m)
        let far = CLLocationCoordinate2D(latitude: 43.653740, longitude: -79.383200)

        let t0 = ISO8601DateFormatter().date(from: "2026-04-22T15:00:00Z")!

        let s0 = ParkingSession(locationName: "A", latitude: a.latitude, longitude: a.longitude, startTime: t0, expectedEndTime: t0, actualEndTime: nil, note: "", persistedStatus: .completed)
        let s1 = ParkingSession(locationName: "B", latitude: far.latitude, longitude: far.longitude, startTime: t0.addingTimeInterval(1), expectedEndTime: t0, actualEndTime: nil, note: "", persistedStatus: .completed)

        let groups = svc.groupSessions([s0, s1])
        XCTAssertEqual(groups.count, 2)
    }
}
