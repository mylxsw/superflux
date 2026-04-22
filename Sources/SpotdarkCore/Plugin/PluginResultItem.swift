import Foundation

public struct PluginResultItem: Equatable, Hashable, Sendable {
    public let pluginID: String
    public let id: String
    public let title: String
    public let subtitle: String?
    public let iconSystemName: String?
    /// When set, the UI uses this bundle URL to load the actual application icon instead of an SF Symbol.
    public let iconBundleURL: URL?
    public let actionPayload: String

    public init(
        pluginID: String,
        id: String,
        title: String,
        subtitle: String? = nil,
        iconSystemName: String? = nil,
        iconBundleURL: URL? = nil,
        actionPayload: String = ""
    ) {
        self.pluginID = pluginID
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.iconSystemName = iconSystemName
        self.iconBundleURL = iconBundleURL
        self.actionPayload = actionPayload
    }
}
