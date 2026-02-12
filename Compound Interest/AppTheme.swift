import SwiftUI

/// EN: Enum definition for app theme.
/// ZH: AppTheme 的 enum 定義。
enum AppTheme {
    /// EN: Returns overlay scrim color tuned for current color scheme.
    /// ZH: 回傳符合目前深淺色模式的遮罩顏色。
    /// - Parameter scheme: EN: `scheme` (ColorScheme). ZH: 參數 `scheme`（ColorScheme）。
    /// - Returns: EN: `Color` result. ZH: 回傳 `Color` 結果。
    static func overlayScrim(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.black.opacity(0.5) : Color.black.opacity(0.25)
    }

    /// EN: Returns strong separator color for section boundaries.
    /// ZH: 回傳用於區塊邊界的強分隔線顏色。
    /// - Parameter scheme: EN: `scheme` (ColorScheme). ZH: 參數 `scheme`（ColorScheme）。
    /// - Returns: EN: `Color` result. ZH: 回傳 `Color` 結果。
    static func separatorStrong(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.35) : Color.black.opacity(0.18)
    }

    /// EN: Returns elevated surface fill color.
    /// ZH: 回傳凸起層級表面的填色。
    /// - Parameter scheme: EN: `scheme` (ColorScheme). ZH: 參數 `scheme`（ColorScheme）。
    /// - Returns: EN: `Color` result. ZH: 回傳 `Color` 結果。
    static func surfaceElevatedFill(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.14) : Color.black.opacity(0.05)
    }

    /// EN: Returns elevated surface stroke color.
    /// ZH: 回傳凸起層級表面的邊框色。
    /// - Parameter scheme: EN: `scheme` (ColorScheme). ZH: 參數 `scheme`（ColorScheme）。
    /// - Returns: EN: `Color` result. ZH: 回傳 `Color` 結果。
    static func surfaceElevatedStroke(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.28) : Color.black.opacity(0.12)
    }

    /// EN: Returns level-1 surface fill color.
    /// ZH: 回傳第 1 層表面填色。
    /// - Parameter scheme: EN: `scheme` (ColorScheme). ZH: 參數 `scheme`（ColorScheme）。
    /// - Returns: EN: `Color` result. ZH: 回傳 `Color` 結果。
    static func surfaceLevel1Fill(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.blue.opacity(0.28) : Color.blue.opacity(0.18)
    }

    /// EN: Returns level-1 surface stroke color.
    /// ZH: 回傳第 1 層表面邊框色。
    /// - Parameter scheme: EN: `scheme` (ColorScheme). ZH: 參數 `scheme`（ColorScheme）。
    /// - Returns: EN: `Color` result. ZH: 回傳 `Color` 結果。
    static func surfaceLevel1Stroke(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.blue.opacity(0.55) : Color.blue.opacity(0.36)
    }

    /// EN: Returns level-2 surface fill color.
    /// ZH: 回傳第 2 層表面填色。
    /// - Parameter scheme: EN: `scheme` (ColorScheme). ZH: 參數 `scheme`（ColorScheme）。
    /// - Returns: EN: `Color` result. ZH: 回傳 `Color` 結果。
    static func surfaceLevel2Fill(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.orange.opacity(0.22) : Color.orange.opacity(0.15)
    }

    /// EN: Returns level-2 surface stroke color.
    /// ZH: 回傳第 2 層表面邊框色。
    /// - Parameter scheme: EN: `scheme` (ColorScheme). ZH: 參數 `scheme`（ColorScheme）。
    /// - Returns: EN: `Color` result. ZH: 回傳 `Color` 結果。
    static func surfaceLevel2Stroke(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.orange.opacity(0.45) : Color.orange.opacity(0.30)
    }

    /// EN: Returns level-3 surface fill color.
    /// ZH: 回傳第 3 層表面填色。
    /// - Parameter scheme: EN: `scheme` (ColorScheme). ZH: 參數 `scheme`（ColorScheme）。
    /// - Returns: EN: `Color` result. ZH: 回傳 `Color` 結果。
    static func surfaceLevel3Fill(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.06) : Color.gray.opacity(0.06)
    }

    /// EN: Returns level-3 surface stroke color.
    /// ZH: 回傳第 3 層表面邊框色。
    /// - Parameter scheme: EN: `scheme` (ColorScheme). ZH: 參數 `scheme`（ColorScheme）。
    /// - Returns: EN: `Color` result. ZH: 回傳 `Color` 結果。
    static func surfaceLevel3Stroke(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.14) : Color.gray.opacity(0.10)
    }

    /// EN: Returns semantic error color for emphasis states.
    /// ZH: 回傳語意化錯誤色，用於強調狀態。
    /// - Parameter scheme: EN: `scheme` (ColorScheme). ZH: 參數 `scheme`（ColorScheme）。
    /// - Returns: EN: `Color` result. ZH: 回傳 `Color` 結果。
    static func semanticError(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.red.opacity(0.9) : Color.red
    }
}
