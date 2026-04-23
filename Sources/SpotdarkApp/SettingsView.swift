import AppKit
import SwiftUI
import UniformTypeIdentifiers
import SpotdarkCore

// MARK: - Root

struct SettingsView: View {
    @ObservedObject var store: SettingsStore

    var body: some View {
        VStack(spacing: 0) {
            SDTabBar(selectedPane: $store.selectedPane)
            Divider()
            contentView
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 820, height: 560)
    }

    @ViewBuilder
    private var contentView: some View {
        switch store.selectedPane {
        case .search:    SDSearchScopePane(store: store)
        case .general:   SDAppearancePane(store: store)
        case .shortcuts: SDShortcutsPane(store: store)
        case .about:     SDAdvancedPane(store: store)
        }
    }
}

// MARK: - Tab Bar

private struct SDTabBar: View {
    @Binding var selectedPane: SettingsPane

    private let orderedPanes: [SettingsPane] = [.search, .general, .shortcuts, .about]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(orderedPanes) { pane in
                SDTabButton(title: pane.title, isSelected: selectedPane == pane) {
                    selectedPane = pane
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .frame(height: 44)
    }
}

private struct SDTabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                Text(title)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? Color.primary : Color.secondary)
                    .padding(.horizontal, 14)
                    .frame(maxHeight: .infinity)
                Rectangle()
                    .fill(isSelected ? Color.accentColor : Color.clear)
                    .frame(height: 2)
            }
        }
        .buttonStyle(.plain)
        .frame(height: 44)
    }
}

// MARK: - Search Scope Pane

private struct SDSearchScopePane: View {
    @ObservedObject var store: SettingsStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                SDPaneHeader(
                    title: "Search Scope",
                    subtitle: "Configure where Spotdark looks for files and information across your system."
                )

                // System Locations
                VStack(alignment: .leading, spacing: 8) {
                    SDSectionHeader("SYSTEM LOCATIONS")
                    SDCard {
                        ForEach(Array(systemLocationItems.enumerated()), id: \.offset) { index, item in
                            if index > 0 {
                                Divider().padding(.leading, 52)
                            }
                            HStack(spacing: 12) {
                                SDIconBadge(systemImage: item.icon, backgroundColor: item.iconColor)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.title)
                                        .font(.system(size: 13, weight: .medium))
                                    Text(item.subtitle)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer(minLength: 8)
                                Toggle("", isOn: .constant(true))
                                    .toggleStyle(.switch)
                                    .labelsHidden()
                                    .tint(.blue)
                                    .disabled(true)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                        }
                    }
                }

