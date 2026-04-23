import Foundation
import SpotdarkCore

struct LauncherItemSection: Identifiable, Equatable {
    let kind: Kind
    let rows: [Row]

    var id: Kind { kind }
    var title: String? { kind.title }

    struct Row: Identifiable, Equatable {
        let index: Int
        let item: SearchItem

        var id: Int { index }
    }

    enum Kind: Equatable {
        case pinned
        case recent
        case calculator
        case applications
        case files
        case commands
        case mixed
        case webSearch
        case plugin

        var title: String? {
            switch self {
            case .pinned:
                return LauncherStrings.pinnedSectionTitle
            case .recent:
                return LauncherStrings.recentSectionTitle
            case .calculator:
                return nil
            case .applications:
                return LauncherStrings.applicationsSectionTitle
            case .files:
                return LauncherStrings.filesSectionTitle
            case .commands:
                return LauncherStrings.commandsSectionTitle
            case .mixed:
                return nil
            case .webSearch:
                return nil
            case .plugin:
                return LauncherStrings.pluginSectionTitle
            }
        }
    }
}

enum LauncherItemSectionBuilder {
    static func makeSections(
        items: [SearchItem],
        isShowingRecentItems: Bool,
        pinnedIDs: Set<String> = [],
        minimumGroupedItemCount _: Int = LauncherPanelMetrics.groupedResultsMinimumCount
    ) -> [LauncherItemSection] {
        guard !items.isEmpty else { return [] }

        let allRows = items.enumerated().map { LauncherItemSection.Row(index: $0, item: $1) }

        // Pinned items always appear first in a labelled section of their own.
        let pinnedRows = allRows.filter { stableID(for: $0.item).map { pinnedIDs.contains($0) } ?? false }
        let pinnedIndices = Set(pinnedRows.map(\.index))
        let unpinnedRows = allRows.filter { !pinnedIndices.contains($0.index) }

        // Calculator results appear next in an unlabeled section of their own.
        let calculatorRows  = unpinnedRows.filter { if case .calculator  = $0.item { return true };  return false }
        let webSearchRows   = unpinnedRows.filter { if case .webSearch   = $0.item { return true };  return false }
        let remainingRows   = unpinnedRows.filter {
            if case .calculator = $0.item { return false }
            if case .webSearch  = $0.item { return false }
            return true
        }

        var sections: [LauncherItemSection] = []
        if !pinnedRows.isEmpty {
            sections.append(LauncherItemSection(kind: .pinned, rows: pinnedRows))
        }
        if !calculatorRows.isEmpty {
            sections.append(LauncherItemSection(kind: .calculator, rows: calculatorRows))
        }

        if !remainingRows.isEmpty {
            if isShowingRecentItems {
                sections.append(LauncherItemSection(kind: .recent, rows: remainingRows))
            } else {
                sections.append(LauncherItemSection(kind: .mixed, rows: remainingRows))
            }
        }

        // Web search always appears last in its own unlabeled section.
        if !webSearchRows.isEmpty {
            sections.append(LauncherItemSection(kind: .webSearch, rows: webSearchRows))
        }

        return sections
    }
}
