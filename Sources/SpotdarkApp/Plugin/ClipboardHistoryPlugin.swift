import AppKit
import CoreGraphics
import SpotdarkCore

/// SearchSourcePlugin that surfaces clipboard history entries and pastes the selection.
final class ClipboardHistoryPlugin: SearchSourcePlugin, @unchecked Sendable {
    let pluginID = "com.spotdark.clipboard-history"
    let displayName = "Clipboard History"

    private let store = ClipboardHistoryStore.shared

    // MARK: - SearchSourcePlugin

    func search(query: String) -> [PluginSearchResult] {
        let lower = query.lowercased()
        guard lower.count >= 2 else { return [] }

        var results: [PluginSearchResult] = []

        for entry in store.items {
            let entryLower = entry.text.lowercased()

            let score: Int
            if entryLower.hasPrefix(lower) {
                score = 0
            } else if entryLower.contains(lower) {
                score = 2
            } else {
                continue
            }

            let item = PluginResultItem(
                pluginID: pluginID,
                id: entry.id,
                title: entry.preview,
                subtitle: "Clipboard History",
                iconSystemName: "doc.on.clipboard",
                actionPayload: entry.text
            )
            results.append(PluginSearchResult(item: item, score: score))

            if results.count >= 5 { break }
        }

        return results
    }

    func perform(item: PluginResultItem) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(item.actionPayload, forType: .string)

        // Post Cmd+V after the panel dismissal animation (~0.15s) completes.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            Self.postPasteEvent()
        }
    }

    // MARK: - CGEvent paste

    private static func postPasteEvent() {
        let source = CGEventSource(stateID: .hidSystemState)
        let vKey: CGKeyCode = 0x09 // 'v'

        guard let down = CGEvent(keyboardEventSource: source, virtualKey: vKey, keyDown: true),
              let up = CGEvent(keyboardEventSource: source, virtualKey: vKey, keyDown: false) else { return }

        down.flags = .maskCommand
        up.flags = .maskCommand
        down.post(tap: .cghidEventTap)
        up.post(tap: .cghidEventTap)
    }
}
