import XCTest

/// Completes a ballot pick through the accessibility tree, the way VoiceOver
/// sees it, and audits the Ballot (P4-14). UI tests still need XCTest; they
/// run from the OscarsTrackerUITests scheme, not the Tests workflow.
nonisolated final class BallotAccessibilityTests: XCTestCase {
    @MainActor
    func testPickAndChangeAPickByAccessibilityElements() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-sample-data", "-tab", "ballot"]
        app.launch()

        // Animated Feature has no pick yet, so its nominees are open.
        let nominee = app.buttons["KPop Demon Hunters"]
        XCTAssertTrue(nominee.waitForExistence(timeout: 10))
        XCTAssertEqual(nominee.value as? String, "")
        nominee.tap()

        // The card folds to the pick, which reads as a button to open it again.
        let summary = app.buttons["Your pick: KPop Demon Hunters"]
        XCTAssertTrue(summary.waitForExistence(timeout: 5))
        summary.tap()
        let reopened = app.buttons["KPop Demon Hunters"]
        XCTAssertTrue(reopened.waitForExistence(timeout: 5))
        XCTAssertEqual(reopened.value as? String, "Your pick")
        XCTAssertTrue(reopened.isSelected)

        // An acting category reads the person first, then the film.
        let summaryActress = app.buttons["Your pick: Jessie Buckley, in Hamnet"]
        XCTAssertTrue(summaryActress.exists)
        summaryActress.tap()
        let other = app.buttons["Renate Reinsve, in Sentimental Value"]
        XCTAssertTrue(other.waitForExistence(timeout: 5))
        other.tap()
        XCTAssertTrue(app.buttons["Your pick: Renate Reinsve, in Sentimental Value"].waitForExistence(timeout: 5))

        // The two pinned bars stop growing at a set text size on purpose
        // (P3-10) and show the whole line in the Large Content Viewer. The
        // ticker's text is the system's vibrant .primary on the accessory's
        // glass, which the contrast check samples as the posters behind it.
        let cappedBars: Set = ["season-ticker", "ballot-status"]
        try app.performAccessibilityAudit { issue in
            let id = issue.element?.identifier ?? ""
            switch issue.auditType {
            case .dynamicType: return cappedBars.contains(id)
            case .contrast: return id == "season-ticker"
            default: return false
            }
        }
    }
}
