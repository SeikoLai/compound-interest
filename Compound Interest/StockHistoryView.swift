import SwiftUI
import UIKit

/// EN: Struct definition for stock trend lite record.
/// ZH: StockTrendLiteRecord 的 struct 定義。
private struct StockTrendLiteRecord: Decodable {
    /// EN: Trading date in YYYY/MM/DD. ZH: 交易日期（YYYY/MM/DD）。
    let date: String
    /// EN: Close price from source. ZH: 來源收盤價。
    let close: Double
    /// EN: Adjusted close if available. ZH: 若有提供則為調整收盤價。
    let adjust_close: Double?
}

/// EN: Struct definition for stock trend lite annual.
/// ZH: StockTrendLiteAnnual 的 struct 定義。
private struct StockTrendLiteAnnual: Decodable {
    /// EN: Summary year. ZH: 摘要年份。
    let year: String
    /// EN: Annual average close. ZH: 年度平均收盤價。
    let average_close: Double
}

/// EN: Struct definition for stock trend lite response.
/// ZH: StockTrendLiteResponse 的 struct 定義。
private struct StockTrendLiteResponse: Decodable {
    /// EN: Daily trend records. ZH: 日資料走勢紀錄。
    let records: [StockTrendLiteRecord]
    /// EN: Optional annual summaries. ZH: 可選年度摘要。
    let annual_summaries: [StockTrendLiteAnnual]?
}

/// EN: Struct definition for picker bottom preference key.
/// ZH: PickerBottomPreferenceKey 的 struct 定義。
private struct PickerBottomPreferenceKey: PreferenceKey {
    /// EN: Default picker bottom position. ZH: Picker 底部預設座標。
    static var defaultValue: CGFloat = 0
    /// EN: Combines preference values by taking the latest emitted value.
    /// ZH: 以最新值合併 PreferenceKey 傳遞的值。
    /// - Parameter value: EN: `value` (inout CGFloat). ZH: 參數 `value`（inout CGFloat）。
    /// - Parameter nextValue: EN: `nextValue` (() -> CGFloat). ZH: 參數 `nextValue`（() -> CGFloat）。
    /// - Returns: EN: `CGFloat)` result. ZH: 回傳 `CGFloat)` 結果。
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

/// EN: Struct definition for year trend bar.
/// ZH: YearTrendBar 的 struct 定義。
private struct YearTrendBar: Identifiable {
    /// EN: Stable identifier for chart drawing. ZH: 圖表繪製用識別值。
    let id: Int
    /// EN: Normalized value used for bar height. ZH: 用於柱高計算的數值。
    let value: Double
    /// EN: 1=up, -1=down, 0=flat. ZH: 1=上漲、-1=下跌、0=平盤。
    let direction: Int
}

/// EN: Struct definition for top bar trend background.
/// ZH: TopBarTrendBackground 的 struct 定義。
private struct TopBarTrendBackground: View {
    /// EN: Yearly bars to render in top background. ZH: 頂部背景要繪製的年度柱狀資料。
    let bars: [YearTrendBar]

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let values = bars.map(\.value)
            let minValue = values.min() ?? 0
            let maxValue = values.max() ?? 1
            let range = max((maxValue - minValue) * 1.1, 0.0001)
            let spacing: CGFloat = 2
            let count = max(bars.count, 1)
            let totalSpacing = spacing * CGFloat(max(count - 1, 0))
            let barWidth = max((size.width - totalSpacing) / CGFloat(count), 1)