                // Custom Locations
                VStack(alignment: .leading, spacing: 8) {
                    SDSectionHeader("CUSTOM LOCATIONS")
                    if store.customSearchLocations.isEmpty {
                        SDCard {
                            SDEmptyState(
                                icon: "folder.badge.questionmark",
                                title: "No custom folders",
                                message: "Add specific folders or external drives you want Spotdark to index."
                            )
                        }
                    } else {
                        SDCard {
                            ForEach(Array(store.customSearchLocations.enumerated()), id: \.offset) { index, location in
                                if index > 0 {
                                    Divider().padding(.leading, 52)
                                }
                                HStack(spacing: 12) {
                                    SDIconBadge(systemImage: "folder", backgroundColor: Color.blue.opacity(0.15))
                                    Text(NSString(string: location).abbreviatingWithTildeInPath)
                                        .font(.system(size: 13))
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                    Spacer(minLength: 8)
                                    Button {
                                        store.selectedCustomSearchLocation = location
                                        store.removeSelectedCustomSearchLocation()
                                    } label: {
                                        Image(systemName: "minus.circle.fill")
                                            .font(.system(size: 16))
                                            .foregroundStyle(.secondary)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                            }
                        }
                    }

                    Button { presentFolderPicker() } label: {
                        Label("Add Folder...", systemImage: "plus")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(Color.accentColor)
                            )
                    }
                    .buttonStyle(.plain)
                }

                // Web Search Integration
                SDCard {
                    HStack(spacing: 12) {
                        SDIconBadge(systemImage: "globe", backgroundColor: Color.blue.opacity(0.15))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Web Search Integration")
                                .font(.system(size: 13, weight: .semibold))
                            Text("Allow Spotdark to fetch results from the web when local files aren't enough.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 8)
                        Picker("", selection: $store.selectedWebSearchEngine) {
                            ForEach(WebSearchEngine.allCases, id: \.self) { engine in
                                Text(engine.displayName).tag(engine)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 100)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                }
            }
            .padding(20)
        }
    }

    private var systemLocationItems: [(icon: String, iconColor: Color, title: String, subtitle: String)] {
        store.defaultSearchLocations.map { path in
            let name = URL(fileURLWithPath: path).lastPathComponent
            let (icon, color): (String, Color)
            if path.hasPrefix("/System/") {
                (icon, color) = ("apple.logo", Color.gray.opacity(0.2))
            } else if path.hasPrefix("/usr/local") {
                (icon, color) = ("shippingbox.fill", Color.orange.opacity(0.15))
            } else if path.contains("/Users/") {
                (icon, color) = ("house.fill", Color.orange.opacity(0.15))
            } else {
                (icon, color) = ("folder.fill", Color.blue.opacity(0.15))
            }
            return (icon, color, name, NSString(string: path).abbreviatingWithTildeInPath)
        }
    }

    private func presentFolderPicker() {
        let panel = NSOpenPanel()
        panel.title = SettingsStrings.folderPickerTitle
        panel.message = SettingsStrings.folderPickerMessage
        panel.prompt = SettingsStrings.folderPickerPrompt
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        guard panel.runModal() == .OK, let url = panel.url else { return }
        store.addCustomSearchLocation(url)
    }
}

// MARK: - Appearance Pane

private struct SDAppearancePane: View {
    @ObservedObject var store: SettingsStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                SDPaneHeader(
                    title: "Appearance",
                    subtitle: "Choose how Spotdark looks and feels across all surfaces."
                )

                VStack(alignment: .leading, spacing: 8) {
                    SDSectionHeader("WINDOW APPEARANCE")
                    SDCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Picker("", selection: $store.selectedAppearance) {
                                ForEach(SettingsAppearance.allCases) { appearance in
                                    Text(appearance.title).tag(appearance)
                                }
                            }
                            .pickerStyle(.segmented)
                            .labelsHidden()
                            Text("Choose whether Spotdark follows the system appearance or stays pinned to light or dark mode.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    SDSectionHeader("COLOR THEME")
                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 220, maximum: 300), spacing: 12)],
                        alignment: .leading,
                        spacing: 12
                    ) {
                        ForEach(LauncherThemePreset.allCases) { preset in
                            ThemePresetCard(
                                preset: preset,
                                isSelected: store.selectedThemePreset == preset,
                                action: { store.selectedThemePreset = preset }
                            )
                        }
                    }
                    Text("Presets recolor the launcher immediately and stay active across relaunches.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(20)
        }
    }
}

// MARK: - Shortcuts Pane

private struct SDShortcutsPane: View {
    @ObservedObject var store: SettingsStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                SDPaneHeader(
                    title: "Shortcuts",
                    subtitle: "Configure keyboard shortcuts to navigate and control Spotdark."
                )

