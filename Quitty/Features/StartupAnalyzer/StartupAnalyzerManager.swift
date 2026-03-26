import Foundation
import AppKit
import Combine
import SwiftUI
import ServiceManagement

struct StartupItem: Identifiable {
    let id = UUID()
    let name: String
    let bundleIdentifier: String?
    let path: URL
    let type: StartupType
    let icon: NSImage
    var isEnabled: Bool
    var estimatedImpact: StartupImpact
    
    enum StartupType: String {
        case loginItem = "Login Item"
        case launchAgent = "Launch Agent"
        case launchDaemon = "Launch Daemon"
    }
    
    enum StartupImpact: String {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        
        var color: Color {
            switch self {
            case .low: return .green
            case .medium: return .orange
            case .high: return .red
            }
        }
    }
}

class StartupAnalyzerManager: ObservableObject {
    @Published var startupItems: [StartupItem] = []
    @Published var isScanning = false
    @Published var statusMessage = "Ready to analyze"
    @Published var bootTime: TimeInterval = 0
    @Published var estimatedBootTime: TimeInterval = 0
    
    func scanStartupItems() {
        isScanning = true
        statusMessage = "Scanning startup items..."
        startupItems = []
        
        Task {
            var items: [StartupItem] = []
            
            // Get login items
            items.append(contentsOf: await getLoginItems())
            
            // Get launch agents
            items.append(contentsOf: await getLaunchAgents())
            
            // Calculate boot time
            let uptime = getSystemUptime()
            
            await MainActor.run {
                self.startupItems = items.sorted { $0.name < $1.name }
                self.bootTime = uptime
                self.estimatedBootTime = calculateEstimatedBootTime(items: items)
                self.isScanning = false
                self.statusMessage = "Found \(items.count) startup items"
            }
        }
    }
    
    private func getLoginItems() async -> [StartupItem] {
        var items: [StartupItem] = []
        
        // Get SMLoginItems
        if #available(macOS 13.0, *) {
            // Modern API - would need proper implementation
        }
        
        // Scan ~/Library/LaunchAgents for user login items
        let libraryURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/LaunchAgents")
        
        if let enumerator = FileManager.default.enumerator(at: libraryURL, includingPropertiesForKeys: nil) {
            for case let fileURL as URL in enumerator where fileURL.pathExtension == "plist" {
                if let item = parseLoginItem(from: fileURL, type: .loginItem) {
                    items.append(item)
                }
            }
        }
        
        return items
    }
    
    private func getLaunchAgents() async -> [StartupItem] {
        var items: [StartupItem] = []
        
        let agentPaths = [
            FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/LaunchAgents"),
            URL(fileURLWithPath: "/Library/LaunchAgents"),
            URL(fileURLWithPath: "/System/Library/LaunchAgents")
        ]
        
        for agentPath in agentPaths {
            guard let enumerator = FileManager.default.enumerator(
                at: agentPath,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            ) else { continue }
            
            for case let fileURL as URL in enumerator where fileURL.pathExtension == "plist" {
                if let item = parseLoginItem(from: fileURL, type: .launchAgent) {
                    items.append(item)
                }
            }
        }
        
        return items
    }
    
    private func parseLoginItem(from url: URL, type: StartupItem.StartupType) -> StartupItem? {
        guard let plistData = try? Data(contentsOf: url) else { return nil }
        guard let plist = try? PropertyListSerialization.propertyList(from: plistData, format: nil) as? [String: Any] else { return nil }
        
        let label = plist["Label"] as? String ?? url.deletingPathExtension().lastPathComponent
        let disabled = plist["Disabled"] as? Bool ?? false
        
        // Estimate impact based on program path
        var impact: StartupItem.StartupImpact = .low
        if let program = plist["Program"] as? String {
            if program.contains("Adobe") || program.contains("Microsoft") || program.contains("Google") {
                impact = .high
            } else if program.contains("Dropbox") || program.contains("Spotify") {
                impact = .medium
            }
        }
        
        return StartupItem(
            name: label,
            bundleIdentifier: nil,
            path: url,
            type: type,
            icon: NSWorkspace.shared.icon(forFile: url.path),
            isEnabled: !disabled,
            estimatedImpact: impact
        )
    }
    
    private func getSystemUptime() -> TimeInterval {
        var boottime = timeval()
        var size = MemoryLayout<timeval>.stride
        var mib: [Int32] = [CTL_KERN, KERN_BOOTTIME]
        
        if sysctl(&mib, 2, &boottime, &size, nil, 0) == 0 {
            let now = Date().timeIntervalSince1970
            let boot = Double(boottime.tv_sec) + Double(boottime.tv_usec) / 1_000_000.0
            return now - boot
        }
        
        return 0
    }
    
    private func calculateEstimatedBootTime(items: [StartupItem]) -> TimeInterval {
        let enabledItems = items.filter { $0.isEnabled }
        var total: TimeInterval = 15.0 // Base boot time
        
        for item in enabledItems {
            switch item.estimatedImpact {
            case .low: total += 0.5
            case .medium: total += 2.0
            case .high: total += 5.0
            }
        }
        
        return total
    }
    
    func toggleStartupItem(_ item: StartupItem) {
        // Toggle enabled/disabled state in plist
        guard let plistData = try? Data(contentsOf: item.path) else { return }
        guard var plist = try? PropertyListSerialization.propertyList(from: plistData, format: nil) as? [String: Any] else { return }
        
        plist["Disabled"] = !item.isEnabled
        
        if let newData = try? PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0) {
            try? newData.write(to: item.path)
        }
        
        // Update in list
        if let index = startupItems.firstIndex(where: { $0.id == item.id }) {
            startupItems[index].isEnabled.toggle()
            estimatedBootTime = calculateEstimatedBootTime(items: startupItems)
        }
    }
    
    func removeStartupItem(_ item: StartupItem) {
        try? FileManager.default.trashItem(at: item.path, resultingItemURL: nil)
        startupItems.removeAll { $0.id == item.id }
        estimatedBootTime = calculateEstimatedBootTime(items: startupItems)
        statusMessage = "Removed \(item.name)"
    }
}
