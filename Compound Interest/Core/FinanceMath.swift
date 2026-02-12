import Foundation

/// EN: Enum definition for finance math.
/// ZH: FinanceMath 的 enum 定義。
enum FinanceMath {
    /// EN: Calculates one-year annuity-due compounding results.
    /// ZH: 計算期初年金模型的一年複利結果。
    /// - Parameter principalStart: EN: `principalStart` (Double). ZH: 參數 `principalStart`（Double）。
    /// - Parameter payment: EN: `payment` (Double). ZH: 參數 `payment`（Double）。
    /// - Parameter interestRate: EN: `interestRate` (Double) -> (interestEarned: Double, totalEnd: Double). ZH: 參數 `interestRate`（Double) -> (interestEarned: Double, totalEnd: Double）。
    /// - Returns: EN: `(interestEarned: Double, totalEnd: Double)` result. ZH: 回傳 `(interestEarned: Double, totalEnd: Double)` 結果。
    static func annuityDueYearStep(principalStart: Double, payment: Double, interestRate: Double) -> (interestEarned: Double, totalEnd: Double) {
        let base = principalStart + payment
        let interestEarned = base * interestRate
        return (interestEarned, base + interestEarned)
    }

    /// EN: Computes CAGR using latest, base, and year span.
    /// ZH: 依期末、期初與年數計算年化成長率（CAGR）。
    /// - Parameter latest: EN: `latest` (Double). ZH: 參數 `latest`（Double）。
    /// - Parameter base: EN: `base` (Double). ZH: 參數 `base`（Double）。
    /// - Parameter years: EN: `years` (Int). ZH: 參數 `years`（Int）。
    /// - Returns: EN: `Double` result. ZH: 回傳 `Double` 結果。
    static func cagr(latest: Double, base: Double, years: Int) -> Double {
        guard latest > 0, base > 0 else { return 0 }
        let safeYears = max(1, years)
        return pow(latest / base, 1.0 / Double(safeYears)) - 1.0
    }

    /// EN: Restricts a value into the closed range [min, max].
    /// ZH: 將數值限制在 [min, max] 範圍內。
    /// - Parameter value: EN: `value` (Double). ZH: 參數 `value`（Double）。
    /// - Parameter minValue: EN: `minValue` (Double). ZH: 參數 `minValue`（Double）。
    /// - Parameter maxValue: EN: `maxValue` (Double). ZH: 參數 `maxValue`（Double）。
    /// - Returns: EN: `Double` result. ZH: 回傳 `Double` 結果。
    static func clamp(_ value: Double, min minValue: Double, max maxValue: Double) -> Double {
        Swift.min(Swift.max(value, minValue), maxValue)
    }

    /// EN: Converts a close price to a split-normalized basis.
    /// ZH: 將收盤價轉換為分割校正後的同基準價格。
    /// - Parameter close: EN: `close` (Double). ZH: 參數 `close`（Double）。
    /// - Parameter tradeDate: EN: `tradeDate` (String). ZH: 參數 `tradeDate`（String）。
    /// - Parameter splitEvents: EN: `splitEvents` ([(effectiveDate: String, ratio: Double)]). ZH: 參數 `splitEvents`（[(effectiveDate: String, ratio: Double)]）。
    /// - Returns: EN: `Double` result. ZH: 回傳 `Double` 結果。
    static func adjustedClose(close: Double, tradeDate: String, splitEvents: [(effectiveDate: String, ratio: Double)]) -> Double {
        guard close > 0 else { return close }
        var adjusted = close
        for event in splitEvents where event.ratio > 0 {
            if tradeDate < event.effectiveDate {
                adjusted /= event.ratio
            }
        }
        return adjusted
    }
}
