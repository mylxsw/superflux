import AppKit
import ApplicationServices
import SpotdarkCore

/// Global hotkey manager using NSEvent.addGlobalMonitorForEvents.
///
/// Requires Accessibility (Input Monitoring) permission on macOS 10.15+.
/// If permission is absent, `register` throws `.accessibilityPermissionRequired`
/// and the system permission dialog is presented automatically.
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
        let monitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            guard event.keyCode == targetKeyCode else { return }
            let flags = event.modifierFlags.intersection(primaryModifierMask)
            guard flags == expectedNSFlags else { return }
            handler()
        }

        guard let monitor else {
            let err = HotKeyError.monitorRegistrationFailed
            onError?(err)
            throw err
        }

        monitors.append(monitor)
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
