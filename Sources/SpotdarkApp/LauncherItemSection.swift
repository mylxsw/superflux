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
        case recent
        case calculator
        case applications
        case files
        case commands
        case mixed

        var title: String? {
            switch self {
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
            }
        }
    }
}

enum LauncherItemSectionBuilder {
    static func makeSections(
        items: [SearchItem],
        isShowingRecentItems: Bool,
        minimumGroupedItemCount: Int = LauncherPanelMetrics.groupedResultsMinimumCount
    ) -> [LauncherItemSection] {
        guard !items.isEmpty else { return [] }

        let allRows = items.enumerated().map { LauncherItemSection.Row(index: $0, item: $1) }

        // Calculator results always appear first in an unlabeled section of their own.
        let calculatorRows = allRows.filter { if case .calculator = $0.item { return true }; return false }
        let otherRows      = allRows.filter { if case .calculator = $0.item { return false }; return true }

        var sections: [LauncherItemSection] = []
        if !calculatorRows.isEmpty {
            sections.append(LauncherItemSection(kind: .calculator, rows: calculatorRows))
        }

        guard !otherRows.isEmpty else { return sections }

        if isShowingRecentItems {
            sections.append(LauncherItemSection(kind: .recent, rows: otherRows))
            return sections
        }

        let groupedRows = Dictionary(grouping: otherRows) { kind(for: $0.item) }
        let orderedKinds: [LauncherItemSection.Kind] = [.applications, .files, .commands]
        let nonEmptyKinds = orderedKinds.filter { groupedRows[$0]?.isEmpty == false }
        let shouldCollapse = otherRows.count < minimumGroupedItemCount || nonEmptyKinds.count <= 1

        if shouldCollapse {
            sections.append(LauncherItemSection(kind: .mixed, rows: otherRows))
        } else {
            sections += orderedKinds.compactMap { kind in
                guard let sectionRows = groupedRows[kind], !sectionRows.isEmpty else { return nil }
                return LauncherItemSection(kind: kind, rows: sectionRows)
            }
        }

        return sections
    }

    private static func kind(for item: SearchItem) -> LauncherItemSection.Kind {
        switch item {
        case .application:
            return .applications
        case .file:
            return .files
        case .command:
            return .commands
        case .calculator:
            return .calculator
        }
    }
}
