import Foundation
import SpotdarkCore

@Observable
@MainActor
final class PinnedItemsStore {
    static let shared = PinnedItemsStore()

    private(set) var pinnedIDs: Set<String> = []

    private let defaults: UserDefaults
    private let key = "spotdark.pinnedItems"

    private init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        pinnedIDs = Set(defaults.stringArray(forKey: key) ?? [])
    }

    func pin(_ item: SearchItem) {
        guard let id = stableID(for: item) else { return }
        pinnedIDs.insert(id)
        persist()
    }

    func unpin(_ item: SearchItem) {
        guard let id = stableID(for: item) else { return }
        pinnedIDs.remove(id)
        persist()
    }

    func isPinned(_ item: SearchItem) -> Bool {
        guard let id = stableID(for: item) else { return false }
        return pinnedIDs.contains(id)
    }

    private func persist() {
        defaults.set(Array(pinnedIDs), forKey: key)
    }
}

func stableID(for item: SearchItem) -> String? {
    switch item {
    case .application(let app): return "app:\(app.bundleURL.path)"
    case .file(let file):       return "file:\(file.path.path)"
    case .command(let cmd):     return "cmd:\(cmd.id)"
    case .calculator, .webSearch, .plugin: return nil
    }
}
