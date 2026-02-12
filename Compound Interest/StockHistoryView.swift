//
//  StockHistoryView.swift
//  Compound Interest
//

import SwiftUI

struct StockHistoryView: View {
    private enum StockSymbol: String, CaseIterable, Identifiable {
        case s0050 = "0050"
        case s2330 = "2330"

        var id: String { rawValue }
    }

    @State private var selectedStock: StockSymbol = .s0050
    @State private var searchText: String = ""
    @State private var showInfoPopover: Bool = false
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

    var body: some View {
        VStack(spacing: 5) {
            Picker("Stock", selection: $selectedStock) {
                Text(localized("stock_segment_0050")).tag(StockSymbol.s0050)
                Text(localized("stock_segment_2330")).tag(StockSymbol.s2330)
            }
            .pickerStyle(.segmented)
            .padding([.horizontal, .top])

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
        .fontDesign(.monospaced)
        .navigationTitle(localized("stock_title"))
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
    }
}

#Preview {
    NavigationStack {
        StockHistoryView()
    }
}
