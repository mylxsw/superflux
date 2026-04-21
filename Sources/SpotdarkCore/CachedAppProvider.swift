import Foundation

/// Simple in-process cache for expensive providers.
public final class CachedAppProvider: AppProviding {
    private let base: AppProviding
    private var cached: [AppItem]?

    public init(base: AppProviding) {
        self.base = base
    }

    public func fetchApplications() async throws -> [AppItem] {
        if let cached { return cached }
        let apps = try await base.fetchApplications()
        cached = apps
        return apps
    }

    public func invalidate() {
        cached = nil
    }
}
