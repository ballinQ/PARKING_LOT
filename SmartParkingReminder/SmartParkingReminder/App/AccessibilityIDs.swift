import Foundation

enum A11y {
    // Tabs
    static let tabHome = "tab.home"
    static let tabHistory = "tab.history"

    // Home
    static let homeStartParkingButton = "home.startParking"
    static let homeEndParkingButton = "home.endParking"
    static let homeNoActiveSessionView = "home.noActiveSession"
    static let homeActiveSessionCard = "home.activeSessionCard"
    static let homeSessionStatusLabel = "home.sessionStatus"
    static let homeRemainingTimeLabel = "home.remainingTime"
    static let homeQuickStartPanel = "home.quickStartPanel"

    static func homeQuickStartButton(minutes: Int) -> String {
        "home.quickStart.\(minutes)"
    }

    // New Session
    static let newSessionLocationField = "newSession.locationField"
    static let newSessionNoteField = "newSession.noteField"
    static let newSessionDurationPicker = "newSession.durationPicker"
    static let newSessionStartButton = "newSession.startButton"
    static let newSessionCancelButton = "newSession.cancelButton"

    // History
    static let historyMap = "history.map"
    static let historySearchField = "history.searchField"
    static let historySearchButton = "history.searchButton"
    static let historyClearSearchButton = "history.clearSearchButton"
    static let historySearchStatus = "history.searchStatus"
    static let historyPersonalHistoryToggle = "history.personalHistoryToggle"
    static let historyPersonalSpotButton = "history.personalSpotButton"
    static let historySearchPanel = "historySearchPanel"
    static let historyPreviewPanel = "historyPreviewPanel"

    // Detail Sheet
    static let detailSheet = "historySpotDetailSheet"
    static let detailBackButton = "historyDetailBackButton"
    static let detailSpotName = "spotDetail.name"
    static let detailSpotCount = "spotDetail.count"
    static let detailSpotLatLon = "spotDetail.latlon"
    static let detailOpenAppleMaps = "spotDetail.openAppleMaps"
    static let detailOpenGoogleMaps = "spotDetail.openGoogleMaps"

    // UI-test-only hooks
    static let uiTestOpenFirstSpotDetail = "uitest.openFirstSpotDetail"
}
