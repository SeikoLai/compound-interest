//
//  History0050View.swift
//  Compound Interest
//
//  Created by Sam Lai on 2026/2/10.
//

import SwiftUI

private struct DailyCandlestickView: View {
    let open: Double
    let high: Double
    let low: Double
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

struct StockHistoryRecord: Identifiable, Decodable {
    let id = UUID()
    let date: String
    let open: Double
    let high: Double
    let low: Double
    let close: Double
    let adjust_close: Double
    let volume: Double

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

struct StockHistoryResponse: Decodable {
    let records: [StockHistoryRecord]
    let annual_summaries: [StockAnnualSummary]?
    let monthly_summaries: [StockMonthlySummary]?
}

struct StockAnnualSummary: Decodable {
    let year: String
    let volume: Double
    let amount: Double
    let trades: Double
    let high: Double
    let high_date: String
    let low: Double
    let low_date: String
    let average_close: Double
}

struct StockMonthlySummary: Decodable {
    let year: String
    let month: String
    let high: Double
    let low: Double
    let weighted_average: Double
    let trades: Double
    let amount: Double
    let volume: Double
    let turnover_rate: Double
}

struct StockHistoryMonthGroup: Identifiable {
    let id: String
    let month: String
    let records: [StockHistoryRecord]
}

struct StockHistoryYearGroup: Identifiable {
    let id: String
    let year: String
    let months: [StockHistoryMonthGroup]
    var recordsCount: Int {
        return months.reduce(into: 0) { $0 += $1.records.count }
    }
}

struct StockHistoryListView: View {
    let jsonFileName: String
    let titleKey: String
    var searchText: String = ""
    var showNavigationUI: Bool = true

    @State private var records: [StockHistoryRecord] = []
    @State private var annualSummariesByYear: [String: StockAnnualSummary] = [:]
    @State private var monthlySummariesByYearMonth: [String: StockMonthlySummary] = [:]
    @State private var loadError: String?
    @State private var expandedYears: Set<String> = []
    @State private var expandedMonths: Set<String> = []
    @AppStorage("appLanguage") private var appLanguage: String = "en"
    @Environment(\.colorScheme) private var colorScheme
    
    private struct AnnualSummaryDisplay {
        let open: Double
        let close: Double
        let high: Double
        let low: Double
        let averageClose: Double
        let highDate: String
        let lowDate: String
        let volume: Double
    }

    private struct MonthlySummaryDisplay {
        let open: Double
        let close: Double
        let high: Double
        let low: Double
        let weightedAverage: Double
        let volume: Double
        let turnoverText: String?
    }

    private let annualCandleSize = CGSize(width: 26, height: 54)   // 100%
    private let monthlyCandleSize = CGSize(width: 20.8, height: 43.2) // 80%
    private let dailyCandleSize = CGSize(width: 18.2, height: 37.8) // 70%
    private let yearIndent: CGFloat = 2
    private let monthIndent: CGFloat = 10
    private let dayIndent: CGFloat = 18

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

    private func monthKey(year: String, month: String) -> String {
        "\(year)-\(month)"
    }

    private func yearAnchorId(_ year: String) -> String {
        "year-anchor-\(year)"
    }

    private func annualSummary(for year: String) -> StockAnnualSummary? {
        annualSummariesByYear[year]
    }

    private func monthlySummary(year: String, month: String) -> StockMonthlySummary? {
        monthlySummariesByYearMonth[monthKey(year: year, month: month)]
    }

    private func monthDayText(from date: String) -> String {
        let parts = date.split(separator: "/")
        guard parts.count == 3 else { return "--/--" }
        let month = Int(parts[1]) ?? 0
        let day = Int(parts[2]) ?? 0
        return "\(month)/\(String(format: "%02d", day))"
    }

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
                                        (
                                            Text(
                                                localizedFormat(
                                                    "history_annual_high_price",
                                                    summary.high.formatted(.number.precision(.fractionLength(2)))
                                                )
                                            ) +
                                            Text(" ") +
                                            Text(localizedFormat("history_date_suffix", summary.highDate))
                                                .font(.subheadline.weight(.semibold))
                                                .foregroundStyle(.secondary)
                                        )
                                        .frame(maxWidth: .infinity, alignment: .leading)

                                        (
                                            Text(
                                                localizedFormat(
                                                    "history_annual_low_price",
                                                    summary.low.formatted(.number.precision(.fractionLength(2)))
                                                )
                                            ) +
                                            Text(" ") +
                                            Text(localizedFormat("history_date_suffix", summary.lowDate))
                                                .font(.subheadline.weight(.semibold))
                                                .foregroundStyle(.secondary)
                                        )
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
                    ForEach(groupedByYear.map { $0.year }, id: \.self) { year in
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

private struct StockHistoryNavigationModifier: ViewModifier {
    let showNavigationUI: Bool
    let titleKey: String
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
