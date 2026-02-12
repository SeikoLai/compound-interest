import XCTest

/// EN: Class definition for compound interest uitests.
/// ZH: CompoundInterestUITests 的 class 定義。
final class CompoundInterestUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// EN: Verifies Stock tab renders segmented control with expected symbols.
    /// ZH: 驗證 Stock 分頁會顯示含預期代號的 segmented control。
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

    /// EN: Verifies floating keyboard button can toggle the input panel.
    /// ZH: 驗證鍵盤懸浮按鈕可切換輸入面板顯示狀態。
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
