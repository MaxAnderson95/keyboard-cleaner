/// One key on the drawn keyboard. `width` is in key units; every row adds up to 14.5 units.
struct Keycap: Identifiable {
    let code: KeyCode?
    let label: String
    var symbol: String? = nil
    var width: Double = 1

    var id: String { code.map(String.init) ?? label }
}

/// A MacBook ANSI layout keyed by virtual key code.
enum KeyboardLayout {
    static let functionRow: [Keycap] = [
        Keycap(code: 53, label: "esc", width: 1.5),
        Keycap(code: 122, label: "F1", symbol: "sun.min"),
        Keycap(code: 120, label: "F2", symbol: "sun.max"),
        Keycap(code: 99, label: "F3", symbol: "rectangle.3.group"),
        Keycap(code: 118, label: "F4", symbol: "magnifyingglass"),
        Keycap(code: 96, label: "F5", symbol: "mic"),
        Keycap(code: 97, label: "F6", symbol: "moon"),
        Keycap(code: 98, label: "F7", symbol: "backward"),
        Keycap(code: 100, label: "F8", symbol: "playpause"),
        Keycap(code: 101, label: "F9", symbol: "forward"),
        Keycap(code: 109, label: "F10", symbol: "speaker"),
        Keycap(code: 103, label: "F11", symbol: "speaker.wave.1"),
        Keycap(code: 111, label: "F12", symbol: "speaker.wave.3"),
        Keycap(code: nil, label: "touch-id", symbol: "touchid")
    ]

    static let rows: [[Keycap]] = [
        [
            Keycap(code: 50, label: "`"), Keycap(code: 18, label: "1"), Keycap(code: 19, label: "2"),
            Keycap(code: 20, label: "3"), Keycap(code: 21, label: "4"), Keycap(code: 23, label: "5"),
            Keycap(code: 22, label: "6"), Keycap(code: 26, label: "7"), Keycap(code: 28, label: "8"),
            Keycap(code: 25, label: "9"), Keycap(code: 29, label: "0"), Keycap(code: 27, label: "-"),
            Keycap(code: 24, label: "="), Keycap(code: 51, label: "delete", width: 1.5)
        ],
        [
            Keycap(code: 48, label: "tab", width: 1.5), Keycap(code: 12, label: "Q"), Keycap(code: 13, label: "W"),
            Keycap(code: 14, label: "E"), Keycap(code: 15, label: "R"), Keycap(code: 17, label: "T"),
            Keycap(code: 16, label: "Y"), Keycap(code: 32, label: "U"), Keycap(code: 34, label: "I"),
            Keycap(code: 31, label: "O"), Keycap(code: 35, label: "P"), Keycap(code: 33, label: "["),
            Keycap(code: 30, label: "]"), Keycap(code: 42, label: "\\")
        ],
        [
            Keycap(code: 57, label: "caps lock", width: 1.75), Keycap(code: 0, label: "A"), Keycap(code: 1, label: "S"),
            Keycap(code: 2, label: "D"), Keycap(code: 3, label: "F"), Keycap(code: 5, label: "G"),
            Keycap(code: 4, label: "H"), Keycap(code: 38, label: "J"), Keycap(code: 40, label: "K"),
            Keycap(code: 37, label: "L"), Keycap(code: 41, label: ";"), Keycap(code: 39, label: "'"),
            Keycap(code: 36, label: "return", width: 1.75)
        ],
        [
            Keycap(code: 56, label: "shift", width: 2.25), Keycap(code: 6, label: "Z"), Keycap(code: 7, label: "X"),
            Keycap(code: 8, label: "C"), Keycap(code: 9, label: "V"), Keycap(code: 11, label: "B"),
            Keycap(code: 45, label: "N"), Keycap(code: 46, label: "M"), Keycap(code: 43, label: ","),
            Keycap(code: 47, label: "."), Keycap(code: 44, label: "/"), Keycap(code: 60, label: "shift", width: 2.25)
        ]
    ]

    static let bottomRow: [Keycap] = [
        Keycap(code: 63, label: "fn", symbol: "globe"),
        Keycap(code: 59, label: "control", symbol: "control"),
        Keycap(code: 58, label: "option", symbol: "option"),
        Keycap(code: 55, label: "command", symbol: "command", width: 1.25),
        Keycap(code: ExitHold.spaceBar, label: "", width: 5),
        Keycap(code: 54, label: "command", symbol: "command", width: 1.25),
        Keycap(code: 61, label: "option", symbol: "option")
    ]

    static let arrowLeft = Keycap(code: 123, label: "left", symbol: "arrowtriangle.left.fill")
    static let arrowUp = Keycap(code: 126, label: "up", symbol: "arrowtriangle.up.fill")
    static let arrowDown = Keycap(code: 125, label: "down", symbol: "arrowtriangle.down.fill")
    static let arrowRight = Keycap(code: 124, label: "right", symbol: "arrowtriangle.right.fill")

    static let allKeys: Set<KeyCode> = {
        let keys = functionRow + rows.flatMap(\.self) + bottomRow + [arrowLeft, arrowUp, arrowDown, arrowRight]
        return Set(keys.compactMap(\.code))
    }()
}
