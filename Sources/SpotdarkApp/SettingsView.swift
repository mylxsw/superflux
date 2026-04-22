import AppKit
import SwiftUI
import UniformTypeIdentifiers
import SpotdarkCore

struct SettingsView: View {
    @ObservedObject var store: SettingsStore

    private var theme: LauncherThemePalette {
        store.selectedThemePreset.theme
    }

    var body: some View {
        TabView(selection: $store.selectedPane) {
            GeneralSettingsPane(store: store)
                .tabItem {
                    Label(SettingsPane.general.title, systemImage: SettingsPane.general.systemImage)
                }
                .tag(SettingsPane.general)

            ShortcutSettingsPane(store: store)
                .tabItem {
                    Label(SettingsPane.shortcuts.title, systemImage: SettingsPane.shortcuts.systemImage)
                }
                .tag(SettingsPane.shortcuts)

            SearchSettingsPane(store: store)
                .tabItem {
                    Label(SettingsPane.search.title, systemImage: SettingsPane.search.systemImage)
                }
                .tag(SettingsPane.search)

            AboutSettingsPane()
                .tabItem {
                    Label(SettingsPane.about.title, systemImage: SettingsPane.about.systemImage)
                }
                .tag(SettingsPane.about)
        }
        .frame(minWidth: 720, minHeight: 520)
        .tint(theme.accentColor)
    }
}

private struct GeneralSettingsPane: View {
    @ObservedObject var store: SettingsStore

    @State private var importPreview: SettingsImportPreview?

    var body: some View {
        Form {
            SettingsIntroSection(
                title: SettingsStrings.generalIntroTitle,
                message: SettingsStrings.generalIntroMessage
            )

            Section(SettingsStrings.appearanceSectionTitle) {
                Picker(SettingsStrings.appearancePickerTitle, selection: $store.selectedAppearance) {
                    ForEach(SettingsAppearance.allCases) { appearance in
                        Text(appearance.title).tag(appearance)
                    }
                }

                SettingsSecondaryText(SettingsStrings.appearanceHelp)
            }

            Section(SettingsStrings.themePresetSectionTitle) {
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 220, maximum: 280), spacing: 16)],
                    alignment: .leading,
                    spacing: 16
                ) {
                    ForEach(LauncherThemePreset.allCases) { preset in
                        ThemePresetCard(
                            preset: preset,
                            isSelected: store.selectedThemePreset == preset,
                            action: {
                                store.selectedThemePreset = preset
                            }
                        )
                    }
                }

                SettingsSecondaryText(SettingsStrings.themePresetHelp)
            }

            Section(SettingsStrings.panelSectionTitle) {
                Toggle(SettingsStrings.launchAtLoginTitle, isOn: $store.launchAtLoginEnabled)
                SettingsSecondaryText(SettingsStrings.launchAtLoginHelp)

                Toggle(SettingsStrings.menuBarTitle, isOn: $store.showsMenuBarItem)
                SettingsSecondaryText(SettingsStrings.menuBarHelp)

                Toggle(SettingsStrings.panelPositionTitle, isOn: $store.remembersPanelPosition)
                SettingsSecondaryText(SettingsStrings.panelPositionHelp)
            }

            Section(SettingsStrings.dataManagementSectionTitle) {
                HStack {
                    Button(SettingsStrings.exportSettingsButton) {
                        exportSettingsToFile()
                    }
                    Button(SettingsStrings.importSettingsButton) {
                        importSettingsFromFile()
                    }
                }
                SettingsSecondaryText(SettingsStrings.dataManagementHelp)
            }
        }
        .formStyle(.grouped)
        .padding(20)
        .sheet(item: $importPreview) { preview in
            SettingsImportSheet(preview: preview) { strategy in
                let newPinnedIDs = store.applyImport(preview.payload, strategy: strategy, currentPinnedIDs: PinnedItemsStore.shared.pinnedIDs)
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

private struct ThemePresetCard: View {
    let preset: LauncherThemePreset
    let isSelected: Bool
    let action: () -> Void

    private var theme: LauncherThemePalette {
        preset.theme
    }

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
        .accessibilityValue(isSelected ? SettingsStrings.themePresetSelectedAccessibilityValue : "")
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Color.primary.opacity(isSelected ? 0.08 : 0.045))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(isSelected ? theme.selectionStrokeColor : Color.primary.opacity(0.08), lineWidth: 1)
            )
    }
}

