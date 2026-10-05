import Testing
@testable import KeyboardCleaner

struct ExitHoldTests {
    private let start = ContinuousClock.now
    private func at(_ seconds: Double) -> ContinuousClock.Instant { start + .seconds(seconds) }
    private func space(down: Bool, repeat isRepeat: Bool = false) -> Input {
        .key(ExitHold.spaceBar, isDown: down, isRepeat: isRepeat)
    }

    @Test func holdingSpaceForFiveSecondsCompletes() {
        var hold = ExitHold()
        hold.register(space(down: true), at: at(0))
        hold.register(space(down: true, repeat: true), at: at(2))
        #expect(!hold.isComplete(at: at(4.9)))
        #expect(hold.isComplete(at: at(5)))
    }

    @Test func releasingSpaceResets() {
        var hold = ExitHold()
        hold.register(space(down: true), at: at(0))
        hold.register(space(down: false), at: at(4))
        hold.register(space(down: true), at: at(4.5))
        #expect(!hold.isComplete(at: at(9)))
        #expect(hold.isComplete(at: at(9.5)))
    }

    @Test func anotherKeyResetsTheHold() {
        var hold = ExitHold()
        hold.register(space(down: true), at: at(0))
        hold.register(.key(0, isDown: true, isRepeat: false), at: at(3))
        #expect(hold.heldSince == nil)
        hold.register(space(down: true, repeat: true), at: at(3.5))
        #expect(hold.progress(at: at(10)) == 0)
    }

    @Test func trackpadInputDoesNotReset() {
        var hold = ExitHold()
        hold.register(space(down: true), at: at(0))
        hold.register(.pointer, at: at(2))
        #expect(hold.isComplete(at: at(5)))
    }
}
