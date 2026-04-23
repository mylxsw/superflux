import AppKit
import SwiftUI

struct LauncherThemePalette {
    let accentColor: Color
    let panelBackgroundTop: Color
    let panelBackgroundBottom: Color
    let panelTintTop: Color
    let panelTintBottom: Color
    let panelStrokeColor: Color
    let dividerColor: Color
    let searchTextColor: Color
    let searchPlaceholderColor: Color
    let secondaryTextColor: Color
    let tertiaryTextColor: Color
    let searchFieldTintTop: Color
    let searchFieldTintBottom: Color
    let searchFieldStrokeColor: Color
    let selectionFillColor: Color
    let selectionStrokeColor: Color
    let rowHoverFillColor: Color
    let subtitleAccentColor: Color
    let selectedChevronColor: Color
    let capsuleFillColor: Color
    let capsuleStrokeColor: Color
    let footerTintTop: Color
    let footerTintBottom: Color
    let footerStrokeColor: Color
    let statusIndicatorColor: Color
    let shadowColor: Color
    let previewGlowColor: Color
}

enum LauncherThemePreset: String, CaseIterable, Identifiable {
    case ocean
    case sunrise

    var id: Self { self }

    var title: String {
        switch self {
        case .ocean:
            SettingsStrings.themePresetOceanTitle
        case .sunrise:
            SettingsStrings.themePresetSunriseTitle
        }
    }

    var summary: String {
        switch self {
        case .ocean:
            SettingsStrings.themePresetOceanSummary
        case .sunrise:
            SettingsStrings.themePresetSunriseSummary
        }
    }