private struct ThemePresetPreview: View {
    let theme: LauncherThemePalette

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [theme.panelTintTop, theme.panelTintBottom],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(theme.panelStrokeColor, lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 10) {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.thinMaterial)
                    .frame(height: 18)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [theme.searchFieldTintTop, theme.searchFieldTintBottom],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        HStack(spacing: 6) {
                            Circle()
                                .fill(theme.accentColor)
                                .frame(width: 6, height: 6)

                            RoundedRectangle(cornerRadius: 3, style: .continuous)
                                .fill(Color.primary.opacity(0.16))
                                .frame(width: 72, height: 6)

                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, 8)
                    )

                VStack(spacing: 6) {
                    previewRow(width: 0.92, highlighted: true)
                    previewRow(width: 0.72, highlighted: false)
                    previewRow(width: 0.84, highlighted: false)
                }
            }
            .padding(12)
        }
        .frame(height: 130)
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(theme.previewGlowColor)
                .frame(width: 44, height: 44)
                .blur(radius: 12)
                .offset(x: 6, y: -10)
                .allowsHitTesting(false)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    @ViewBuilder
    private func previewRow(width: CGFloat, highlighted: Bool) -> some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(highlighted ? theme.accentColor.opacity(0.24) : theme.capsuleFillColor)
                .frame(width: 22, height: 22)
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .strokeBorder(highlighted ? theme.selectionStrokeColor : theme.capsuleStrokeColor, lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 5) {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(Color.primary.opacity(highlighted ? 0.17 : 0.12))
                    .frame(width: 132 * width, height: 8)
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(Color.primary.opacity(0.08))
                    .frame(width: 88 * width, height: 6)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(highlighted ? theme.selectionFillColor : Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(highlighted ? theme.selectionStrokeColor : Color.clear, lineWidth: 1)
                )
        )
    }
}

private struct ShortcutSettingsPane: View {
    @ObservedObject var store: SettingsStore

    var body: some View {
        Form {
            SettingsIntroSection(
                title: SettingsStrings.shortcutsIntroTitle,
                message: SettingsStrings.shortcutsIntroMessage
            )

            Section {
                SettingsShortcutRecorderView(store: store)

                HStack {
                    Button(store.shortcutPrimaryButtonTitle) {
                        store.toggleShortcutRecording()
                    }

                    Button(SettingsStrings.resetShortcutButton) {
                        store.resetShortcutToDefault()
                    }
                    .disabled(!store.canResetShortcut || store.isRecordingShortcut)
                }

                if let feedback = store.shortcutFeedback {
                    SettingsShortcutFeedbackView(feedback: feedback)
                }

                SettingsSecondaryText(SettingsStrings.shortcutRecordingHelp)
            }

            Section {
                SettingsValueRow(
                    title: SettingsStrings.fallbackShortcutTitle,
                    value: store.fallbackShortcutDisplay
                )
                SettingsValueRow(
                    title: SettingsStrings.conflictHandlingTitle,
                    value: SettingsStrings.conflictHandlingValue
                )
                SettingsValueRow(
                    title: SettingsStrings.shortcutLiveUpdateTitle,
                    value: SettingsStrings.shortcutLiveUpdateValue
                )
                SettingsInlineNote(
                    title: SettingsStrings.shortcutRulesTitle,
                    message: SettingsStrings.shortcutRulesMessage
                )
            }
        }
        .formStyle(.grouped)
        .padding(20)
    }
}

private struct SearchSettingsPane: View {
    @ObservedObject var store: SettingsStore

