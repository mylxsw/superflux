import AppKit
import SwiftUI
import SpotdarkCore

struct LauncherItemListView: View {
    let sections: [LauncherItemSection]
    let query: String
    let selectedIndex: Int
    let onSelect: (Int) -> Void
    let onActivate: (Int) -> Void

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
                                LauncherRowView(item: row.item, query: query)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(rowBackground(isSelected: selectedIndex == row.index))
                            }
                            .buttonStyle(.plain)
                            .id(row.index)
                        }
                    }
                }
                .padding(.vertical, 2)
            }
            .background(Color.clear)
            .onChange(of: selectedIndex) {
                withAnimation(.snappy(duration: LauncherPanelMetrics.selectionScrollAnimationDuration, extraBounce: 0)) {
                    proxy.scrollTo(selectedIndex, anchor: .center)
                }
            }
        }
    }

    @ViewBuilder
    private func rowBackground(isSelected: Bool) -> some View {
        if isSelected {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.accentColor.opacity(0.18))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(Color.accentColor.opacity(0.35), lineWidth: 1)
                )
        } else {
            Color.clear
        }
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

    var body: some View {
        HStack(spacing: 12) {
            icon
                .frame(width: 28, height: 28)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(SearchHighlight.highlight(text: title, query: query))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .contentShape(Rectangle())
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
                .background(.thinMaterial)
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
                .background(.thinMaterial)
        }
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
