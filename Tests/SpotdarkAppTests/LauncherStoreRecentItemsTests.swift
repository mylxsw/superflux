import XCTest
import SpotdarkCore
@testable import SpotdarkApp

@MainActor
final class LauncherStoreRecentItemsTests: XCTestCase {
    func testEmptyQueryKeepsPanelCollapsedEvenWithRecentItemsAvailable() async throws {
        let store = LauncherStore(
            commandProvider: CommandRegistry(),
            indexStream: StubAppIndexStream(
                items: [
                    .initial([
                        IndexedApplication(bundleURL: URL(fileURLWithPath: "/Applications/Notes.app"))
                    ])
                ]
            ),
            fileSearchProvider: EmptyFileSearchProvider(),
            recentItemsProvider: { _ in
                [
                    .application(AppItem(
                        name: "Notes",
                        bundleIdentifier: nil,
                        bundleURL: URL(fileURLWithPath: "/Applications/Notes.app")
                    ))
                ]
            }
        )

        try await waitUntil {
            !store.isInitialIndexing
        }

        XCTAssertFalse(store.isShowingRecentItems)
        XCTAssertFalse(store.isShowingExpandedContent)
        XCTAssertTrue(store.displayedItems.isEmpty)
        XCTAssertEqual(store.preferredPanelHeight, LauncherPanelMetrics.collapsedHeight)
    }

    func testTypingQueryShowsSearchResultsFromCollapsedState() async throws {
        let store = LauncherStore(
            commandProvider: CommandRegistry(),
            indexStream: StubAppIndexStream(
                items: [
                    .initial([
                        IndexedApplication(bundleURL: URL(fileURLWithPath: "/Applications/Notes.app")),
                        IndexedApplication(bundleURL: URL(fileURLWithPath: "/Applications/TextEdit.app"))
                    ])
                ]
            ),
            fileSearchProvider: EmptyFileSearchProvider(),
            recentItemsProvider: { _ in
                [
                    .application(AppItem(
                        name: "Notes",
                        bundleIdentifier: nil,
                        bundleURL: URL(fileURLWithPath: "/Applications/Notes.app")
                    ))
                ]
            }
        )

        try await waitUntil {
            !store.isInitialIndexing
        }

        store.query = "text"

        try await waitUntil {
            !store.isShowingRecentItems
                && store.isShowingResults
                && store.displayedItems.count == 1
        }

        XCTAssertFalse(store.isShowingRecentItems)
        XCTAssertTrue(store.isShowingExpandedContent)
        XCTAssertEqual(store.displayedItems.count, 1)
    }

    func testClearingQueryWithoutRecentItemsCollapsesPanel() async throws {
        let store = LauncherStore(
            commandProvider: CommandRegistry(),
            indexStream: StubAppIndexStream(
                items: [
                    .initial([
                        IndexedApplication(bundleURL: URL(fileURLWithPath: "/Applications/Notes.app"))
                    ])
                ]
            ),
            fileSearchProvider: EmptyFileSearchProvider(),
            recentItemsProvider: { _ in [] }
        )

        try await waitUntil {
            !store.isInitialIndexing
        }

        XCTAssertEqual(store.preferredPanelHeight, LauncherPanelMetrics.collapsedHeight)
        XCTAssertFalse(store.isShowingExpandedContent)

        store.query = "note"

        try await waitUntil {
            store.isShowingResults && store.preferredPanelHeight == LauncherPanelMetrics.expandedHeight
        }

        XCTAssertEqual(store.preferredPanelHeight, LauncherPanelMetrics.expandedHeight)

        store.query = ""

        try await waitUntil {
            !store.isShowingExpandedContent
                && store.preferredPanelHeight == LauncherPanelMetrics.collapsedHeight
        }

        XCTAssertEqual(store.preferredPanelHeight, LauncherPanelMetrics.collapsedHeight)
        XCTAssertFalse(store.isShowingExpandedContent)
    }
}

private struct StubAppIndexStream: AppIndexStreaming {
    let items: [AppIndexDelta]

    func deltas() -> AsyncStream<AppIndexDelta> {
        AsyncStream { continuation in
            for delta in items {
                continuation.yield(delta)
            }
            continuation.finish()
        }
    }
}

private struct EmptyFileSearchProvider: FileSearchProviding {
    func search(query: String) -> AsyncStream<[FileItem]> {
        AsyncStream { continuation in
            continuation.yield([])
            continuation.finish()
        }
    }
}

@MainActor
private func waitUntil(
    attempts: Int = 100,
    sleepNanoseconds: UInt64 = 10_000_000,
    condition: @escaping () -> Bool
) async throws {
    for _ in 0..<attempts {
        if condition() {
            return
        }

        try await Task.sleep(nanoseconds: sleepNanoseconds)
    }

    XCTFail("Condition was not met before timeout")
}
