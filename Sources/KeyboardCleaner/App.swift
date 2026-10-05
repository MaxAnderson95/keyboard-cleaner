import AppKit
import SwiftUI

@main
@MainActor
enum KeyboardCleanerApp {
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.regular)
        app.run()
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let session = CleaningSession()
    private var windows: [NSWindow] = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.mainMenu = Self.makeMainMenu()
        let mainScreen = NSScreen.main
        windows = NSScreen.screens.map { screen in
            let content: AnyView = screen == mainScreen
                ? AnyView(RootView(session: session))
                : AnyView(Backdrop(session: session))
            return OverlayWindow(screen: screen, content: content)
        }
        session.onPhaseChange = { [weak self] phase in self?.apply(phase) }
        session.startCleaning()
        apply(session.phase)
        NSApp.activate()
        windows.forEach { $0.makeKeyAndOrderFront(nil) }
        windows.first { $0.screen == mainScreen }?.makeKey()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }

    private func apply(_ phase: CleaningSession.Phase) {
        // System Settings has to be able to sit above us while Accessibility access is granted.
        let level: NSWindow.Level = phase == .needsPermission ? .normal : .screenSaver
        windows.forEach { $0.level = level }

        var options: NSApplication.PresentationOptions = [.hideDock, .hideMenuBar]
        if phase == .cleaning || phase == .finished {
            options.formUnion([.disableProcessSwitching, .disableForceQuit, .disableSessionTermination,
                               .disableHideApplication, .disableAppleMenu])
        }
        NSApp.presentationOptions = options

        if phase == .ready {
            NSApp.activate()
            windows.forEach { $0.orderFrontRegardless() }
        }
    }

    private static func makeMainMenu() -> NSMenu {
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "Quit Keyboard Cleaner", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        let appItem = NSMenuItem()
        appItem.submenu = appMenu
        let menu = NSMenu()
        menu.addItem(appItem)
        return menu
    }
}

/// A borderless, see-through window covering one whole screen.
final class OverlayWindow: NSWindow {
    init(screen: NSScreen, content: AnyView) {
        super.init(contentRect: screen.frame, styleMask: [.borderless, .fullSizeContentView], backing: .buffered, defer: false)
        setFrame(screen.frame, display: false)
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        isMovable = false
        animationBehavior = .none
        isReleasedWhenClosed = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        contentView = NSHostingView(rootView: content.ignoresSafeArea())
    }

    // AppKit otherwise pulls the window below the menu bar.
    override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect { frameRect }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}