                SDCard {
                    VStack(spacing: 0) {
                        // Global Hotkey row — tap to begin recording
                        Button {
                            if !store.isRecordingShortcut { store.beginShortcutRecording() }
                        } label: {
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Global Hotkey")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(.primary)
                                    Text("The primary shortcut to summon or dismiss Spotdark from anywhere.")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer(minLength: 16)
                                if store.isRecordingShortcut {
                                    Text("Recording…")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundStyle(Color.accentColor)
                                } else {
                                    SDHotkeyBadgeRow(hotKey: store.launcherHotKey)
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        // Inline recorder + event monitor (always present when recording)
                        if store.isRecordingShortcut {
                            Divider().padding(.leading, 14)
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "waveform.badge.mic")
                                        .foregroundStyle(Color.accentColor)
                                    Text("Press the new key combination. Escape to cancel.")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Button("Cancel") { store.cancelShortcutRecording() }
                                        .buttonStyle(.borderless)
                                        .controlSize(.small)
                                }
                                // Hidden event monitor — captures keystrokes when active
                                Color.clear.frame(height: 0)
                                    .background(
                                        SettingsShortcutRecorderView(store: store)
                                            .opacity(0)
                                    )
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                        }

                        if let feedback = store.shortcutFeedback {
                            Divider().padding(.leading, 14)
                            SettingsShortcutFeedbackView(feedback: feedback)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                        }

                        Divider().padding(.leading, 14)

                        // Fallback shortcut row
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Fallback Shortcut")
                                    .font(.system(size: 13, weight: .medium))
                                Text("Alternative activation if the primary shortcut is blocked.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer(minLength: 16)
                            SDKeyBadge(label: store.fallbackShortcutDisplay)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)

                        Divider().padding(.leading, 14)

                        // Conflict handling row
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Conflict Handling")
                                    .font(.system(size: 13, weight: .medium))
                                Text("Behavior when another app uses the same shortcut.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer(minLength: 16)
                            SDKeyBadge(label: "Reject reserved combos")
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                    }
                }

                HStack(spacing: 10) {
                    Button(store.shortcutPrimaryButtonTitle) {
                        store.toggleShortcutRecording()
                    }
                    Button("Reset to Default") {
                        store.resetShortcutToDefault()
                    }
                    .disabled(!store.canResetShortcut || store.isRecordingShortcut)
                }

                VStack(alignment: .leading, spacing: 8) {
                    SDSectionHeader("NAVIGATION")
                    SDCard {
                        VStack(spacing: 0) {
                            SDNavShortcutRow(title: "Next Item", keys: ["Tab"])
                            Divider().padding(.leading, 14)
                            SDNavShortcutRow(title: "Previous Item", keys: ["⇧", "Tab"])
                        }
                    }
                }
            }
            .padding(20)
        }
    }
}

private struct SDNavShortcutRow: View {
    let title: String
    let keys: [String]

