import AppKit
import SwiftUI
import SpotdarkCore

/// A global singleton that owns the launcher panel.
@MainActor
final class LauncherCoordinator {
    static let shared = LauncherCoordinator()

    private let panelController: LauncherPanelController
    private let errorFeedbackController: ErrorFeedbackPanelController

    private init() {
        panelController = LauncherPanelController()
        errorFeedbackController = ErrorFeedbackPanelController()
    }

    func toggle() {
        if panelController.isVisible {
            panelController.hide()
        } else {
            panelController.showCenteredAndFocus()
        }
    }

    func show() {
        panelController.showCenteredAndFocus()
    }

    func hide() {
        panelController.hide()
    }

    func showErrorFeedback(_ content: ErrorFeedbackContent) {
        errorFeedbackController.present(content)
    }

    func showSettings(pane: SettingsPane? = nil) {
        if let pane {
            SettingsStore.shared.selectedPane = pane
        }

        NSApp.activate(ignoringOtherApps: true)
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }
}

/// Application delegate for hotkey registration and menu bar.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let hotKeyManager: HotKeyRegistering = NSEventHotKeyManager()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        hotKeyManager.onError = { error in
            LauncherCoordinator.shared.showErrorFeedback(.hotKeyError(error))
        }
        registerHotKey()
        setupMenuBar()
    }

    func applicationWillTerminate(_ notification: Notification) {
        hotKeyManager.unregisterAll()
    }

    private func registerHotKey() {
        // Default to Option+Space to avoid conflicting with Spotlight (Cmd+Space).
        // NSEvent monitors are passive — they cannot take exclusive ownership of a key combo,
        // so defaulting to a non-conflicting binding is the right approach.
        do {
            try registerLauncherHotKey(.optionSpace)
        } catch let error as HotKeyError {
            LauncherCoordinator.shared.showErrorFeedback(.hotKeyError(error))
        } catch {
            LauncherCoordinator.shared.showErrorFeedback(.shortcutMonitorError)
        }
    }

    private func setupMenuBar() {
        let mainMenu = NSMenu()
        let appMenuItem = NSMenuItem()
        mainMenu.addItem(appMenuItem)

        let appMenu = NSMenu()
        appMenuItem.submenu = appMenu

        appMenu.addItem(NSMenuItem(title: SettingsStrings.showLauncherMenuItemTitle, action: #selector(showLauncherFromMenu), keyEquivalent: "l"))
        appMenu.addItem(NSMenuItem(title: SettingsStrings.settingsMenuItemTitle, action: #selector(showSettingsFromMenu), keyEquivalent: ","))
        appMenu.addItem(.separator())
        appMenu.addItem(NSMenuItem(title: SettingsStrings.quitMenuItemTitle, action: #selector(quit), keyEquivalent: "q"))

        NSApp.mainMenu = mainMenu
    }

    private func registerLauncherHotKey(_ hotKey: HotKey) throws {
        try hotKeyManager.register(hotKey: hotKey) {
            Task { @MainActor in
                LauncherCoordinator.shared.toggle()
            }
        }
    }

    @objc private func showLauncherFromMenu() {
        Task { @MainActor in
            LauncherCoordinator.shared.show()
        }
    }

    @objc private func showSettingsFromMenu() {
        Task { @MainActor in
            LauncherCoordinator.shared.showSettings()
        }
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}

@main
struct SpotdarkApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        // No default windows; this behaves like a menu bar accessory.
        Settings {
            SettingsView(store: SettingsStore.shared)
        }
    }
}
