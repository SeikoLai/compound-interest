import SwiftUI
import UIKit

/// EN: Struct definition for stock history lite record.
/// ZH: StockHistoryLiteRecord 的 struct 定義。
private struct StockHistoryLiteRecord: Decodable {
/// EN: Trading date in YYYY/MM/DD.
/// ZH: 交易日期（YYYY/MM/DD）。
    let date: String
/// EN: Close price from source data.
/// ZH: 來源資料的收盤價。
    let close: Double
/// EN: Exchange-adjusted close if provided.
/// ZH: 若有提供，使用交易所調整後收盤價。
    let adjust_close: Double?
}

/// EN: Struct definition for stock annual summary lite.
/// ZH: StockAnnualSummaryLite 的 struct 定義。
private struct StockAnnualSummaryLite: Decodable {
/// EN: Summary year.
/// ZH: 年度摘要年份。
    let year: String
/// EN: Annual average close from source summary.
/// ZH: 來源摘要提供的年度平均收盤價。
    let average_close: Double
}

/// EN: Struct definition for stock history lite response.
/// ZH: StockHistoryLiteResponse 的 struct 定義。
private struct StockHistoryLiteResponse: Decodable {
/// EN: Daily records used for growth estimation.
/// ZH: 用於估算成長率的日資料。
    let records: [StockHistoryLiteRecord]
/// EN: Optional annual summaries from source.
/// ZH: 來源可選的年度摘要資料。
    let annual_summaries: [StockAnnualSummaryLite]?
}

/// EN: Struct definition for stock split event.
/// ZH: StockSplitEvent 的 struct 定義。
private struct StockSplitEvent {
/// EN: Split effective date in YYYY/MM/DD.
/// ZH: 股票分割生效日（YYYY/MM/DD）。
    let effectiveDate: String  // YYYY/MM/DD
/// EN: Split ratio; 4.0 means 1 old share becomes 4 new shares.
/// ZH: 分割比率；4.0 代表 1 股拆成 4 股。
    let splitRatio: Double     // e.g. 4.0 means 1 -> 4
}

/// EN: Struct definition for record.
/// ZH: Record 的 struct 定義。
struct Record: Identifiable {
/// EN: Stable identity for SwiftUI list diffing.
/// ZH: SwiftUI 清單更新用的穩定識別值。
    let id: UUID = UUID()
    /// EN: Projection year index (1-based). ZH: 預估年份（從 1 開始）。
    var year: Int
    /// EN: Annual contribution amount. ZH: 每年投入金額。
    var payment: Double
    /// EN: Principal at beginning of year. ZH: 年初本金。
    var principalStart: Double
    /// EN: Interest earned in current year. ZH: 當年利息。
    var interestEarned: Double
    /// EN: Contribution booked this year. ZH: 當年投入。
    var contribution: Double
    /// EN: End-of-year total value. ZH: 年底總額。
    var totalEnd: Double
    /// EN: Cumulative invested capital by this year. ZH: 截至當年累積投入本金。
    var investedToDate: Double
    /// EN: Growth multiple vs invested capital. ZH: 相對累積投入的成長倍數。
    var times: Double { investedToDate > 0 ? (totalEnd / investedToDate) : 0 }
}

/// EN: Struct definition for content view.
/// ZH: ContentView 的 struct 定義。
struct ContentView: View {
    /// EN: Enum definition for tab.
    /// ZH: Tab 的 enum 定義。
    private enum Tab: Hashable {
        case compound
        case history
    }

    /// EN: Enum definition for input field.
    /// ZH: InputField 的 enum 定義。
    private enum InputField: Hashable {
        case principal
        case annualContribution
    }