    var body: some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
            Spacer(minLength: 16)
            HStack(spacing: 4) {
                ForEach(Array(keys.enumerated()), id: \.offset) { index, key in
                    if index > 0 {
                        Text("+")
                            .font(.system(size: 11))
                            .foregroundStyle(.tertiary)
                    }
                    SDKeyBadge(label: key)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}

private struct SDHotkeyBadgeRow: View {
    let hotKey: HotKey

    var body: some View {
        HStack(spacing: 4) {
            ForEach(Array(badgeLabels.enumerated()), id: \.offset) { index, label in
                if index > 0 {
                    Text("+")
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                }
                SDKeyBadge(label: label)
            }
        }
    }

    private var badgeLabels: [String] {
        let modifierSymbols: [Character] = ["⌃", "⌥", "⇧", "⌘"]
        var badges: [String] = []
        var remaining = hotKey.displayString

        while let first = remaining.first, modifierSymbols.contains(first) {
            badges.append(String(first))
            remaining = String(remaining.dropFirst())
        }
        if !remaining.isEmpty { badges.append(remaining) }
        return badges
    }
}

// MARK: - Advanced Pane

private struct SDAdvancedPane: View {
    @ObservedObject var store: SettingsStore
    @State private var importPreview: SettingsImportPreview?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                SDPaneHeader(
                    title: "Advanced",
                    subtitle: "Launcher behavior, data management, and application information."
                )

                VStack(alignment: .leading, spacing: 8) {
                    SDSectionHeader("LAUNCHER PANEL")
                    SDCard {
                        VStack(spacing: 0) {
                            SDToggleRow(
                                icon: "arrow.up.right.square",
                                iconColor: Color.blue.opacity(0.15),
                                title: "Launch at login",
                                subtitle: "Start Spotdark automatically when you log in.",
                                isOn: $store.launchAtLoginEnabled
                            )
                            Divider().padding(.leading, 52)
                            SDToggleRow(
                                icon: "menubar.rectangle",
                                iconColor: Color.green.opacity(0.15),
                                title: "Show menu bar helper",
                                subtitle: "Keep Spotdark accessible via the menu bar as a fallback launcher trigger.",
                                isOn: $store.showsMenuBarItem
                            )
                            Divider().padding(.leading, 52)
                            SDToggleRow(
                                icon: "rectangle.arrowtriangle.2.inward",
                                iconColor: Color.purple.opacity(0.15),
                                title: "Remember last panel position",
                                subtitle: "Panel stays centered for now; this toggle reserves the future preference.",
                                isOn: $store.remembersPanelPosition
                            )
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    SDSectionHeader("DATA MANAGEMENT")
                    SDCard {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 10) {
                                Button("Export Settings…") { exportSettingsToFile() }
                                Button("Import Settings…") { importSettingsFromFile() }
                            }
                            Text("Export your settings as a portable JSON file or import one to restore a previous configuration.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    SDSectionHeader("ABOUT")
                    SDCard {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Spotdark")
                                .font(.system(size: 15, weight: .semibold))
                            Text("A macOS Spotlight-style launcher with file search, app launching, clipboard history, and command execution.")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                    }
                }
            }
            .padding(20)
        }
        .sheet(item: $importPreview) { preview in
            SettingsImportSheet(preview: preview) { strategy in
                let newPinnedIDs = store.applyImport(
                    preview.payload,
                    strategy: strategy,
                    currentPinnedIDs: PinnedItemsStore.shared.pinnedIDs
                )
                PinnedItemsStore.shared.setPinnedIDs(newPinnedIDs)
                importPreview = nil
            } onCancel: {
                importPreview = nil
            }
        }
    }

    private func exportSettingsToFile() {
        let payload = store.exportPayload(pinnedIDs: PinnedItemsStore.shared.pinnedIDs)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(payload) else { return }
        let panel = NSSavePanel()
        panel.title = SettingsStrings.exportSavePanelTitle
        panel.nameFieldStringValue = SettingsStrings.exportDefaultFilename
        panel.allowedContentTypes = [.json]
        panel.canCreateDirectories = true
        guard panel.runModal() == .OK, let url = panel.url else { return }
        try? data.write(to: url, options: .atomic)
    }

    private func importSettingsFromFile() {
        let panel = NSOpenPanel()
        panel.title = SettingsStrings.importOpenPanelTitle
        panel.prompt = SettingsStrings.importOpenPanelPrompt
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.json]
        guard panel.runModal() == .OK, let url = panel.url else { return }
        guard let data = try? Data(contentsOf: url) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let payload = try? decoder.decode(SettingsExportPayload.self, from: data) else { return }
        importPreview = store.importPreview(payload, currentPinnedIDs: PinnedItemsStore.shared.pinnedIDs)
    }
}

// MARK: - Reusable Design Components

private struct SDPaneHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.title2.weight(.semibold))
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

struct SDSectionHeader: View {
    let title: String

    init(_ title: String) { self.title = title }

    var body: some View {
        Text(title)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.secondary)
            .tracking(0.5)
    }
}

struct SDCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.07), lineWidth: 1)
        )
    }
}

struct SDIconBadge: View {
    let systemImage: String
    let backgroundColor: Color

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(.primary)
            .frame(width: 32, height: 32)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(backgroundColor)
            )
    }
}

struct SDKeyBadge: View {
    let label: String

    var body: some View {
        Text(label)
            .font(.system(size: 12, weight: .medium, design: .rounded))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color.secondary.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .strokeBorder(Color.secondary.opacity(0.2), lineWidth: 1)
                    )
            )
    }
}

private struct SDToggleRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 12) {
            SDIconBadge(systemImage: icon, backgroundColor: iconColor)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 8)
            Toggle("", isOn: $isOn)
                .toggleStyle(.switch)
                .labelsHidden()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}

private struct SDEmptyState: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(.secondary)
            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
    }
}

// MARK: - Theme Preset Card (preserved from original)

private struct ThemePresetCard: View {
    let preset: LauncherThemePreset
    let isSelected: Bool
    let action: () -> Void

    private var theme: LauncherThemePalette { preset.theme }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(preset.title)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text(preset.summary)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(isSelected ? theme.accentColor : Color.secondary.opacity(0.55))
                }
                ThemePresetPreview(theme: theme)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(cardBackground)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(preset.title)
        .accessibilityValue(isSelected ? "Selected" : "")
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(Color.primary.opacity(isSelected ? 0.08 : 0.045))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(isSelected ? theme.selectionStrokeColor : Color.primary.opacity(0.08), lineWidth: 1)
            )
    }
}

