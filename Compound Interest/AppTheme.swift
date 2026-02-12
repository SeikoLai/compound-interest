//
//  AppTheme.swift
//  Compound Interest
//

import SwiftUI

enum AppTheme {
    static func overlayScrim(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.black.opacity(0.5) : Color.black.opacity(0.25)
    }

    static func separatorStrong(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.35) : Color.black.opacity(0.18)
    }

    static func surfaceElevatedFill(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.14) : Color.black.opacity(0.05)
    }

    static func surfaceElevatedStroke(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.28) : Color.black.opacity(0.12)
    }

    static func surfaceLevel1Fill(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.blue.opacity(0.28) : Color.blue.opacity(0.18)
    }

    static func surfaceLevel1Stroke(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.blue.opacity(0.55) : Color.blue.opacity(0.36)
    }

    static func surfaceLevel2Fill(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.orange.opacity(0.22) : Color.orange.opacity(0.15)
    }

    static func surfaceLevel2Stroke(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.orange.opacity(0.45) : Color.orange.opacity(0.30)
    }

    static func surfaceLevel3Fill(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.06) : Color.gray.opacity(0.06)
    }

    static func surfaceLevel3Stroke(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.14) : Color.gray.opacity(0.10)
    }

    static func semanticError(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.red.opacity(0.9) : Color.red
    }
}
