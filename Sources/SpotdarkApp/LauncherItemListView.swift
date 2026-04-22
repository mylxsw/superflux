import AppKit
import SwiftUI
import SpotdarkCore

struct LauncherItemListView: View {
    let items: [SearchItem]
    let query: String
    let selectedIndex: Int
    let sectionTitle: String?
    let onSelect: (Int) -> Void
    let onActivate: (Int) -> Void

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 4) {
                    if let sectionTitle {
                        LauncherSectionHeaderView(title: sectionTitle)
                            .padding(.horizontal, 10)
                            .padding(.top, 2)
                            .padding(.bottom, 4)
                    }

                    ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                        Button {
                            onSelect(index)
                            onActivate(index)
                        } label: {
                            LauncherRowView(item: item, query: query)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(rowBackground(isSelected: selectedIndex == index))
                        }
                        .buttonStyle(.plain)
                        .id(index)
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
        }
    }
}

#Preview("Recent Section") {
    LauncherItemListView(
        items: [
            .application(AppItem(name: "TextEdit", bundleIdentifier: nil, bundleURL: URL(fileURLWithPath: "/Applications/TextEdit.app"))),
            .file(FileItem(name: "Quarterly Report.pdf", path: URL(fileURLWithPath: "/Users/demo/Documents/Quarterly Report.pdf"), contentType: nil, modificationDate: nil))
        ],
        query: "",
        selectedIndex: 0,
        sectionTitle: LauncherStrings.recentSectionTitle,
        onSelect: { _ in },
        onActivate: { _ in }
    )
    .frame(width: LauncherPanelMetrics.width, height: 220)
    .padding()
    .background(.ultraThinMaterial)
}
