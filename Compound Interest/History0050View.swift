import SwiftUI

/// EN: Struct definition for daily candlestick view.
/// ZH: DailyCandlestickView 的 struct 定義。
private struct DailyCandlestickView: View {
    /// EN: Session open price. ZH: 當日開盤價。
    let open: Double
    /// EN: Session high price. ZH: 當日最高價。
    let high: Double
    /// EN: Session low price. ZH: 當日最低價。
    let low: Double
    /// EN: Session close price. ZH: 當日收盤價。
    let close: Double

    private var isUp: Bool { close > open }
    private var isDown: Bool { close < open }
    private var isFlat: Bool { !isUp && !isDown }
    private var wickColor: Color { isUp ? .red : (isDown ? .green : .gray) }
    private var bodyFillColor: Color { isUp ? .red : (isDown ? .green : .white) }
    private var bodyStrokeColor: Color { isFlat ? .gray : .clear }

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height
            let range = max(high - low, 0.0001)
            let wickX = width * 0.5
            let bodyWidth = max(width * 0.45, CGFloat(6))
            let minBodyHeight = max(height * 0.06, CGFloat(2))
            let highY: CGFloat = 0
            let lowY: CGFloat = height
            let openY = CGFloat((high - open) / range) * height
            let closeY = CGFloat((high - close) / range) * height
            let bodyTop = min(openY, closeY)
            let rawBodyHeight = abs(openY - closeY)
            let bodyHeight = max(rawBodyHeight, minBodyHeight)

            ZStack {
                Path { path in
                    path.move(to: CGPoint(x: wickX, y: highY))
                    path.addLine(to: CGPoint(x: wickX, y: lowY))
                }
                .stroke(wickColor, lineWidth: 1.5)

                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(bodyFillColor)
                    .overlay {
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .stroke(bodyStrokeColor, lineWidth: isFlat ? 1 : 0)
                    }
                    .frame(width: bodyWidth, height: bodyHeight)
                    .position(x: wickX, y: bodyTop + (bodyHeight / 2))
            }
        }
        .background(Color.clear)
    }
}

/// EN: Struct definition for stock history record.
/// ZH: StockHistoryRecord 的 struct 定義。
struct StockHistoryRecord: Identifiable, Decodable {
    /// EN: Stable identifier for list rendering. ZH: 清單渲染用識別值。
    let id = UUID()
    /// EN: Trading date in YYYY/MM/DD. ZH: 交易日期（YYYY/MM/DD）。
    let date: String
    /// EN: Open price. ZH: 開盤價。
    let open: Double
    /// EN: High price. ZH: 最高價。
    let high: Double
    /// EN: Low price. ZH: 最低價。
    let low: Double
    /// EN: Close price. ZH: 收盤價。
    let close: Double
    /// EN: Adjusted close from source. ZH: 來源提供的調整收盤價。
    let adjust_close: Double
    /// EN: Trading volume. ZH: 成交量。
    let volume: Double

    /// EN: Enum definition for coding keys.
    /// ZH: CodingKeys 的 enum 定義。
    private enum CodingKeys: String, CodingKey {
        case date
        case open
        case high
        case low
        case close
        case adjust_close
        case volume
    }
}

/// EN: Struct definition for stock history response.
/// ZH: StockHistoryResponse 的 struct 定義。
struct StockHistoryResponse: Decodable {
    /// EN: Daily records. ZH: 每日資料。
    let records: [StockHistoryRecord]
    /// EN: Optional annual summaries. ZH: 可選年度摘要。
    let annual_summaries: [StockAnnualSummary]?
    /// EN: Optional monthly summaries. ZH: 可選月度摘要。
    let monthly_summaries: [StockMonthlySummary]?
}

/// EN: Struct definition for stock annual summary.
/// ZH: StockAnnualSummary 的 struct 定義。
struct StockAnnualSummary: Decodable {
    /// EN: Year label. ZH: 年份。
    let year: String
    /// EN: Annual volume. ZH: 年度成交量。
    let volume: Double
    /// EN: Annual amount. ZH: 年度成交金額。
    let amount: Double
    /// EN: Annual trades count. ZH: 年度成交筆數。
    let trades: Double
    /// EN: Annual high price. ZH: 年度最高價。
    let high: Double
    /// EN: Date of annual high. ZH: 年度最高價日期。
    let high_date: String
    /// EN: Annual low price. ZH: 年度最低價。
    let low: Double
    /// EN: Date of annual low. ZH: 年度最低價日期。
    let low_date: String
    /// EN: Annual average close. ZH: 年度平均收盤價。
    let average_close: Double
}