    var theme: LauncherThemePalette {
        switch self {
        case .ocean:
            LauncherThemePalette(
                accentColor: .dynamic(light: (0.13, 0.40, 0.92, 1), dark: (0.54, 0.72, 1, 1)),
                panelBackgroundTop: .dynamic(light: (0.97, 0.98, 1, 0.94), dark: (0.21, 0.24, 0.22, 0.97)),
                panelBackgroundBottom: .dynamic(light: (0.93, 0.96, 1, 0.90), dark: (0.17, 0.20, 0.19, 0.97)),
                panelTintTop: .dynamic(light: (0.73, 0.84, 1, 0.18), dark: (0.55, 0.60, 0.44, 0.12)),
                panelTintBottom: .dynamic(light: (0.89, 0.95, 1, 0.08), dark: (0.23, 0.29, 0.25, 0.08)),
                panelStrokeColor: .dynamic(light: (0.26, 0.38, 0.55, 0.10), dark: (1, 1, 1, 0.07)),
                dividerColor: .dynamic(light: (0.12, 0.16, 0.24, 0.08), dark: (1, 1, 1, 0.05)),
                searchTextColor: .dynamic(light: (0.11, 0.13, 0.18, 0.96), dark: (0.95, 0.96, 0.95, 0.96)),
                searchPlaceholderColor: .dynamic(light: (0.28, 0.32, 0.40, 0.58), dark: (0.86, 0.88, 0.86, 0.52)),
                secondaryTextColor: .dynamic(light: (0.17, 0.20, 0.26, 0.80), dark: (0.94, 0.95, 0.94, 0.88)),
                tertiaryTextColor: .dynamic(light: (0.23, 0.28, 0.35, 0.52), dark: (0.83, 0.85, 0.84, 0.52)),
                searchFieldTintTop: .dynamic(light: (1, 1, 1, 0.24), dark: (0.25, 0.28, 0.26, 0.16)),
                searchFieldTintBottom: .dynamic(light: (0.89, 0.95, 1, 0.10), dark: (0.18, 0.21, 0.20, 0.08)),
                searchFieldStrokeColor: .dynamic(light: (0.18, 0.28, 0.44, 0.10), dark: (1, 1, 1, 0.06)),
                selectionFillColor: .dynamic(light: (0.11, 0.14, 0.18, 0.08), dark: (1, 1, 1, 0.12)),
                selectionStrokeColor: .dynamic(light: (0.16, 0.24, 0.38, 0.08), dark: (1, 1, 1, 0.07)),
                rowHoverFillColor: .dynamic(light: (0.08, 0.10, 0.14, 0.04), dark: (1, 1, 1, 0.03)),
                subtitleAccentColor: .dynamic(light: (0.23, 0.42, 0.84, 0.88), dark: (0.64, 0.76, 1, 0.96)),
                selectedChevronColor: .dynamic(light: (0.22, 0.26, 0.33, 0.86), dark: (0.97, 0.98, 0.97, 0.92)),
                capsuleFillColor: .dynamic(light: (0.13, 0.17, 0.24, 0.08), dark: (0.26, 0.29, 0.34, 0.62)),
                capsuleStrokeColor: .dynamic(light: (0.16, 0.24, 0.36, 0.06), dark: (1, 1, 1, 0.04)),
                footerTintTop: .dynamic(light: (0.11, 0.14, 0.18, 0.03), dark: (0.10, 0.11, 0.12, 0.76)),
                footerTintBottom: .dynamic(light: (0.11, 0.14, 0.18, 0.08), dark: (0.08, 0.09, 0.10, 0.88)),
                footerStrokeColor: .dynamic(light: (0.10, 0.13, 0.20, 0.08), dark: (1, 1, 1, 0.04)),
                statusIndicatorColor: .dynamic(light: (0.16, 0.78, 0.37, 1), dark: (0.18, 0.84, 0.40, 1)),
                shadowColor: .dynamic(light: (0.07, 0.11, 0.17, 0.12), dark: (0, 0, 0, 0.28)),
                previewGlowColor: .dynamic(light: (0.40, 0.63, 1, 0.32), dark: (0.27, 0.57, 0.94, 0.50))
            )
        case .sunrise:
            LauncherThemePalette(
                accentColor: .dynamic(light: (0.83, 0.36, 0.22, 1), dark: (1, 0.68, 0.38, 1)),
                panelBackgroundTop: .dynamic(light: (1, 0.98, 0.95, 0.95), dark: (0.18, 0.14, 0.12, 0.95)),
                panelBackgroundBottom: .dynamic(light: (1, 0.95, 0.90, 0.92), dark: (0.13, 0.10, 0.09, 0.95)),
                panelTintTop: .dynamic(light: (1, 0.86, 0.72, 0.20), dark: (0.46, 0.30, 0.16, 0.20)),
                panelTintBottom: .dynamic(light: (1, 0.95, 0.86, 0.10), dark: (0.26, 0.13, 0.10, 0.14)),
                panelStrokeColor: .dynamic(light: (0.34, 0.17, 0.10, 0.10), dark: (1, 1, 1, 0.08)),
                dividerColor: .dynamic(light: (0.22, 0.12, 0.09, 0.08), dark: (1, 1, 1, 0.06)),
                searchTextColor: .dynamic(light: (0.15, 0.10, 0.08, 0.96), dark: (0.96, 0.94, 0.92, 0.96)),
                searchPlaceholderColor: .dynamic(light: (0.32, 0.20, 0.16, 0.56), dark: (0.92, 0.87, 0.82, 0.46)),
                secondaryTextColor: .dynamic(light: (0.19, 0.13, 0.11, 0.82), dark: (0.95, 0.91, 0.88, 0.84)),
                tertiaryTextColor: .dynamic(light: (0.28, 0.17, 0.12, 0.52), dark: (0.92, 0.87, 0.82, 0.48)),
                searchFieldTintTop: .dynamic(light: (1, 1, 1, 0.26), dark: (0.28, 0.18, 0.14, 0.26)),
                searchFieldTintBottom: .dynamic(light: (1, 0.95, 0.88, 0.12), dark: (0.20, 0.12, 0.10, 0.16)),
                searchFieldStrokeColor: .dynamic(light: (0.34, 0.19, 0.12, 0.10), dark: (1, 1, 1, 0.08)),
                selectionFillColor: .dynamic(light: (0.14, 0.10, 0.09, 0.08), dark: (1, 1, 1, 0.14)),
                selectionStrokeColor: .dynamic(light: (0.24, 0.14, 0.09, 0.08), dark: (1, 1, 1, 0.08)),
                rowHoverFillColor: .dynamic(light: (0.14, 0.09, 0.07, 0.04), dark: (1, 1, 1, 0.04)),
                subtitleAccentColor: .dynamic(light: (0.66, 0.33, 0.20, 0.90), dark: (1, 0.72, 0.42, 0.94)),
                selectedChevronColor: .dynamic(light: (0.24, 0.16, 0.12, 0.86), dark: (0.97, 0.94, 0.92, 0.92)),
                capsuleFillColor: .dynamic(light: (0.28, 0.17, 0.14, 0.08), dark: (0.22, 0.16, 0.14, 0.88)),
                capsuleStrokeColor: .dynamic(light: (0.26, 0.14, 0.11, 0.06), dark: (1, 1, 1, 0.05)),
                footerTintTop: .dynamic(light: (0.14, 0.09, 0.08, 0.03), dark: (0.09, 0.06, 0.05, 0.72)),
                footerTintBottom: .dynamic(light: (0.14, 0.09, 0.08, 0.08), dark: (0.07, 0.05, 0.04, 0.84)),
                footerStrokeColor: .dynamic(light: (0.20, 0.10, 0.08, 0.08), dark: (1, 1, 1, 0.05)),
                statusIndicatorColor: .dynamic(light: (0.16, 0.78, 0.37, 1), dark: (0.18, 0.84, 0.40, 1)),
                shadowColor: .dynamic(light: (0.17, 0.09, 0.05, 0.12), dark: (0, 0, 0, 0.28)),
                previewGlowColor: .dynamic(light: (0.96, 0.60, 0.36, 0.34), dark: (0.92, 0.48, 0.24, 0.52))
            )
        }
    }
}

private extension Color {
    static func dynamic(
        light: (Double, Double, Double, Double),
        dark: (Double, Double, Double, Double)
    ) -> Color {
        Color(
            nsColor: NSColor(name: nil) { appearance in
                let palette = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? dark : light
                return NSColor(
                    calibratedRed: palette.0,
                    green: palette.1,
                    blue: palette.2,
                    alpha: palette.3
                )
            }
        )
    }
}
