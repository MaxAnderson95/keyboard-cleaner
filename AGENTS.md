# Keyboard Cleaner

Native macOS app (Swift 6, SwiftUI in AppKit windows, SwiftPM, no Xcode project). Read `README.md` first.

## Layout

- `Sources/KeyboardCleaner/InputLock.swift`: the CGEvent tap that swallows input and decodes it into `Input`. Owns cursor freezing.
- `ExitHold.swift`: the exit gesture rule (space alone for 5 s). Pure and unit tested; change its tests with it.
- `CleaningSession.swift`: phases (needsPermission, ready, cleaning, finished), wiped-key tracking, quitting.
- `App.swift`: one borderless `OverlayWindow` per screen, window level and presentation options per phase.
- `Views/`: SwiftUI. `KeyboardLayout.swift` maps virtual key codes to the drawn MacBook ANSI keyboard.

## Develop and verify

- `bash scripts/test.sh` runs the Swift Testing suite.
- `bash scripts/build-app.sh` builds and ad-hoc signs `build/Keyboard Cleaner.app`.
- On a Command Line Tools setup both scripts build against CLT's macOS 26 SDK because the macOS 27 SDK's `@State` macro plugin is not shipped with CLT, so plain `swift build` fails there. CI uses full Xcode and the default SDK.
- Engaging the lock happens on launch and needs Accessibility access for the built app, which only a human can grant. Never engage it in an unattended session: it blocks all keyboard and trackpad input until space is held.

## Release

- Repo: `MaxAnderson95/keyboard-cleaner` (personal account).
- `ci.yml` runs the tests and builds the app bundle on `macos-26` with Xcode 26.6.
- An annotated `vMAJOR.MINOR.PATCH[-prerelease]` tag triggers `release.yml`, which rejects lightweight and non-SemVer tags, stamps the version into `Info.plist`, ad-hoc signs, and publishes `KeyboardCleaner-<tag>-macos-arm64.zip` as a GitHub release. Only tag when Max asks.