/// EN: Struct definition for stock monthly summary.
/// ZH: StockMonthlySummary 的 struct 定義。
struct StockMonthlySummary: Decodable {
    /// EN: Year label. ZH: 年份。
    let year: String
    /// EN: Month label. ZH: 月份。
    let month: String
    /// EN: Monthly high. ZH: 月最高價。
    let high: Double
    /// EN: Monthly low. ZH: 月最低價。
    let low: Double
    /// EN: Monthly weighted average price. ZH: 月加權平均價。
    let weighted_average: Double
    /// EN: Monthly trades count. ZH: 月成交筆數。
    let trades: Double
    /// EN: Monthly amount. ZH: 月成交金額。
    let amount: Double
    /// EN: Monthly volume. ZH: 月成交量。
    let volume: Double
    /// EN: Monthly turnover rate. ZH: 月週轉率。
    let turnover_rate: Double
}

/// EN: Struct definition for stock history month group.
/// ZH: StockHistoryMonthGroup 的 struct 定義。
struct StockHistoryMonthGroup: Identifiable {
    /// EN: Unique month group id. ZH: 月分群唯一識別值。
    let id: String
    /// EN: Month key. ZH: 月份鍵值。
    let month: String
    /// EN: Daily rows in this month. ZH: 本月每日資料。
    let records: [StockHistoryRecord]
}

/// EN: Struct definition for stock history year group.
/// ZH: StockHistoryYearGroup 的 struct 定義。
struct StockHistoryYearGroup: Identifiable {
    /// EN: Unique year group id. ZH: 年分群唯一識別值。
    let id: String
    /// EN: Year key. ZH: 年份鍵值。
    let year: String
    /// EN: Month groups under this year. ZH: 該年度底下的月份分群。
    let months: [StockHistoryMonthGroup]
    var recordsCount: Int {
        return months.reduce(into: 0) { $0 += $1.records.count }
    }
}

/// EN: Struct definition for stock history list view.
/// ZH: StockHistoryListView 的 struct 定義。
struct StockHistoryListView: View {
    /// EN: Source JSON file name. ZH: 資料來源 JSON 檔名。
    let jsonFileName: String
    /// EN: Navigation title localization key. ZH: 導覽標題語系 key。
    let titleKey: String
    /// EN: External search keyword. ZH: 外部傳入搜尋關鍵字。
    var searchText: String = ""
    /// EN: Whether to show navigation title/toolbars. ZH: 是否顯示導覽列與工具列。
    var showNavigationUI: Bool = true

    /// EN: Loaded daily records. ZH: 載入後的每日資料。
    @State private var records: [StockHistoryRecord] = []
    /// EN: Annual summary lookup by year. ZH: 以年份索引的年度摘要。
    @State private var annualSummariesByYear: [String: StockAnnualSummary] = [:]
    /// EN: Monthly summary lookup by year-month. ZH: 以年月索引的月度摘要。
    @State private var monthlySummariesByYearMonth: [String: StockMonthlySummary] = [:]
    /// EN: Load error text for UI. ZH: 載入錯誤訊息。
    @State private var loadError: String?
    /// EN: Expanded year sections. ZH: 已展開的年度集合。
    @State private var expandedYears: Set<String> = []
    /// EN: Expanded month sections. ZH: 已展開的月份集合。
    @State private var expandedMonths: Set<String> = []
    /// EN: Persisted app language key. ZH: App 語系儲存鍵值。
    @AppStorage("appLanguage") private var appLanguage: String = "en"
    /// EN: Current color scheme. ZH: 目前深淺色模式。
    @Environment(\.colorScheme) private var colorScheme
    
