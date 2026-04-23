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

    func testFallbackTextInputUpdatesQueryBeforeFieldFocus() async throws {
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

        store.insertTextInput("n")

        XCTAssertEqual(store.query, "n")
        XCTAssertTrue(store.isShowingExpandedContent)
    }

    func testMoveSelectionNavigatesAcrossSectionsInVisualOrder() async throws {
        // Query must be >= 2 chars to trigger the file search task.
        // Search results are now displayed as one unified, already-ranked list.
        let store = LauncherStore(
            commandProvider: CommandRegistry(),
            indexStream: StubAppIndexStream(items: [
                .initial([
                    IndexedApplication(bundleURL: URL(fileURLWithPath: "/Applications/SafariApp.app")),
                    IndexedApplication(bundleURL: URL(fileURLWithPath: "/Applications/SafeEdit.app")),
                    IndexedApplication(bundleURL: URL(fileURLWithPath: "/Applications/SafeGuard.app")),
                ])
            ]),
            fileSearchProvider: StubFileSearchProvider(items: [
                FileItem(name: "safe.html", path: URL(fileURLWithPath: "/tmp/safe.html"), contentType: nil, modificationDate: nil),
                FileItem(name: "safe.css",  path: URL(fileURLWithPath: "/tmp/safe.css"),  contentType: nil, modificationDate: nil),
                FileItem(name: "safe.js",   path: URL(fileURLWithPath: "/tmp/safe.js"),   contentType: nil, modificationDate: nil),
                FileItem(name: "safe.txt",  path: URL(fileURLWithPath: "/tmp/safe.txt"),  contentType: nil, modificationDate: nil),
            ]),
            recentItemsProvider: { _ in [] }
        )

        try await waitUntil { !store.isInitialIndexing }

        store.query = "sa"   // length >= 2 triggers file search

        try await waitUntil {
            store.isShowingResults && store.displayedItems.count == 7
        }

        XCTAssertEqual(store.displayedSections.map(\.kind), [.mixed])

        // selectedIndex starts at 0; step through every item via moveSelection
        let totalItems = store.displayedItems.count
        var visitedFlatIndices: [Int] = [store.selectedIndex]

        for _ in 1..<totalItems {
            store.moveSelection(delta: 1)
            visitedFlatIndices.append(store.selectedIndex)
        }

        // Every flat index must be visited exactly once
        XCTAssertEqual(Set(visitedFlatIndices).count, totalItems, "Each item should be visited exactly once")
        XCTAssertEqual(visitedFlatIndices.count, totalItems)

        // Pressing down at the end should clamp (not wrap)
        let lastIndex = store.selectedIndex
        store.moveSelection(delta: 1)
        XCTAssertEqual(store.selectedIndex, lastIndex, "Selection should clamp at the last item")

        // Navigate back to the beginning; every item should be visited again
        var reverseIndices: [Int] = [store.selectedIndex]
        for _ in 1..<totalItems {
            store.moveSelection(delta: -1)
            reverseIndices.append(store.selectedIndex)
        }
        XCTAssertEqual(Set(reverseIndices).count, totalItems)
    }

    func testFileResultsCanRankAheadOfApplicationsByNameMatch() async throws {
        let store = LauncherStore(
            commandProvider: CommandRegistry(),
            indexStream: StubAppIndexStream(items: [
                .initial([
                    IndexedApplication(bundleURL: URL(fileURLWithPath: "/Applications/My Safe App.app"))
                ])
            ]),
            fileSearchProvider: StubFileSearchProvider(items: [
                FileItem(name: "safe.txt", path: URL(fileURLWithPath: "/tmp/safe.txt"), contentType: nil, modificationDate: nil)
            ]),
            recentItemsProvider: { _ in [] }
        )

        try await waitUntil { !store.isInitialIndexing }

        store.query = "safe"

        try await waitUntil {
            store.displayedItems.count == 2
        }

        XCTAssertEqual(store.displayedSections.map(\.kind), [.mixed])
        guard case .file(let file) = store.displayedItems.first else {
            return XCTFail("Expected prefix-matching file result to rank before word-boundary application match")
        }
        XCTAssertEqual(file.name, "safe.txt")
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

private struct StubFileSearchProvider: FileSearchProviding {
    let items: [FileItem]

    func search(query: String) -> AsyncStream<[FileItem]> {
        let items = self.items
        return AsyncStream { continuation in
            continuation.yield(items)
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
