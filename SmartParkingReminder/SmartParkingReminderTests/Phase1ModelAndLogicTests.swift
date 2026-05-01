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
        XCTAssertEqual(s.remainingTimeInterval(now: expectedEnd), 0)

        XCTAssertEqual(s.displayStatus(now: expectedEnd.addingTimeInterval(5)), .overdue)
        XCTAssertEqual(s.remainingTimeInterval(now: expectedEnd.addingTimeInterval(5)), 0)
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

    func test_Phase2DisplayFormatter_NeverFormatsNegativeIntervals() throws {
        let formatter = ParkingSessionDisplayFormatter()

        XCTAssertEqual(formatter.formatTimeInterval(-111), "0m 0s")
    }

    func test_Phase1HistoryTimingSummary_CompletedOnTimeSessionCountsOnTime() throws {
        let start = ISO8601DateFormatter().date(from: "2026-04-22T15:00:00Z")!
        let session = ParkingSession(
            locationName: "On Time Lot",
            latitude: 43.6532,
            longitude: -79.3832,
            startTime: start,
            expectedEndTime: start.addingTimeInterval(60),
            actualEndTime: start.addingTimeInterval(60),
            note: "",
            persistedStatus: .completed
        )
        let group = makeGroup(sessions: [session])

        let summary = group.timingSummary(now: start.addingTimeInterval(120))

        XCTAssertEqual(summary.onTime, 1)
        XCTAssertEqual(summary.active, 0)
        XCTAssertEqual(summary.overdue, 0)
        XCTAssertEqual(session.historyStatusLine(now: start.addingTimeInterval(120)), "Completed · On time")
        XCTAssertNil(session.historyOverdueLine(now: start.addingTimeInterval(120)))
    }

    func test_Phase1HistoryTimingSummary_CompletedOverdueSessionCountsOverdue() throws {
        let start = ISO8601DateFormatter().date(from: "2026-04-22T15:00:00Z")!
        let session = ParkingSession(
            locationName: "Late Lot",
            latitude: 43.6532,
            longitude: -79.3832,
            startTime: start,
            expectedEndTime: start.addingTimeInterval(60),
            actualEndTime: start.addingTimeInterval(180),
            note: "",
            persistedStatus: .completed
        )
        let group = makeGroup(sessions: [session])

        let summary = group.timingSummary(now: start.addingTimeInterval(240))

        XCTAssertEqual(summary.onTime, 0)
        XCTAssertEqual(summary.active, 0)
        XCTAssertEqual(summary.overdue, 1)
        XCTAssertEqual(session.timingOutcome(now: start.addingTimeInterval(240)).overdueDuration, 120)
    }

    func test_Phase1HistoryTimingSummary_ActiveOverdueSessionCountsOverdue() throws {
        let start = ISO8601DateFormatter().date(from: "2026-04-22T15:00:00Z")!
        let session = ParkingSession(
            locationName: "Active Late Lot",
            latitude: 43.6532,
            longitude: -79.3832,
            startTime: start,
            expectedEndTime: start.addingTimeInterval(60),
            actualEndTime: nil,
            note: "",
            persistedStatus: .active
        )
        let group = makeGroup(sessions: [session])

        let summary = group.timingSummary(now: start.addingTimeInterval(180))

        XCTAssertEqual(summary.onTime, 0)
        XCTAssertEqual(summary.active, 0)
        XCTAssertEqual(summary.overdue, 1)
        XCTAssertEqual(session.historyStatusLine(now: start.addingTimeInterval(180)), "Active · Overdue")
    }

    func test_Phase1HistoryRecentSessionRowText_ShowsOverdueDuration() throws {
        let start = ISO8601DateFormatter().date(from: "2026-04-22T15:00:00Z")!
        let session = ParkingSession(
            locationName: "Late Row Lot",
            latitude: 43.6532,
            longitude: -79.3832,
            startTime: start,
            expectedEndTime: start.addingTimeInterval(60),
            actualEndTime: start.addingTimeInterval(171),
            note: "",
            persistedStatus: .completed
        )

        XCTAssertEqual(session.historyStatusLine(now: start.addingTimeInterval(240)), "Completed · Overdue")
        XCTAssertEqual(session.historyOverdueLine(now: start.addingTimeInterval(240)), "Overdue by 1m 51s")
    }

    @MainActor
    func test_Phase2HistoryMapSearch_UsesInjectedProviderAndFiltersNearbyHistory() async throws {
        let provider = FakeMapSearchProvider(results: [
            HistoryMapSearchResult(
                title: "Toronto City Hall",
                subtitle: "100 Queen St W",
                coordinate: CLLocationCoordinate2D(latitude: 43.6532, longitude: -79.3832)
            )
        ])
        let vm = HistoryMapViewModel(searchProvider: provider)

        let start = ISO8601DateFormatter().date(from: "2026-04-22T15:00:00Z")!
        let near = ParkingSession(
            locationName: "Near City Hall",
            latitude: 43.65321,
            longitude: -79.38321,
            startTime: start,
            expectedEndTime: start.addingTimeInterval(60),
            actualEndTime: start.addingTimeInterval(50),
            note: "",
            persistedStatus: .completed
        )
        let far = ParkingSession(
            locationName: "Far Garage",
            latitude: 43.7000,
            longitude: -79.4200,
            startTime: start,
            expectedEndTime: start.addingTimeInterval(60),
            actualEndTime: start.addingTimeInterval(50),
            note: "",
            persistedStatus: .completed
        )

        vm.updateSessions([near, far])
        vm.searchText = "city hall"

        let results = await vm.searchAddressResults()
        vm.selectSearchResult(try XCTUnwrap(results.first))

        XCTAssertEqual(provider.queries, ["city hall"])
        XCTAssertEqual(results.first?.title, "Toronto City Hall")
        XCTAssertEqual(vm.visibleGroups.count, 1)
        XCTAssertEqual(vm.visibleGroups.first?.name, "Near City Hall")
        XCTAssertEqual(vm.statusText, "1 saved parking spot within 1 km of Toronto City Hall.")
    }

    @MainActor
    func test_Phase2HistoryMapSearch_SearchFailureKeepsHistoryVisible() async throws {
        let provider = FakeMapSearchProvider(error: TestSearchError.failed)
        let vm = HistoryMapViewModel(searchProvider: provider)

        let start = ISO8601DateFormatter().date(from: "2026-04-22T15:00:00Z")!
        let session = ParkingSession(
            locationName: "Saved Spot",
            latitude: 43.6532,
            longitude: -79.3832,
            startTime: start,
            expectedEndTime: start.addingTimeInterval(60),
            actualEndTime: start.addingTimeInterval(50),
            note: "",
            persistedStatus: .completed
        )

        vm.updateSessions([session])
        vm.searchText = "bad address"

        let results = await vm.searchAddressResults()

        XCTAssertTrue(results.isEmpty)
        XCTAssertEqual(provider.queries, ["bad address"])
        XCTAssertEqual(vm.visibleGroups.count, 1)
        XCTAssertEqual(vm.statusText, "Could not search that address. Check the spelling or try a nearby landmark.")
    }

    @MainActor
    func test_Phase2HistoryMapSearch_LocalQueryFiltersSavedSpotNamesAndNotes() throws {
        let provider = FakeMapSearchProvider()
        let vm = HistoryMapViewModel(searchProvider: provider)

        let start = ISO8601DateFormatter().date(from: "2026-04-22T15:00:00Z")!
        let work = ParkingSession(
            locationName: "Work Garage",
            latitude: 43.6532,
            longitude: -79.3832,
            startTime: start,
            expectedEndTime: start.addingTimeInterval(60),
            actualEndTime: start.addingTimeInterval(50),
            note: "blue pillar",
            persistedStatus: .completed
        )
        let home = ParkingSession(
            locationName: "Home Street",
            latitude: 43.7000,
            longitude: -79.4200,
            startTime: start,
            expectedEndTime: start.addingTimeInterval(60),
            actualEndTime: start.addingTimeInterval(50),
            note: "near mailbox",
            persistedStatus: .completed
        )

        vm.updateSessions([work, home])
        vm.updateSearchText("pillar")

        XCTAssertEqual(provider.queries, [])
        XCTAssertEqual(vm.visibleGroups.count, 1)
        XCTAssertEqual(vm.visibleGroups.first?.name, "Work Garage")
        XCTAssertEqual(vm.statusText, "1 saved parking spot matching \"pillar\".")
    }

    @MainActor
    func test_Phase2PersonalSpotMetadata_LocalQueryFiltersTagsAndSpotNote() throws {
        let provider = FakeMapSearchProvider()
        let metadataStorage = InMemorySpotMetadataStorage()
        let vm = HistoryMapViewModel(searchProvider: provider, metadataStorage: metadataStorage)

        let start = ISO8601DateFormatter().date(from: "2026-04-22T15:00:00Z")!
        let session = ParkingSession(
            locationName: "Office Garage",
            latitude: 43.6532,
            longitude: -79.3832,
            startTime: start,
            expectedEndTime: start.addingTimeInterval(60),
            actualEndTime: start.addingTimeInterval(50),
            note: "",
            persistedStatus: .completed
        )

        vm.updateSessions([session])
        let group = try XCTUnwrap(vm.visibleGroups.first)
        vm.updateMetadata(
            SavedParkingSpotMetadata(
                spotID: group.id,
                note: "level two by elevator",
                rating: 4,
                tags: ["Covered"],
                isFavorite: true
            ),
            for: group
        )

        vm.updateSearchText("covered")

        XCTAssertEqual(provider.queries, [])
        XCTAssertEqual(vm.visibleGroups.count, 1)
        XCTAssertEqual(vm.visibleGroups.first?.metadata?.tags, ["Covered"])
        XCTAssertEqual(vm.statusText, "1 saved parking spot matching \"covered\".")

        vm.updateSearchText("elevator")

        XCTAssertEqual(vm.visibleGroups.count, 1)
        XCTAssertEqual(vm.visibleGroups.first?.metadata?.note, "level two by elevator")
    }

    @MainActor
    func test_Phase2PersonalSpotMetadata_UpdatePersistsAndKeepsSelectionVisible() throws {
        let metadataStorage = InMemorySpotMetadataStorage()
        let vm = HistoryMapViewModel(searchProvider: FakeMapSearchProvider(), metadataStorage: metadataStorage)

        let start = ISO8601DateFormatter().date(from: "2026-04-22T15:00:00Z")!
        let session = ParkingSession(
            locationName: "Saved Garage",
            latitude: 43.6532,
            longitude: -79.3832,
            startTime: start,
            expectedEndTime: start.addingTimeInterval(60),
            actualEndTime: start.addingTimeInterval(50),
            note: "",
            persistedStatus: .completed
        )

        vm.updateSessions([session])
        let group = try XCTUnwrap(vm.visibleGroups.first)
        vm.selectGroup(group)

        let metadata = SavedParkingSpotMetadata(
            spotID: group.id,
            note: "best entrance on Bay",
            rating: 5,
            tags: ["Safe"],
            isFavorite: true
        )
        vm.updateMetadata(metadata, for: group)

        XCTAssertEqual(metadataStorage.savedMetadata[group.id]?.note, "best entrance on Bay")
        XCTAssertEqual(vm.selectedGroup?.metadata?.rating, 5)
        XCTAssertEqual(vm.visibleGroups.first?.metadata?.isFavorite, true)
    }

    @MainActor
    func test_Phase2PersonalSpotMetadataFilter_FavoritesFiltersVisibleMapGroups() throws {
        let vm = HistoryMapViewModel(searchProvider: FakeMapSearchProvider(), metadataStorage: InMemorySpotMetadataStorage())
        let start = ISO8601DateFormatter().date(from: "2026-04-22T15:00:00Z")!
        let favorite = ParkingSession(
            locationName: "Favorite Garage",
            latitude: 43.6532,
            longitude: -79.3832,
            startTime: start,
            expectedEndTime: start.addingTimeInterval(60),
            actualEndTime: start.addingTimeInterval(50),
            note: "",
            persistedStatus: .completed
        )
        let regular = ParkingSession(
            locationName: "Regular Street",
            latitude: 43.7000,
            longitude: -79.4200,
            startTime: start,
            expectedEndTime: start.addingTimeInterval(60),
            actualEndTime: start.addingTimeInterval(50),
            note: "",
            persistedStatus: .completed
        )

        vm.updateSessions([favorite, regular])
        let favoriteGroup = try XCTUnwrap(vm.visibleGroups.first(where: { $0.name == "Favorite Garage" }))
        vm.updateMetadata(
            SavedParkingSpotMetadata(spotID: favoriteGroup.id, isFavorite: true),
            for: favoriteGroup
        )

        vm.metadataFilter = .favorites

        XCTAssertEqual(vm.visibleGroups.map(\.name), ["Favorite Garage"])
        XCTAssertEqual(vm.statusText, "1 saved parking spot matching Favorites.")
    }

    @MainActor
    func test_Phase2PersonalSpotMetadataFilter_ComposesWithAddressRadius() async throws {
        let provider = FakeMapSearchProvider(results: [
            HistoryMapSearchResult(
                title: "Toronto City Hall",
                subtitle: "100 Queen St W",
                coordinate: CLLocationCoordinate2D(latitude: 43.6532, longitude: -79.3832)
            )
        ])
        let vm = HistoryMapViewModel(
            searchProvider: provider,
            metadataStorage: InMemorySpotMetadataStorage(),
            initialSearchRadius: .twoKilometers
        )
        let start = ISO8601DateFormatter().date(from: "2026-04-22T15:00:00Z")!
        let coveredNear = ParkingSession(
            locationName: "Covered Near",
            latitude: 43.65321,
            longitude: -79.38321,
            startTime: start,
            expectedEndTime: start.addingTimeInterval(60),
            actualEndTime: start.addingTimeInterval(50),
            note: "",
            persistedStatus: .completed
        )
        let streetNear = ParkingSession(
            locationName: "Street Near",
            latitude: 43.6540,
            longitude: -79.3832,
            startTime: start,
            expectedEndTime: start.addingTimeInterval(60),
            actualEndTime: start.addingTimeInterval(50),
            note: "",
            persistedStatus: .completed
        )

        vm.updateSessions([coveredNear, streetNear])
        let coveredGroup = try XCTUnwrap(vm.visibleGroups.first(where: { $0.name == "Covered Near" }))
        vm.updateMetadata(
            SavedParkingSpotMetadata(spotID: coveredGroup.id, tags: ["Covered"]),
            for: coveredGroup
        )
        vm.searchText = "city hall"
        let results = await vm.searchAddressResults()
        vm.selectSearchResult(try XCTUnwrap(results.first))

        vm.metadataFilter = .covered

        XCTAssertEqual(vm.visibleGroups.map(\.name), ["Covered Near"])
        XCTAssertEqual(vm.statusText, "1 saved parking spot matching Covered within 2 km of Toronto City Hall.")
    }

    @MainActor
    func test_Phase2HistoryMapSearch_NoAddressResultKeepsLocalHistoryMatches() async throws {
        let provider = FakeMapSearchProvider(results: [])
        let vm = HistoryMapViewModel(searchProvider: provider)

        let start = ISO8601DateFormatter().date(from: "2026-04-22T15:00:00Z")!
        let session = ParkingSession(
            locationName: "Work Garage",
            latitude: 43.6532,
            longitude: -79.3832,
            startTime: start,
            expectedEndTime: start.addingTimeInterval(60),
            actualEndTime: start.addingTimeInterval(50),
            note: "blue pillar",
            persistedStatus: .completed
        )

        vm.updateSessions([session])
        vm.updateSearchText("pillar")

        let results = await vm.searchAddressResults()

        XCTAssertTrue(results.isEmpty)
        XCTAssertEqual(provider.queries, ["pillar"])
        XCTAssertEqual(vm.visibleGroups.count, 1)
        XCTAssertEqual(vm.visibleGroups.first?.name, "Work Garage")
        XCTAssertEqual(vm.statusText, "No address found for \"pillar\". Showing saved history matches.")
    }

    @MainActor
    func test_Phase2HistoryMapSearch_AdjustingRadiusRecomputesNearbyHistory() async throws {
        let provider = FakeMapSearchProvider(results: [
            HistoryMapSearchResult(
                title: "Toronto City Hall",
                subtitle: "100 Queen St W",
                coordinate: CLLocationCoordinate2D(latitude: 43.6532, longitude: -79.3832)
            )
        ])
        let vm = HistoryMapViewModel(searchProvider: provider, initialSearchRadius: .meters500)

        let start = ISO8601DateFormatter().date(from: "2026-04-22T15:00:00Z")!
        let near = ParkingSession(
            locationName: "Near City Hall",
            latitude: 43.65321,
            longitude: -79.38321,
            startTime: start,
            expectedEndTime: start.addingTimeInterval(60),
            actualEndTime: start.addingTimeInterval(50),
            note: "",
            persistedStatus: .completed
        )
        let widerRadius = ParkingSession(
            locationName: "Wider Radius Garage",
            latitude: 43.6608,
            longitude: -79.3832,
            startTime: start,
            expectedEndTime: start.addingTimeInterval(60),
            actualEndTime: start.addingTimeInterval(50),
            note: "",
            persistedStatus: .completed
        )

        vm.updateSessions([near, widerRadius])
        vm.searchText = "city hall"

        let results = await vm.searchAddressResults()
        vm.selectSearchResult(try XCTUnwrap(results.first))

        XCTAssertEqual(vm.visibleGroups.map(\.name), ["Near City Hall"])
        XCTAssertEqual(vm.statusText, "1 saved parking spot within 500 m of Toronto City Hall.")

        vm.searchRadius = .twoKilometers

        XCTAssertEqual(Set(vm.visibleGroups.map(\.name)), ["Near City Hall", "Wider Radius Garage"])
        XCTAssertEqual(vm.statusText, "2 saved parking spots within 2 km of Toronto City Hall.")
    }

    private func makeGroup(sessions: [ParkingSession]) -> ParkingSpotGroup {
        ParkingSpotGroup(
            id: "test-group",
            coordinate: CLLocationCoordinate2D(latitude: 43.6532, longitude: -79.3832),
            name: "Test Group",
            sessions: sessions
        )
    }
}

private enum TestSearchError: Error {
    case failed
}

private final class FakeMapSearchProvider: MapSearchProviding {
    private let results: [HistoryMapSearchResult]
    private let error: Error?
    private(set) var queries: [String] = []

    init(results: [HistoryMapSearchResult] = [], error: Error? = nil) {
        self.results = results
        self.error = error
    }

    func searchAddress(query: String) async throws -> [HistoryMapSearchResult] {
        queries.append(query)
        if let error {
            throw error
        }
        return results
    }
}

private final class InMemorySpotMetadataStorage: SavedParkingSpotMetadataStorageServiceProtocol {
    var savedMetadata: [String: SavedParkingSpotMetadata]

    init(savedMetadata: [String: SavedParkingSpotMetadata] = [:]) {
        self.savedMetadata = savedMetadata
    }

    func load() throws -> [String: SavedParkingSpotMetadata] {
        savedMetadata
    }

    func save(_ metadataBySpotID: [String: SavedParkingSpotMetadata]) throws {
        savedMetadata = metadataBySpotID
    }
}
