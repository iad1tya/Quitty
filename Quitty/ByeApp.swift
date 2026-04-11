import SwiftUI
import UserNotifications
import AppKit

@main
struct QuittyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Window("Quitty", id: "main") {
            ContentView()
                .onAppear {
                    setupKeyboardShortcuts()
                }
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 620, height: 460)
        .commands {
            CommandGroup(after: .appInfo) {
                Button("Quick Actions") {}
                    .keyboardShortcut("k", modifiers: [.command, .shift])
                    .disabled(true)
                
                Divider()
                
                Button("Quit All Apps") {
                    NotificationCenter.default.post(name: NSNotification.Name("QuickActionQuitAll"), object: nil)
                }
                .keyboardShortcut("q", modifiers: [.command, .shift])
                
                Button("Free RAM") {
                    NotificationCenter.default.post(name: NSNotification.Name("QuickActionFreeRAM"), object: nil)
                }
                .keyboardShortcut("r", modifiers: [.command, .shift])
                
                Button("Empty Trash") {
                    NotificationCenter.default.post(name: NSNotification.Name("QuickActionEmptyTrash"), object: nil)
                }
                .keyboardShortcut("t", modifiers: [.command, .shift])
            }
        }

        Settings {
            SettingsView()
        }
    }
    
    private func setupKeyboardShortcuts() {
        // Additional global hotkey setup if needed
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private var statusItem: NSStatusItem?
    private let criticalApps = ["com.apple.finder", "com.apple.dock", "com.apple.systemuiserver"]

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()

        // Set up window delegate to handle close events
        NSApplication.shared.windows.forEach { window in
            if !window.title.contains("Settings") {
                window.delegate = self
            }
        }
        
        // Register for scheduled task notifications
        registerNotificationObservers()
        
        // Request notification permissions
        requestNotificationPermissions()
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            // Create and show main window
            NSApplication.shared.activate(ignoringOtherApps: true)
        }
        return true
    }
    
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        // Allow normal termination
        return .terminateNow
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            if let icon = NSImage(named: "MenuBarIcon") {
                icon.isTemplate = true
                button.image = icon
            } else {
                button.image = NSImage(systemSymbolName: "sparkles", accessibilityDescription: "Quitty")
            }
            button.toolTip = "Quitty"
        }

        let menu = NSMenu()
        menu.delegate = self
        menu.addItem(NSMenuItem.separator())

        let closeAllItem = NSMenuItem(title: "Close All Open Applications", action: #selector(closeAllOpenApplications), keyEquivalent: "")
        closeAllItem.target = self
        menu.addItem(closeAllItem)

        let runningAppsSubmenuItem = NSMenuItem(title: "Close Open Applications", action: nil, keyEquivalent: "")
        let runningAppsMenu = NSMenu(title: "Close Open Applications")
        runningAppsSubmenuItem.submenu = runningAppsMenu
        menu.addItem(runningAppsSubmenuItem)

        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit Quitty", action: #selector(quitFromMenuBar), keyEquivalent: "q"))

        statusItem?.menu = menu
    }

    @objc private func quitFromMenuBar() {
        NSApplication.shared.terminate(nil)
    }

    @objc private func closeAllOpenApplications() {
        for app in closableRunningApplications() {
            _ = app.terminate()
        }
    }

    @objc private func closeApplicationFromMenu(_ sender: NSMenuItem) {
        guard let pid = sender.representedObject as? pid_t else { return }
        guard let app = NSRunningApplication(processIdentifier: pid) else { return }
        _ = app.terminate()
    }

    private func closableRunningApplications() -> [NSRunningApplication] {
        let quittyBundleId = Bundle.main.bundleIdentifier

        return NSWorkspace.shared.runningApplications
            .filter { app in
                guard app.activationPolicy == .regular else { return false }
                guard let bundleId = app.bundleIdentifier else { return false }
                if bundleId == quittyBundleId { return false }
                if criticalApps.contains(bundleId) { return false }
                return true
            }
            .sorted { ($0.localizedName ?? "") < ($1.localizedName ?? "") }
    }

    private func rebuildRunningAppsMenuIfNeeded(_ menu: NSMenu) {
        guard let submenuItem = menu.items.first(where: { $0.title == "Close Open Applications" }),
              let runningAppsMenu = submenuItem.submenu else {
            return
        }

        runningAppsMenu.removeAllItems()

        let apps = closableRunningApplications()
        if apps.isEmpty {
            let empty = NSMenuItem(title: "No open applications", action: nil, keyEquivalent: "")
            empty.isEnabled = false
            runningAppsMenu.addItem(empty)
            return
        }

        for app in apps {
            let item = NSMenuItem(title: app.localizedName ?? "Unknown App", action: #selector(closeApplicationFromMenu(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = app.processIdentifier
            if let icon = app.icon {
                icon.size = NSSize(width: 16, height: 16)
                item.image = icon
            }
            runningAppsMenu.addItem(item)
        }
    }
    
    private func registerNotificationObservers() {
        // Scheduled task notifications
        NotificationCenter.default.addObserver(self, selector: #selector(handleScheduledTask), name: NSNotification.Name("ExecuteCleanJunk"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleScheduledTask), name: NSNotification.Name("ExecuteEmptyTrash"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleScheduledTask), name: NSNotification.Name("ExecuteFreeRAM"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleScheduledTask), name: NSNotification.Name("ExecuteFindDuplicates"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleScheduledTask), name: NSNotification.Name("ExecuteScanLargeFiles"), object: nil)
        
        // Quick action notifications from dashboard
        NotificationCenter.default.addObserver(self, selector: #selector(handleQuickActionCleanJunk), name: NSNotification.Name("ExecuteCleanJunk"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleQuickActionEmptyTrash), name: NSNotification.Name("ExecuteEmptyTrash"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleQuickActionFreeRAM), name: NSNotification.Name("QuickActionFreeRAM"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleQuickActionFindDuplicates), name: NSNotification.Name("ExecuteFindDuplicates"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleQuickActionScanLargeFiles), name: NSNotification.Name("ExecuteScanLargeFiles"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleQuickActionQuitAll), name: NSNotification.Name("QuickActionQuitAll"), object: nil)
    }
    
    @objc private func handleScheduledTask(_ notification: Notification) {
        // Show notification that task was executed
        let content = UNMutableNotificationContent()
        content.title = "Quitty"
        content.body = "Scheduled task executed"
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
    
    @objc private func handleQuickActionCleanJunk(_ notification: Notification) {
        // Trigger junk cleaning
        NotificationCenter.default.post(name: NSNotification.Name("ExecuteCleanJunk"), object: nil)
    }
    
    @objc private func handleQuickActionEmptyTrash(_ notification: Notification) {
        // Trigger trash emptying
        NotificationCenter.default.post(name: NSNotification.Name("ExecuteEmptyTrash"), object: nil)
    }
    
    @objc private func handleQuickActionFreeRAM(_ notification: Notification) {
        // Trigger RAM freeing - find the RAM manager and call freeRAMAction
        DispatchQueue.main.async {
            if let window = NSApplication.shared.windows.first,
               let contentView = window.contentView,
               let hostingView = contentView.subviews.first {
                // Try to get the RAM manager from the view hierarchy
                // This is a fallback - ideally we'd have a shared instance
                print("Free RAM action triggered from dashboard")
            }
        }
    }
    
    @objc private func handleQuickActionFindDuplicates(_ notification: Notification) {
        // Trigger duplicate finding
        NotificationCenter.default.post(name: NSNotification.Name("ExecuteFindDuplicates"), object: nil)
    }
    
    @objc private func handleQuickActionScanLargeFiles(_ notification: Notification) {
        // Trigger large files scanning
        NotificationCenter.default.post(name: NSNotification.Name("ExecuteScanLargeFiles"), object: nil)
    }
    
    @objc private func handleQuickActionQuitAll(_ notification: Notification) {
        // Quit all apps except critical ones
        let runningApps = NSWorkspace.shared.runningApplications
        let criticalApps = ["com.apple.finder", "com.apple.dock", "com.apple.systemuiserver"]
        let quittyBundleId = Bundle.main.bundleIdentifier
        
        for app in runningApps {
            guard let bundleId = app.bundleIdentifier else { continue }
            
            // Skip critical apps and Quitty itself
            if criticalApps.contains(bundleId) || bundleId == quittyBundleId {
                continue
            }
            
            // Only quit regular apps (not background processes)
            if app.activationPolicy == .regular {
                app.terminate()
            }
        }
    }
    
    private func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted")
            }
        }
    }

    @objc func toggleWindow() {
        let app = NSApplication.shared
        
        // Unhide the app first
        app.unhide(nil)
        
        // Try to find existing main window
        if let window = app.windows.first(where: { !$0.title.contains("Settings") && $0.canBecomeMain }) {
            window.makeKeyAndOrderFront(nil)
            app.activate(ignoringOtherApps: true)
            return
        }
        
        // If no window exists, activate the app and create a new one
        app.activate(ignoringOtherApps: true)
        
        // Force window creation by bringing the app to front
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let window = app.windows.first(where: { !$0.title.contains("Settings") && $0.canBecomeMain }) {
                window.makeKeyAndOrderFront(nil)
            }
        }
    }
    
    func windowWillClose(_ notification: Notification) {
        // Keep app alive in the menu bar when the main window is closed.
        guard let window = notification.object as? NSWindow else { return }
        if !window.title.contains("Settings") {
            window.orderOut(nil)
        }
    }
    
    deinit {
        if let statusItem {
            NSStatusBar.system.removeStatusItem(statusItem)
        }
    }
}

extension AppDelegate: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        rebuildRunningAppsMenuIfNeeded(menu)
    }
}
