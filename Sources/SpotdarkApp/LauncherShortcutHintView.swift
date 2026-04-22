import SwiftUI

@MainActor
struct LauncherShortcutHintView: View {
    @ObservedObject private var settingsStore: SettingsStore

    init(settingsStore: SettingsStore) {
        _settingsStore = ObservedObject(wrappedValue: settingsStore)
    }

    var body: some View {
        Text(settingsStore.currentShortcutDisplay)
            .font(.system(size: 12, weight: .medium, design: .rounded))
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.primary.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
                    )
            )
            .accessibilityLabel(
                Text(
                    String(
                        format: LauncherStrings.launcherShortcutAccessibilityLabelTemplate,
                        settingsStore.currentShortcutDisplay
                    )
                )
            )
    }
}

#Preview("Launcher Shortcut Hint") {
    LauncherShortcutHintView(
        settingsStore: SettingsStore(
            launcherHotKey: .optionSpace,
            defaults: nil
        )
    )
    .padding()
    .frame(width: 180)
    .background(.ultraThinMaterial)
}
