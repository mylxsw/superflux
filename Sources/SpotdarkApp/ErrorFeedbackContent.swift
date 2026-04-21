import SwiftUI
import SpotdarkCore

struct ErrorFeedbackContent {
    enum Style {
        case warning
        case error

        var symbolName: String {
            switch self {
            case .warning:
                "exclamationmark.triangle.fill"
            case .error:
                "xmark.octagon.fill"
            }
        }

        var tint: Color {
            switch self {
            case .warning:
                Color.orange
            case .error:
                Color.red
            }
        }
    }

    let style: Style
    let title: String
    let message: String
    let footnote: String?
    let duration: TimeInterval
}

enum ErrorFeedbackStrings {
    static let accessibilityTitle = "Accessibility Permission Needed"
    static let accessibilityMessage = "Spotdark needs Accessibility access before it can listen for the launcher shortcut globally."
    static let accessibilityFootnote = "Enable Spotdark in System Settings > Privacy & Security > Accessibility, then relaunch the app."

    static let monitorFailureTitle = "Shortcut Monitor Failed"
    static let monitorFailureMessage = "Spotdark could not start listening for the launcher shortcut."
    static let monitorFailureFootnote = "Close other shortcut tools if needed, then relaunch the app to retry."
}

extension ErrorFeedbackContent {
    static let accessibilityPermissionError = ErrorFeedbackContent(
        style: .warning,
        title: ErrorFeedbackStrings.accessibilityTitle,
        message: ErrorFeedbackStrings.accessibilityMessage,
        footnote: ErrorFeedbackStrings.accessibilityFootnote,
        duration: 8
    )

    static let shortcutMonitorError = ErrorFeedbackContent(
        style: .error,
        title: ErrorFeedbackStrings.monitorFailureTitle,
        message: ErrorFeedbackStrings.monitorFailureMessage,
        footnote: ErrorFeedbackStrings.monitorFailureFootnote,
        duration: 8
    )

    static func hotKeyError(_ error: HotKeyError) -> ErrorFeedbackContent {
        switch error {
        case .accessibilityPermissionRequired:
            accessibilityPermissionError
        case .monitorRegistrationFailed:
            shortcutMonitorError
        }
    }
}
