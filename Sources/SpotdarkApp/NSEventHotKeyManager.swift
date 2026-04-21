import AppKit
import ApplicationServices
import SpotdarkCore

/// Global hotkey manager using NSEvent global + local monitors.
///
/// Requires Accessibility (Input Monitoring) permission on macOS 10.15+.
/// If permission is absent, `register` throws `.accessibilityPermissionRequired`
/// and the system permission dialog is presented automatically.
///
/// Both a global monitor (fires while another app is active) and a local monitor
/// (fires while this app is active) are registered so that the hotkey works both
/// to open the launcher and to close it when the panel already has focus.
final class NSEventHotKeyManager: HotKeyRegistering {
    var onError: ((HotKeyError) -> Void)?

    private var monitors: [Any] = []
    private var registeredHotKeys: [(HotKey, @Sendable () -> Void)] = []

    func register(hotKey: HotKey, handler: @escaping @Sendable () -> Void) throws {
        // On macOS 10.15+, NSEvent global key monitors require Input Monitoring permission.
        // Accessibility also satisfies the requirement on all macOS versions.
        // Accept either so the user only needs to grant whichever prompt the system shows.
        guard AXIsProcessTrusted() || CGPreflightListenEventAccess() else {
            // Request Input Monitoring first (macOS 10.15+ — the permission the system
            // will prompt for when a key logger is detected).  Then also request Accessibility
            // so older systems and users who prefer that path are covered.
            CGRequestListenEventAccess()
            let opts = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
            AXIsProcessTrustedWithOptions(opts as CFDictionary)
            throw HotKeyError.accessibilityPermissionRequired
        }

        let targetKeyCode = hotKey.keyCode
        let targetModifiers = hotKey.modifiers
        let expectedNSFlags = NSEvent.ModifierFlags(rawValue: targetModifiers.rawValue)

        // Only compare primary modifier keys (cmd/ctrl/opt/shift) so that CapsLock,
        // numericPad, function, and other device-independent flags don't block the match.
        let primaryModifierMask: NSEvent.ModifierFlags = [.shift, .control, .option, .command]

        // Global monitor — fires when another application is the active app.
        // This handles opening the launcher from any other app.
        let globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            guard event.keyCode == targetKeyCode else { return }
            let flags = event.modifierFlags.intersection(primaryModifierMask)
            guard flags == expectedNSFlags else { return }
            handler()
        }

        guard let globalMonitor else {
            let err = HotKeyError.monitorRegistrationFailed
            onError?(err)
            throw err
        }
        monitors.append(globalMonitor)

        // Local monitor — fires when this app is the active app (panel is open and focused).
        // Returning nil consumes the event so it doesn't propagate to SwiftUI views.
        // This handles closing the launcher by pressing the hotkey a second time.
        if let localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown, handler: { event in
            guard event.keyCode == targetKeyCode else { return event }
            let flags = event.modifierFlags.intersection(primaryModifierMask)
            guard flags == expectedNSFlags else { return event }
            handler()
            return nil
        }) {
            monitors.append(localMonitor)
        }

        registeredHotKeys.append((hotKey, handler))
    }

    func unregisterAll() {
        for monitor in monitors {
            NSEvent.removeMonitor(monitor)
        }
        monitors.removeAll()
        registeredHotKeys.removeAll()
    }
}
