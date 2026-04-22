import CoreGraphics
import Foundation

enum LauncherPanelMetrics {
    static let width: CGFloat = 720
    static let collapsedHeight: CGFloat = 84
    static let expandedHeight: CGFloat = 420
    static let recentItemsLimit = 5
    static let cornerRadius: CGFloat = 16
    static let contentPadding: CGFloat = 16
    static let contentSpacing: CGFloat = 12
    static let searchFieldCornerRadius: CGFloat = 12
    static let searchFieldHeight: CGFloat = 52
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