    /// EN: Struct definition for annual summary display.
    /// ZH: AnnualSummaryDisplay 的 struct 定義。
    private struct AnnualSummaryDisplay {
        /// EN: First trading price used as annual open proxy. ZH: 年度開盤代理值（首筆交易價）。
        let open: Double
        /// EN: Last trading close used as annual close proxy. ZH: 年度收盤代理值（末筆交易價）。
        let close: Double
        /// EN: Annual high price. ZH: 年度最高價。
        let high: Double
        /// EN: Annual low price. ZH: 年度最低價。
        let low: Double
        /// EN: Annual average close. ZH: 年度平均收盤價。
        let averageClose: Double
        /// EN: Date text for annual high. ZH: 年高點日期文字。
        let highDate: String
        /// EN: Date text for annual low. ZH: 年低點日期文字。
        let lowDate: String
        /// EN: Annual volume summary. ZH: 年度成交量摘要。
        let volume: Double
    }

    /// EN: Struct definition for monthly summary display.
    /// ZH: MonthlySummaryDisplay 的 struct 定義。
    private struct MonthlySummaryDisplay {
        /// EN: First trading price used as monthly open proxy. ZH: 月開盤代理值（首筆交易價）。
        let open: Double
        /// EN: Last trading close used as monthly close proxy. ZH: 月收盤代理值（末筆交易價）。
        let close: Double
        /// EN: Monthly high price. ZH: 月最高價。
        let high: Double
        /// EN: Monthly low price. ZH: 月最低價。
        let low: Double
        /// EN: Monthly weighted average price. ZH: 月加權平均價。
        let weightedAverage: Double
        /// EN: Monthly volume summary. ZH: 月成交量摘要。
        let volume: Double
        /// EN: Monthly turnover text (if available). ZH: 月週轉率文字（若有資料）。
        let turnoverText: String?
    }

    /// EN: Candlestick size for annual summary rows (100%). ZH: 年度 K 線尺寸（100%）。
    private let annualCandleSize = CGSize(width: 26, height: 54)
    /// EN: Candlestick size for monthly summary rows (80%). ZH: 月度 K 線尺寸（80%）。
    private let monthlyCandleSize = CGSize(width: 20.8, height: 43.2)
    /// EN: Candlestick size for daily rows (70%). ZH: 每日 K 線尺寸（70%）。
    private let dailyCandleSize = CGSize(width: 18.2, height: 37.8)
    /// EN: Left indentation for year cards. ZH: 年度卡片左縮排。
    private let yearIndent: CGFloat = 2
    /// EN: Left indentation for month cards. ZH: 月度卡片左縮排。
    private let monthIndent: CGFloat = 10
    /// EN: Left indentation for daily rows. ZH: 每日列左縮排。
    private let dayIndent: CGFloat = 18

    /// EN: Returns a localized string for the current in-app language.
    /// ZH: 依目前 App 內語系回傳在地化字串。
    /// - Parameter key: EN: `key` (String). ZH: 參數 `key`（String）。
    /// - Returns: EN: `String` result. ZH: 回傳 `String` 結果。
    private func localized(_ key: String) -> String {
        guard
            let path = Bundle.main.path(forResource: appLanguage, ofType: "lproj"),
            let bundle = Bundle(path: path)
        else {
            return NSLocalizedString(key, comment: "")
        }
        return NSLocalizedString(key, bundle: bundle, comment: "")
    }

    /// EN: Formats a localized template string with runtime arguments.
    /// ZH: 使用執行期參數格式化在地化模板字串。
    /// - Parameter key: EN: `key` (String). ZH: 參數 `key`（String）。
    /// - Parameter args: EN: `args` (CVarArg...). ZH: 參數 `args`（CVarArg...）。
    /// - Returns: EN: `String` result. ZH: 回傳 `String` 結果。
    private func localizedFormat(_ key: String, _ args: CVarArg...) -> String {
        let format = localized(key)
        return String(format: format, locale: Locale(identifier: appLanguage), arguments: args)
    }

