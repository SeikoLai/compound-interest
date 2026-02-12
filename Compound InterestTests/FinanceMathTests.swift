import XCTest
@testable import Compound_Interest

/// EN: Class definition for finance math tests.
/// ZH: FinanceMathTests 的 class 定義。
final class FinanceMathTests: XCTestCase {
    /// EN: Verifies annuity-due one-year compounding calculation values.
    /// ZH: 驗證期初年金單年複利計算結果。
    func testAnnuityDueYearStep() {
        let step = FinanceMath.annuityDueYearStep(principalStart: 60_000, payment: 120_000, interestRate: 0.1)
        XCTAssertEqual(step.interestEarned, 18_000, accuracy: 0.0001)
        XCTAssertEqual(step.totalEnd, 198_000, accuracy: 0.0001)
    }

    /// EN: Verifies CAGR formula output for a known sample.
    /// ZH: 驗證已知樣本的 CAGR 計算結果。
    func testCAGR() {
        let value = FinanceMath.cagr(latest: 200, base: 100, years: 5)
        XCTAssertEqual(value, 0.148698355, accuracy: 0.000001)
    }

    /// EN: Verifies value clamping behavior at lower/upper bounds.
    /// ZH: 驗證數值在上下界時的夾值行為。
    func testClamp() {
        XCTAssertEqual(FinanceMath.clamp(0.3, min: -0.05, max: 0.12), 0.12)
        XCTAssertEqual(FinanceMath.clamp(-0.2, min: -0.05, max: 0.12), -0.05)
        XCTAssertEqual(FinanceMath.clamp(0.04, min: -0.05, max: 0.12), 0.04)
    }

    /// EN: Verifies split-adjusted close conversion before and after split date.
    /// ZH: 驗證分割日前後的收盤價分割校正邏輯。
    func testAdjustedCloseForSplit() {
        let splitEvents = [(effectiveDate: "2025/06/18", ratio: 4.0)]
        XCTAssertEqual(FinanceMath.adjustedClose(close: 160, tradeDate: "2025/06/10", splitEvents: splitEvents), 40, accuracy: 0.0001)
        XCTAssertEqual(FinanceMath.adjustedClose(close: 75.5, tradeDate: "2026/02/10", splitEvents: splitEvents), 75.5, accuracy: 0.0001)
    }
}
