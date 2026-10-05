import AppKit
import CoreGraphics

/// A physical key, identified by the macOS virtual key code printed on it in the standard layout.
typealias KeyCode = UInt16

enum Input: Equatable {
    case key(KeyCode, isDown: Bool, isRepeat: Bool)
    case pointer
}

enum InputLockError: Error {
    case tapUnavailable
}

/// Swallows every keyboard, trackpad, mouse, and media-key event system-wide while engaged, and reports
/// each one as an `Input` so the UI can react. Requires Accessibility access; `engage` throws without it.
///
/// The tap runs on the main run loop on purpose: if the main thread ever hangs, macOS disables the tap
/// after a timeout and input comes back, so a stuck app cannot hold the Mac hostage.
@MainActor
final class InputLock {
    private var tap: CFMachPort?
    private var source: CFRunLoopSource?
    private var onInput: (Input) -> Void = { _ in }

    var isEngaged: Bool { tap != nil }

    func engage(onInput: @escaping (Input) -> Void) throws {
        guard tap == nil else { return }
        guard let tap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: Self.blockedEvents,
            callback: tapCallback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else { throw InputLockError.tapUnavailable }

        self.onInput = onInput
        self.tap = tap
        let source = CFMachPortCreateRunLoopSource(nil, tap, 0)
        self.source = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        // Swallowing mouse events stops clicks, but the cursor is moved below the tap, so freeze it too.
        CGAssociateMouseAndMouseCursorPosition(0)
        NSCursor.hide()
    }

    func release() {
        guard let tap else { return }
        CGEvent.tapEnable(tap: tap, enable: false)
        if let source { CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes) }
        CFMachPortInvalidate(tap)
        self.tap = nil
        source = nil
        onInput = { _ in }
        CGAssociateMouseAndMouseCursorPosition(1)
        NSCursor.unhide()
    }

    /// Returns true when the event should be swallowed.
    fileprivate func handle(type: CGEventType, event: CGEvent) -> Bool {
        switch type.rawValue {
        case CGEventType.tapDisabledByTimeout.rawValue, CGEventType.tapDisabledByUserInput.rawValue:
            if let tap { CGEvent.tapEnable(tap: tap, enable: true) }
            return false
        case CGEventType.keyDown.rawValue, CGEventType.keyUp.rawValue:
            let code = KeyCode(truncatingIfNeeded: event.getIntegerValueField(.keyboardEventKeycode))
            onInput(.key(
                Self.physicalKey(forKeyCode: code),
                isDown: type == .keyDown,
                isRepeat: event.getIntegerValueField(.keyboardEventAutorepeat) != 0
            ))
        case CGEventType.flagsChanged.rawValue:
            let code = KeyCode(truncatingIfNeeded: event.getIntegerValueField(.keyboardEventKeycode))
            if code == Self.capsLock {
                // Caps Lock reports each press as a toggle with no key-up, so treat it as a tap.
                onInput(.key(code, isDown: true, isRepeat: false))
                onInput(.key(code, isDown: false, isRepeat: false))
            } else if let flag = Self.modifierFlags[code] {
                onInput(.key(code, isDown: event.flags.contains(flag), isRepeat: false))
            }
        case Self.systemDefined:
            if let input = Self.mediaKeyInput(from: event) { onInput(input) }
        default:
            onInput(.pointer)
        }
        return true
    }

    // MARK: - Event decoding

    private static let systemDefined: UInt32 = 14
    private static let capsLock: KeyCode = 57

    private static let blockedEvents: CGEventMask = {
        let keyboard: [UInt32] = [10, 11, 12, systemDefined]
        let pointer: [UInt32] = [1, 2, 3, 4, 5, 6, 7, 22, 23, 24, 25, 26, 27]
        // NSEvent gesture types (rotate, begin/end gesture, gesture, magnify, swipe, smart magnify,
        // quick look, pressure, direct touch, change mode). Swallowing them stops Mission Control,
        // App Exposé, and other system trackpad gestures.
        let gestures: [UInt32] = [18, 19, 20, 29, 30, 31, 32, 33, 34, 37, 38]
        return (keyboard + pointer + gestures).reduce(0) { $0 | (CGEventMask(1) << $1) }
    }()

    private static let modifierFlags: [KeyCode: CGEventFlags] = [
        56: .maskShift, 60: .maskShift,
        59: .maskControl, 62: .maskControl,
        58: .maskAlternate, 61: .maskAlternate,
        55: .maskCommand, 54: .maskCommand,
        63: .maskSecondaryFn
    ]

    /// MacBook top-row keys that send special key codes instead of F3 to F6.
    private static let specialTopRowKeys: [KeyCode: KeyCode] = [160: 99, 131: 118, 177: 118, 176: 96, 178: 97]

    /// Media keys (NX_KEYTYPE_*) mapped to the F-key they sit on in the MacBook top row.
    private static let mediaKeys: [Int: KeyCode] = [
        3: 122, 2: 120, // brightness down, up
        18: 98, 20: 98, 16: 100, 17: 101, 19: 101, // previous/rewind, play, next/fast
        7: 109, 1: 103, 0: 111 // mute, volume down, volume up
    ]

    private static func physicalKey(forKeyCode code: KeyCode) -> KeyCode {
        specialTopRowKeys[code] ?? code
    }

    private static func mediaKeyInput(from event: CGEvent) -> Input? {
        guard let nsEvent = NSEvent(cgEvent: event), nsEvent.subtype.rawValue == 8 else { return nil }
        let data = nsEvent.data1
        let keyType = (data & 0xFFFF_0000) >> 16
        let state = (data & 0xFF00) >> 8
        guard let code = mediaKeys[keyType] else { return nil }
        return .key(code, isDown: state == 0x0A, isRepeat: data & 0x1 != 0)
    }
}

private let tapCallback: CGEventTapCallBack = { _, type, event, userInfo in
    guard let userInfo else { return Unmanaged.passUnretained(event) }
    let lock = Unmanaged<InputLock>.fromOpaque(userInfo).takeUnretainedValue()
    // The tap's run loop source is on the main run loop, so this callback already runs on the main thread.
    nonisolated(unsafe) let event = event
    let swallow = MainActor.assumeIsolated { lock.handle(type: type, event: event) }
    return swallow ? nil : Unmanaged.passUnretained(event)
}
