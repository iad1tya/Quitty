import Foundation
import AppKit
import Combine
import SystemConfiguration

struct NetworkProcess: Identifiable {
    let id = UUID()
    let pid: Int32
    let name: String
    let bundleIdentifier: String?
    let icon: NSImage
    var bytesIn: UInt64 = 0
    var bytesOut: UInt64 = 0
    var packetsIn: UInt64 = 0
    var packetsOut: UInt64 = 0
    
    var downloadSpeed: String {
        ByteCountFormatter.string(fromByteCount: Int64(bytesIn), countStyle: .file) + "/s"
    }
    
    var uploadSpeed: String {
        ByteCountFormatter.string(fromByteCount: Int64(bytesOut), countStyle: .file) + "/s"
    }
    
    var totalTraffic: UInt64 {
        bytesIn + bytesOut
    }
}

class NetworkMonitorManager: ObservableObject {
    @Published var processes: [NetworkProcess] = []
    @Published var totalDownload: UInt64 = 0
    @Published var totalUpload: UInt64 = 0
    @Published var isMonitoring = false
    @Published var statusMessage = "Network monitoring ready"
    
    private var monitorTimer: Timer?
    private var previousStats: [Int32: (bytesIn: UInt64, bytesOut: UInt64)] = [:]
    
    func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true
        statusMessage = "Monitoring network activity..."
        
        monitorTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateNetworkStats()
        }
        
        updateNetworkStats()
    }
    
    func stopMonitoring() {
        monitorTimer?.invalidate()
        monitorTimer = nil
        isMonitoring = false
        processes = []
        statusMessage = "Monitoring stopped"
    }
    
    private func updateNetworkStats() {
        let workspace = NSWorkspace.shared
        let runningApps = workspace.runningApplications.filter { !$0.isTerminated }
        
        var newProcesses: [NetworkProcess] = []
        var totalDown: UInt64 = 0
        var totalUp: UInt64 = 0
        
        for app in runningApps {
            let pid = app.processIdentifier
            
            // Simulate network stats (in real implementation, use nettop or lsof)
            let bytesIn = UInt64.random(in: 0...1024*1024)
            let bytesOut = UInt64.random(in: 0...512*1024)
            
            if bytesIn > 0 || bytesOut > 0 {
                let process = NetworkProcess(
                    pid: pid,
                    name: app.localizedName ?? "Unknown",
                    bundleIdentifier: app.bundleIdentifier,
                    icon: app.icon ?? NSImage(),
                    bytesIn: bytesIn,
                    bytesOut: bytesOut,
                    packetsIn: 0,
                    packetsOut: 0
                )
                
                newProcesses.append(process)
                totalDown += bytesIn
                totalUp += bytesOut
            }
        }
        
        newProcesses.sort { $0.totalTraffic > $1.totalTraffic }
        
        DispatchQueue.main.async {
            self.processes = newProcesses
            self.totalDownload = totalDown
            self.totalUpload = totalUp
        }
    }
    
    func killProcess(_ process: NetworkProcess) {
        let task = Process()
        task.launchPath = "/bin/kill"
        task.arguments = ["-9", "\(process.pid)"]
        try? task.run()
        
        processes.removeAll { $0.id == process.id }
        statusMessage = "Terminated \(process.name)"
    }
    
    deinit {
        stopMonitoring()
    }
}
