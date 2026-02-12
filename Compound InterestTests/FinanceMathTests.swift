import XCTest
@testable import Compound_Interest

final class FinanceMathTests: XCTestCase {
    func testAnnuityDueYearStep() {
        let step = FinanceMath.annuityDueYearStep(principalStart: 60_000, payment: 120_000, interestRate: 0.1)
        XCTAssertEqual(step.interestEarned, 18_000, accuracy: 0.0001)
        XCTAssertEqual(step.totalEnd, 198_000, accuracy: 0.0001)
    }

    func testCAGR() {
        let value = FinanceMath.cagr(latest: 200, base: 100, years: 5)
        XCTAssertEqual(value, 0.148698355, accuracy: 0.000001)
    }

    func testClamp() {
        XCTAssertEqual(FinanceMath.clamp(0.3, min: -0.05, max: 0.12), 0.12)
        XCTAssertEqual(FinanceMath.clamp(-0.2, min: -0.05, max: 0.12), -0.05)
        XCTAssertEqual(FinanceMath.clamp(0.04, min: -0.05, max: 0.12), 0.04)
    }

    func testAdjustedCloseForSplit() {
        let splitEvents = [(effectiveDate: "2025/06/18", ratio: 4.0)]
        XCTAssertEqual(FinanceMath.adjustedClose(close: 160, tradeDate: "2025/06/10", splitEvents: splitEvents), 40, accuracy: 0.0001)
        XCTAssertEqual(FinanceMath.adjustedClose(close: 75.5, tradeDate: "2026/02/10", splitEvents: splitEvents), 75.5, accuracy: 0.0001)
    }
}
