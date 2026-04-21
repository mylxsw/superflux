import Foundation

final class SettingsStore: ObservableObject {
    static let shared = SettingsStore()

    @Published var selectedPane: SettingsPane
    @Published var launchAtLoginEnabled: Bool
    @Published var showsMenuBarItem: Bool
    @Published var selectedAppearance: SettingsAppearance
    @Published var remembersPanelPosition: Bool
    @Published var currentShortcutDisplay: String
    @Published var defaultSearchLocations: [String]
    @Published var customSearchLocations: [String]

    init(
        selectedPane: SettingsPane = .general,
        launchAtLoginEnabled: Bool = false,
        showsMenuBarItem: Bool = true,
        selectedAppearance: SettingsAppearance = .followSystem,
        remembersPanelPosition: Bool = false,
        currentShortcutDisplay: String = SettingsStrings.currentShortcutValue,
        defaultSearchLocations: [String] = [
            "/Applications",
            "/Applications/Utilities",
            "/System/Applications",
            "/System/Applications/Utilities",
            "~/Applications"
        ],
        customSearchLocations: [String] = []
    ) {
        self.selectedPane = selectedPane
        self.launchAtLoginEnabled = launchAtLoginEnabled
        self.showsMenuBarItem = showsMenuBarItem
        self.selectedAppearance = selectedAppearance
        self.remembersPanelPosition = remembersPanelPosition
        self.currentShortcutDisplay = currentShortcutDisplay
        self.defaultSearchLocations = defaultSearchLocations
        self.customSearchLocations = customSearchLocations
    }

    static var preview: SettingsStore {
        SettingsStore(
            selectedPane: .shortcuts,
            selectedAppearance: .followSystem,
            customSearchLocations: [
                "~/Developer/Applications",
                "~/Applications/Setapp"
            ]
        )
    }
}

enum SettingsPane: String, CaseIterable, Identifiable {
    case general
    case shortcuts
    case search
    case about

    var id: Self { self }

    var title: String {
        switch self {
        case .general:
            SettingsStrings.generalTabTitle
        case .shortcuts:
            SettingsStrings.shortcutsTabTitle
        case .search:
            SettingsStrings.searchTabTitle
        case .about:
            SettingsStrings.aboutTabTitle
        }
    }

    var systemImage: String {
        switch self {
        case .general:
            "gearshape"
        case .shortcuts:
            "command"
        case .search:
            "magnifyingglass"
        case .about:
            "sparkles"
        }
    }
}

enum SettingsAppearance: String, CaseIterable, Identifiable {
    case followSystem
    case light
    case dark

    var id: Self { self }

    var title: String {
        switch self {
        case .followSystem:
            SettingsStrings.systemAppearance
        case .light:
            SettingsStrings.lightAppearance
        case .dark:
            SettingsStrings.darkAppearance
        }
    }
}
