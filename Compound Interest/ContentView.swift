//
//  ContentView.swift
//  Compound Interest
//
//  Created by Sam Lai on 2026/2/2.
//

import SwiftUI
import UIKit

private struct StockHistoryLiteRecord: Decodable {
    let date: String
    let close: Double
    let adjust_close: Double?
}

private struct StockAnnualSummaryLite: Decodable {
    let year: String
    let average_close: Double
}

private struct StockHistoryLiteResponse: Decodable {
    let records: [StockHistoryLiteRecord]
    let annual_summaries: [StockAnnualSummaryLite]?
}

private struct StockGrowthModel {
    let latestPrice: Double
    let annualGrowthRate: Double
}

struct Record: Identifiable {
    let id: UUID = UUID()
    var year: Int
    var payment: Double
    var principalStart: Double
    var interestEarned: Double
    var contribution: Double
    var totalEnd: Double
    var investedToDate: Double
    var times: Double { investedToDate > 0 ? (totalEnd / investedToDate) : 0 }
}

struct ContentView: View {
    private enum Tab: Hashable {
        case compound
        case history
    }

    private enum InputField: Hashable {
        case principal
        case annualContribution
    }

    @State var capital: Int = 60000
    @State var paymentsEnabled: Bool = true
    @State var payment: Int = 120000
    @State var year: Int = 20
    @State var interest = 0.1
    @AppStorage("appLanguage") private var appLanguage: String = "en"
    @State private var showInputAlert: Bool = false
    @State private var keyboardRotation: Double = 0
    @State private var fabPosition: CGPoint = .zero
    @State private var fabStartPosition: CGPoint = .zero
    @State private var fabInitialized: Bool = false
    @State private var isDraggingFab: Bool = false
    @State private var selectedTab: Tab = .compound
    @State private var keyboardTopY: CGFloat = .greatestFiniteMagnitude
    @State private var principalText: String = "0"
    @State private var paymentText: String = "120000"
    @FocusState private var focusedField: InputField?
    @State private var growthModel0050: StockGrowthModel?
    @State private var growthModel2330: StockGrowthModel?
    @State private var growthLookbackYears: Int = 5
    @State private var expandedProjectionYears: Set<Int> = []
    @Environment(\.colorScheme) private var colorScheme

    private let fabSize: CGFloat = 56
    private let fabMargin: CGFloat = 12
    private let tabBarRowCenterFromSafeBottom: CGFloat = 54
    private let keyboardGap: CGFloat = 10

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

