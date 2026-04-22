import Foundation

enum LauncherStrings {
    static let searchPlaceholder = "Search apps or commands"
    static let searchFieldAccessibilityLabel = "Search"
    static let searchFieldAccessibilityHint = "Type to search apps, files, and commands. Use the arrow keys to move through results, Return to confirm, and Escape to close."
    static let launcherShortcutAccessibilityLabelTemplate = "Launcher shortcut %@"
    static let searchResultsAccessibilityLabel = "Search results"
    static let recentItemsAccessibilityLabel = "Recent items"
    static let resultSelectedAccessibilityValue = "Selected"
    static let openResultAccessibilityHint = "Press Return to open."
    static let runCommandAccessibilityHint = "Press Return to run the command."
    static let copyCalculatorResultAccessibilityHint = "Press Return to copy the result."
    static let applicationResultAccessibilityLabelTemplate = "%@, application"
    static let commandResultAccessibilityLabelTemplate = "%@, command"
    static let fileResultAccessibilityLabelTemplate = "%@, file"
    static let calculatorResultAccessibilityLabelTemplate = "%@, calculator result"
    static let fileResultAccessibilityValueTemplate = "Location %@"

    static let applicationResultLabel = "Application"
    static let commandResultLabel = "Command"
    static let fileResultLabel = "File"
    static let calculatorResultLabel = "Calculator — press Return to copy"
    static let recentSectionTitle = "Recent"
    static let applicationsSectionTitle = "Applications"
    static let filesSectionTitle = "Files"
    static let commandsSectionTitle = "Commands"
    static let webSearchResultTitleTemplate = "Search %@ for \"%@\""
    static let webSearchResultLabel = "Web Search"
    static let pluginSectionTitle = "Extensions"
    static let pluginResultAccessibilityLabelTemplate = "%@, extension result"
    static let pluginResultLabel = "Extension"

    static let loadingTitle = "Indexing Applications"
    static let loadingMessage = "Building the initial app catalog so results can appear instantly."

    static let noResultsTitle = "No Results Found"
    static let noResultsMessageTemplate = "No apps or commands match \"%@\"."
    static let noResultsHint = "Try a shorter name or different keywords."

    static let pinnedSectionTitle = "Pinned"
    static let pinItemLabel = "Pin"
    static let unpinItemLabel = "Unpin"
}