    /// EN: Initial principal input. ZH: 初始本金輸入值。
    @State var capital: Int = 60000
    /// EN: Toggle for annual fixed contribution. ZH: 是否啟用每年固定投入。
    @State var paymentsEnabled: Bool = true
    /// EN: Annual contribution input. ZH: 每年固定投入金額。
    @State var payment: Int = 120000
    /// EN: Projection horizon in years. ZH: 預估年數。
    @State var year: Int = 20
    /// EN: Compound interest rate for cash model. ZH: 現金複利模型年利率。
    @State var interest = 0.1
    /// EN: Persisted app language key. ZH: App 語系儲存鍵值。
    @AppStorage("appLanguage") private var appLanguage: String = "en"
    /// EN: Controls input panel visibility. ZH: 控制輸入面板顯示。
    @State private var showInputAlert: Bool = false
    /// EN: FAB tap animation rotation. ZH: 懸浮按鈕點擊旋轉角度。
    @State private var keyboardRotation: Double = 0
    /// EN: Current FAB center position. ZH: 懸浮按鈕目前中心座標。
    @State private var fabPosition: CGPoint = .zero
    /// EN: FAB drag start anchor. ZH: 懸浮按鈕拖曳起始座標。
    @State private var fabStartPosition: CGPoint = .zero
    /// EN: One-time FAB initial positioning flag. ZH: 懸浮按鈕是否已完成初始定位。
    @State private var fabInitialized: Bool = false
    /// EN: FAB dragging state. ZH: 懸浮按鈕拖曳中狀態。
    @State private var isDraggingFab: Bool = false
    /// EN: Current selected tab. ZH: 目前選取分頁。
    @State private var selectedTab: Tab = .compound
    /// EN: Keyboard top Y in global coordinates. ZH: 鍵盤頂部的全域 Y 座標。
    @State private var keyboardTopY: CGFloat = .greatestFiniteMagnitude
    /// EN: Principal text field binding. ZH: 本金輸入框字串。
    @State private var principalText: String = "0"
    /// EN: Annual contribution text field binding. ZH: 每年投入輸入框字串。
    @State private var paymentText: String = "120000"
    /// EN: Focus target for input fields. ZH: 輸入框焦點控制。
    @FocusState private var focusedField: InputField?
    /// EN: Growth model cache for 0050. ZH: 0050 成長模型快取。
    @State private var growthModel0050: StockGrowthModel?
    /// EN: Growth model cache for 2330. ZH: 2330 成長模型快取。
    @State private var growthModel2330: StockGrowthModel?
    /// EN: Lookback window for CAGR estimation. ZH: CAGR 回朔區間年數。
    @State private var growthLookbackYears: Int = 5
    /// EN: Expanded years for projection panel. ZH: 展開股票預估區塊的年份集合。
    @State private var expandedProjectionYears: Set<Int> = []
    /// EN: Current color scheme for theming. ZH: 目前深淺色模式。
    @Environment(\.colorScheme) private var colorScheme

    /// EN: Floating action button diameter. ZH: 懸浮按鈕直徑。
    private let fabSize: CGFloat = 56
    /// EN: Minimum edge margin for FAB movement. ZH: 懸浮按鈕與邊界最小距離。
    private let fabMargin: CGFloat = 12
    /// EN: Default FAB center offset above safe-bottom/tab area. ZH: 預設懸浮按鈕位於 tab 區上方的中心偏移。
    private let tabBarRowCenterFromSafeBottom: CGFloat = 54
    /// EN: Gap between keyboard top and locked FAB. ZH: 鍵盤頂部與懸浮按鈕鎖定位置的間距。
    private let keyboardGap: CGFloat = 10

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

    /// EN: Filters input text to digits only for numeric fields.
    /// ZH: 將輸入文字過濾為純數字，供數值欄位使用。
    /// - Parameter value: EN: `value` (String). ZH: 參數 `value`（String）。
    /// - Returns: EN: `String` result. ZH: 回傳 `String` 結果。
    private func digitsOnly(_ value: String) -> String {
        value.filter(\.isNumber)
    }

    /// EN: Clamps the floating button center to the draggable safe region.
    /// ZH: 將懸浮按鈕中心限制在可拖曳安全區域內。
    /// - Parameter point: EN: `point` (CGPoint). ZH: 參數 `point`（CGPoint）。
    /// - Parameter proxy: EN: `proxy` (GeometryProxy). ZH: 參數 `proxy`（GeometryProxy）。
    /// - Returns: EN: `CGPoint` result. ZH: 回傳 `CGPoint` 結果。
    private func clampedFabPosition(_ point: CGPoint, in proxy: GeometryProxy) -> CGPoint {
        let minX = (fabSize / 2) + fabMargin
        let maxX = proxy.size.width - (fabSize / 2) - fabMargin
        let minY = proxy.safeAreaInsets.top + (fabSize / 2) + fabMargin
        let maxY = proxy.size.height - proxy.safeAreaInsets.bottom - tabBarRowCenterFromSafeBottom
        return CGPoint(
            x: min(max(point.x, minX), maxX),
            y: min(max(point.y, minY), maxY)
        )
    }

