import AppKit
import SwiftUI

struct LauncherThemePalette {
    let accentColor: Color
    let panelTintTop: Color
    let panelTintBottom: Color
    let panelStrokeColor: Color
    let searchFieldTintTop: Color
    let searchFieldTintBottom: Color
    let searchFieldStrokeColor: Color
    let selectionFillColor: Color
    let selectionStrokeColor: Color
    let capsuleFillColor: Color
    let capsuleStrokeColor: Color
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
                accentColor: .dynamic(light: (0.13, 0.40, 0.92, 1), dark: (0.42, 0.79, 1, 1)),
                panelTintTop: .dynamic(light: (0.73, 0.84, 1, 0.40), dark: (0.16, 0.29, 0.45, 0.48)),
                panelTintBottom: .dynamic(light: (0.89, 0.95, 1, 0.32), dark: (0.08, 0.17, 0.28, 0.44)),
                panelStrokeColor: .dynamic(light: (0.32, 0.56, 0.95, 0.24), dark: (0.50, 0.78, 1, 0.28)),
                searchFieldTintTop: .dynamic(light: (1, 1, 1, 0.30), dark: (0.24, 0.34, 0.46, 0.42)),
                searchFieldTintBottom: .dynamic(light: (0.89, 0.95, 1, 0.22), dark: (0.10, 0.17, 0.25, 0.36)),
                searchFieldStrokeColor: .dynamic(light: (0.25, 0.46, 0.88, 0.18), dark: (0.46, 0.72, 0.98, 0.26)),
                selectionFillColor: .dynamic(light: (0.21, 0.46, 0.94, 0.15), dark: (0.31, 0.62, 0.94, 0.24)),
                selectionStrokeColor: .dynamic(light: (0.18, 0.42, 0.88, 0.34), dark: (0.49, 0.78, 1, 0.42)),
                capsuleFillColor: .dynamic(light: (1, 1, 1, 0.42), dark: (0.17, 0.24, 0.31, 0.62)),
                capsuleStrokeColor: .dynamic(light: (0.24, 0.44, 0.84, 0.12), dark: (0.49, 0.78, 1, 0.18)),
                previewGlowColor: .dynamic(light: (0.40, 0.63, 1, 0.32), dark: (0.27, 0.57, 0.94, 0.50))
            )
        case .sunrise:
            LauncherThemePalette(
                accentColor: .dynamic(light: (0.83, 0.36, 0.22, 1), dark: (1, 0.68, 0.38, 1)),
                panelTintTop: .dynamic(light: (1, 0.86, 0.72, 0.44), dark: (0.39, 0.20, 0.12, 0.52)),
                panelTintBottom: .dynamic(light: (1, 0.95, 0.86, 0.30), dark: (0.23, 0.11, 0.09, 0.46)),
                panelStrokeColor: .dynamic(light: (0.90, 0.46, 0.29, 0.24), dark: (1, 0.71, 0.44, 0.28)),
                searchFieldTintTop: .dynamic(light: (1, 1, 1, 0.30), dark: (0.42, 0.22, 0.16, 0.40)),
                searchFieldTintBottom: .dynamic(light: (1, 0.95, 0.88, 0.22), dark: (0.25, 0.13, 0.10, 0.34)),
                searchFieldStrokeColor: .dynamic(light: (0.90, 0.48, 0.29, 0.18), dark: (1, 0.73, 0.47, 0.24)),
                selectionFillColor: .dynamic(light: (0.95, 0.48, 0.28, 0.14), dark: (0.98, 0.57, 0.31, 0.23)),
                selectionStrokeColor: .dynamic(light: (0.87, 0.40, 0.25, 0.34), dark: (1, 0.75, 0.51, 0.40)),
                capsuleFillColor: .dynamic(light: (1, 0.99, 0.97, 0.48), dark: (0.29, 0.18, 0.14, 0.62)),
                capsuleStrokeColor: .dynamic(light: (0.86, 0.44, 0.26, 0.12), dark: (1, 0.74, 0.47, 0.16)),
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
