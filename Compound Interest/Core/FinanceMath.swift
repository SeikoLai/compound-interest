import Foundation

enum FinanceMath {
    static func annuityDueYearStep(principalStart: Double, payment: Double, interestRate: Double) -> (interestEarned: Double, totalEnd: Double) {
        let base = principalStart + payment
        let interestEarned = base * interestRate
        return (interestEarned, base + interestEarned)
    }

    static func cagr(latest: Double, base: Double, years: Int) -> Double {
        guard latest > 0, base > 0 else { return 0 }
        let safeYears = max(1, years)
        return pow(latest / base, 1.0 / Double(safeYears)) - 1.0
    }

    static func clamp(_ value: Double, min minValue: Double, max maxValue: Double) -> Double {
        Swift.min(Swift.max(value, minValue), maxValue)
    }

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