    var body: some View {
        Form {
            SettingsIntroSection(
                title: SettingsStrings.searchIntroTitle,
                message: SettingsStrings.searchIntroMessage
            )

            Section(SettingsStrings.webSearchSectionTitle) {
                Picker(SettingsStrings.webSearchEnginePickerTitle, selection: $store.selectedWebSearchEngine) {
                    ForEach(WebSearchEngine.allCases, id: \.self) { engine in
                        Text(engine.displayName).tag(engine)
                    }
                }
                SettingsSecondaryText(SettingsStrings.webSearchEngineHelp)
            }

            Section(SettingsStrings.defaultLocationsSectionTitle) {
                ForEach(store.defaultSearchLocations, id: \.self) { location in
                    SettingsPathRow(path: location)
                }
                SettingsSecondaryText(SettingsStrings.defaultLocationsHelp)
            }

            Section(SettingsStrings.customLocationsSectionTitle) {
                if store.customSearchLocations.isEmpty {
                    SettingsEmptyState(
                        title: SettingsStrings.customLocationsEmptyTitle,
                        message: SettingsStrings.customLocationsEmptyMessage
                    )
                } else {
                    List(selection: $store.selectedCustomSearchLocation) {
                        ForEach(store.customSearchLocations, id: \.self) { location in
                            SettingsPathRow(path: location)
                                .tag(location)
                        }
                    }
                    .frame(minHeight: 168)
                    .listStyle(.inset(alternatesRowBackgrounds: true))
                }

                HStack {
                    Button(SettingsStrings.addFolderButton) {
                        presentFolderPicker()
                    }
                    Button(SettingsStrings.removeFolderButton) {
                        store.removeSelectedCustomSearchLocation()
                    }
                    .disabled(!store.canRemoveSelectedCustomSearchLocation)
                    Button(SettingsStrings.moveFolderUpButton) {
                        store.moveSelectedCustomSearchLocationUp()
                    }
                    .disabled(!store.canMoveSelectedCustomSearchLocationUp)
                    Button(SettingsStrings.moveFolderDownButton) {
                        store.moveSelectedCustomSearchLocationDown()
                    }
                    .disabled(!store.canMoveSelectedCustomSearchLocationDown)
                }

                SettingsSecondaryText(SettingsStrings.customLocationsHelp)
            }
        }
        .formStyle(.grouped)
        .padding(20)
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

private struct AboutSettingsPane: View {
    var body: some View {
        Form {
            Section(SettingsStrings.aboutSectionTitle) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(SettingsStrings.aboutHeadline)
                        .font(.title3.weight(.semibold))
                    Text(SettingsStrings.aboutSummary)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 6)
            }

            Section(SettingsStrings.roadmapSectionTitle) {
                SettingsRoadmapRow(
                    title: SettingsStrings.roadmapShortcutTitle,
                    summary: SettingsStrings.roadmapShortcutSummary
                )
                SettingsRoadmapRow(
                    title: SettingsStrings.roadmapSearchTitle,
                    summary: SettingsStrings.roadmapSearchSummary
                )
                SettingsRoadmapRow(
                    title: SettingsStrings.roadmapFeedbackTitle,
                    summary: SettingsStrings.roadmapFeedbackSummary
                )
            }
        }
        .formStyle(.grouped)
        .padding(20)
    }
}

private struct SettingsIntroSection: View {
    let title: String
    let message: String

    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Label(title, systemImage: "sidebar.leading")
                    .font(.headline)
                Text(message)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
        }
    }
}

private struct SettingsSecondaryText: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(.footnote)
            .foregroundStyle(.secondary)
    }
}

private struct SettingsValueRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
            Spacer(minLength: 16)
            Text(value)
                .font(.system(.body, design: .rounded).weight(.medium))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    Capsule(style: .continuous)
                        .fill(Color.secondary.opacity(0.12))
                )
        }
    }
}

private struct SettingsPathRow: View {
    let path: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "folder")
                .foregroundStyle(.secondary)
            Text(NSString(string: path).abbreviatingWithTildeInPath)
                .textSelection(.enabled)
            Spacer(minLength: 0)
        }
    }
}

private struct SettingsEmptyState: View {
    let title: String
    let message: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
            Text(message)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

private struct SettingsRoadmapRow: View {
    let title: String
    let summary: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
            Text(summary)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}

private struct SettingsInlineNote: View {
    let title: String
    let message: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
            Text(message)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}

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
                    ForEach(Array(preview.conflicts.enumerated()), id: \.offset) { _, conflict in
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
                        .background(Color.primary.opacity(preview.conflicts.firstIndex(where: { $0.settingName == conflict.settingName }).map { $0 % 2 == 0 ? 0.04 : 0 } ?? 0))
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
                        Button(SettingsStrings.importReplaceAllButton) {
                            onApply(.replaceAll)
                        }
                        .controlSize(.large)
                        Text(SettingsStrings.importReplaceAllHelp)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Button(SettingsStrings.importMergeButton) {
                            onApply(.merge)
                        }
                        .controlSize(.large)
                        Text(SettingsStrings.importMergeHelp)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                Text(SettingsStrings.importSheetNoConflictsMessage)
                    .foregroundStyle(.secondary)

                Button(SettingsStrings.importReplaceAllButton) {
                    onApply(.replaceAll)
                }
                .controlSize(.large)
            }

            HStack {
                Spacer()
                Button(SettingsStrings.importCancelButton) {
                    onCancel()
                }
                .keyboardShortcut(.cancelAction)
            }
        }
        .padding(24)
        .frame(minWidth: 520)
    }
}

#Preview("Settings") {
    SettingsView(store: .preview)
}
