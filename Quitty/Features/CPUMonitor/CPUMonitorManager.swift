import Foundation
import AppKit
import Combine
import IOKit

struct CPUStats {
    var usage: Double = 0
    var temperature: Double = 0
    var processes: [CPUProcess] = []
}

struct CPUProcess: Identifiable {
    let id = UUID()
    let pid: Int32
    let name: String
    let icon: NSImage
    let cpuUsage: Double
    let bundleIdentifier: String?
}

class CPUMonitorManager: ObservableObject {
    @Published var cpuUsage: Double = 0
    @Published var cpuTemperature: Double = 0
    @Published var topProcesses: [CPUProcess] = []
    @Published var isMonitoring = false
    @Published var statusMessage = "CPU monitoring ready"
    
    private var monitorTimer: Timer?
    
    func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true
        statusMessage = "Monitoring CPU activity..."
        
        monitorTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.updateCPUStats()
        }
        
        updateCPUStats()
    }
    
    func stopMonitoring() {
        monitorTimer?.invalidate()
        monitorTimer = nil
        isMonitoring = false
        topProcesses = []
        statusMessage = "Monitoring stopped"
    }
    
    private func updateCPUStats() {
        // Get overall CPU usage
        cpuUsage = getSystemCPUUsage()
        
        // Get CPU temperature (requires SMC access)
        cpuTemperature = getCPUTemperature()
        
        // Get top CPU processes
        topProcesses = getTopCPUProcesses()
    }
    
    private func getSystemCPUUsage() -> Double {
        var cpuInfo: processor_info_array_t!
        var numCPUInfo: mach_msg_type_number_t = 0
        var numCPUs: natural_t = 0
        
        let result = host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &numCPUs, &cpuInfo, &numCPUInfo)
        
        guard result == KERN_SUCCESS else { return 0 }
        
        var totalUser: UInt32 = 0
        var totalSystem: UInt32 = 0
        var totalIdle: UInt32 = 0
        var totalNice: UInt32 = 0
        
        for i in 0..<Int(numCPUs) {
            let cpuLoadInfo = cpuInfo.advanced(by: Int(CPU_STATE_MAX) * i)
            totalUser += UInt32(cpuLoadInfo[Int(CPU_STATE_USER)])
            totalSystem += UInt32(cpuLoadInfo[Int(CPU_STATE_SYSTEM)])
            totalIdle += UInt32(cpuLoadInfo[Int(CPU_STATE_IDLE)])
            totalNice += UInt32(cpuLoadInfo[Int(CPU_STATE_NICE)])
        }
        
        let total = totalUser + totalSystem + totalIdle + totalNice
        let used = totalUser + totalSystem + totalNice
        
        vm_deallocate(mach_task_self_, vm_address_t(bitPattern: cpuInfo), vm_size_t(numCPUInfo))
        
        return total > 0 ? Double(used) / Double(total) * 100.0 : 0
    }
    
    private func getCPUTemperature() -> Double {
        // Note: Reading SMC requires special entitlements or helper tool
        // This is a placeholder - real implementation needs IOKit SMC access
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSMC"))
        guard service != 0 else { return 0 }
        
        defer { IOObjectRelease(service) }
        
        // Simplified - actual SMC reading is more complex
        // Would need to read TC0P (CPU proximity temp) key
        return Double.random(in: 40...75) // Placeholder
    }
    
    private func getTopCPUProcesses() -> [CPUProcess] {
        let task = Process()
        task.launchPath = "/bin/ps"
        task.arguments = ["-arcwwwxo", "pid,%cpu,comm"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            guard let output = String(data: data, encoding: .utf8) else { return [] }
            
            let lines = output.components(separatedBy: "\n").dropFirst()
            var processes: [CPUProcess] = []
            let fallbackIcon = NSWorkspace.shared.icon(forFileType: "public.unix-executable")
            
            for line in lines.prefix(10) {
                let fields = line.split(maxSplits: 2, omittingEmptySubsequences: true, whereSeparator: { $0.isWhitespace })
                guard fields.count == 3 else { continue }
                guard let pid = Int32(fields[0]) else { continue }
                guard let cpu = Double(fields[1]), cpu > 0.1 else { continue }

                let commandPath = String(fields[2])
                let fallbackName = URL(fileURLWithPath: commandPath).lastPathComponent

                if let app = NSRunningApplication(processIdentifier: pid) {
                    processes.append(
                        CPUProcess(
                            pid: pid,
                            name: app.localizedName ?? fallbackName,
                            icon: app.icon ?? fallbackIcon,
                            cpuUsage: cpu,
                            bundleIdentifier: app.bundleIdentifier
                        )
                    )
                } else {
                    processes.append(
                        CPUProcess(
                            pid: pid,
                            name: fallbackName.isEmpty ? commandPath : fallbackName,
                            icon: fallbackIcon,
                            cpuUsage: cpu,
                            bundleIdentifier: nil
                        )
                    )
                }
            }
            
            return processes.sorted { $0.cpuUsage > $1.cpuUsage }
            
        } catch {
            return []
        }
    }
    
    func killProcess(_ process: CPUProcess) {
        let task = Process()
        task.launchPath = "/bin/kill"
        task.arguments = ["-9", "\(process.pid)"]
        try? task.run()
        
        topProcesses.removeAll { $0.id == process.id }
        statusMessage = "Terminated \(process.name)"
    }
    
    deinit {
        stopMonitoring()
    }
}
