import AppKit
import Foundation

/// Monitors NSPasteboard for changes and maintains a persisted history of recent text entries.
final class ClipboardHistoryStore: @unchecked Sendable {
    static let shared = ClipboardHistoryStore()

    struct Entry: Codable, Equatable, Sendable {
        let id: String
        let text: String
        let timestamp: Date

        var preview: String {
            let firstLine = text
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .components(separatedBy: .newlines)
                .first(where: { !$0.trimmingCharacters(in: .whitespaces).isEmpty }) ?? ""
            return firstLine.count > 120 ? String(firstLine.prefix(120)) + "…" : firstLine
        }
    }

    private let maxItems = 50
    private let defaultsKey = "com.spotdark.clipboardHistory"

    private let lock = NSLock()
    private var _items: [Entry] = []
    private var lastChangeCount: Int = -1
    private var timer: Timer?

    var items: [Entry] {
        lock.withLock { _items }
    }

    private init() {
        loadFromDisk()
    }

    // MARK: - Monitoring

    func startMonitoring() {
        assert(Thread.isMainThread)
        timer?.invalidate()
        lastChangeCount = NSPasteboard.general.changeCount
        timer = Timer.scheduledTimer(withTimeInterval: 0.75, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    private func checkClipboard() {
        let current = NSPasteboard.general.changeCount
        guard current != lastChangeCount else { return }
        lastChangeCount = current

        guard let text = NSPasteboard.general.string(forType: .string),
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        appendEntry(text: text)
    }

    // MARK: - Storage

    private func appendEntry(text: String) {
        lock.lock()
        defer { lock.unlock() }

        if _items.first?.text == text { return }
        _items.removeAll { $0.text == text }

        _items.insert(Entry(id: UUID().uuidString, text: text, timestamp: Date()), at: 0)

        if _items.count > maxItems {
            _items = Array(_items.prefix(maxItems))
        }

        saveToDisk()
    }

    private func saveToDisk() {
        guard let data = try? JSONEncoder().encode(_items) else { return }
        UserDefaults.standard.set(data, forKey: defaultsKey)
    }

    private func loadFromDisk() {
        guard let data = UserDefaults.standard.data(forKey: defaultsKey),
              let saved = try? JSONDecoder().decode([Entry].self, from: data) else { return }
        lock.lock()
        defer { lock.unlock() }
        _items = saved
    }
}
