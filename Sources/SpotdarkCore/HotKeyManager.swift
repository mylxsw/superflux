import Foundation

/// Platform-neutral modifier flags whose raw values match NSEvent.ModifierFlags.
public struct HotKeyModifierFlags: OptionSet, Sendable, Hashable {
    public let rawValue: UInt

    public init(rawValue: UInt) { self.rawValue = rawValue }

    public static let shift   = HotKeyModifierFlags(rawValue: 1 << 17)  // 131072
    public static let control = HotKeyModifierFlags(rawValue: 1 << 18)  // 262144
    public static let option  = HotKeyModifierFlags(rawValue: 1 << 19)  // 524288
    public static let command = HotKeyModifierFlags(rawValue: 1 << 20)  // 1048576
}

/// A hotkey combination defined by a virtual key code and modifier flags.
public struct HotKey: Equatable, Sendable {
    /// Virtual key code (same codes used by Carbon kVK_* and NSEvent.keyCode).
    public let keyCode: UInt16
    public let modifiers: HotKeyModifierFlags

    public init(keyCode: UInt16, modifiers: HotKeyModifierFlags) {
        self.keyCode = keyCode
        self.modifiers = modifiers
    }

    /// Option(Alt) + Space.
    public static let optionSpace  = HotKey(keyCode: 49, modifiers: .option)

    /// Command + Space (likely reserved by Spotlight).
    public static let commandSpace = HotKey(keyCode: 49, modifiers: .command)

    /// Human-readable display string, e.g. "⌘Space".
    public var displayString: String {
        var parts: [String] = []
        if modifiers.contains(.control) { parts.append("⌃") }
        if modifiers.contains(.option)  { parts.append("⌥") }
        if modifiers.contains(.shift)   { parts.append("⇧") }
        if modifiers.contains(.command) { parts.append("⌘") }
        parts.append(keyCodeDisplayString)
        return parts.joined()
    }

    private var keyCodeDisplayString: String {
        switch keyCode {
        case 49: return "Space"
        default: return "Key(\(keyCode))"
        }
    }
}

/// Errors from hotkey registration or monitoring.
public enum HotKeyError: Error, Equatable {
    /// Accessibility permissions are required for global event monitoring.
    case accessibilityPermissionRequired
    /// The system rejected the monitor registration (rare; monitor returned nil).
    case monitorRegistrationFailed
}

/// Abstraction for registering global hotkeys.
///
/// `register` may throw synchronously (e.g. permission denied at call time).
/// Post-registration errors (e.g. permission revoked) arrive via `onError`.
public protocol HotKeyRegistering: AnyObject {
    /// Called on the main thread when an async error occurs after registration.
    var onError: ((HotKeyError) -> Void)? { get set }

    /// Register a global hotkey. Throws `HotKeyError` if immediate setup fails.
    func register(hotKey: HotKey, handler: @escaping @Sendable () -> Void) throws

    /// Remove all registered hotkeys and monitors.
    func unregisterAll()
}