    private var filteredRecords: [StockHistoryRecord] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return records }
        let query = trimmed.lowercased()
        return records.filter { record in
            let date = record.date.lowercased()
            if date.contains(query) { return true }
            if String(record.open).lowercased().contains(query) { return true }
            if String(record.high).lowercased().contains(query) { return true }
            if String(record.low).lowercased().contains(query) { return true }
            if String(record.close).lowercased().contains(query) { return true }
            if String(record.adjust_close).lowercased().contains(query) { return true }
            if String(Int(record.volume)).contains(query) { return true }
            return false
        }
    }

    private var groupedByYear: [StockHistoryYearGroup] {
/// EN: Merge daily-data years with summary-only years so annual/monthly cards can still be shown.
/// ZH: 合併「每日資料年份」與「僅摘要年份」，確保年/月摘要仍可呈現。
        let dailyYearGroups = Dictionary(grouping: filteredRecords) { String($0.date.prefix(4)) }
        let summaryYears = Set(annualSummariesByYear.keys).union(
            monthlySummariesByYearMonth.keys.compactMap { String($0.split(separator: "-").first ?? "") }
        )
        let allYears = Set(dailyYearGroups.keys).union(summaryYears)
        let sortedYears = allYears.sorted(by: >)

        return sortedYears.map { year in
            let yearRecords = dailyYearGroups[year] ?? []
            let dailyMonthGroups = Dictionary(grouping: yearRecords) { record in
                let parts = record.date.split(separator: "/")
                return parts.count > 1 ? String(parts[1]) : "00"
            }
            let summaryMonths = Set(monthlySummariesByYearMonth.keys.compactMap { key -> String? in
                let parts = key.split(separator: "-")
                guard parts.count == 2, String(parts[0]) == year else { return nil }
                return String(parts[1])
            })
            let allMonths = Set(dailyMonthGroups.keys).union(summaryMonths)
            let sortedMonths = allMonths.sorted(by: >)
            let months = sortedMonths.map { month in
                let monthRecords = (dailyMonthGroups[month] ?? []).sorted { $0.date > $1.date }
                return StockHistoryMonthGroup(
                    id: "\(year)-\(month)",
                    month: month,
                    records: monthRecords
                )
            }
            return StockHistoryYearGroup(id: year, year: year, months: months)
        }
    }

    private var indexYears: [String] {
/// EN: Right-side index only shows years that contain daily rows.
/// ZH: 右側索引僅顯示有「每日資料」的年份。
        groupedByYear
            .filter { $0.recordsCount > 0 }
            .map(\.year)
    }

    /// EN: Builds a canonical year-month key used by monthly summary lookup.
    /// ZH: 建立月度摘要查找使用的標準年月鍵值。
    /// - Parameter year: EN: `year` (String). ZH: 參數 `year`（String）。
    /// - Parameter month: EN: `month` (String). ZH: 參數 `month`（String）。
    /// - Returns: EN: `String` result. ZH: 回傳 `String` 結果。
    private func monthKey(year: String, month: String) -> String {
        "\(year)-\(month)"
    }

    /// EN: Builds a stable scroll anchor identifier for a year section.
    /// ZH: 建立年份區塊用的穩定捲動錨點識別值。
    /// - Parameter year: EN: `year` (String). ZH: 參數 `year`（String）。
    /// - Returns: EN: `String` result. ZH: 回傳 `String` 結果。
    private func yearAnchorId(_ year: String) -> String {
        "year-anchor-\(year)"
    }

    /// EN: Looks up annual summary data for a given year.
    /// ZH: 查找指定年份的年度摘要資料。
    /// - Parameter year: EN: `year` (String). ZH: 參數 `year`（String）。
    /// - Returns: EN: `StockAnnualSummary?` result. ZH: 回傳 `StockAnnualSummary?` 結果。
    private func annualSummary(for year: String) -> StockAnnualSummary? {
        annualSummariesByYear[year]
    }

    /// EN: Looks up monthly summary data by year and month.
    /// ZH: 依年份與月份查找月度摘要資料。
    /// - Parameter year: EN: `year` (String). ZH: 參數 `year`（String）。
    /// - Parameter month: EN: `month` (String). ZH: 參數 `month`（String）。
    /// - Returns: EN: `StockMonthlySummary?` result. ZH: 回傳 `StockMonthlySummary?` 結果。
    private func monthlySummary(year: String, month: String) -> StockMonthlySummary? {
        monthlySummariesByYearMonth[monthKey(year: year, month: month)]
    }

    /// EN: Converts YYYY/MM/DD text into MM/DD display text.
    /// ZH: 將 YYYY/MM/DD 文字轉換為 MM/DD 顯示格式。
    /// - Parameter date: EN: `date` (String). ZH: 參數 `date`（String）。
    /// - Returns: EN: `String` result. ZH: 回傳 `String` 結果。
    private func monthDayText(from date: String) -> String {
        let parts = date.split(separator: "/")
        guard parts.count == 3 else { return "--/--" }
        let month = Int(parts[1]) ?? 0
        let day = Int(parts[2]) ?? 0
        return "\(month)/\(String(format: "%02d", day))"
    }

    /// EN: Builds annual summary display data from summary or daily fallback.
    /// ZH: 由年度摘要或每日資料備援建立年度顯示資料。
    /// - Parameter year: EN: `year` (String). ZH: 參數 `year`（String）。
    /// - Returns: EN: `AnnualSummaryDisplay?` result. ZH: 回傳 `AnnualSummaryDisplay?` 結果。
    private func annualSummaryDisplay(for year: String) -> AnnualSummaryDisplay? {
        let yearPrefix = "\(year)/"
        let yearRecords = records.filter { $0.date.hasPrefix(yearPrefix) }
        let highRecord = yearRecords.max(by: { $0.high < $1.high })
        let lowRecord = yearRecords.min(by: { $0.low < $1.low })
        let firstRecord = yearRecords.min(by: { $0.date < $1.date })
        let lastRecord = yearRecords.max(by: { $0.date < $1.date })

        if let summary = annualSummary(for: year) {
            let openPrice = firstRecord?.open ?? summary.average_close
            let closePrice = lastRecord?.close ?? summary.average_close
            return AnnualSummaryDisplay(
                open: openPrice,
                close: closePrice,
                high: summary.high,
                low: summary.low,
                averageClose: summary.average_close,
                highDate: summary.high_date,
                lowDate: summary.low_date,
                volume: summary.volume
            )
        }

        guard
            !yearRecords.isEmpty,
            let highRecord,
            let lowRecord,
            let firstRecord,
            let lastRecord
        else { return nil }

        let totalVolume = yearRecords.reduce(0.0) { $0 + $1.volume }
        let avgClose = yearRecords.reduce(0.0) { $0 + $1.close } / Double(yearRecords.count)
        return AnnualSummaryDisplay(
            open: firstRecord.open,
            close: lastRecord.close,
            high: highRecord.high,
            low: lowRecord.low,
            averageClose: avgClose,
            highDate: monthDayText(from: highRecord.date),
            lowDate: monthDayText(from: lowRecord.date),
            volume: totalVolume
        )
    }

    /// EN: Builds monthly summary display data from summary or daily fallback.
    /// ZH: 由月度摘要或每日資料備援建立月度顯示資料。
    /// - Parameter year: EN: `year` (String). ZH: 參數 `year`（String）。
    /// - Parameter month: EN: `month` (String). ZH: 參數 `month`（String）。
    /// - Returns: EN: `MonthlySummaryDisplay?` result. ZH: 回傳 `MonthlySummaryDisplay?` 結果。
    private func monthlySummaryDisplay(year: String, month: String) -> MonthlySummaryDisplay? {
        let monthPrefix = "\(year)/\(month)/"
        let monthRecords = records.filter { $0.date.hasPrefix(monthPrefix) }
        let highRecord = monthRecords.max(by: { $0.high < $1.high })
        let lowRecord = monthRecords.min(by: { $0.low < $1.low })
        let firstRecord = monthRecords.min(by: { $0.date < $1.date })
        let lastRecord = monthRecords.max(by: { $0.date < $1.date })

        if let summary = monthlySummary(year: year, month: month) {
            let openPrice = firstRecord?.open ?? summary.weighted_average
            let closePrice = lastRecord?.close ?? summary.weighted_average
            return MonthlySummaryDisplay(
                open: openPrice,
                close: closePrice,
                high: summary.high,
                low: summary.low,
                weightedAverage: summary.weighted_average,
                volume: summary.volume,
                turnoverText: "\(summary.turnover_rate.formatted(.number.precision(.fractionLength(2))))%"
            )
        }

        guard
            !monthRecords.isEmpty,
            let highRecord,
            let lowRecord,
            let firstRecord,
            let lastRecord
        else { return nil }

        let avgClose = monthRecords.reduce(0.0) { $0 + $1.close } / Double(monthRecords.count)
        let totalVolume = monthRecords.reduce(0.0) { $0 + $1.volume }
        return MonthlySummaryDisplay(
            open: firstRecord.open,
            close: lastRecord.close,
            high: highRecord.high,
            low: lowRecord.low,
            weightedAverage: avgClose,
            volume: totalVolume,
            turnoverText: nil
        )
    }

    /// EN: Initializes default expanded/collapsed state for year and month sections.
    /// ZH: 初始化年與月區塊的預設展開/收合狀態。
    private func initializeExpansionState() {
        expandedYears = Set(groupedByYear.map { $0.year })
        expandedMonths = []
    }

    var body: some View {
        ScrollViewReader { proxy in
            List {
                if let loadError {
                    Text(loadError)
                        .foregroundStyle(AppTheme.semanticError(for: colorScheme))
                }

                ForEach(groupedByYear, id: \.year) { yearGroup in
                    Section {
                        Button {
                            if expandedYears.contains(yearGroup.year) {
                                expandedYears.remove(yearGroup.year)
                            } else {
                                expandedYears.insert(yearGroup.year)
                            }
                        } label: {
                            HStack(alignment: .top, spacing: 10) {
                                if let summary = annualSummaryDisplay(for: yearGroup.year) {
                                    DailyCandlestickView(
                                        open: summary.open,
                                        high: summary.high,
                                        low: summary.low,
                                        close: summary.close
                                    )
                                    .frame(width: annualCandleSize.width, height: annualCandleSize.height)

                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(
                                            localizedFormat(
                                                "history_annual_avg_line",
                                                summary.averageClose.formatted(.number.precision(.fractionLength(2)))
                                            )
                                        )
                                        HStack(spacing: 4) {
                                            Text(
                                                localizedFormat(
                                                    "history_annual_high_price",
                                                    summary.high.formatted(.number.precision(.fractionLength(2)))
                                                )
                                            )
                                            Text(localizedFormat("history_date_suffix", summary.highDate))
                                                .font(.subheadline.weight(.semibold))
                                                .foregroundStyle(.secondary)
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)

                                        HStack(spacing: 4) {
                                            Text(
                                                localizedFormat(
                                                    "history_annual_low_price",
                                                    summary.low.formatted(.number.precision(.fractionLength(2)))
                                                )
                                            )
                                            Text(localizedFormat("history_date_suffix", summary.lowDate))
                                                .font(.subheadline.weight(.semibold))
                                                .foregroundStyle(.secondary)
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)

                                        Text(
                                            localizedFormat(
                                                "history_annual_volume_line",
                                                summary.volume.formatted(.number.precision(.fractionLength(0)))
                                            )
                                        )
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    .font(.headline.weight(.bold))
                                    .foregroundStyle(.primary)
                                    .lineLimit(nil)
                                } else {
                                    Text(localizedFormat("history_year_data_count", "\(yearGroup.recordsCount)"))
                                        .font(.title3.bold())
                                }
                                Spacer()
                                Image(systemName: expandedYears.contains(yearGroup.year) ? "chevron.down" : "chevron.right")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(10)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(AppTheme.surfaceLevel1Fill(for: colorScheme))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(AppTheme.surfaceLevel1Stroke(for: colorScheme), lineWidth: 1.3)
                            )
                            .padding(.leading, yearIndent)
                            .padding(.trailing, 4)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .id(yearAnchorId(yearGroup.year))

                        if expandedYears.contains(yearGroup.year) {
                            ForEach(yearGroup.months) { monthGroup in
                                let monthExpanded = expandedMonths.contains(monthKey(year: yearGroup.year, month: monthGroup.month))
                                let monthly = monthlySummaryDisplay(year: yearGroup.year, month: monthGroup.month)
                                VStack(alignment: .leading, spacing: 8) {
                                    Button {
                                        let key = monthKey(year: yearGroup.year, month: monthGroup.month)
                                        if expandedMonths.contains(key) {
                                            expandedMonths.remove(key)
                                        } else {
                                            expandedMonths.insert(key)
                                        }
                                    } label: {
                                        VStack(alignment: .leading, spacing: 8) {
                                            HStack {
                                                Text(localizedFormat("history_month_header", monthGroup.month))
                                                    .font(.headline)
                                                Spacer()
                                                Image(systemName: monthExpanded ? "chevron.down" : "chevron.right")
                                                    .font(.footnote)
                                                    .foregroundStyle(.secondary)
                                            }

                                            if let monthly {
                                                HStack(alignment: .top, spacing: 10) {
                                            DailyCandlestickView(
                                                open: monthly.open,
                                                high: monthly.high,
                                                low: monthly.low,
                                                close: monthly.close
                                            )
                                            .frame(width: monthlyCandleSize.width, height: monthlyCandleSize.height)

                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(
                                                    localizedFormat(
                                                        "history_monthly_avg_line",
                                                        monthly.weightedAverage.formatted(.number.precision(.fractionLength(2)))
                                                    )
                                                )
                                                HStack(alignment: .top, spacing: 12) {
                                                    Text(
                                                        localizedFormat(
                                                            "history_monthly_high_line",
                                                            monthly.high.formatted(.number.precision(.fractionLength(2)))
                                                        )
                                                    )
                                                    .frame(maxWidth: .infinity, alignment: .leading)

                                                    Text(
                                                        localizedFormat(
                                                            "history_monthly_low_line",
                                                            monthly.low.formatted(.number.precision(.fractionLength(2)))
                                                        )
                                                    )
                                                    .frame(maxWidth: .infinity, alignment: .leading)
                                                }
                                                HStack(alignment: .top, spacing: 12) {
                                                    Text(
                                                        localizedFormat(
                                                            "history_monthly_volume_line",
                                                            monthly.volume.formatted(.number.precision(.fractionLength(0)))
                                                        )
                                                    )
                                                    .frame(maxWidth: .infinity, alignment: .leading)

                                                    if let turnoverText = monthly.turnoverText {
                                                        Text(
                                                            localizedFormat(
                                                                "history_monthly_turnover_line",
                                                                turnoverText
                                                            )
                                                        )
                                                        .frame(maxWidth: .infinity, alignment: .leading)
                                                    }
                                                }
                                            }
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(.primary)
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.65)
                                            .allowsTightening(true)
                                            Spacer()
                                        }
                                    }
                                        }
                                        .padding(10)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                .fill(AppTheme.surfaceLevel2Fill(for: colorScheme))
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                .stroke(AppTheme.surfaceLevel2Stroke(for: colorScheme), lineWidth: 1)
                                        )
                                        .padding(.leading, monthIndent)
                                        .padding(.trailing, 4)
                                        .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)

                                    if monthExpanded {
                                        ForEach(monthGroup.records) { record in
                                            HStack(alignment: .top, spacing: 10) {
                                                DailyCandlestickView(
                                                    open: record.open,
                                                    high: record.high,
                                                    low: record.low,
                                                    close: record.close
                                                )
                                                .frame(width: dailyCandleSize.width, height: dailyCandleSize.height)

                                                VStack(alignment: .leading, spacing: 6) {
                                                    Text(localizedFormat("history_close", record.close.formatted(.number.precision(.fractionLength(2)))))
                                                        .bold()
                                                    Text(
                                                        localizedFormat(
                                                            "history_ohl",
                                                            record.open.formatted(.number.precision(.fractionLength(2))),
                                                            record.high.formatted(.number.precision(.fractionLength(2))),
                                                            record.low.formatted(.number.precision(.fractionLength(2)))
                                                        )
                                                    )
                                                    .font(.footnote)
                                                    Text(
                                                        localizedFormat(
                                                            "history_adjusted_volume",
                                                            record.adjust_close.formatted(.number.precision(.fractionLength(2))),
                                                            record.volume.formatted(.number.precision(.fractionLength(0)))
                                                        )
                                                    )
                                                    .font(.footnote)
                                                    Text(record.date)
                                                        .font(.footnote)
                                                        .foregroundStyle(.secondary)
                                                }
                                            }
                                            .padding(8)
                                            .background(
                                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                    .fill(AppTheme.surfaceLevel3Fill(for: colorScheme))
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                    .stroke(AppTheme.surfaceLevel3Stroke(for: colorScheme), lineWidth: 0.6)
                                            )
                                            .padding(.leading, dayIndent)
                                            .padding(.trailing, 4)
                                        }
                                    }
                                }
                            }
                        }
                    } header: {
                        Button {
                            if expandedYears.contains(yearGroup.year) {
                                expandedYears.remove(yearGroup.year)
                            } else {
                                expandedYears.insert(yearGroup.year)
                            }
                        } label: {
                            HStack {
                                Text(yearGroup.year)
                                Spacer()
                                Image(systemName: expandedYears.contains(yearGroup.year) ? "chevron.down" : "chevron.right")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    .id(yearGroup.year)
                }
            }
            .listStyle(.grouped)
            .overlay(alignment: .trailing) {
                VStack(spacing: 6) {
                    ForEach(indexYears, id: \.self) { year in
                        Text(year)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .frame(width: 28, height: 18)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    proxy.scrollTo(yearAnchorId(year), anchor: .top)
                                }
                            }
                    }
                }
                .padding(.trailing, 6)
            }
            .modifier(StockHistoryNavigationModifier(showNavigationUI: showNavigationUI, titleKey: titleKey))
            .fontDesign(.monospaced)
        }
        .onAppear(perform: load)
    }

    /// EN: Loads and decodes stock history JSON into grouped view state.
    /// ZH: 載入並解碼股票歷史 JSON，建立分群後的畫面狀態。
    private func load() {
        guard let url = Bundle.main.url(forResource: jsonFileName, withExtension: "json") else {
            loadError = localized("history_missing")
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let response = try JSONDecoder().decode(StockHistoryResponse.self, from: data)
            records = response.records
            annualSummariesByYear = Dictionary(uniqueKeysWithValues: (response.annual_summaries ?? []).map { ($0.year, $0) })
            monthlySummariesByYearMonth = Dictionary(uniqueKeysWithValues: (response.monthly_summaries ?? []).map { (monthKey(year: $0.year, month: $0.month), $0) })
            initializeExpansionState()
            loadError = nil
        } catch {
            loadError = localizedFormat("history_load_failed", error.localizedDescription)
        }
    }
}

