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
        if !AXIsProcessTrusted() {
            // Prompt the system accessibility dialog.
            let opts = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
            AXIsProcessTrustedWithOptions(opts as CFDictionary)
            throw HotKeyError.accessibilityPermissionRequired
        }

        let targetKeyCode = hotKey.keyCode
        let targetModifiers = hotKey.modifiers
        let expectedNSFlags = NSEvent.ModifierFlags(rawValue: targetModifiers.rawValue)

        let monitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            guard event.keyCode == targetKeyCode else { return }
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
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
