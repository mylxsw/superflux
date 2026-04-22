import Foundation

public struct PluginSearchResult: Sendable {
    public let item: PluginResultItem
    public let score: Int

    public init(item: PluginResultItem, score: Int) {
        self.item = item
        self.score = score
    }
}

public protocol SearchSourcePlugin: AnyObject, Sendable {
    var pluginID: String { get }
    var displayName: String { get }

    func search(query: String) -> [PluginSearchResult]
    func perform(item: PluginResultItem)
}
