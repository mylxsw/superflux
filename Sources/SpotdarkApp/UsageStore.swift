import Foundation
import SpotdarkCore

/// Persists simple usage signals for ranking.
///
/// Swift 6 Concurrency:
/// - `UsageScoring` is a nonisolated protocol used by `SearchEngine`.
/// - Therefore this type must NOT be `@MainActor`.
/// - We keep it thread-safe via a private lock.
final class UsageStore: UsageScoring {
    static let shared = UsageStore()

    private let defaults: UserDefaults
    private let countKey = "usage.app.open.count"
    private let lastLaunchKey = "usage.app.last.launch"
    private let lock = NSLock()

    private init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func recordAppLaunch(bundleURL: URL) {
        lock.lock()
        defer { lock.unlock() }

        var counts = defaults.dictionary(forKey: countKey) as? [String: Int] ?? [:]
        counts[bundleURL.path] = (counts[bundleURL.path] ?? 0) + 1
        defaults.set(counts, forKey: countKey)

        var lastLaunches = defaults.dictionary(forKey: lastLaunchKey) as? [String: TimeInterval] ?? [:]
        lastLaunches[bundleURL.path] = Date().timeIntervalSince1970
        defaults.set(lastLaunches, forKey: lastLaunchKey)
    }

    func score(forAppBundleURL url: URL) -> Int {
        lock.lock()
        defer { lock.unlock() }

        let dict = defaults.dictionary(forKey: countKey) as? [String: Int] ?? [:]
        return dict[url.path] ?? 0
    }

    func score(forCommandID id: String) -> Int {
        0
    }

    func recentApps(from availableApps: [AppItem], limit: Int) -> [AppItem] {
        lock.lock()
        defer { lock.unlock() }

        let counts = defaults.dictionary(forKey: countKey) as? [String: Int] ?? [:]
        let lastLaunches = defaults.dictionary(forKey: lastLaunchKey) as? [String: TimeInterval] ?? [:]

        let candidates = availableApps.filter { app in
            counts[app.bundleURL.path] != nil || lastLaunches[app.bundleURL.path] != nil
        }

        let sorted = candidates.sorted { lhs, rhs in
            let lhsTimestamp = lastLaunches[lhs.bundleURL.path] ?? 0
            let rhsTimestamp = lastLaunches[rhs.bundleURL.path] ?? 0
            if lhsTimestamp != rhsTimestamp {
                return lhsTimestamp > rhsTimestamp
            }

            let lhsCount = counts[lhs.bundleURL.path] ?? 0
            let rhsCount = counts[rhs.bundleURL.path] ?? 0
            if lhsCount != rhsCount {
                return lhsCount > rhsCount
            }

            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }

        return Array(sorted.prefix(limit))
    }
}
