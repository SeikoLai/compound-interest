//
//  StockHistoryView.swift
//  Compound Interest
//

import SwiftUI
import UIKit

private struct StockTrendLiteRecord: Decodable {
    let date: String
    let close: Double
    let adjust_close: Double?
}

private struct StockTrendLiteAnnual: Decodable {
    let year: String
    let average_close: Double
}

private struct StockTrendLiteResponse: Decodable {
    let records: [StockTrendLiteRecord]
    let annual_summaries: [StockTrendLiteAnnual]?
}

private struct PickerBottomPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

private struct YearTrendBar: Identifiable {
    let id: Int
    let value: Double
    // 1 = up (red), -1 = down (green), 0 = flat (gray)
    let direction: Int
}

private struct TopBarTrendBackground: View {
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

struct StockHistoryView: View {
    private enum StockSymbol: String, CaseIterable, Identifiable {
        case s0050 = "0050"
        case s2330 = "2330"

        var id: String { rawValue }
    }

    @State private var selectedStock: StockSymbol = .s0050
    @State private var searchText: String = ""
    @State private var showInfoPopover: Bool = false
    @State private var trend0050: [YearTrendBar] = []
    @State private var trend2330: [YearTrendBar] = []
    @State private var pickerBottomGlobalY: CGFloat = 0
    @AppStorage("appLanguage") private var appLanguage: String = "en"

    private func localized(_ key: String) -> String {
        guard
            let path = Bundle.main.path(forResource: appLanguage, ofType: "lproj"),
            let bundle = Bundle(path: path)
        else {
            return NSLocalizedString(key, comment: "")
        }
        return NSLocalizedString(key, bundle: bundle, comment: "")
    }

    private func localizedFormat(_ key: String, _ args: CVarArg...) -> String {
        let format = localized(key)
        return String(format: format, locale: Locale(identifier: appLanguage), arguments: args)
    }

    @ViewBuilder
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
                // Extend through segmented control height so chart reaches picker bottom edge.
                let segmentedBridgeHeight: CGFloat = 40
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
