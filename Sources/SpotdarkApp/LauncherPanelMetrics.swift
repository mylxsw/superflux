import CoreGraphics
import Foundation

enum LauncherPanelMetrics {
    static let width: CGFloat = 742
    static let collapsedHeight: CGFloat = 118
    static let expandedHeight: CGFloat = 404
    static let recentItemsLimit = 5
    static let cornerRadius: CGFloat = 24
    static let contentPadding: CGFloat = 0
    static let contentSpacing: CGFloat = 0
    static let searchFieldCornerRadius: CGFloat = 12
    static let searchFieldHeight: CGFloat = 62
    static let searchBarHorizontalPadding: CGFloat = 18
    static let searchBarTopPadding: CGFloat = 12
    static let searchBarBottomPadding: CGFloat = 10
    static let resultsHorizontalPadding: CGFloat = 10
    static let resultsTopPadding: CGFloat = 10
    static let resultsBottomPadding: CGFloat = 8
    static let rowCornerRadius: CGFloat = 14
    static let rowIconSize: CGFloat = 32
    static let rowMinHeight: CGFloat = 54
    static let footerHeight: CGFloat = 42
    static let collapsedBodyHeight: CGFloat = 13
    static let panelResizeAnimationDuration: TimeInterval = 0.14
    static let panelPresentationDuration: TimeInterval = 0.18
    static let panelDismissalDuration: TimeInterval = 0.14
    static let panelPresentationOffset: CGFloat = 14
    static let expandedContentAnimationDuration: TimeInterval = 0.16
    static let contentSwapAnimationDuration: TimeInterval = 0.12
    static let selectionScrollAnimationDuration: TimeInterval = 0.14
    static let searchDebounceNanoseconds: UInt64 = 30_000_000
    static let groupedResultsMinimumCount = 5
}
