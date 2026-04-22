import XCTest
import SpotdarkCore
@testable import SpotdarkApp

final class LauncherItemSectionBuilderTests: XCTestCase {
    func testSearchResultsGroupByTypeInStableOrder() {
        let app = SearchItem.application(
            AppItem(
                name: "Notes",
                bundleIdentifier: nil,
                bundleURL: URL(fileURLWithPath: "/Applications/Notes.app")
            )
        )
        let file = SearchItem.file(
            FileItem(
                name: "Notes.md",
                path: URL(fileURLWithPath: "/Users/demo/Documents/Notes.md"),
                contentType: nil,
                modificationDate: nil
            )
        )
        let command = SearchItem.command(
            CommandItem(id: "open-settings", title: "Open Settings", keywords: ["settings"])
        )

        let sections = LauncherItemSectionBuilder.makeSections(
            items: [command, app, file, app, command],
            isShowingRecentItems: false,
            minimumGroupedItemCount: 5
        )

        XCTAssertEqual(sections.map(\.kind), [.applications, .files, .commands])
        XCTAssertEqual(sections[0].rows.map(\.index), [1, 3])
        XCTAssertEqual(sections[1].rows.map(\.index), [2])
        XCTAssertEqual(sections[2].rows.map(\.index), [0, 4])
    }

    func testSmallResultSetsCollapseIntoSingleSection() {
        let sections = LauncherItemSectionBuilder.makeSections(
            items: [
                .application(
                    AppItem(
                        name: "Notes",
                        bundleIdentifier: nil,
                        bundleURL: URL(fileURLWithPath: "/Applications/Notes.app")
                    )
                ),
                .file(
                    FileItem(
                        name: "Notes.md",
                        path: URL(fileURLWithPath: "/Users/demo/Documents/Notes.md"),
                        contentType: nil,
                        modificationDate: nil
                    )
                )
            ],
            isShowingRecentItems: false,
            minimumGroupedItemCount: 5
        )

        XCTAssertEqual(sections.map(\.kind), [.mixed])
        XCTAssertNil(sections.first?.title)
        XCTAssertEqual(sections.first?.rows.map(\.index), [0, 1])
    }

    func testSingleTypeResultsStayCollapsedEvenAboveThreshold() {
        let sections = LauncherItemSectionBuilder.makeSections(
            items: [
                .command(CommandItem(id: "quit", title: "Quit", keywords: [])),
                .command(CommandItem(id: "settings", title: "Settings", keywords: [])),
                .command(CommandItem(id: "reload", title: "Reload", keywords: [])),
                .command(CommandItem(id: "restart", title: "Restart", keywords: [])),
                .command(CommandItem(id: "reset", title: "Reset", keywords: []))
            ],
            isShowingRecentItems: false,
            minimumGroupedItemCount: 5
        )

        XCTAssertEqual(sections.map(\.kind), [.mixed])
        XCTAssertEqual(sections.first?.rows.map(\.index), [0, 1, 2, 3, 4])
    }

    func testRecentItemsAlwaysUseRecentSection() {
        let sections = LauncherItemSectionBuilder.makeSections(
            items: [
                .application(
                    AppItem(
                        name: "Notes",
                        bundleIdentifier: nil,
                        bundleURL: URL(fileURLWithPath: "/Applications/Notes.app")
                    )
                )
            ],
            isShowingRecentItems: true
        )

        XCTAssertEqual(sections.map(\.kind), [.recent])
        XCTAssertEqual(sections.first?.title, LauncherStrings.recentSectionTitle)
    }
}
