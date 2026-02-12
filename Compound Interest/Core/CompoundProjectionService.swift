import Foundation

/// EN: Struct definition for stock growth model.
/// ZH: StockGrowthModel 的 struct 定義。
struct StockGrowthModel {
/// EN: Latest normalized price as projection start point.
/// ZH: 經正規化後的最新股價，作為預估起點。
    let latestPrice: Double
/// EN: Annualized growth used by projection loop.
/// ZH: 用於預估迴圈的年化成長率。
    let annualGrowthRate: Double
}

/// EN: Struct definition for compound projection row.
/// ZH: CompoundProjectionRow 的 struct 定義。
struct CompoundProjectionRow {
/// EN: Projection year index (1-based).
/// ZH: 預估年份（從 1 開始）。
    let year: Int
/// EN: Annual contribution amount.
/// ZH: 每年投入金額。
    let payment: Double
/// EN: Principal at beginning of year.
/// ZH: 年初本金。
    let principalStart: Double
/// EN: Interest earned in current year.
/// ZH: 當年利息。
    let interestEarned: Double
/// EN: Contribution booked this year.
/// ZH: 當年投入。
    let contribution: Double
/// EN: End-of-year total value.
/// ZH: 年底總額。
    let totalEnd: Double
/// EN: Cumulative invested capital by this year.
/// ZH: 截至當年累積投入本金。
    let investedToDate: Double
}

/// EN: Struct definition for stock projection year.
/// ZH: StockProjectionYear 的 struct 定義。
struct StockProjectionYear {
/// EN: Estimated 0050 price for this year.
/// ZH: 本年度預估 0050 股價。
    let price0050: Double
/// EN: Estimated 2330 price for this year.
/// ZH: 本年度預估 2330 股價。
    let price2330: Double
/// EN: Cumulative 0050 shares held.
/// ZH: 累計持有 0050 股數。
    let shares0050: Double
/// EN: Cumulative 2330 shares held.
/// ZH: 累計持有 2330 股數。
    let shares2330: Double
/// EN: Newly purchased 0050 shares this year.
/// ZH: 本年新增 0050 股數。
    let delta0050: Double
/// EN: Newly purchased 2330 shares this year.
/// ZH: 本年新增 2330 股數。
    let delta2330: Double
}

/// EN: Enum definition for compound projection service.
/// ZH: CompoundProjectionService 的 enum 定義。
enum CompoundProjectionService {
    /// EN: Generates yearly cash-compound rows for annuity-due simulation.
    /// ZH: 產生期初年金模擬的逐年現金複利資料列。
    /// - Parameter capital: EN: `capital` (Int). ZH: 參數 `capital`（Int）。
    /// - Parameter paymentsEnabled: EN: `paymentsEnabled` (Bool). ZH: 參數 `paymentsEnabled`（Bool）。
    /// - Parameter payment: EN: `payment` (Int). ZH: 參數 `payment`（Int）。
    /// - Parameter years: EN: `years` (Int). ZH: 參數 `years`（Int）。
    /// - Parameter interestRate: EN: `interestRate` (Double). ZH: 參數 `interestRate`（Double）。
    /// - Returns: EN: `[CompoundProjectionRow]` result. ZH: 回傳 `[CompoundProjectionRow]` 結果。
    static func buildCompoundRows(
        capital: Int,
        paymentsEnabled: Bool,
        payment: Int,
        years: Int,
        interestRate: Double
    ) -> [CompoundProjectionRow] {
        var rows: [CompoundProjectionRow] = []
        let totalYears = max(0, years)
        let paymentAmount = paymentsEnabled ? Double(payment) : 0
        var principal = Double(capital)

        for yearIndex in 0..<totalYears {
            let principalStart = principal
            let step = FinanceMath.annuityDueYearStep(
                principalStart: principalStart,
                payment: paymentAmount,
                interestRate: interestRate
            )
            principal = step.totalEnd

            rows.append(
                CompoundProjectionRow(
                    year: yearIndex + 1,
                    payment: paymentAmount,
                    principalStart: principalStart,
                    interestEarned: step.interestEarned,
                    contribution: paymentAmount,
                    totalEnd: principal,
                    investedToDate: Double(capital) + paymentAmount * Double(yearIndex + 1)
                )
            )
        }

        return rows
    }

