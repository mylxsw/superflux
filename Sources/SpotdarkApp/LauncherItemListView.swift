import AppKit
import SwiftUI
import SpotdarkCore

struct LauncherItemListView: View {
    let sections: [LauncherItemSection]
    let query: String
    let selectedIndex: Int
    let onSelect: (Int) -> Void
    let onActivate: (Int) -> Void

    @AccessibilityFocusState private var accessibilityFocusedRowIndex: Int?
    @ObservedObject private var settingsStore = SettingsStore.shared
    private var pinnedStore: PinnedItemsStore { PinnedItemsStore.shared }

    private var theme: LauncherThemePalette {
        settingsStore.selectedThemePreset.theme
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(sections) { section in
                        if let title = section.title {
                            LauncherSectionHeaderView(title: title)
                                .padding(.horizontal, 10)
                                .padding(.top, 2)
                                .padding(.bottom, 4)
                        }

                        ForEach(section.rows) { row in
                            Button {
                                onSelect(row.index)
                                onActivate(row.index)
                            } label: {
                                LauncherRowView(
                                    item: row.item,
                                    query: query,
                                    isSelected: selectedIndex == row.index,
                                    isPinned: pinnedStore.isPinned(row.item)
                                )
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(rowBackground(isSelected: selectedIndex == row.index))
                            }
                            .buttonStyle(.plain)
                            .id(row.index)
                            .accessibilityFocused($accessibilityFocusedRowIndex, equals: row.index)
                            .contextMenu {
                                if stableID(for: row.item) != nil {
                                    if pinnedStore.isPinned(row.item) {
                                        Button(LauncherStrings.unpinItemLabel) {
                                            pinnedStore.unpin(row.item)
                                        }
                                    } else {
                                        Button(LauncherStrings.pinItemLabel) {
                                            pinnedStore.pin(row.item)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.vertical, 2)
            }
            .background(Color.clear)
            .accessibilityElement(children: .contain)
            .accessibilityLabel(listAccessibilityLabel)
            .onChange(of: selectedIndex) {
                withAnimation(.snappy(duration: LauncherPanelMetrics.selectionScrollAnimationDuration, extraBounce: 0)) {
                    proxy.scrollTo(selectedIndex, anchor: .center)
                }
                syncAccessibilityFocus()
            }
            .onAppear(perform: syncAccessibilityFocus)
            .onChange(of: sections, syncAccessibilityFocus)
        }
    }

    private var listAccessibilityLabel: String {
        sections.contains { $0.kind == .recent }
            ? LauncherStrings.recentItemsAccessibilityLabel
            : LauncherStrings.searchResultsAccessibilityLabel
    }

    @ViewBuilder
    private func rowBackground(isSelected: Bool) -> some View {
        if isSelected {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(theme.selectionFillColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(theme.selectionStrokeColor, lineWidth: 1)
                )
        } else {
            Color.clear
        }
    }

    private func syncAccessibilityFocus() {
        let rowIndices = sections.flatMap(\.rows).map(\.index)
        guard !rowIndices.isEmpty else {
            accessibilityFocusedRowIndex = nil
            return
        }

        accessibilityFocusedRowIndex = rowIndices.contains(selectedIndex) ? selectedIndex : rowIndices[0]
    }
}

private struct LauncherSectionHeaderView: View {
    let title: String

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.tertiary)
                .textCase(.uppercase)
                .tracking(0.8)

            Spacer(minLength: 0)
        }
    }
}

struct LauncherRowView: View {
    let item: SearchItem
    let query: String
    let isSelected: Bool
    var isPinned: Bool = false

    @ObservedObject private var settingsStore = SettingsStore.shared

    private var theme: LauncherThemePalette {
        settingsStore.selectedThemePreset.theme
    }

