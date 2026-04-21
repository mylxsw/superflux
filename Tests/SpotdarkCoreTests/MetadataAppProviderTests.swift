import XCTest
@testable import SpotdarkCore

final class MetadataAppProviderTests: XCTestCase {
    func testMetadataAppProviderBuildsItemsFromURLs() async throws {
        let fake = FakeMetadataQuery(urls: [
            URL(fileURLWithPath: "/Applications/Safari.app"),
            URL(fileURLWithPath: "/System/Applications/Mail.app"),
            URL(fileURLWithPath: "/Applications/NotAnApp.txt")
        ])

        let provider = MetadataAppProvider(query: fake)
        let apps = try await provider.fetchApplications()

        XCTAssertEqual(Set(apps.map { $0.name }), Set(["Safari", "Mail"]))
    }

    func testMetadataAppProviderDeduplicatesDuplicateURLs() async throws {
        let url = URL(fileURLWithPath: "/Applications/Duplicate.app")
        let fake = FakeMetadataQuery(urls: [url, url])

        let provider = MetadataAppProvider(query: fake)
        let apps = try await provider.fetchApplications()

        XCTAssertEqual(apps.count, 1)
        XCTAssertEqual(apps.first?.name, "Duplicate")
    }

    func testMetadataAppProviderReturnsSortedResults() async throws {
        let fake = FakeMetadataQuery(urls: [
            URL(fileURLWithPath: "/Applications/Zoom.app"),
            URL(fileURLWithPath: "/Applications/Arc.app"),
            URL(fileURLWithPath: "/Applications/Mail.app")
        ])

        let provider = MetadataAppProvider(query: fake)
        let apps = try await provider.fetchApplications()

        XCTAssertEqual(apps.map { $0.name }, ["Arc", "Mail", "Zoom"])
    }

    func testMetadataAppProviderReturnsEmptyForNoApps() async throws {
        let provider = MetadataAppProvider(query: FakeMetadataQuery(urls: []))
        let apps = try await provider.fetchApplications()
        XCTAssertTrue(apps.isEmpty)
    }

    private struct FakeMetadataQuery: MetadataQuerying {
        let urls: [URL]
        func fetchApplicationBundleURLs() async throws -> [URL] { urls }
    }
}
