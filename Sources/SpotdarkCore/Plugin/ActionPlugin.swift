import Foundation

public protocol ActionPlugin: AnyObject, Sendable {
    var pluginID: String { get }
    var displayName: String { get }

    func commands() -> [CommandItem]
    func handle(commandID: String)
}