            ZStack {
                LinearGradient(
                    colors: [Color.primary.opacity(0.24), Color.primary.opacity(0.12), .clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                HStack(alignment: .bottom, spacing: spacing) {
                    ForEach(bars) { bar in
                        let normalized = (bar.value - minValue) / range
                        let height = max(CGFloat(normalized) * (size.height - 8), 6)
                        let barColor: Color = {
                            if bar.direction > 0 { return .red }
                            if bar.direction < 0 { return .green }
                            return .gray
                        }()

                        RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                            .fill(barColor.opacity(0.95))
                            .frame(width: barWidth, height: height)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .padding(.horizontal, 2)
                .padding(.bottom, 1)

                LinearGradient(
                    colors: [Color.black.opacity(0.28), Color.clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
    }
}

/// EN: Struct definition for stock history view.
/// ZH: StockHistoryView 的 struct 定義。
struct StockHistoryView: View {
    /// EN: Enum definition for stock symbol.
    /// ZH: StockSymbol 的 enum 定義。
    private enum StockSymbol: String, CaseIterable, Identifiable {
        case s0050 = "0050"
        case s2330 = "2330"

        /// EN: Stable ID for segmented picker tags. ZH: segmented picker 用穩定識別值。
        var id: String { rawValue }
    }

    /// EN: Current selected stock symbol. ZH: 目前選取的股票代號。
    @State private var selectedStock: StockSymbol = .s0050
    /// EN: Search text for stock list filtering. ZH: 股票列表搜尋文字。
    @State private var searchText: String = ""
    /// EN: Info popover visibility state. ZH: 資訊提示視窗顯示狀態。
    @State private var showInfoPopover: Bool = false
    /// EN: 0050 top trend bar cache. ZH: 0050 頂部走勢柱狀資料快取。
    @State private var trend0050: [YearTrendBar] = []
    /// EN: 2330 top trend bar cache. ZH: 2330 頂部走勢柱狀資料快取。
    @State private var trend2330: [YearTrendBar] = []
    /// EN: Picker bottom Y in global coordinate space. ZH: Picker 底部全域座標 Y 值。
    @State private var pickerBottomGlobalY: CGFloat = 0
    /// EN: Persisted app language key. ZH: App 語系儲存鍵值。
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

    /// EN: Formats a localized template string with runtime arguments.
    /// ZH: 使用執行期參數格式化在地化模板字串。
    /// - Parameter key: EN: `key` (String). ZH: 參數 `key`（String）。
    /// - Parameter args: EN: `args` (CVarArg...). ZH: 參數 `args`（CVarArg...）。
    /// - Returns: EN: `String` result. ZH: 回傳 `String` 結果。
    private func localizedFormat(_ key: String, _ args: CVarArg...) -> String {
        let format = localized(key)
        return String(format: format, locale: Locale(identifier: appLanguage), arguments: args)
    }

    @ViewBuilder
    /// EN: Builds the stock history information popover content view.
    /// ZH: 建立股票歷史資訊提示視窗內容。
    /// - Returns: EN: `some View` result. ZH: 回傳 `some View` 結果。
    private func infoPopoverContent() -> some View {
        let content = VStack(alignment: .leading, spacing: 8) {
            Text(localized("stock_info_title"))
                .font(.headline)
            Text(localized("stock_info_source"))
                .font(.subheadline)
        }
        .padding(14)
        .frame(maxWidth: 320, alignment: .leading)
        .fontDesign(.monospaced)

        if #available(iOS 16.4, *) {
            content.presentationCompactAdaptation(.popover)
        } else {
            content
        }
    }

    private var selectedTrendBars: [YearTrendBar] {
        let bars: [YearTrendBar]
        switch selectedStock {
        case .s0050:
            bars = trend0050
        case .s2330:
            bars = trend2330
        }
        if bars.isEmpty {
            return fallbackTrendBars()
        }
        return bars
    }

    /// EN: Provides fallback trend bars when source data is unavailable.
    /// ZH: 當資料不可用時提供預設備援趨勢柱。
    /// - Returns: EN: `[YearTrendBar]` result. ZH: 回傳 `[YearTrendBar]` 結果。
    private func fallbackTrendBars() -> [YearTrendBar] {
        var result: [YearTrendBar] = []
        result.reserveCapacity(20)

        for idx in 0..<20 {
            let value = Double((idx % 7) + 1)
            let mod = idx % 3
            let direction: Int
            if mod == 0 {
                direction = 1
            } else if mod == 1 {
                direction = -1
            } else {
                direction = 0
            }

            result.append(
                YearTrendBar(id: idx, value: value, direction: direction)
            )
        }
        return result
    }

    /// EN: Loads annual trend bars from stock history JSON.
    /// ZH: 從股票歷史 JSON 載入年度趨勢柱資料。
    /// - Parameter jsonName: EN: `jsonName` (String). ZH: 參數 `jsonName`（String）。
    /// - Returns: EN: `[YearTrendBar]` result. ZH: 回傳 `[YearTrendBar]` 結果。
    private func loadTrend(from jsonName: String) -> [YearTrendBar] {
        guard let url = Bundle.main.url(forResource: jsonName, withExtension: "json") else { return [] }
        guard
            let data = try? Data(contentsOf: url),
            let response = try? JSONDecoder().decode(StockTrendLiteResponse.self, from: data)
        else { return [] }

        var yearly: [(Int, Double)] = []

        if let annual = response.annual_summaries, !annual.isEmpty {
            yearly = annual.compactMap { row in
                guard let y = Int(row.year), row.average_close > 0 else { return nil }
                return (y, row.average_close)
            }
            .sorted { $0.0 < $1.0 }
        } else {
            let grouped = Dictionary(grouping: response.records) { Int($0.date.prefix(4)) ?? 0 }
            yearly = grouped.compactMap { year, rows in
                guard year > 0, !rows.isEmpty else { return nil }
                let avg = rows.reduce(0.0) { $0 + (($1.adjust_close ?? $1.close) > 0 ? ($1.adjust_close ?? $1.close) : $1.close) } / Double(rows.count)
                return (year, avg)
            }
            .sorted { $0.0 < $1.0 }
        }

        let recent = Array(yearly.suffix(20))
        var lastValue: Double?
        return recent.enumerated().map { idx, item in
            let value = item.1
            let direction: Int
            if let lastValue {
                if value > lastValue { direction = 1 }
                else if value < lastValue { direction = -1 }
                else { direction = 0 }
            } else {
                direction = 0
            }
            lastValue = value
            return YearTrendBar(id: idx, value: value, direction: direction)
        }
    }

    var body: some View {
        ZStack(alignment: .top) {
            GeometryReader { geo in
                let topPanelHeight = geo.safeAreaInsets.top + 44
                let fallbackLowerHeight: CGFloat = 188
/// EN: Bridge height extends background to segmented control lower edge.
/// ZH: 透過補償高度讓背景延伸到 segmented control 下緣。
                let segmentedBridgeHeight: CGFloat = 40
/// EN: Convert picker bottom from global space back to local view space.
/// ZH: 將 picker 底部座標由全域座標轉回目前容器的本地座標。
                let lowerMaskStart = pickerBottomGlobalY > 1
                    ? max(0, pickerBottomGlobalY - geo.frame(in: .global).minY + segmentedBridgeHeight)
                    : fallbackLowerHeight
                let revealHeight = topPanelHeight + lowerMaskStart

                ZStack(alignment: .top) {
                    TopBarTrendBackground(bars: selectedTrendBars)
                        .frame(height: revealHeight)
                        .offset(y: -topPanelHeight)
                        .ignoresSafeArea(edges: .top)

                    Rectangle()
                        .fill(Color(uiColor: .systemBackground))
                        .frame(height: max(geo.size.height - lowerMaskStart, 0))
                        .offset(y: lowerMaskStart)
                }
                .allowsHitTesting(false)
                .opacity(0.05)
            }

            VStack(spacing: 5) {
                Picker("Stock", selection: $selectedStock) {
                    Text(localized("stock_segment_0050")).tag(StockSymbol.s0050)
                    Text(localized("stock_segment_2330")).tag(StockSymbol.s2330)
                }
                .pickerStyle(.segmented)
                .accessibilityIdentifier("stock.segment")
                .padding([.horizontal, .top])
                .background(
                    GeometryReader { geo in
                        Color.clear
                            .preference(
                                key: PickerBottomPreferenceKey.self,
                                value: geo.frame(in: .global).maxY
                            )
                    }
                )

                ZStack {
                    History0050View(searchText: searchText, showNavigationUI: false)
                        .opacity(selectedStock == .s0050 ? 1 : 0)
                        .allowsHitTesting(selectedStock == .s0050)
                        .accessibilityHidden(selectedStock != .s0050)

                    History2330View(searchText: searchText, showNavigationUI: false)
                        .opacity(selectedStock == .s2330 ? 1 : 0)
                        .allowsHitTesting(selectedStock == .s2330)
                        .accessibilityHidden(selectedStock != .s2330)
                }
            }
        }
        .fontDesign(.monospaced)
        .onPreferenceChange(PickerBottomPreferenceKey.self) { value in
            pickerBottomGlobalY = value
        }
        .navigationTitle(localized("stock_title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .automatic), prompt: localized("stock_search_placeholder"))
        .searchToolbarBehavior(.automatic)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showInfoPopover.toggle()
                } label: {
                    Image(systemName: "info.circle")
                }
                .accessibilityLabel(Text(localized("stock_info_accessibility")))
                .popover(isPresented: $showInfoPopover, arrowEdge: .top) {
                    infoPopoverContent()
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    appLanguage = (appLanguage == "en") ? "zh-Hant" : "en"
                } label: {
                    Image(systemName: "globe")
                }
                .accessibilityLabel(Text(localized("globe_accessibility")))
            }
        }
        .onAppear {
            if trend0050.isEmpty { trend0050 = loadTrend(from: "0050_history") }
            if trend2330.isEmpty { trend2330 = loadTrend(from: "2330_history") }
        }
    }
}

#Preview {
    NavigationStack {
        StockHistoryView()
    }
}