    /// EN: Computes the floating button position locked above the keyboard.
    /// ZH: 計算鍵盤顯示時固定於鍵盤上方的懸浮按鈕位置。
    /// - Parameter point: EN: `point` (CGPoint). ZH: 參數 `point`（CGPoint）。
    /// - Parameter proxy: EN: `proxy` (GeometryProxy). ZH: 參數 `proxy`（GeometryProxy）。
    /// - Returns: EN: `CGPoint` result. ZH: 回傳 `CGPoint` 結果。
    private func keyboardLockedFabPosition(_ point: CGPoint, in proxy: GeometryProxy) -> CGPoint {
        let minX = (fabSize / 2) + fabMargin
        let maxX = proxy.size.width - (fabSize / 2) - fabMargin
        let minY = proxy.safeAreaInsets.top + (fabSize / 2) + fabMargin
        let localKeyboardTop = keyboardTopY - proxy.frame(in: .global).minY
        let fixedY = localKeyboardTop - keyboardGap - (fabSize / 2)
        return CGPoint(
            x: min(max(point.x, minX), maxX),
            y: max(fixedY, minY)
        )
    }

    private var isKeyboardVisible: Bool {
        keyboardTopY.isFinite && keyboardTopY < .greatestFiniteMagnitude
    }

    /// EN: Returns the default bottom-right floating button position.
    /// ZH: 回傳右下角的懸浮按鈕預設位置。
    /// - Parameter proxy: EN: `proxy` (GeometryProxy). ZH: 參數 `proxy`（GeometryProxy）。
    /// - Returns: EN: `CGPoint` result. ZH: 回傳 `CGPoint` 結果。
    private func defaultFabPosition(in proxy: GeometryProxy) -> CGPoint {
        let x = proxy.size.width - (fabSize / 2) - fabMargin
        let y = proxy.size.height - proxy.safeAreaInsets.bottom - tabBarRowCenterFromSafeBottom
        return clampedFabPosition(CGPoint(x: x, y: y), in: proxy)
    }

