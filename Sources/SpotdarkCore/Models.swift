import Foundation

/// A unified search item.
public enum SearchItem: Equatable {
    case application(AppItem)
    case command(CommandItem)
    case file(FileItem)
    case calculator(CalculatorItem)
    case webSearch(WebSearchItem)
    case plugin(PluginResultItem)
}

/// Represents a web search action that opens the query in the default browser.
public struct WebSearchItem: Equatable, Hashable, Sendable {
    public let query: String
    public let engine: WebSearchEngine
    public let url: URL

    public init(query: String, engine: WebSearchEngine, url: URL) {
        self.query = query
        self.engine = engine
        self.url = url
    }
}

/// Supported web search engines.
public enum WebSearchEngine: String, CaseIterable, Sendable {
    case google
    case bing
    case baidu

    public var displayName: String {
        switch self {
        case .google: return "Google"
        case .bing:   return "Bing"
        case .baidu:  return "百度"
        }
    }

    public func searchURL(for query: String) -> URL? {
        guard let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return nil }
        let urlString: String
        switch self {
        case .google: urlString = "https://www.google.com/search?q=\(encoded)"
        case .bing:   urlString = "https://www.bing.com/search?q=\(encoded)"
        case .baidu:  urlString = "https://www.baidu.com/s?wd=\(encoded)"
        }
        return URL(string: urlString)
    }
}

/// Represents a macOS application bundle that can be launched.
public struct AppItem: Equatable, Hashable {
    public let name: String
    public let bundleIdentifier: String?
    public let bundleURL: URL

    public init(name: String, bundleIdentifier: String?, bundleURL: URL) {
        self.name = name
        self.bundleIdentifier = bundleIdentifier
        self.bundleURL = bundleURL
    }
}

/// Represents an executable command (not a shell command, but an in-app action).
public struct CommandItem: Equatable, Hashable {
    public let id: String
    public let title: String
    public let keywords: [String]

    public init(id: String, title: String, keywords: [String]) {
        self.id = id
        self.title = title
        self.keywords = keywords
    }
}

/// Represents a file or document found by Spotlight.
public struct FileItem: Equatable, Hashable, Sendable {
    public let name: String
    public let path: URL
    public let contentType: String?
    public let modificationDate: Date?

    public init(name: String, path: URL, contentType: String?, modificationDate: Date?) {
        self.name = name
        self.path = path
        self.contentType = contentType
        self.modificationDate = modificationDate
    }
}
