import AppKit
import IOKit.ps
import SpotdarkCore

final class SystemInfoPlugin: SearchSourcePlugin, @unchecked Sendable {
    let pluginID = "com.spotdark.system-info"
    let displayName = "System Info"

    private let keywords: [(keyword: String, id: String, provider: () -> (title: String, value: String)?)] = [
        ("ip", "ip-address", { SystemInfoPlugin.ipAddress() }),
        ("battery", "battery-level", { SystemInfoPlugin.batteryLevel() }),
        ("hostname", "hostname", { SystemInfoPlugin.hostname() }),
        ("os", "os-version", { SystemInfoPlugin.osVersion() }),
        ("macos", "os-version", { SystemInfoPlugin.osVersion() }),
        ("uptime", "uptime", { SystemInfoPlugin.uptime() }),
    ]

    func search(query: String) -> [PluginSearchResult] {
        let lower = query.lowercased()
        guard lower.count >= 2 else { return [] }

        var seen = Set<String>()
        var results: [PluginSearchResult] = []

        for entry in keywords {
            guard entry.keyword.contains(lower) || lower.contains(entry.keyword) else { continue }
            guard seen.insert(entry.id).inserted else { continue }
            guard let info = entry.provider() else { continue }

            let score = entry.keyword.hasPrefix(lower) ? 0 : 2
            let item = PluginResultItem(
                pluginID: pluginID,
                id: entry.id,
                title: info.title,
                subtitle: info.value,
                iconSystemName: iconName(for: entry.id),
                actionPayload: info.value
            )
            results.append(PluginSearchResult(item: item, score: score))
        }
        return results
    }

    func perform(item: PluginResultItem) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(item.actionPayload, forType: .string)
    }

    private func iconName(for id: String) -> String {
        switch id {
        case "ip-address": return "network"
        case "battery-level": return "battery.100"
        case "hostname": return "desktopcomputer"
        case "os-version": return "apple.logo"
        case "uptime": return "clock"
        default: return "info.circle"
        }
    }

    private static func ipAddress() -> (title: String, value: String)? {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let first = ifaddr else { return nil }
        defer { freeifaddrs(ifaddr) }

        for ptr in sequence(first: first, next: { $0.pointee.ifa_next }) {
            let flags = Int32(ptr.pointee.ifa_flags)
            let addr = ptr.pointee.ifa_addr.pointee
            guard (flags & (IFF_UP | IFF_RUNNING)) != 0, !(flags & IFF_LOOPBACK != 0) else { continue }
            guard addr.sa_family == UInt8(AF_INET) else { continue }
            var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            if getnameinfo(ptr.pointee.ifa_addr, socklen_t(addr.sa_len),
                           &hostname, socklen_t(hostname.count), nil, 0, NI_NUMERICHOST) == 0 {
                let ip = String(cString: hostname)
                return ("IP Address", ip)
            }
        }
        return nil
    }

    private static func batteryLevel() -> (title: String, value: String)? {
        let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue()
        let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef] ?? []
        for source in sources {
            guard let desc = IOPSGetPowerSourceDescription(snapshot, source)?.takeUnretainedValue() as? [String: Any],
                  let capacity = desc[kIOPSCurrentCapacityKey] as? Int,
                  let max = desc[kIOPSMaxCapacityKey] as? Int, max > 0 else { continue }
            let pct = (capacity * 100) / max
            let charging = (desc[kIOPSIsChargingKey] as? Bool) == true
            let status = charging ? " (Charging)" : ""
            return ("Battery", "\(pct)%\(status)")
        }
        return nil
    }

    private static func hostname() -> (title: String, value: String)? {
        ("Hostname", ProcessInfo.processInfo.hostName)
    }

    private static func osVersion() -> (title: String, value: String)? {
        let v = ProcessInfo.processInfo.operatingSystemVersion
        return ("macOS Version", "\(v.majorVersion).\(v.minorVersion).\(v.patchVersion)")
    }

    private static func uptime() -> (title: String, value: String)? {
        let seconds = ProcessInfo.processInfo.systemUptime
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        if hours > 24 {
            let days = hours / 24
            let remainingHours = hours % 24
            return ("Uptime", "\(days)d \(remainingHours)h \(minutes)m")
        }
        return ("Uptime", "\(hours)h \(minutes)m")
    }
}
