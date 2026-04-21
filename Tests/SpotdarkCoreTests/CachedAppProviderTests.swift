import XCTest
@testable import SpotdarkCore

final class CachedAppProviderTests: XCTestCase {
    func testFirstCallFetchesFromBase() async throws {
        let base = SpyAppProvider(apps: [
            AppItem(name: "Xcode", bundleIdentifier: "com.apple.dt.Xcode",
                    bundleURL: URL(fileURLWithPath: "/Applications/Xcode.app"))
        ])
        let cached = CachedAppProvider(base: base)

        let result = try await cached.fetchApplications()

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(base.fetchCount, 1)
    }

    func testSubsequentCallsReturnCachedResultWithoutCallingBase() async throws {
        let base = SpyAppProvider(apps: [
            AppItem(name: "Xcode", bundleIdentifier: nil,
                    bundleURL: URL(fileURLWithPath: "/Applications/Xcode.app"))
        ])
        let cached = CachedAppProvider(base: base)

        _ = try await cached.fetchApplications()
        _ = try await cached.fetchApplications()
        _ = try await cached.fetchApplications()

        XCTAssertEqual(base.fetchCount, 1)
    }

    func testInvalidateForcesRefetchOnNextCall() async throws {
        let base = SpyAppProvider(apps: [
            AppItem(name: "TextEdit", bundleIdentifier: nil,
                    bundleURL: URL(fileURLWithPath: "/Applications/TextEdit.app"))
        ])
        let cached = CachedAppProvider(base: base)

        _ = try await cached.fetchApplications()
        cached.invalidate()
        _ = try await cached.fetchApplications()

        XCTAssertEqual(base.fetchCount, 2)
    }

    func testInvalidateWithoutPriorFetchDoesNotCrash() async throws {
        let base = SpyAppProvider(apps: [])
        let cached = CachedAppProvider(base: base)

        cached.invalidate()
        let result = try await cached.fetchApplications()

        XCTAssertEqual(result.count, 0)
        XCTAssertEqual(base.fetchCount, 1)
    }
}

private final class SpyAppProvider: AppProviding {
    private(set) var fetchCount = 0
    private let apps: [AppItem]

    init(apps: [AppItem]) {
        self.apps = apps
    }

    func fetchApplications() throws -> [AppItem] {
        fetchCount += 1
        return apps
    }
}
