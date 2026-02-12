import XCTest

final class CompoundInterestUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testStockTabShowsSegmentedControl() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-ui-testing"]
        app.launch()

        app.tabBars.buttons["Stock"].tap()

        let segment = app.segmentedControls["stock.segment"]
        XCTAssertTrue(segment.waitForExistence(timeout: 5))
        XCTAssertTrue(segment.buttons["0050"].exists)
        XCTAssertTrue(segment.buttons["2330"].exists)
    }

    func testFloatingButtonTogglesInputPanel() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-ui-testing"]
        app.launch()

        let fab = app.descendants(matching: .any)["compound.fab.keyboard"].firstMatch
        XCTAssertTrue(fab.waitForExistence(timeout: 5))

        fab.tap()
        let panel = app.descendants(matching: .any)["compound.input.panel"].firstMatch
        XCTAssertTrue(panel.waitForExistence(timeout: 5))

        fab.tap()
        let hidden = NSPredicate(format: "exists == false")
        expectation(for: hidden, evaluatedWith: panel)
        waitForExpectations(timeout: 3)
    }
}
