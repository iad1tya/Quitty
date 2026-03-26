import SwiftUI

@main
struct QuittyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Window("Quitty", id: "main") {
            ContentView()
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 620, height: 460)

        Settings {
            SettingsView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create menu bar icon
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem?.button {
            button.image = NSImage(named: "MenuBarIcon")
            button.action = #selector(toggleWindow)
            button.target = self
        }
    }

    @objc func toggleWindow() {
        let app = NSApplication.shared

        // Find any non-settings window
        if let window = app.windows.first(where: { !$0.title.contains("Settings") && $0.canBecomeMain }) {
            if window.isVisible && window.isKeyWindow {
                window.orderOut(nil)
            } else {
                window.makeKeyAndOrderFront(nil)
                app.activate(ignoringOtherApps: true)
            }
        } else {
            // No window found — activate app, SwiftUI will recreate
            app.activate(ignoringOtherApps: true)
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            for window in NSApplication.shared.windows where window.canBecomeMain {
                window.makeKeyAndOrderFront(nil)
            }
            NSApplication.shared.activate(ignoringOtherApps: true)
        }
        return true
    }
}
