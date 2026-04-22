import XCTest
@testable import SpotdarkCore

final class SearchEngineTests: XCTestCase {
    func testUsageBoostAffectsRankingWhenMatchScoreEqual() {
        let appA = AppItem(name: "Alpha", bundleIdentifier: nil, bundleURL: URL(fileURLWithPath: "/Applications/Alpha.app"))
        let appB = AppItem(name: "Alpine", bundleIdentifier: nil, bundleURL: URL(fileURLWithPath: "/Applications/Alpine.app"))

        struct Usage: UsageScoring {
            func score(forAppBundleURL url: URL) -> Int { url.lastPathComponent == "Alpine.app" ? 100 : 0 }
            func score(forCommandID id: String) -> Int { 0 }
        }

        let engine = SearchEngine(apps: [appA, appB], commands: [], usage: Usage())
        // Both are prefix matches for "al" (same match score), so usage should decide.
        let results = engine.search(query: "al")
        XCTAssertEqual(results.first, .application(appB))
    }

    func testSearchReturnsEmptyForBlankQuery() {
        let engine = SearchEngine(apps: [], commands: [])
        XCTAssertEqual(engine.search(query: ""), [])
        XCTAssertEqual(engine.search(query: "   "), [])
    }

    func testAppPrefixMatchRanksHigherThanSubstring() {
        let apps = [
            AppItem(name: "Safari", bundleIdentifier: "com.apple.Safari", bundleURL: URL(fileURLWithPath: "/Applications/Safari.app")),
            AppItem(name: "Google Chrome", bundleIdentifier: "com.google.Chrome", bundleURL: URL(fileURLWithPath: "/Applications/Google Chrome.app"))
        ]
        let engine = SearchEngine(apps: apps, commands: [])
        let results = engine.search(query: "sa")
        XCTAssertEqual(results.first, .application(apps[0]))
    }

    func testCommandKeywordMatchWorks() {
        let commands = [
            CommandItem(id: "open-settings", title: "Open Settings", keywords: ["preferences", "settings"])
        ]
        let engine = SearchEngine(apps: [], commands: commands)
        let results = engine.search(query: "pref")
        XCTAssertEqual(results, [.command(commands[0])])
    }

    // MARK: - Fuzzy match tests

    func testFuzzyMatchOneCharTypo() {
        let apps = [
            AppItem(name: "Safari", bundleIdentifier: nil, bundleURL: URL(fileURLWithPath: "/Applications/Safari.app"))
        ]
        let engine = SearchEngine(apps: apps, commands: [])
        // "safri" is 1 edit away from "safari"
        let results = engine.search(query: "safri")
        XCTAssertFalse(results.isEmpty, "1-char typo should still match")
        XCTAssertEqual(results.first, .application(apps[0]))
    }

    func testFuzzyMatchTwoCharTypo() {
        let apps = [
            AppItem(name: "Firefox", bundleIdentifier: nil, bundleURL: URL(fileURLWithPath: "/Applications/Firefox.app"))
        ]
        let engine = SearchEngine(apps: apps, commands: [])
        // "firrfox" is 2 edits away from "firefox"
        let results = engine.search(query: "firrfox")
        XCTAssertFalse(results.isEmpty, "2-char typo should still match")
        XCTAssertEqual(results.first, .application(apps[0]))
    }

    func testFuzzyMatchMultiWordApp() {
        let apps = [
            AppItem(name: "Google Chrome", bundleIdentifier: nil, bundleURL: URL(fileURLWithPath: "/Applications/Google Chrome.app"))
        ]
        let engine = SearchEngine(apps: apps, commands: [])
        // "chroem" is 2 edits away from "chrome"
        let results = engine.search(query: "chroem")
        XCTAssertFalse(results.isEmpty, "2-char typo in multi-word app name should still match")
    }

    func testFuzzyMatchRanksLowerThanExactSubstring() {
        let safari = AppItem(name: "Safari", bundleIdentifier: nil, bundleURL: URL(fileURLWithPath: "/Applications/Safari.app"))
        let radium = AppItem(name: "Radium", bundleIdentifier: nil, bundleURL: URL(fileURLWithPath: "/Applications/Radium.app"))
        let engine = SearchEngine(apps: [safari, radium], commands: [])
        // "rad" is an exact prefix match for Radium; "safri" is a fuzzy match for Safari.
        // Radium (exact) should rank above Safari (fuzzy).
        let results = engine.search(query: "rad")
        XCTAssertEqual(results.first, .application(radium))
    }

    func testFuzzyMatchIgnoredForShortQuery() {
        let apps = [
            AppItem(name: "Notes", bundleIdentifier: nil, bundleURL: URL(fileURLWithPath: "/Applications/Notes.app"))
        ]
        let engine = SearchEngine(apps: apps, commands: [])
        // "nx" (2 chars) should NOT fuzzy-match "notes" — too short, too noisy.
        let results = engine.search(query: "nx")
        XCTAssertTrue(results.isEmpty, "2-char query should not trigger fuzzy matching")
    }
}