/// EN: Struct definition for stock history navigation modifier.
/// ZH: StockHistoryNavigationModifier 的 struct 定義。
private struct StockHistoryNavigationModifier: ViewModifier {
    let showNavigationUI: Bool
    let titleKey: String
    @AppStorage("appLanguage") private var appLanguage: String = "en"

    /// EN: Returns a localized string for the current in-app language.
    /// ZH: 依目前 App 內語系回傳在地化字串。
    /// - Parameter key: EN: `key` (String). ZH: 參數 `key`（String）。
    /// - Returns: EN: `String` result. ZH: 回傳 `String` 結果。
    private func localized(_ key: String) -> String {
        guard
            let path = Bundle.main.path(forResource: appLanguage, ofType: "lproj"),
            let bundle = Bundle(path: path)
        else {
            return NSLocalizedString(key, comment: "")
        }
        return NSLocalizedString(key, bundle: bundle, comment: "")
    }

    /// EN: Builds modified content with stock-history navigation chrome.
    /// ZH: 建立含股票歷史導覽外觀的修飾後內容。
    /// - Parameter content: EN: `content` (Content). ZH: 參數 `content`（Content）。
    /// - Returns: EN: `some View` result. ZH: 回傳 `some View` 結果。
    func body(content: Content) -> some View {
        if showNavigationUI {
            content
                .navigationTitle(localized(titleKey))
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            appLanguage = (appLanguage == "en") ? "zh-Hant" : "en"
                        } label: {
                            Image(systemName: "globe")
                        }
                        .accessibilityLabel(Text(localized("globe_accessibility")))
                    }
                }
        } else {
            content
        }
    }
}

/// EN: Struct definition for history0050 view.
/// ZH: History0050View 的 struct 定義。
struct History0050View: View {
    var searchText: String = ""
    var showNavigationUI: Bool = true

    var body: some View {
        StockHistoryListView(
            jsonFileName: "0050_history",
            titleKey: "history_0050_title",
            searchText: searchText,
            showNavigationUI: showNavigationUI
        )
    }
}

/// EN: Struct definition for history2330 view.
/// ZH: History2330View 的 struct 定義。
struct History2330View: View {
    var searchText: String = ""
    var showNavigationUI: Bool = true

    var body: some View {
        StockHistoryListView(
            jsonFileName: "2330_history",
            titleKey: "history_2330_title",
            searchText: searchText,
            showNavigationUI: showNavigationUI
        )
    }
}

#Preview {
    NavigationStack {
        History0050View()
    }
}