    /// EN: Dismisses the input panel and resigns active text input focus.
    /// ZH: 關閉輸入面板並取消目前文字輸入焦點。
    private func dismissInputPanelAndKeyboard() {
        showInputAlert = false
        focusedField = nil
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

/// EN: Build UI records from projection service output.
/// ZH: 將預估服務輸出轉為 UI 顯示用資料列。
    private var records: [Record] {
        CompoundProjectionService.buildCompoundRows(
            capital: capital,
            paymentsEnabled: paymentsEnabled,
            payment: payment,
            years: year,
            interestRate: interest
        ).map { row in
            Record(
                year: row.year,
                payment: row.payment,
                principalStart: row.principalStart,
                interestEarned: row.interestEarned,
                contribution: row.contribution,
                totalEnd: row.totalEnd,
                investedToDate: row.investedToDate
            )
        }
    }

/// EN: Build yearly stock projection map keyed by year.
/// ZH: 建立以年份為鍵的股票預估資料映射。
    private var stockProjectionByYear: [Int: (price0050: Double, price2330: Double, shares0050: Double, shares2330: Double, delta0050: Double, delta2330: Double)] {
        let projections = CompoundProjectionService.buildStockProjectionByYear(
            capital: capital,
            paymentsEnabled: paymentsEnabled,
            payment: payment,
            years: year,
            model0050: growthModel0050,
            model2330: growthModel2330
        )

        return projections.mapValues { year in
            (
                price0050: year.price0050,
                price2330: year.price2330,
                shares0050: year.shares0050,
                shares2330: year.shares2330,
                delta0050: year.delta0050,
                delta2330: year.delta2330
            )
        }
    }

    /// EN: Provides stock split events for the specified dataset.
    /// ZH: 依指定資料集提供股票分割事件。
    /// - Parameter jsonName: EN: `jsonName` (String). ZH: 參數 `jsonName`（String）。
    /// - Returns: EN: `[StockSplitEvent]` result. ZH: 回傳 `[StockSplitEvent]` 結果。
    private func splitEvents(for jsonName: String) -> [StockSplitEvent] {
        if jsonName == "0050_history" {
            return [
/// EN: 0050 stock split 1 -> 4, effective from 2025/06/18.
/// ZH: 0050 於 2025/06/18 起進行 1 拆 4。
                StockSplitEvent(effectiveDate: "2025/06/18", splitRatio: 4.0)
            ]
        }
        return []
    }

    /// EN: Converts a close price to a split-normalized basis.
    /// ZH: 將收盤價轉換為分割校正後的同基準價格。
    /// - Parameter jsonName: EN: `jsonName` (String). ZH: 參數 `jsonName`（String）。
    /// - Parameter tradeDate: EN: `tradeDate` (String). ZH: 參數 `tradeDate`（String）。
    /// - Parameter close: EN: `close` (Double). ZH: 參數 `close`（Double）。
    /// - Returns: EN: `Double` result. ZH: 回傳 `Double` 結果。
    private func adjustedClose(jsonName: String, tradeDate: String, close: Double) -> Double {
        guard close > 0 else { return close }
        let events = splitEvents(for: jsonName)
        guard !events.isEmpty else { return close }

        var adjusted = close
        for event in events {
            guard event.splitRatio > 0 else { continue }
/// EN: Convert pre-split prices into a post-split per-share basis for apples-to-apples CAGR.
/// ZH: 將分割前價格換算到分割後每股基準，確保 CAGR 可同基準比較。
            adjusted = FinanceMath.adjustedClose(
                close: adjusted,
                tradeDate: tradeDate,
                splitEvents: [(event.effectiveDate, event.splitRatio)]
            )
        }
        return adjusted
    }

    /// EN: Loads local history JSON and builds a bounded CAGR growth model.
    /// ZH: 載入本地歷史 JSON，並建立受限 CAGR 成長模型。
    /// - Parameter jsonName: EN: `jsonName` (String). ZH: 參數 `jsonName`（String）。
    /// - Parameter lookbackYears: EN: `lookbackYears` (Int). ZH: 參數 `lookbackYears`（Int）。
    /// - Returns: EN: `StockGrowthModel?` result. ZH: 回傳 `StockGrowthModel?` 結果。
    private func loadGrowthModel(from jsonName: String, lookbackYears: Int) -> StockGrowthModel? {
        guard let url = Bundle.main.url(forResource: jsonName, withExtension: "json") else { return nil }
        guard
            let data = try? Data(contentsOf: url),
            let response = try? JSONDecoder().decode(StockHistoryLiteResponse.self, from: data)
        else { return nil }

/// EN: Prefer adjusted close; then apply split normalization for a consistent valuation basis.
/// ZH: 優先使用調整收盤價，再套用分割正規化，統一估值基準。
        let normalized: [StockHistoryLiteRecord] = response.records.map { row in
            let baseClose = (row.adjust_close ?? row.close) > 0 ? (row.adjust_close ?? row.close) : row.close
            let splitAdjusted = adjustedClose(jsonName: jsonName, tradeDate: row.date, close: baseClose)
            return StockHistoryLiteRecord(date: row.date, close: splitAdjusted, adjust_close: row.adjust_close)
        }

        let sorted = normalized.sorted { $0.date < $1.date }
        guard let latest = sorted.last, latest.close > 0 else { return nil }

        let latestYear = Int(latest.date.prefix(4)) ?? 0
        let targetYear = latestYear - max(1, lookbackYears)

        let baseRecord = sorted.first { (Int($0.date.prefix(4)) ?? 0) >= targetYear } ?? sorted.first
        guard let baseRecord, baseRecord.close > 0 else { return nil }
        let baseYear = Int(baseRecord.date.prefix(4)) ?? targetYear
        let yearsSpan = max(1, latestYear - baseYear)
/// EN: CAGR formula = (latest/base)^(1/years) - 1.
/// ZH: 年化成長率公式：CAGR = (期末/期初)^(1/年數) - 1。
        let rawGrowth = FinanceMath.cagr(
            latest: latest.close,
            base: baseRecord.close,
            years: yearsSpan
        )

/// EN: Clamp to a conservative interval for projection stability in UI.
/// ZH: 將成長率限制在保守區間，避免 UI 預估值過度震盪。
        let growth = FinanceMath.clamp(rawGrowth, min: -0.05, max: 0.12)

        return StockGrowthModel(latestPrice: latest.close, annualGrowthRate: growth)
    }

    /// EN: Builds one stock projection column for symbol, shares, and price.
    /// ZH: 建立單一股票的預估欄位（代號、股數與價格）。
    /// - Parameter symbol: EN: `symbol` (String). ZH: 參數 `symbol`（String）。
    /// - Parameter totalShares: EN: `totalShares` (Double). ZH: 參數 `totalShares`（Double）。
    /// - Parameter deltaShares: EN: `deltaShares` (Double). ZH: 參數 `deltaShares`（Double）。
    /// - Parameter estimatedPrice: EN: `estimatedPrice` (Double). ZH: 參數 `estimatedPrice`（Double）。
    /// - Returns: EN: `some View` result. ZH: 回傳 `some View` 結果。
    private func stockProjectionColumn(symbol: String, totalShares: Double, deltaShares: Double, estimatedPrice: Double) -> some View {
        let sharesBase = localizedFormat(
            "record_stock_shares_single_base",
            totalShares.formatted(.number.precision(.fractionLength(0)))
        )
        let sharesDelta = localizedFormat(
            "record_stock_shares_delta",
            deltaShares.formatted(.number.precision(.fractionLength(0)))
        )

        return VStack(alignment: .leading, spacing: 2) {
            Text(symbol)
                .font(.headline.weight(.bold))
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text(sharesBase)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.9)
                    .layoutPriority(2)
                Text(sharesDelta)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
                    .layoutPriority(1)
            }
            .allowsTightening(true)
            Text(
                localizedFormat(
                    "record_stock_price_single_format",
                    estimatedPrice.formatted(.number.precision(.fractionLength(2)))
                )
            )
            .font(.title3.weight(.semibold))
            .lineLimit(1)
            .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                TabView(selection: $selectedTab) {
                    NavigationStack {
                        List(records.reversed()) { record in
                            Section {
                                VStack(alignment: .leading, spacing: 6) {
                                    let projection = stockProjectionByYear[record.year]
                                    Button {
                                        guard projection != nil else { return }
                                        if expandedProjectionYears.contains(record.year) {
                                            expandedProjectionYears.remove(record.year)
                                        } else {
                                            expandedProjectionYears.insert(record.year)
                                        }
                                    } label: {
                                        HStack(alignment: .top, spacing: 8) {
                                            Text(
                                                localizedFormat(
                                                    "record_total_format",
                                                    record.totalEnd.formatted(.number.precision(.fractionLength(2))),
                                                    record.times.formatted(.number.precision(.fractionLength(2)))
                                                )
                                            )
                                            .bold()
                                            Spacer(minLength: 0)
                                            if projection != nil {
                                                Image(systemName: expandedProjectionYears.contains(record.year) ? "chevron.up" : "chevron.down")
                                                    .font(.caption.weight(.semibold))
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                        .fontWeight(expandedProjectionYears.contains(record.year) ? .black : .bold)
                                        .padding(.vertical, 2)
                                        .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)

                                    if let projection, expandedProjectionYears.contains(record.year) {
                                        Divider()
                                            .overlay(AppTheme.separatorStrong(for: colorScheme))
                                       
                                        HStack(alignment: .top, spacing: 10) {
                                            stockProjectionColumn(
                                                symbol: "0050",
                                                totalShares: projection.shares0050,
                                                deltaShares: projection.delta0050,
                                                estimatedPrice: projection.price0050
                                            )
                                            stockProjectionColumn(
                                                symbol: "2330",
                                                totalShares: projection.shares2330,
                                                deltaShares: projection.delta2330,
                                                estimatedPrice: projection.price2330
                                            )
                                        }
                                        .padding(.top, 2)
                                        .padding(8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                .fill(AppTheme.surfaceElevatedFill(for: colorScheme))
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                .stroke(AppTheme.surfaceElevatedStroke(for: colorScheme), lineWidth: 0.8)
                                        )
                                    }
                                }
                            } header: {
                                HStack {
                                    Text(localized("year").uppercased())
                                    Text(record.year, format: .number.precision(.fractionLength(0)))
                                }
                            } footer: {
                                Text(
                                    localizedFormat(
                                        "record_footer_format",
                                        record.principalStart.formatted(.number.precision(.fractionLength(2))),
                                        record.interestEarned.formatted(.number.precision(.fractionLength(2))),
                                        record.contribution.formatted(.number.precision(.fractionLength(2)))
                                    )
                                )
                                .font(.footnote)
                            }
                        }
                        .fontDesign(.monospaced)
                        .listStyle(.grouped)
                        .listSectionSpacing(10)
                        .navigationTitle(Text(localized("nav_title")))
                        .navigationSubtitle(Text(localized("nav_subtitle")))
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
                    }
                    .tabItem {
                        Label(localized("tab_compound"), systemImage: "chart.line.uptrend.xyaxis")
                    }
                    .tag(Tab.compound)

                    NavigationStack {
                        StockHistoryView()
                    }
                    .tabItem {
                        Label(localized("stock_tab"), systemImage: "chart.bar")
                    }
                    .tag(Tab.history)
                }
                .environment(\.locale, Locale(identifier: appLanguage))

                if selectedTab == .compound && showInputAlert {
                    AppTheme.overlayScrim(for: colorScheme)
                        .ignoresSafeArea()

                    VStack(spacing: 14) {
                        HStack {
                            Text(localized("input_alert_title"))
                                .font(.headline)
                            Spacer()
                            Button {
                                showInputAlert = false
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title3)
                            }
                            .accessibilityLabel(Text(localized("input_alert_dismiss")))
                        }

                        Toggle(isOn: $paymentsEnabled) {
                            Text(localized("toggle_annual_fixed"))
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text(localized("growth_lookback_title"))
                            Picker("", selection: $growthLookbackYears) {
                                Text("3Y").tag(3)
                                Text("5Y").tag(5)
                                Text("10Y").tag(10)
                            }
                            .pickerStyle(.segmented)
                        }

                        HStack(spacing: 10) {
                            Text(localized("label_principal"))
                                .frame(width: 110, alignment: .leading)
                                .lineLimit(2)
                                .minimumScaleFactor(0.9)

                            TextField(localized("placeholder_principal"), text: $principalText)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .font(.system(size: 17, weight: .bold, design: .monospaced))
                                .focused($focusedField, equals: .principal)
                                .accessibilityIdentifier("compound.input.principal")
                            .frame(maxWidth: .infinity)
                            .frame(height: 36)
                        }
                        .onChange(of: principalText) { _, newValue in
                            let filtered = digitsOnly(newValue)
                            if filtered != newValue {
                                principalText = filtered
                                return
                            }
                            capital = Int(filtered) ?? 0
                        }

                        HStack(spacing: 10) {
                            Text(localized("label_annual_contribution"))
                                .frame(width: 110, alignment: .leading)
                                .lineLimit(2)
                                .minimumScaleFactor(0.7)

                            TextField(localized("placeholder_annual_contribution"), text: $paymentText)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .font(.system(size: 17, weight: .bold, design: .monospaced))
                                .focused($focusedField, equals: .annualContribution)
                                .accessibilityIdentifier("compound.input.annual")
                            .frame(maxWidth: .infinity)
                            .frame(height: 36)
                        }
                        .onChange(of: paymentText) { _, newValue in
                            let filtered = digitsOnly(newValue)
                            if filtered != newValue {
                                paymentText = filtered
                                return
                            }
                            payment = Int(filtered) ?? 0
                        }
                        .opacity(paymentsEnabled ? 1 : 0.45)
                        .disabled(!paymentsEnabled)
                    }
                    .padding(18)
                    .frame(maxWidth: 360)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .padding(.horizontal, 20)
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier("compound.input.panel")
                }

                if selectedTab == .compound {
                    Image(systemName: "keyboard")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)
                        .frame(width: fabSize, height: fabSize)
                        .background(Circle().fill(AppTheme.surfaceElevatedFill(for: colorScheme)))
                        .overlay(
                            Circle().stroke(AppTheme.surfaceElevatedStroke(for: colorScheme), lineWidth: 0.8)
                        )
                        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                        .rotationEffect(.degrees(keyboardRotation))
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(Text("input panel toggle"))
                        .accessibilityIdentifier("compound.fab.keyboard")
                        .accessibilityAddTraits(.isButton)
                        .position(fabPosition)
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    if isKeyboardVisible { return }
                                    if !isDraggingFab {
                                        isDraggingFab = true
                                        fabStartPosition = fabPosition
                                    }
                                    let candidate = CGPoint(
                                        x: fabStartPosition.x + value.translation.width,
                                        y: fabStartPosition.y + value.translation.height
                                    )
                                    fabPosition = clampedFabPosition(candidate, in: proxy)
                                }
                                .onEnded { value in
                                    if isKeyboardVisible {
                                        isDraggingFab = false
                                        let moved = hypot(value.translation.width, value.translation.height)
                                        if moved < 10 {
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                fabPosition = defaultFabPosition(in: proxy)
                                            }
                                            dismissInputPanelAndKeyboard()
                                        }
                                        return
                                    }
                                    isDraggingFab = false
                                    let moved = hypot(value.translation.width, value.translation.height)
                                    if moved < 10 {
                                        withAnimation(.easeInOut(duration: 0.5)) {
                                            keyboardRotation += 360
                                        }
                                        showInputAlert.toggle()
                                        if showInputAlert {
                                            principalText = String(capital)
                                            paymentText = String(payment)
                                            DispatchQueue.main.async {
                                                focusedField = .principal
                                            }
                                        } else {
                                            focusedField = nil
                                        }
                                    }
                                }
                        )
                }
            }
            .fontDesign(.monospaced)
            .onAppear {
                if !fabInitialized {
                    let initial = defaultFabPosition(in: proxy)
                    fabPosition = initial
                    fabInitialized = true
                }
            }
            .onChange(of: proxy.size) { _, _ in
                if fabInitialized {
                    if isKeyboardVisible {
                        fabPosition = keyboardLockedFabPosition(defaultFabPosition(in: proxy), in: proxy)
                    } else {
                        fabPosition = clampedFabPosition(fabPosition, in: proxy)
                    }
                }
            }
            .onChange(of: selectedTab) { _, newValue in
                if newValue != .compound {
                    dismissInputPanelAndKeyboard()
                }
            }
            .onChange(of: keyboardTopY) { _, _ in
                if fabInitialized {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        if isKeyboardVisible {
                            fabPosition = keyboardLockedFabPosition(defaultFabPosition(in: proxy), in: proxy)
                        } else {
                            fabPosition = defaultFabPosition(in: proxy)
                        }
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)) { notification in
                guard
                    let frameValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
                else { return }
                keyboardTopY = frameValue.minY
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                keyboardTopY = .greatestFiniteMagnitude
            }
            .onChange(of: showInputAlert) { _, newValue in
                if !newValue {
                    focusedField = nil
                }
            }
            .onAppear {
                principalText = String(capital)
                paymentText = String(payment)
                growthModel0050 = loadGrowthModel(from: "0050_history", lookbackYears: growthLookbackYears)
                growthModel2330 = loadGrowthModel(from: "2330_history", lookbackYears: growthLookbackYears)
            }
            .onChange(of: growthLookbackYears) { _, newValue in
                growthModel0050 = loadGrowthModel(from: "0050_history", lookbackYears: newValue)
                growthModel2330 = loadGrowthModel(from: "2330_history", lookbackYears: newValue)
            }
        }
    }
}

#Preview {
    ContentView()
}