    private func digitsOnly(_ value: String) -> String {
        value.filter(\.isNumber)
    }

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
        keyboardTopY < UIScreen.main.bounds.height
    }

    private func defaultFabPosition(in proxy: GeometryProxy) -> CGPoint {
        let x = proxy.size.width - (fabSize / 2) - fabMargin
        let y = proxy.size.height - proxy.safeAreaInsets.bottom - tabBarRowCenterFromSafeBottom
        return clampedFabPosition(CGPoint(x: x, y: y), in: proxy)
    }

    private func dismissInputPanelAndKeyboard() {
        showInputAlert = false
        focusedField = nil
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    private var records: [Record] {
        var list = [Record]()
        let totalYears = max(0, year)
        let paymentAmount = paymentsEnabled ? Double(payment) : 0
        var principal = Double(capital)

        for yearIndex in 0..<totalYears {
            let principalStart = principal

            // Annuity Due: payment at beginning of each year, then annual compounding once.
            principal += paymentAmount
            let interestEarned = principal * interest
            principal += interestEarned

            let totalEnd = principal
            let contribution = paymentAmount
            let investedToDate = Double(capital) + paymentAmount * Double(yearIndex + 1)
            list
                .append(
                    Record(
                        year: yearIndex + 1,
                        payment: paymentAmount,
                        principalStart: principalStart,
                        interestEarned: interestEarned,
                        contribution: contribution,
                        totalEnd: totalEnd,
                        investedToDate: investedToDate
                    )
                )
        }
        return list
    }

    private var stockProjectionByYear: [Int: (price0050: Double, price2330: Double, shares0050: Double, shares2330: Double, delta0050: Double, delta2330: Double)] {
        let totalYears = max(0, year)
        guard
            totalYears > 0,
            let model0050 = growthModel0050,
            let model2330 = growthModel2330
        else { return [:] }

        var result: [Int: (price0050: Double, price2330: Double, shares0050: Double, shares2330: Double, delta0050: Double, delta2330: Double)] = [:]
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
            result[index] = (price0050, price2330, shares0050, shares2330, yearBought0050, yearBought2330)
        }
        return result
    }

    private func effectiveGrowthRate(base: Double, projectionYear: Int) -> Double {
        if projectionYear <= 10 {
            return base
        }
        let terminalGrowth = 0.04
        let span = 10.0
        let progress = min(max((Double(projectionYear) - 10.0) / span, 0), 1)
        return base + (terminalGrowth - base) * progress
    }

    private func loadGrowthModel(from jsonName: String, lookbackYears: Int) -> StockGrowthModel? {
        guard let url = Bundle.main.url(forResource: jsonName, withExtension: "json") else { return nil }
        guard
            let data = try? Data(contentsOf: url),
            let response = try? JSONDecoder().decode(StockHistoryLiteResponse.self, from: data)
        else { return nil }

        // Use adjusted close first to avoid distortions from splits/corporate actions.
        let normalized: [StockHistoryLiteRecord] = response.records.map { row in
            let adjusted = (row.adjust_close ?? row.close) > 0 ? (row.adjust_close ?? row.close) : row.close
            return StockHistoryLiteRecord(date: row.date, close: adjusted, adjust_close: row.adjust_close)
        }

        let sorted = normalized.sorted { $0.date < $1.date }
        guard let latest = sorted.last, latest.close > 0 else { return nil }

        let latestYear = Int(latest.date.prefix(4)) ?? 0
        let targetYear = latestYear - max(1, lookbackYears)

        var rawGrowth: Double?
        if let annual = response.annual_summaries {
            let annualMap = Dictionary(uniqueKeysWithValues: annual.compactMap { item -> (Int, Double)? in
                guard let y = Int(item.year), item.average_close > 0 else { return nil }
                return (y, item.average_close)
            })
            if
                let latestAnnualYear = annualMap.keys.max(),
                let latestAnnualPrice = annualMap[latestAnnualYear], latestAnnualPrice > 0
            {
                let annualTarget = latestAnnualYear - max(1, lookbackYears)
                let baseAnnualYear = annualMap.keys.filter { $0 >= annualTarget }.min() ?? annualMap.keys.min()
                if let baseAnnualYear, let baseAnnualPrice = annualMap[baseAnnualYear], baseAnnualPrice > 0 {
                    let yearsSpan = max(1, latestAnnualYear - baseAnnualYear)
                    rawGrowth = pow(latestAnnualPrice / baseAnnualPrice, 1.0 / Double(yearsSpan)) - 1.0
                }
            }
        }

        if rawGrowth == nil {
            let baseRecord = sorted.first { (Int($0.date.prefix(4)) ?? 0) >= targetYear } ?? sorted.first
            guard let baseRecord, baseRecord.close > 0 else { return nil }
            let baseYear = Int(baseRecord.date.prefix(4)) ?? targetYear
            let yearsSpan = max(1, latestYear - baseYear)
            rawGrowth = pow(latest.close / baseRecord.close, 1.0 / Double(yearsSpan)) - 1.0
        }

        let growth = min(max(rawGrowth ?? 0, -0.05), 0.12)

        return StockGrowthModel(latestPrice: latest.close, annualGrowthRate: growth)
    }

    private func stockProjectionColumn(symbol: String, totalShares: Double, deltaShares: Double, estimatedPrice: Double) -> some View {
        let sharesLine =
            Text(
                localizedFormat(
                    "record_stock_shares_single_base",
                    totalShares.formatted(.number.precision(.fractionLength(0)))
                )
            ) +
            Text(
                localizedFormat(
                    "record_stock_shares_delta",
                    deltaShares.formatted(.number.precision(.fractionLength(0)))
                )
            )
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)

        return VStack(alignment: .leading, spacing: 2) {
            Text(symbol)
                .font(.headline.weight(.bold))
            sharesLine
                .font(.title3.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
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
