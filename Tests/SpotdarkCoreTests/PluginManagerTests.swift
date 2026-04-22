import Foundation
import Testing
@testable import SpotdarkCore

private final class StubSearchSource: SearchSourcePlugin, @unchecked Sendable {
    let pluginID: String
    let displayName: String
    var searchResults: [PluginSearchResult] = []
    var performedItems: [PluginResultItem] = []

    init(pluginID: String, displayName: String = "Stub") {
        self.pluginID = pluginID
        self.displayName = displayName
    }

    func search(query: String) -> [PluginSearchResult] { searchResults }
    func perform(item: PluginResultItem) { performedItems.append(item) }
}

private final class StubActionPlugin: ActionPlugin, @unchecked Sendable {
    let pluginID: String
    let displayName: String
    let commandItems: [CommandItem]
    var handledCommandIDs: [String] = []

    init(pluginID: String, displayName: String = "Stub", commands: [CommandItem] = []) {
        self.pluginID = pluginID
        self.displayName = displayName
        self.commandItems = commands
    }

    func commands() -> [CommandItem] { commandItems }
    func handle(commandID: String) { handledCommandIDs.append(commandID) }
}

private final class Counter: Sendable {
    private let lock = NSLock()
    private var _value = 0
    var value: Int { lock.withLock { _value } }
    func increment() { lock.withLock { _value += 1 } }
}

@Suite("PluginManager")
struct PluginManagerTests {

    @Test("Register and retrieve search source")
    func registerSearchSource() {
        let manager = PluginManager.shared
        let plugin = StubSearchSource(pluginID: "test.search.\(UUID())")
        defer { manager.unregister(pluginID: plugin.pluginID) }

        let registered = manager.register(searchSource: plugin)
        #expect(registered)
        #expect(manager.searchSource(for: plugin.pluginID) === plugin)
    }

    @Test("Duplicate search source registration returns false")
    func duplicateSearchSource() {
        let manager = PluginManager.shared
        let plugin = StubSearchSource(pluginID: "test.dup.\(UUID())")
        defer { manager.unregister(pluginID: plugin.pluginID) }

        #expect(manager.register(searchSource: plugin))
        #expect(!manager.register(searchSource: plugin))
    }

    @Test("Register and retrieve action plugin")
    func registerActionPlugin() {
        let manager = PluginManager.shared
        let cmd = CommandItem(id: "test-cmd-\(UUID())", title: "Test", keywords: [])
        let plugin = StubActionPlugin(pluginID: "test.action.\(UUID())", commands: [cmd])
        defer { manager.unregister(pluginID: plugin.pluginID) }

        #expect(manager.register(action: plugin))
        #expect(manager.actionPlugin(for: cmd.id) === plugin)
    }

    @Test("Unregister removes plugin")
    func unregister() {
        let manager = PluginManager.shared
        let plugin = StubSearchSource(pluginID: "test.unreg.\(UUID())")

        manager.register(searchSource: plugin)
        manager.unregister(pluginID: plugin.pluginID)
        #expect(manager.searchSource(for: plugin.pluginID) == nil)
    }

    @Test("onChange fires on registration and unregistration")
    func onChangeCallback() {
        let manager = PluginManager.shared
        let counter = Counter()
        let previousOnChange = manager.onChange
        manager.onChange = { counter.increment() }

        let plugin = StubSearchSource(pluginID: "test.change.\(UUID())")
        manager.register(searchSource: plugin)
        let afterRegister = counter.value
        manager.unregister(pluginID: plugin.pluginID)
        let afterUnregister = counter.value

        manager.onChange = previousOnChange

        #expect(afterRegister >= 1)
        #expect(afterUnregister >= afterRegister + 1)
    }

    @Test("Plugin result item round-trips through SearchItem")
    func pluginSearchItemCase() {
        let resultItem = PluginResultItem(
            pluginID: "test",
            id: "r1",
            title: "Hello",
            subtitle: "World",
            iconSystemName: "star",
            actionPayload: "payload"
        )
        let searchItem = SearchItem.plugin(resultItem)
        if case .plugin(let extracted) = searchItem {
            #expect(extracted == resultItem)
        } else {
            Issue.record("Expected .plugin case")
        }
    }
}
