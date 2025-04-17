import SwiftUI
import Cocoa

@main
struct WallinApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        // Removed the line to set the app to not show in the Dock
    }

    var body: some Scene {
        Settings {
            EmptyView() // 不需要主窗口
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow?
    var statusBarController: StatusBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let contentView = ContentView()

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 480),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false)
        window.center()
        window.setFrameAutosaveName("Main Window")
        window.isReleasedWhenClosed = false
        window.title = "Wallin 壁纸"
        window.titleVisibility = .visible
        window.titlebarAppearsTransparent = false
        window.contentView = NSHostingView(rootView: contentView)
        window.makeKeyAndOrderFront(nil)

        self.window = window
        self.statusBarController = StatusBarController(window: window)
    }
}
