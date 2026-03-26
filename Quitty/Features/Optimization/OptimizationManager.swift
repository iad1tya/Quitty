import Foundation
import Combine
import Darwin

struct LaunchItem: Identifiable {
    let id = UUID()
    let name: String
    let path: URL
    let label: String
    var isEnabled: Bool
    let isUserAgent: Bool // true = user, false = system (read-only)
    let description: String

    static func descriptionFor(_ label: String) -> String {
        let key = label.lowercased()
        // Known agents
        if key.contains("steam") { return "Steam game platform background service" }
        if key.contains("bluejeans") || key.contains("bluejeansn") { return "BlueJeans video conferencing helper" }
        if key.contains("tunnelblick") { return "Tunnelblick VPN auto-connect at login" }
        if key.contains("cleanmymac") || key.contains("macpaw") {
            if key.contains("scheduler") { return "CleanMyMac scheduled cleanup tasks" }
            if key.contains("updater") || key.contains("update") { return "CleanMyMac auto-updater" }
            return "CleanMyMac background service"
        }
        if key.contains("google") && key.contains("keystone") { return "Google Chrome auto-updater" }
        if key.contains("google") && key.contains("update") { return "Google software updater" }
        if key.contains("spotify") { return "Spotify background helper" }
        if key.contains("discord") { return "Discord auto-update helper" }
        if key.contains("slack") { return "Slack background service" }
        if key.contains("zoom") { return "Zoom video meetings helper" }
        if key.contains("dropbox") { return "Dropbox file sync service" }
        if key.contains("adobe") { return "Adobe Creative Cloud background service" }
        if key.contains("microsoft") { return "Microsoft Office background service" }
        if key.contains("krisp") { return "Krisp AI noise cancellation" }
        if key.contains("1password") || key.contains("onepassword") { return "1Password browser integration helper" }
        if key.contains("raycast") { return "Raycast launcher background service" }
        if key.contains("alfred") { return "Alfred launcher background service" }
        if key.contains("bartender") { return "Bartender menu bar manager" }
        if key.contains("istat") { return "iStat Menus system monitor" }
        if key.contains("little.snitch") || key.contains("littlesnitch") { return "Little Snitch network firewall" }
        if key.contains("karabiner") { return "Karabiner keyboard remapper" }
        if key.contains("backblaze") { return "Backblaze cloud backup service" }
        if key.contains("jetbrains") { return "JetBrains IDE toolbox helper" }
        if key.contains("docker") { return "Docker container engine" }

        // Generic patterns
        if key.contains("update") || key.contains("updater") { return "Auto-update service" }
        if key.contains("helper") || key.contains("agent") { return "Background helper service" }
        if key.contains("launch") && key.contains("login") { return "Auto-start at login" }
        if key.contains("sync") { return "File sync service" }

        return "Background service"
    }
}

struct HeavyProcess: Identifiable {
    let id: Int32 // pid
    let name: String
    let cpuPercent: Double
    let memoryMB: Double
}

class OptimizationManager: ObservableObject {
    @Published var launchItems: [LaunchItem] = []
    @Published var heavyProcesses: [HeavyProcess] = []
    @Published var isScanning = false

    func scan() {
        guard !isScanning else { return }
        
        isScanning = true
        
        // Add timeout to prevent infinite loading
        let workItem = DispatchWorkItem {
            let agents = self.scanLaunchAgents()
            let processes = self.getHeavyProcesses()

            DispatchQueue.main.async {
                self.launchItems = agents
                self.heavyProcesses = processes
                self.isScanning = false
            }
        }
        
        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 0.1, execute: workItem)
        
        // Timeout after 10 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            if workItem.isCancelled {
                return
            }
            workItem.cancel()
            self.isScanning = false
        }
    }

    func toggleAgent(_ item: LaunchItem) {
        guard item.isUserAgent else { return }

        let enabled = item.isEnabled
        let source = item.path
        let disabledPath = source.appendingPathExtension("disabled")
        let enabledPath = URL(fileURLWithPath: source.path.replacingOccurrences(of: ".plist.disabled", with: ".plist"))

        do {
            if enabled {
                // Disable: rename .plist → .plist.disabled
                try FileManager.default.moveItem(at: source, to: disabledPath)
            } else {
                // Enable: rename .plist.disabled → .plist
                try FileManager.default.moveItem(at: source, to: enabledPath)
            }
            scan()
        } catch {
            print("Failed to toggle launch agent: \(error)")
        }
    }

    func killProcess(_ pid: Int32) {
        kill(pid, SIGTERM)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.heavyProcesses.removeAll { $0.id == pid }
            self.refreshHeavyProcesses()
        }
    }

    func refreshHeavyProcesses() {
        DispatchQueue.global(qos: .userInitiated).async {
            let processes = self.getHeavyProcesses()
            DispatchQueue.main.async {
                self.heavyProcesses = processes
            }
        }
    }

    private func scanLaunchAgents() -> [LaunchItem] {
        var items: [LaunchItem] = []
        let home = FileManager.default.homeDirectoryForCurrentUser
        let userAgentsDir = home.appendingPathComponent("Library/LaunchAgents")

        // User Launch Agents
        items.append(contentsOf: scanPlistDirectory(userAgentsDir, isUserAgent: true))

        // System Launch Agents (read-only)
        let systemAgentsDir = URL(fileURLWithPath: "/Library/LaunchAgents")
        items.append(contentsOf: scanPlistDirectory(systemAgentsDir, isUserAgent: false))

        return items.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private func scanPlistDirectory(_ dir: URL, isUserAgent: Bool) -> [LaunchItem] {
        var items: [LaunchItem] = []
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: dir,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) else { return items }

        for url in contents {
            let ext = url.pathExtension
            guard ext == "plist" || url.path.hasSuffix(".plist.disabled") else { continue }

            let isEnabled = ext == "plist" && !url.path.hasSuffix(".plist.disabled")
            let label = url.deletingPathExtension().lastPathComponent
                .replacingOccurrences(of: ".plist", with: "")
            let name = label.components(separatedBy: ".").last ?? label

            items.append(LaunchItem(
                name: name.capitalized,
                path: url,
                label: label,
                isEnabled: isEnabled,
                isUserAgent: isUserAgent,
                description: LaunchItem.descriptionFor(label)
            ))
        }
        return items
    }

    private func getHeavyProcesses() -> [HeavyProcess] {
        // Use `ps` to get CPU usage per process
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/bin/ps")
        process.arguments = ["-eo", "pid,pcpu,rss,comm", "-r"]
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return []
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8) else { return [] }

        var results: [HeavyProcess] = []
        let lines = output.components(separatedBy: "\n").dropFirst() // skip header

        for line in lines.prefix(15) {
            let parts = line.trimmingCharacters(in: .whitespaces)
                .components(separatedBy: .whitespaces)
                .filter { !$0.isEmpty }
            guard parts.count >= 4 else { continue }

            let pid = Int32(parts[0]) ?? 0
            let cpu = Double(parts[1]) ?? 0
            let rss = Double(parts[2]) ?? 0
            let name = URL(fileURLWithPath: parts[3...].joined(separator: " ")).lastPathComponent

            guard cpu > 0.5 || rss > 100_000 else { continue } // Filter low usage
            guard pid != ProcessInfo.processInfo.processIdentifier else { continue }

            results.append(HeavyProcess(
                id: pid,
                name: name,
                cpuPercent: cpu,
                memoryMB: rss / 1024
            ))
        }

        return results
    }
}
