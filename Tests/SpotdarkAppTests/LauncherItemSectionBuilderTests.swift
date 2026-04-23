import XCTest
import SpotdarkCore
@testable import SpotdarkApp

final class LauncherItemSectionBuilderTests: XCTestCase {
    func testSearchResultsUseSingleUnifiedSectionInInputOrder() {
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

        XCTAssertEqual(sections.map(\.kind), [.mixed])
        XCTAssertNil(sections.first?.title)
        XCTAssertEqual(sections[0].rows.map(\.index), [0, 1, 2, 3, 4])
    }

    func testSmallResultSetsUseSingleUnifiedSection() {
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
        XCTAssertEqual(sections[0].rows.map(\.index), [0, 1])
    }

    func testSingleTypeResultsUseSingleUnifiedSection() {
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

    func testUnifiedSectionCanContainAllSearchableItemTypes() {
        let app = SearchItem.application(
            AppItem(name: "Notes", bundleIdentifier: nil, bundleURL: URL(fileURLWithPath: "/Applications/Notes.app"))
        )
        let file = SearchItem.file(
            FileItem(name: "notes.txt", path: URL(fileURLWithPath: "/Users/demo/notes.txt"), contentType: nil, modificationDate: nil)
        )
        let command = SearchItem.command(CommandItem(id: "open-settings", title: "Open Settings", keywords: []))
        let plugin = SearchItem.plugin(PluginResultItem(pluginID: "test.plugin", id: "copy", title: "Copy"))

        let sections = LauncherItemSectionBuilder.makeSections(
            items: [file, app, plugin, command, app, file],
            isShowingRecentItems: false,
            minimumGroupedItemCount: 5
        )

        XCTAssertEqual(sections.map(\.kind), [.mixed])
        XCTAssertEqual(sections[0].rows.map(\.index), [0, 1, 2, 3, 4, 5])
    }

    func testVisualRowOrderFollowsUnifiedResultOrder() {
        let app = SearchItem.application(
            AppItem(name: "Notes", bundleIdentifier: nil, bundleURL: URL(fileURLWithPath: "/Applications/Notes.app"))
        )
        let file = SearchItem.file(
            FileItem(name: "notes.txt", path: URL(fileURLWithPath: "/Users/demo/notes.txt"), contentType: nil, modificationDate: nil)
        )
        let command = SearchItem.command(CommandItem(id: "open-settings", title: "Open Settings", keywords: []))

        // Items are interleaved: command(0), app(1), file(2), app(3), command(4)
        // The unified section preserves the already-ranked result order.
        let sections = LauncherItemSectionBuilder.makeSections(
            items: [command, app, file, app, command],
            isShowingRecentItems: false,
            minimumGroupedItemCount: 5
        )

        let visualOrder = sections.flatMap(\.rows).map(\.index)
        XCTAssertEqual(visualOrder, [0, 1, 2, 3, 4])
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
