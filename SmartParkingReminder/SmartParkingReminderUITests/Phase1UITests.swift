import XCTest

final class Phase1UITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UI_TESTING"]
        app.launchEnvironment["UITEST_STORAGE_FILE"] = "parking_sessions_\(name).json"
        app.launch()
    }

    // TC-01 (P0) Start session from New Session screen
    func test_TC01_StartSession_ShowsActiveSessionAndCountdown() {
        app.buttons.matching(identifier: "home.startParking").firstMatch.tap()

        let locationField = app.textFields.matching(identifier: "newSession.locationField").firstMatch
        XCTAssertTrue(locationField.waitForExistence(timeout: 5))
        locationField.tap()
        locationField.typeText("Lot A")

        // Use default duration; just start.
        app.buttons.matching(identifier: "newSession.startButton").firstMatch.tap()

        let activeCard = app.otherElements.matching(identifier: "home.activeSessionCard").firstMatch
        XCTAssertTrue(activeCard.waitForExistence(timeout: 5))

        let remaining = app.staticTexts.matching(identifier: "home.remainingTime").firstMatch
        XCTAssertTrue(remaining.exists)

        // The location name should be visible somewhere in the card.
        XCTAssertTrue(activeCard.staticTexts["Lot A"].exists)
    }

    // TC-07 (P0) End parking manually
    // TC-08 (P0) History map integrity (smoke)
    func test_TC07_TC08_EndSession_AppearsInHistoryMapDetail() {
        startSession(location: "Lot A", note: "pillar B")

        app.buttons.matching(identifier: "home.endParking").firstMatch.tap()

        let noActive = app.otherElements.matching(identifier: "home.noActiveSession").firstMatch
        XCTAssertTrue(noActive.waitForExistence(timeout: 5))

        // Go to Map tab
        app.tabBars.buttons["Map"].tap()

        let map = app.otherElements.matching(identifier: "history.map").firstMatch
        XCTAssertTrue(map.waitForExistence(timeout: 5))

        openFirstSpotFromPersonalHistory()

        let sheet = app.otherElements.matching(identifier: "historySpotDetailSheet").firstMatch
        XCTAssertTrue(sheet.waitForExistence(timeout: 5))

        XCTAssertTrue(app.staticTexts["Lot A"].exists)
        XCTAssertTrue(app.staticTexts["pillar B"].exists)
    }

    // TC-11 (P1) Marker interaction flow => detail sheet opens (UI-test hook)
    // TC-12 (P1) Detail sheet content
    func test_TC11_TC12_MapDetailSheet_ShowsSpotInfoAndActions() {
        // Ensure at least one completed session with coordinates.
        startSession(location: "GPS Spot", note: "")
        app.buttons.matching(identifier: "home.endParking").firstMatch.tap()

        app.tabBars.buttons["Map"].tap()

        // Use the visible personal history side panel to open detail sheet.
        openFirstSpotFromPersonalHistory()

        let sheet = app.otherElements.matching(identifier: "historySpotDetailSheet").firstMatch
        XCTAssertTrue(sheet.waitForExistence(timeout: 5))

        XCTAssertTrue(app.staticTexts.matching(identifier: "spotDetail.name").firstMatch.exists)
        XCTAssertTrue(app.staticTexts.matching(identifier: "spotDetail.count").firstMatch.exists)
        XCTAssertTrue(app.staticTexts.matching(identifier: "spotDetail.latlon").firstMatch.exists)

        XCTAssertTrue(app.buttons.matching(identifier: "spotDetail.openAppleMaps").firstMatch.exists)
        XCTAssertTrue(app.buttons.matching(identifier: "spotDetail.openGoogleMaps").firstMatch.exists)
    }

    func test_Phase1HistoryDetail_BackReturnsToHistoryPanel() {
        startSession(location: "Back Test Spot", note: "")
        app.buttons.matching(identifier: "home.endParking").firstMatch.tap()

        app.tabBars.buttons["Map"].tap()

        let map = app.otherElements.matching(identifier: "history.map").firstMatch
        XCTAssertTrue(map.waitForExistence(timeout: 5))

        openFirstSpotFromPersonalHistory()

        let sheet = app.otherElements.matching(identifier: "historySpotDetailSheet").firstMatch
        XCTAssertTrue(sheet.waitForExistence(timeout: 5))

        let backButton = app.buttons.matching(identifier: "historyDetailBackButton").firstMatch
        XCTAssertTrue(backButton.waitForExistence(timeout: 5))
        backButton.tap()

        let historyPanel = app.descendants(matching: .any).matching(identifier: "historySearchPanel").firstMatch
        XCTAssertTrue(historyPanel.waitForExistence(timeout: 5))
        XCTAssertFalse(app.otherElements.matching(identifier: "historySpotDetailSheet").firstMatch.exists)
        XCTAssertTrue(map.exists)
    }

    // TC-14 (P0) Persistence after relaunch
    func test_TC14_Relaunch_RestoresActiveSession() {
        startSession(location: "Lot A", note: "")

        // Terminate + relaunch
        app.terminate()
        app.launch()

        let activeCard = app.otherElements.matching(identifier: "home.activeSessionCard").firstMatch
        XCTAssertTrue(activeCard.waitForExistence(timeout: 5))
        XCTAssertTrue(activeCard.staticTexts["Lot A"].exists)
    }

    func test_Phase2ActiveSession_DueSoonStateIsVisible() {
        relaunchWithSeededActiveSession(location: "Due Soon Lot", endOffsetSeconds: 10 * 60)

        let activeCard = app.otherElements.matching(identifier: "home.activeSessionCard").firstMatch
        XCTAssertTrue(activeCard.waitForExistence(timeout: 5))

        let status = app.staticTexts.matching(identifier: "home.sessionStatus").firstMatch
        XCTAssertTrue(status.waitForExistence(timeout: 5))
        XCTAssertEqual(status.label, "Due Soon")

        let remaining = app.staticTexts.matching(identifier: "home.remainingTime").firstMatch
        XCTAssertTrue(remaining.exists)
        XCTAssertFalse(remaining.label.contains("-"))
    }

    func test_Phase2ActiveSession_OverdueStateIsVisibleWithoutAutoEnding() {
        relaunchWithSeededActiveSession(location: "Overdue Lot", endOffsetSeconds: -2 * 60)

        let activeCard = app.otherElements.matching(identifier: "home.activeSessionCard").firstMatch
        XCTAssertTrue(activeCard.waitForExistence(timeout: 5))
        XCTAssertTrue(activeCard.staticTexts["Overdue Lot"].exists)

        let status = app.staticTexts.matching(identifier: "home.sessionStatus").firstMatch
        XCTAssertTrue(status.waitForExistence(timeout: 5))
        XCTAssertEqual(status.label, "Overdue")

        let remaining = app.staticTexts.matching(identifier: "home.remainingTime").firstMatch
        XCTAssertTrue(remaining.exists)
        XCTAssertTrue(remaining.label.hasPrefix("Overdue by "))
        XCTAssertFalse(remaining.label.contains("-"))
        XCTAssertTrue(app.buttons.matching(identifier: "home.endParking").firstMatch.exists)
    }

    func test_Phase2QuickStart_ThirtyMinutesStartsActiveSession() {
        let quickStartPanel = app.descendants(matching: .any).matching(identifier: "home.quickStartPanel").firstMatch
        XCTAssertTrue(quickStartPanel.waitForExistence(timeout: 5))

        let thirtyMinuteButton = app.buttons.matching(identifier: "home.quickStart.30").firstMatch
        XCTAssertTrue(thirtyMinuteButton.waitForExistence(timeout: 5))
        thirtyMinuteButton.tap()

        let activeCard = app.otherElements.matching(identifier: "home.activeSessionCard").firstMatch
        XCTAssertTrue(activeCard.waitForExistence(timeout: 5))
        XCTAssertTrue(activeCard.staticTexts["Current Location"].exists)

        let remaining = app.staticTexts.matching(identifier: "home.remainingTime").firstMatch
        XCTAssertTrue(remaining.exists)
        XCTAssertFalse(remaining.label.contains("-"))
    }

    // MARK: - Helpers

    private func startSession(location: String, note: String) {
        app.buttons.matching(identifier: "home.startParking").firstMatch.tap()

        let locationField = app.textFields.matching(identifier: "newSession.locationField").firstMatch
        XCTAssertTrue(locationField.waitForExistence(timeout: 5))
        locationField.tap()
        locationField.typeText(location)

        if !note.isEmpty {
            let noteField = app.textViews.matching(identifier: "newSession.noteField").firstMatch
            if noteField.exists {
                noteField.tap()
                noteField.typeText(note)
            } else {
                // SwiftUI TextField with axis: .vertical often lands as a textView/textField depending on OS.
                let noteAlt = app.textFields.matching(identifier: "newSession.noteField").firstMatch
                if noteAlt.exists {
                    noteAlt.tap()
                    noteAlt.typeText(note)
                }
            }
        }

        app.buttons.matching(identifier: "newSession.startButton").firstMatch.tap()

        let activeCard = app.otherElements.matching(identifier: "home.activeSessionCard").firstMatch
        XCTAssertTrue(activeCard.waitForExistence(timeout: 5))
    }

    private func relaunchWithSeededActiveSession(location: String, endOffsetSeconds: TimeInterval) {
        app.terminate()
        app.launchEnvironment["UITEST_ACTIVE_SESSION_LOCATION"] = location
        app.launchEnvironment["UITEST_ACTIVE_SESSION_OFFSET_SECONDS"] = "\(Int(endOffsetSeconds))"
        app.launch()
    }

    private func openFirstSpotFromPersonalHistory() {
        let detailHook = app.buttons.matching(identifier: "uitest.openFirstSpotDetail").firstMatch
        if detailHook.waitForExistence(timeout: 5) {
            detailHook.tap()
            return
        }

        let searchField = app.textFields.matching(identifier: "history.searchField").firstMatch
        if searchField.waitForExistence(timeout: 5) {
            searchField.tap()
        }

        let toggle = app.buttons.matching(identifier: "history.personalHistoryToggle").firstMatch
        if toggle.waitForExistence(timeout: 5) {
            toggle.tap()
        }

        let spotButton = app.buttons.matching(identifier: "history.personalSpotButton").firstMatch
        XCTAssertTrue(spotButton.waitForExistence(timeout: 5))
        spotButton.tap()
    }
}
