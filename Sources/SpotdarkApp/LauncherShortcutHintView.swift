import SwiftUI

@MainActor
struct LauncherShortcutHintView: View {
    @ObservedObject private var settingsStore: SettingsStore

    init(settingsStore: SettingsStore) {
        _settingsStore = ObservedObject(wrappedValue: settingsStore)
    }

    var body: some View {
        HStack(spacing: 8) {
            ForEach(Array(shortcutTokens.enumerated()), id: \.offset) { _, token in
                Text(token)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(LauncherGlassStyle.secondary)
                    .lineLimit(1)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 5)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(LauncherGlassStyle.capsuleFill)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .strokeBorder(LauncherGlassStyle.capsuleStroke, lineWidth: 1)
                            )
                    )
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            Text(
                String(
                    format: LauncherStrings.launcherShortcutAccessibilityLabelTemplate,
                    settingsStore.currentShortcutDisplay
                )
            )
        )
    }

    private var shortcutTokens: [String] {
        let symbols = CharacterSet(charactersIn: "⌃⌥⇧⌘")
        let display = settingsStore.currentShortcutDisplay
        let modifierScalars = display.unicodeScalars.prefix { symbols.contains($0) }
        let modifierTokens = modifierScalars.map { String($0) }
        let keyToken = String(display.unicodeScalars.dropFirst(modifierScalars.count))
        return modifierTokens + (keyToken.isEmpty ? [] : [keyToken])
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