    /// EN: Generates yearly stock projections for price and share accumulation.
    /// ZH: 產生逐年股票價格與持股累積的預估結果。
    /// - Parameter capital: EN: `capital` (Int). ZH: 參數 `capital`（Int）。
    /// - Parameter paymentsEnabled: EN: `paymentsEnabled` (Bool). ZH: 參數 `paymentsEnabled`（Bool）。
    /// - Parameter payment: EN: `payment` (Int). ZH: 參數 `payment`（Int）。
    /// - Parameter years: EN: `years` (Int). ZH: 參數 `years`（Int）。
    /// - Parameter model0050: EN: `model0050` (StockGrowthModel?). ZH: 參數 `model0050`（StockGrowthModel?）。
    /// - Parameter model2330: EN: `model2330` (StockGrowthModel?). ZH: 參數 `model2330`（StockGrowthModel?）。
    /// - Returns: EN: `[Int: StockProjectionYear]` result. ZH: 回傳 `[Int: StockProjectionYear]` 結果。
    static func buildStockProjectionByYear(
        capital: Int,
        paymentsEnabled: Bool,
        payment: Int,
        years: Int,
        model0050: StockGrowthModel?,
        model2330: StockGrowthModel?
    ) -> [Int: StockProjectionYear] {
        let totalYears = max(0, years)
        guard
            totalYears > 0,
            let model0050,
            let model2330
        else { return [:] }

        var result: [Int: StockProjectionYear] = [:]
        var shares0050 = 0.0
        var shares2330 = 0.0
        var price0050 = model0050.latestPrice
        var price2330 = model2330.latestPrice

        for index in 1...totalYears {
            let growth0050 = effectiveGrowthRate(base: model0050.annualGrowthRate, projectionYear: index)
            let growth2330 = effectiveGrowthRate(base: model2330.annualGrowthRate, projectionYear: index)
            price0050 *= (1 + growth0050)
            price2330 *= (1 + growth2330)
            guard price0050 > 0, price2330 > 0 else { continue }

            let investAmount: Double
            if index == 1 {
                investAmount = Double(capital) + (paymentsEnabled ? Double(payment) : 0)
            } else {
                investAmount = paymentsEnabled ? Double(payment) : 0
            }

            let yearBought0050 = investAmount / price0050
            let yearBought2330 = investAmount / price2330
            shares0050 += yearBought0050
            shares2330 += yearBought2330

            result[index] = StockProjectionYear(
                price0050: price0050,
                price2330: price2330,
                shares0050: shares0050,
                shares2330: shares2330,
                delta0050: yearBought0050,
                delta2330: yearBought2330
            )
        }

        return result
    }

    /// EN: Applies terminal-growth fade after year 10 for stable projections.
    /// ZH: 第 10 年後套用終端成長收斂，維持預估穩定性。
    /// - Parameter base: EN: `base` (Double). ZH: 參數 `base`（Double）。
    /// - Parameter projectionYear: EN: `projectionYear` (Int). ZH: 參數 `projectionYear`（Int）。
    /// - Returns: EN: `Double` result. ZH: 回傳 `Double` 結果。
    private static func effectiveGrowthRate(base: Double, projectionYear: Int) -> Double {
        if projectionYear <= 10 {
            return base
        }
        let terminalGrowth = 0.04
        let span = 10.0
        let progress = FinanceMath.clamp((Double(projectionYear) - 10.0) / span, min: 0, max: 1)
        return base + (terminalGrowth - base) * progress
    }
}
