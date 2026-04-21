import Foundation

/// A minimal interface to make Metadata-based indexing unit-testable.
public protocol MetadataQuerying {
    /// Returns application bundle URLs discovered by the query.
    func fetchApplicationBundleURLs() async throws -> [URL]
}

/// Production implementation using NSMetadataQuery (Spotlight index).
///
/// This is closer to how Spotlight finds apps than directory scanning.
public final class SpotlightMetadataQuery: MetadataQuerying {
    public init() {}

    public func fetchApplicationBundleURLs() async throws -> [URL] {
        // NSMetadataQuery requires a run-loop thread; dispatch to main and bridge via continuation.
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.main.async {
                // Box holds query + observer token so they can reference each other in the callback.
                final class Box: @unchecked Sendable {
                    let query = NSMetadataQuery()
                    var token: NSObjectProtocol?
                }
                let box = Box()
                box.query.predicate = NSPredicate(
                    format: "kMDItemContentType == 'com.apple.application-bundle'"
                )
                box.query.searchScopes = [NSMetadataQueryLocalComputerScope]

                box.token = NotificationCenter.default.addObserver(
                    forName: .NSMetadataQueryDidFinishGathering,
                    object: box.query,
                    queue: .main
                ) { _ in
                    box.query.disableUpdates()
                    box.query.stop()
                    if let token = box.token {
                        NotificationCenter.default.removeObserver(token)
                    }

                    let urls: [URL] = (0 ..< box.query.resultCount).compactMap { idx in
                        (box.query.result(at: idx) as? NSMetadataItem)?
                            .value(forAttribute: kMDItemPath as String) as? String
                    }.map { URL(fileURLWithPath: $0) }

                    continuation.resume(returning: urls)
                }

                box.query.start()
            }
        }
    }
}

/// App provider backed by Spotlight metadata.
public final class MetadataAppProvider: AppProviding {
    private let query: MetadataQuerying

    public init(query: MetadataQuerying = SpotlightMetadataQuery()) {
        self.query = query
    }

    public func fetchApplications() async throws -> [AppItem] {
        let urls = try await query.fetchApplicationBundleURLs()
        var items: [AppItem] = []
        items.reserveCapacity(urls.count)

        for url in urls where url.pathExtension.lowercased() == "app" {
            let name = url.deletingPathExtension().lastPathComponent
            items.append(AppItem(name: name, bundleIdentifier: nil, bundleURL: url))
        }

        // Deduplicate and sort.
        let unique = Array(Set(items))
        return unique.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
}
