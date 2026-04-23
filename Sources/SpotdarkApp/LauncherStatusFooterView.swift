import SwiftUI

struct LauncherStatusFooterView: View {
    let isIndexing: Bool

    @ObservedObject private var settingsStore = SettingsStore.shared

    private var theme: LauncherThemePalette {
        settingsStore.selectedThemePreset.theme
    }

    var body: some View {
        HStack(spacing: 10) {
            Spacer(minLength: 0)

            Circle()
                .fill(theme.statusIndicatorColor.opacity(isIndexing ? 0.65 : 1))
                .frame(width: 10, height: 10)

            Text(statusText)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(theme.secondaryTextColor)
        }
        .padding(.horizontal, 16)
        .frame(height: LauncherPanelMetrics.footerHeight)
        .frame(maxWidth: .infinity)
        .background(
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [theme.footerTintTop, theme.footerTintBottom],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(theme.footerStrokeColor)
                        .frame(height: 1)
                }
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(LauncherStrings.launcherStatusAccessibilityLabel)
        .accessibilityValue(
            isIndexing
                ? LauncherStrings.launcherStatusIndexingAccessibilityValue
                : LauncherStrings.launcherStatusReadyAccessibilityValue
        )
    }

    private var statusText: String {
        let bundle = Bundle.main
        let appName = (bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String)
            ?? (bundle.object(forInfoDictionaryKey: "CFBundleName") as? String)
            ?? LauncherStrings.launcherStatusAppNameFallback
        guard let version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
              !version.isEmpty else {
            return appName
        }

        return String(format: LauncherStrings.launcherStatusVersionTemplate, appName, version)
    }
}

#Preview("Launcher Status Footer") {
    LauncherStatusFooterView(isIndexing: false)
        .frame(width: LauncherPanelMetrics.width)
}