    var body: some View {
        HStack(spacing: 12) {
            icon
                .frame(width: 28, height: 28)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(SearchHighlight.highlight(text: title, query: query, color: theme.accentColor))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            if isPinned {
                Image(systemName: "pin.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
                    .rotationEffect(.degrees(45))
            }
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(accessibilityValue)
        .accessibilityHint(accessibilityHint)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var title: String {
        switch item {
        case .application(let app):
            return app.name
        case .command(let cmd):
            return cmd.title
        case .file(let file):
            return file.name
        case .calculator(let calc):
            return calc.displayResult
        case .webSearch(let ws):
            return String(format: LauncherStrings.webSearchResultTitleTemplate, ws.engine.displayName, ws.query)
        case .plugin(let p):
            return p.title
        }
    }

    private var subtitle: String {
        switch item {
        case .application:
            return LauncherStrings.applicationResultLabel
        case .command:
            return LauncherStrings.commandResultLabel
        case .file(let file):
            let parent = file.path.deletingLastPathComponent().path
            let home = FileManager.default.homeDirectoryForCurrentUser.path
            if parent.hasPrefix(home) {
                return "~" + parent.dropFirst(home.count)
            }
            return parent
        case .calculator:
            return LauncherStrings.calculatorResultLabel
        case .webSearch:
            return LauncherStrings.webSearchResultLabel
        case .plugin(let p):
            return p.subtitle ?? LauncherStrings.pluginResultLabel
        }
    }

    private var accessibilityLabel: String {
        switch item {
        case .application:
            return String(format: LauncherStrings.applicationResultAccessibilityLabelTemplate, title)
        case .command:
            return String(format: LauncherStrings.commandResultAccessibilityLabelTemplate, title)
        case .file:
            return String(format: LauncherStrings.fileResultAccessibilityLabelTemplate, title)
        case .calculator:
            return String(format: LauncherStrings.calculatorResultAccessibilityLabelTemplate, title)
        case .webSearch:
            return title
        case .plugin:
            return String(format: LauncherStrings.pluginResultAccessibilityLabelTemplate, title)
        }
    }

    private var accessibilityValue: String {
        switch item {
        case .application, .command, .webSearch, .plugin:
            return isSelected ? LauncherStrings.resultSelectedAccessibilityValue : ""
        case .file:
            let location = String(format: LauncherStrings.fileResultAccessibilityValueTemplate, subtitle)
            return isSelected ? [location, LauncherStrings.resultSelectedAccessibilityValue].joined(separator: ". ") : location
        case .calculator:
            return isSelected ? LauncherStrings.resultSelectedAccessibilityValue : title
        }
    }

    private var accessibilityHint: String {
        switch item {
        case .application, .file, .webSearch, .plugin:
            return LauncherStrings.openResultAccessibilityHint
        case .command:
            return LauncherStrings.runCommandAccessibilityHint
        case .calculator:
            return LauncherStrings.copyCalculatorResultAccessibilityHint
        }
    }

    @ViewBuilder
    private var icon: some View {
        switch item {
        case .application(let app):
            AppIconView(bundleURL: app.bundleURL)
        case .command:
            Image(systemName: "command")
                .resizable()
                .scaledToFit()
                .padding(5)
                .foregroundStyle(.secondary)
                .background(iconBackground)
        case .file(let file):
            Image(
                nsImage: AppPresentationCache.shared.fileIcon(
                    for: file.path,
                    size: CGSize(width: 28, height: 28)
                )
            )
            .resizable()
            .scaledToFit()
        case .calculator:
            Image(systemName: "equal.square")
                .resizable()
                .scaledToFit()
                .padding(4)
                .foregroundStyle(.secondary)
                .background(iconBackground)
        case .webSearch:
            Image(systemName: "magnifyingglass")
                .resizable()
                .scaledToFit()
                .padding(5)
                .foregroundStyle(.secondary)
                .background(iconBackground)
        case .plugin(let p):
            Image(systemName: p.iconSystemName ?? "puzzlepiece.extension")
                .resizable()
                .scaledToFit()
                .padding(5)
                .foregroundStyle(.secondary)
                .background(iconBackground)
        }
    }

    private var iconBackground: some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(theme.capsuleFillColor)
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(theme.capsuleStrokeColor, lineWidth: 1)
            )
    }
}

#Preview("Recent Section") {
    LauncherItemListView(
        sections: LauncherItemSectionBuilder.makeSections(
            items: [
                .application(AppItem(name: "TextEdit", bundleIdentifier: nil, bundleURL: URL(fileURLWithPath: "/Applications/TextEdit.app"))),
                .file(FileItem(name: "Quarterly Report.pdf", path: URL(fileURLWithPath: "/Users/demo/Documents/Quarterly Report.pdf"), contentType: nil, modificationDate: nil))
            ],
            isShowingRecentItems: true
        ),
        query: "",
        selectedIndex: 0,
        onSelect: { _ in },
        onActivate: { _ in }
    )
    .frame(width: LauncherPanelMetrics.width, height: 220)
    .padding()
    .background(.ultraThinMaterial)
}
