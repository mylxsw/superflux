import XCTest
@testable import SpotdarkCore

// MARK: - Mock

private final class MockHotKeyManager: HotKeyRegistering {
    var onError: ((HotKeyError) -> Void)?

    private(set) var registeredHotKeys: [HotKey] = []
    private(set) var unregisterAllCallCount = 0

    var shouldThrow: HotKeyError?

    func register(hotKey: HotKey, handler: @escaping @Sendable () -> Void) throws {
        if let error = shouldThrow { throw error }
        registeredHotKeys.append(hotKey)
    }

    func unregisterAll() {
        unregisterAllCallCount += 1
        registeredHotKeys.removeAll()
    }

    func simulateError(_ error: HotKeyError) {
        onError?(error)
    }
}

// MARK: - HotKey tests

final class HotKeyTests: XCTestCase {
    func testOptionSpaceKeyCode() {
        XCTAssertEqual(HotKey.optionSpace.keyCode, 49)
        XCTAssertEqual(HotKey.optionSpace.modifiers, .option)
    }

    func testCommandSpaceKeyCode() {
        XCTAssertEqual(HotKey.commandSpace.keyCode, 49)
        XCTAssertEqual(HotKey.commandSpace.modifiers, .command)
    }

    func testEqualityBySameValues() {
        let a = HotKey(keyCode: 49, modifiers: .option)
        let b = HotKey(keyCode: 49, modifiers: .option)
        XCTAssertEqual(a, b)
    }

    func testInequalityByModifiers() {
        let a = HotKey(keyCode: 49, modifiers: .option)
        let b = HotKey(keyCode: 49, modifiers: .command)
        XCTAssertNotEqual(a, b)
    }

    func testDisplayStringOptionSpace() {
        XCTAssertEqual(HotKey.optionSpace.displayString, "⌥Space")
    }

    func testDisplayStringCommandSpace() {
        XCTAssertEqual(HotKey.commandSpace.displayString, "⌘Space")
    }

    func testDisplayStringMultipleModifiers() {
        let hotKey = HotKey(keyCode: 49, modifiers: [.control, .option])
        XCTAssertEqual(hotKey.displayString, "⌃⌥Space")
    }
}

// MARK: - HotKeyModifierFlags tests

final class HotKeyModifierFlagsTests: XCTestCase {
    func testRawValuesMatchNSEventModifierFlagsLayout() {
        // Raw values match NSEvent.ModifierFlags bits (device-independent).
        XCTAssertEqual(HotKeyModifierFlags.shift.rawValue,   131_072)  // 1 << 17
        XCTAssertEqual(HotKeyModifierFlags.control.rawValue, 262_144)  // 1 << 18
        XCTAssertEqual(HotKeyModifierFlags.option.rawValue,  524_288)  // 1 << 19
        XCTAssertEqual(HotKeyModifierFlags.command.rawValue, 1_048_576) // 1 << 20
    }

    func testOptionSetCombination() {
        let combined: HotKeyModifierFlags = [.command, .shift]
        XCTAssertTrue(combined.contains(.command))
        XCTAssertTrue(combined.contains(.shift))
        XCTAssertFalse(combined.contains(.option))
    }
}

// MARK: - MockHotKeyManager tests

final class HotKeyRegisteringTests: XCTestCase {
    func testRegisterStoresHotKey() throws {
        let mgr = MockHotKeyManager()
        try mgr.register(hotKey: .optionSpace) {}
        XCTAssertEqual(mgr.registeredHotKeys.count, 1)
        XCTAssertEqual(mgr.registeredHotKeys.first, .optionSpace)
    }

    func testRegisterThrowsPropagates() {
        let mgr = MockHotKeyManager()
        mgr.shouldThrow = .accessibilityPermissionRequired
        XCTAssertThrowsError(try mgr.register(hotKey: .optionSpace) {}) { error in
            XCTAssertEqual(error as? HotKeyError, .accessibilityPermissionRequired)
        }
        XCTAssertTrue(mgr.registeredHotKeys.isEmpty)
    }

    func testUnregisterAllClearsHotKeys() throws {
        let mgr = MockHotKeyManager()
        try mgr.register(hotKey: .optionSpace) {}
        mgr.unregisterAll()
        XCTAssertTrue(mgr.registeredHotKeys.isEmpty)
        XCTAssertEqual(mgr.unregisterAllCallCount, 1)
    }

    func testOnErrorCallbackIsInvoked() {
        let mgr = MockHotKeyManager()
        var receivedError: HotKeyError?
        mgr.onError = { receivedError = $0 }
        mgr.simulateError(.monitorRegistrationFailed)
        XCTAssertEqual(receivedError, .monitorRegistrationFailed)
    }

    func testRegisterMultipleHotKeys() throws {
        let mgr = MockHotKeyManager()
        try mgr.register(hotKey: .optionSpace) {}
        try mgr.register(hotKey: .commandSpace) {}
        XCTAssertEqual(mgr.registeredHotKeys.count, 2)
    }
}
