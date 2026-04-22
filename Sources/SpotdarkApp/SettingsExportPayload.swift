import Foundation

struct SettingsExportPayload: Codable {
    static let currentVersion = 1

    let version: Int
    let exportedAt: Date
    let hotKeyCode: Int
    let hotKeyModifiers: Int
    let appearance: String
    let themePreset: String
    let showsMenuBarItem: Bool
    let remembersPanelPosition: Bool
    let webSearchEngine: String
    let customSearchLocations: [String]
    let pinnedItemIDs: [String]
}

enum SettingsImportStrategy {
    case replaceAll
    case merge
}

struct SettingsImportConflict {
    let settingName: String
    let currentValue: String
    let importedValue: String
}

struct SettingsImportPreview: Identifiable {
    let id = UUID()
    let conflicts: [SettingsImportConflict]
    let payload: SettingsExportPayload

    var hasConflicts: Bool { !conflicts.isEmpty }
}
