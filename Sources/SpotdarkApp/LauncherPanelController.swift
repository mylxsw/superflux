import AppKit
import SwiftUI
import SpotdarkCore

private let savedPanelOriginKey = "settings.savedPanelFrame"

/// A borderless panel that can become key/main to accept text input.
final class LauncherPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

/// Hosts the SwiftUI launcher view inside an NSPanel.
@MainActor
final class LauncherPanelController: NSObject {
    private let panel: LauncherPanel
    private let store: LauncherStore

    var isVisible: Bool {
        panel.isVisible
    }

    override init() {
        let commandRegistry = CommandRegistry(commands: [
            CommandItem(id: "open-settings", title: "Open Settings", keywords: ["settings", "preferences"]),
            CommandItem(id: "quit", title: "Quit", keywords: ["exit", "close"])
        ])

        // App indexing follows the directories configured in Settings.
        store = LauncherStore(
            commandProvider: commandRegistry,
            indexStream: SettingsAppIndexStream(settingsStore: .shared)
        )

        let rootView = LauncherRootView(store: store)
        let hosting = NSHostingController(rootView: rootView)

        panel = LauncherPanel(
            contentRect: NSRect(x: 0, y: 0, width: 720, height: 420),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        panel.isFloatingPanel = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.hidesOnDeactivate = true
        panel.isMovableByWindowBackground = true

        if #available(macOS 13.0, *) {
            panel.toolbarStyle = .unifiedCompact
        }

        panel.contentViewController = hosting

        // Make SwiftUI background transparent; SwiftUI draws its own material.
        hosting.view.wantsLayer = true
        hosting.view.layer?.backgroundColor = NSColor.clear.cgColor

        super.init()

        panel.delegate = self
        centerOnScreen()
    }

    func showCenteredAndFocus() {
        if SettingsStore.shared.remembersPanelPosition, let savedOrigin = restoredPanelOrigin() {
            panel.setFrameOrigin(savedOrigin)
        } else {
            centerOnScreen()
        }
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
        store.requestFocus()
    }

    private func centerOnScreen() {
        guard let screen = NSScreen.main else { return }
        let frame = screen.frame
        let origin = NSPoint(
            x: frame.midX - panel.frame.width / 2,
            y: frame.midY - panel.frame.height / 2
        )
        panel.setFrameOrigin(origin)
    }

    private func restoredPanelOrigin() -> NSPoint? {
        guard let data = UserDefaults.standard.dictionary(forKey: savedPanelOriginKey),
              let x = data["x"] as? Double,
              let y = data["y"] as? Double else {
            return nil
        }
        return NSPoint(x: x, y: y)
    }

    func hide() {
        panel.orderOut(nil)
    }
}

extension LauncherPanelController: NSWindowDelegate {
    nonisolated func windowDidMove(_ notification: Notification) {
        Task { @MainActor in
            guard SettingsStore.shared.remembersPanelPosition else { return }
            let origin = panel.frame.origin
            UserDefaults.standard.set(
                ["x": origin.x, "y": origin.y],
                forKey: savedPanelOriginKey
            )
        }
    }
}
