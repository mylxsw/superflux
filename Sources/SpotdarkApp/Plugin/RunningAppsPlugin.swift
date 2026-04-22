import AppKit
import CoreGraphics
import SpotdarkCore

/// Shows running applications when the query starts with ">", allowing fast focus switching.
final class RunningAppsPlugin: SearchSourcePlugin, @unchecked Sendable {
    let pluginID = "com.spotdark.running-apps"
    let displayName = "Running Apps"

    private static let prefix = ">"

    func search(query: String) -> [PluginSearchResult] {
        guard query.hasPrefix(Self.prefix) else { return [] }
        let appQuery = query.dropFirst().trimmingCharacters(in: .whitespaces).lowercased()

        let windowCounts = Self.windowCountsByPID()

        return NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular }
            .compactMap { app -> PluginSearchResult? in
                guard let name = app.localizedName, !name.isEmpty else { return nil }
                let lower = name.lowercased()

                let score: Int
                if appQuery.isEmpty {
                    score = 1
                } else if lower.hasPrefix(appQuery) {
                    score = 0
                } else if lower.contains(appQuery) {
                    score = 2
                } else {
                    return nil
                }

                let pid = app.processIdentifier
                let count = windowCounts[pid] ?? 0
                let windowLabel = count == 1 ? "1 window" : "\(count) windows"

                let item = PluginResultItem(
                    pluginID: pluginID,
                    id: "running-\(pid)",
                    title: name,
                    subtitle: windowLabel,
                    iconBundleURL: app.bundleURL,
                    actionPayload: "\(pid)"
                )
                return PluginSearchResult(item: item, score: score)
            }
            .sorted { $0.score < $1.score }
    }

    func perform(item: PluginResultItem) {
        guard let pid = pid_t(item.actionPayload),
              let app = NSRunningApplication(processIdentifier: pid) else { return }
        app.activate(options: [.activateAllWindows])
    }

    private static func windowCountsByPID() -> [pid_t: Int] {
        guard let list = CGWindowListCopyWindowInfo(
            [.optionOnScreenOnly, .excludeDesktopElements],
            kCGNullWindowID
        ) as? [[CFString: Any]] else { return [:] }

        var counts: [pid_t: Int] = [:]
        for info in list {
            guard let pid = info[kCGWindowOwnerPID] as? pid_t,
                  let layer = info[kCGWindowLayer] as? Int,
                  layer == 0 else { continue }
            counts[pid, default: 0] += 1
        }
        return counts
    }
}
