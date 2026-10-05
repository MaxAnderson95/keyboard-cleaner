/// The exit gesture: hold the space bar on its own for `duration`.
///
/// Pressing any other key restarts the hold, so a cloth resting across the keyboard that happens to
/// cover the space bar cannot end the session. Autorepeat never starts a hold; it takes a fresh press.
struct ExitHold {
    static let spaceBar: KeyCode = 49

    let duration: Duration
    private(set) var heldSince: ContinuousClock.Instant?

    init(duration: Duration = .seconds(5)) {
        self.duration = duration
    }

    mutating func register(_ input: Input, at now: ContinuousClock.Instant) {
        guard case let .key(code, isDown, isRepeat) = input else { return }
        switch (code == Self.spaceBar, isDown) {
        case (true, true) where !isRepeat && heldSince == nil:
            heldSince = now
        case (true, false):
            heldSince = nil
        case (false, true) where !isRepeat:
            heldSince = nil
        default:
            break
        }
    }

    func progress(at now: ContinuousClock.Instant) -> Double {
        guard let heldSince else { return 0 }
        return min(1, (now - heldSince) / duration)
    }

    func isComplete(at now: ContinuousClock.Instant) -> Bool {
        progress(at: now) >= 1
    }
}
