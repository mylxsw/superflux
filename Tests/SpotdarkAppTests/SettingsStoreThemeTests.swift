import XCTest
@testable import SpotdarkApp

@MainActor
final class SettingsStoreThemeTests: XCTestCase {
    func testInitializerRestoresPersistedThemePreset() {
        let defaults = makeDefaults()
        defaults.set(LauncherThemePreset.sunrise.rawValue, forKey: "settings.themePreset")

        let store = SettingsStore(defaults: defaults)

        XCTAssertEqual(store.selectedThemePreset, .sunrise)
    }

    func testChangingThemePresetPersistsImmediately() {
        let defaults = makeDefaults()
        let store = SettingsStore(defaults: defaults)

        store.selectedThemePreset = .sunrise

        XCTAssertEqual(
            defaults.string(forKey: "settings.themePreset"),
            LauncherThemePreset.sunrise.rawValue
        )
    }

    private func makeDefaults() -> UserDefaults {
        let suiteName = "SettingsStoreThemeTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        addTeardownBlock {
            defaults.removePersistentDomain(forName: suiteName)
        }
        return defaults
    }
}
