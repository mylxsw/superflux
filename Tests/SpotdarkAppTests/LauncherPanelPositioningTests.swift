import XCTest
@testable import SpotdarkApp

final class LauncherPanelPositioningTests: XCTestCase {
    func testRestoredOriginReturnsSavedPositionWhenFrameFitsVisibleScreen() {
        let origin = LauncherPanelPositioning.restoredOrigin(
            from: ["x": 220.0, "top": 760.0],
            panelSize: CGSize(width: 720, height: 420),
            visibleFrames: [CGRect(x: 0, y: 0, width: 1440, height: 900)]
        )

        XCTAssertEqual(origin?.x, 220)
        XCTAssertEqual(origin?.y, 340)
    }

    func testRestoredOriginFallsBackToLegacyYCoordinate() {
        let origin = LauncherPanelPositioning.restoredOrigin(
            from: ["x": 180.0, "y": 260.0],
            panelSize: CGSize(width: 720, height: 84),
            visibleFrames: [CGRect(x: 0, y: 0, width: 1440, height: 900)]
        )

        XCTAssertEqual(origin?.x, 180)
        XCTAssertEqual(origin?.y, 260)
    }

    func testRestoredOriginReturnsNilWhenSavedFrameNoLongerFitsAnyVisibleScreen() {
        let origin = LauncherPanelPositioning.restoredOrigin(
            from: ["x": 1100.0, "top": 840.0],
            panelSize: CGSize(width: 720, height: 420),
            visibleFrames: [CGRect(x: 0, y: 0, width: 1280, height: 800)]
        )

        XCTAssertNil(origin)
    }

    func testRestoredOriginReturnsNilWhenPersistedCoordinatesAreIncomplete() {
        let origin = LauncherPanelPositioning.restoredOrigin(
            from: ["top": 760.0],
            panelSize: CGSize(width: 720, height: 420),
            visibleFrames: [CGRect(x: 0, y: 0, width: 1440, height: 900)]
        )

        XCTAssertNil(origin)
    }
}