private struct ThemePresetPreview: View {
    let theme: LauncherThemePalette

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(LinearGradient(
                            colors: [theme.panelTintTop, theme.panelTintBottom],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(theme.panelStrokeColor, lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(.thinMaterial)
                    .frame(height: 16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(LinearGradient(
                                colors: [theme.searchFieldTintTop, theme.searchFieldTintBottom],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                    )
                    .overlay(
                        HStack(spacing: 6) {
                            Circle().fill(theme.accentColor).frame(width: 5, height: 5)
                            RoundedRectangle(cornerRadius: 3).fill(Color.primary.opacity(0.16)).frame(width: 60, height: 5)
                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, 6)
                    )

                VStack(spacing: 5) {
                    previewRow(width: 0.92, highlighted: true)
                    previewRow(width: 0.72, highlighted: false)
                    previewRow(width: 0.84, highlighted: false)
                }
            }
            .padding(10)
        }
        .frame(height: 110)
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(theme.previewGlowColor)
                .frame(width: 40, height: 40)
                .blur(radius: 10)
                .offset(x: 6, y: -8)
                .allowsHitTesting(false)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    @ViewBuilder
    private func previewRow(width: CGFloat, highlighted: Bool) -> some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(highlighted ? theme.accentColor.opacity(0.24) : theme.capsuleFillColor)
                .frame(width: 18, height: 18)
                .overlay(
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .strokeBorder(highlighted ? theme.selectionStrokeColor : theme.capsuleStrokeColor, lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 4) {
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(Color.primary.opacity(highlighted ? 0.17 : 0.12))
                    .frame(width: 120 * width, height: 6)
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(Color.primary.opacity(0.08))
                    .frame(width: 80 * width, height: 5)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(highlighted ? theme.selectionFillColor : Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(highlighted ? theme.selectionStrokeColor : Color.clear, lineWidth: 1)
                )
        )
    }
}

// MARK: - Import Sheet (preserved from original)

private struct SettingsImportSheet: View {
    let preview: SettingsImportPreview
    let onApply: (SettingsImportStrategy) -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(SettingsStrings.importSheetTitle)
                .font(.title2.weight(.semibold))

            if preview.hasConflicts {
                Text(SettingsStrings.importSheetConflictsHeading)
                    .foregroundStyle(.secondary)

                VStack(spacing: 0) {
                    ForEach(Array(preview.conflicts.enumerated()), id: \.offset) { index, conflict in
                        HStack(alignment: .top) {
                            Text(conflict.settingName)
                                .frame(width: 180, alignment: .leading)
                                .foregroundStyle(.secondary)
                            Text(conflict.currentValue)
                                .frame(width: 110, alignment: .leading)
                            Image(systemName: "arrow.right")
                                .foregroundStyle(.tertiary)
                                .font(.caption)
                            Text(conflict.importedValue)
                                .frame(width: 110, alignment: .leading)
                                .foregroundStyle(.primary)
                        }
                        .font(.callout)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Color.primary.opacity(index % 2 == 0 ? 0.04 : 0))
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.1), lineWidth: 1)
                )

                Text(SettingsStrings.importSheetStrategyHeading)
                    .foregroundStyle(.secondary)

                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Button(SettingsStrings.importReplaceAllButton) { onApply(.replaceAll) }
                            .controlSize(.large)
                        Text(SettingsStrings.importReplaceAllHelp)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Button(SettingsStrings.importMergeButton) { onApply(.merge) }
                            .controlSize(.large)
                        Text(SettingsStrings.importMergeHelp)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                Text(SettingsStrings.importSheetNoConflictsMessage)
                    .foregroundStyle(.secondary)
                Button(SettingsStrings.importReplaceAllButton) { onApply(.replaceAll) }
                    .controlSize(.large)
            }

            HStack {
                Spacer()
                Button(SettingsStrings.importCancelButton) { onCancel() }
                    .keyboardShortcut(.cancelAction)
            }
        }
        .padding(24)
        .frame(minWidth: 520)
    }
}

// MARK: - Preview

#Preview("Settings") {
    SettingsView(store: .preview)
}
