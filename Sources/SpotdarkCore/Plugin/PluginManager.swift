import Foundation

public final class PluginManager: @unchecked Sendable {
    public static let shared = PluginManager()

    private let lock = NSLock()
    private var searchSources_: [SearchSourcePlugin] = []
    private var actionPlugins_: [ActionPlugin] = []
    private var onChange_: (@Sendable () -> Void)?

    public var onChange: (@Sendable () -> Void)? {
        get { lock.withLock { onChange_ } }
        set { lock.withLock { onChange_ = newValue } }
    }

    private init() {}

    @discardableResult
    public func register(searchSource: SearchSourcePlugin) -> Bool {
        let notify: Bool = lock.withLock {
            guard !searchSources_.contains(where: { $0.pluginID == searchSource.pluginID }) else {
                return false
            }
            searchSources_.append(searchSource)
            return true
        }
        if notify { onChange_?() }
        return notify
    }

    @discardableResult
    public func register(action: ActionPlugin) -> Bool {
        let notify: Bool = lock.withLock {
            guard !actionPlugins_.contains(where: { $0.pluginID == action.pluginID }) else {
                return false
            }
            actionPlugins_.append(action)
            return true
        }
        if notify { onChange_?() }
        return notify
    }

    public func unregister(pluginID: String) {
        var changed = false
        lock.withLock {
            let beforeSearch = searchSources_.count
            let beforeAction = actionPlugins_.count
            searchSources_.removeAll { $0.pluginID == pluginID }
            actionPlugins_.removeAll { $0.pluginID == pluginID }
            changed = searchSources_.count != beforeSearch || actionPlugins_.count != beforeAction
        }
        if changed { onChange_?() }
    }

    public func searchSources() -> [SearchSourcePlugin] {
        lock.withLock { searchSources_ }
    }

    public func actionPlugins() -> [ActionPlugin] {
        lock.withLock { actionPlugins_ }
    }

    public func searchSource(for pluginID: String) -> SearchSourcePlugin? {
        lock.withLock { searchSources_.first { $0.pluginID == pluginID } }
    }

    public func actionPlugin(for commandID: String) -> ActionPlugin? {
        lock.withLock {
            actionPlugins_.first { plugin in
                plugin.commands().contains { $0.id == commandID }
            }
        }
    }
}
