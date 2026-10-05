import AppKit
import ApplicationServices
import Observation

@MainActor
@Observable
final class CleaningSession {
    enum Phase: Equatable {
        case needsPermission
        /// Has Accessibility access but input is not locked. Cleaning starts on its own, so this is only
        /// on screen when engaging the lock failed.
        case ready
        case cleaning
        case finished
    }

    private(set) var phase: Phase
    private(set) var pressedKeys: Set<KeyCode> = []
    private(set) var wipedKeys: Set<KeyCode> = []
    private(set) var trackpadTouchedAt: ContinuousClock.Instant?
    private(set) var exitHold = ExitHold()

    var trackpadWiped: Bool { trackpadTouchedAt != nil }

    @ObservationIgnored var onPhaseChange: (Phase) -> Void = { _ in }
    @ObservationIgnored private let lock = InputLock()
    @ObservationIgnored private var permissionWatcher: Task<Void, Never>?
    @ObservationIgnored private var exitWatcher: Task<Void, Never>?
    @ObservationIgnored private var farewellElapsed = false

    private static let farewellDuration: Duration = .seconds(1.8)
    /// Upper bound on waiting for the space bar to come up after the hold, in case its key-up is lost.
    private static let releaseTimeout: Duration = .seconds(4)
    private static let pointerRedrawInterval: Duration = .milliseconds(120)

    init() {
        phase = AXIsProcessTrusted() ? .ready : .needsPermission
        if phase == .needsPermission { watchForPermission() }
    }

    func requestPermission() {
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        if !AXIsProcessTrustedWithOptions(options),
           let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    func startCleaning() {
        guard phase == .ready,
              (try? lock.engage { [weak self] input in self?.handle(input) }) != nil
        else { return }
        setPhase(.cleaning)
    }

    func quit() {
        lock.release()
        NSApp.terminate(nil)
    }

    private func handle(_ input: Input) {
        let now = ContinuousClock.now
        switch input {
        case let .key(code, isDown, _):
            if isDown {
                pressedKeys.insert(code)
                wipedKeys.insert(code)
            } else {
                pressedKeys.remove(code)
            }
        case .pointer:
            // Trackpad events arrive at display refresh rate; redrawing on each one is wasted work.
            if let last = trackpadTouchedAt, now - last < Self.pointerRedrawInterval { return }
            trackpadTouchedAt = now
        }

        if phase == .finished {
            if !pressedKeys.contains(ExitHold.spaceBar) { quitWhenReleased() }
            return
        }

        let heldSince = exitHold.heldSince
        exitHold.register(input, at: now)
        if exitHold.heldSince != heldSince { watchExitHold() }
    }

    private func watchExitHold() {
        exitWatcher?.cancel()
        guard let heldSince = exitHold.heldSince else { return }
        let deadline = heldSince + exitHold.duration
        exitWatcher = Task { [weak self] in
            try? await Task.sleep(until: deadline, clock: .continuous)
            guard let self, !Task.isCancelled, self.exitHold.isComplete(at: .now) else { return }
            self.finish()
        }
    }

    private func finish() {
        setPhase(.finished)
        // Keep swallowing input until the space bar is up, so autorepeat never leaks into the app behind.
        Task { [weak self] in
            try? await Task.sleep(for: Self.farewellDuration)
            self?.farewellElapsed = true
            self?.quitWhenReleased()
            try? await Task.sleep(for: Self.releaseTimeout)
            self?.quit()
        }
    }

    private func quitWhenReleased() {
        guard farewellElapsed, !pressedKeys.contains(ExitHold.spaceBar) else { return }
        quit()
    }

    private func watchForPermission() {
        permissionWatcher = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard AXIsProcessTrusted() else { continue }
                self?.setPhase(.ready)
                self?.startCleaning()
                return
            }
        }
    }

    private func setPhase(_ newPhase: Phase) {
        phase = newPhase
        onPhaseChange(newPhase)
    }
}
