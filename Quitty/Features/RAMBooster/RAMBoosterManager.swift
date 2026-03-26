import Foundation
import Combine
import SwiftUI
import AppKit
import Darwin

class RAMBoosterManager: ObservableObject {
    @Published var totalRAM: UInt64 = 0
    @Published var usedRAM: UInt64 = 0
    @Published var freeRAM: UInt64 = 0
    @Published var activeRAM: UInt64 = 0
    @Published var wiredRAM: UInt64 = 0
    @Published var compressedRAM: UInt64 = 0
    @Published var isFreeing = false

    var usagePercent: Double {
        guard totalRAM > 0 else { return 0 }
        return Double(usedRAM) / Double(totalRAM)
    }

    var pressureColor: Color {
        if usagePercent < 0.6 { return .green }
        if usagePercent < 0.8 { return .orange }
        return .red
    }

    init() {
        totalRAM = ProcessInfo.processInfo.physicalMemory
        refresh()
    }

    func refresh() {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.stride / MemoryLayout<integer_t>.stride)
        let pageSize = UInt64(vm_kernel_page_size)

        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }

        guard result == KERN_SUCCESS else { return }

        let active = UInt64(stats.active_count) * pageSize
        let wired = UInt64(stats.wire_count) * pageSize
        let compressed = UInt64(stats.compressor_page_count) * pageSize
        let free = UInt64(stats.free_count) * pageSize
        let inactive = UInt64(stats.inactive_count) * pageSize

        DispatchQueue.main.async {
            self.activeRAM = active
            self.wiredRAM = wired
            self.compressedRAM = compressed
            self.freeRAM = free + inactive
            self.usedRAM = self.totalRAM - self.freeRAM
        }
    }

    @Published var freedAmount: UInt64 = 0

    func freeRAMAction() {
        isFreeing = true
        freedAmount = 0
        let beforeUsed = usedRAM

        DispatchQueue.global(qos: .userInitiated).async {
            // 1. Kill heavy background/helper processes (not regular apps)
            let apps = NSWorkspace.shared.runningApplications
            let safeList = SafeListManager.shared.safeAppIDs
            let quittyPid = ProcessInfo.processInfo.processIdentifier

            for app in apps {
                guard let bid = app.bundleIdentifier else { continue }
                if safeList.contains(bid) { continue }
                if app.processIdentifier == quittyPid { continue }
                if bid == "com.apple.finder" || bid == "com.apple.dock" { continue }

                var info = proc_taskinfo()
                let size = MemoryLayout<proc_taskinfo>.stride
                let result = proc_pidinfo(app.processIdentifier, PROC_PIDTASKINFO, 0, &info, Int32(size))
                guard result == size else { continue }
                let mb = Double(info.pti_resident_size) / (1024 * 1024)

                // Terminate hidden regular apps using > 200 MB
                if app.activationPolicy == .regular && app.isHidden && mb > 200 {
                    app.terminate()
                }
                // Terminate background agents using > 300 MB
                if app.activationPolicy != .regular && mb > 300 {
                    app.terminate()
                }
            }

            // 2. Flush disk caches via sync
            let syncProc = Process()
            syncProc.executableURL = URL(fileURLWithPath: "/bin/sync")
            try? syncProc.run()
            syncProc.waitUntilExit()

            // 3. Clear user font caches, quicklook caches
            let atsutil = Process()
            atsutil.executableURL = URL(fileURLWithPath: "/usr/bin/atsutil")
            atsutil.arguments = ["databases", "-removeUser"]
            atsutil.standardOutput = FileHandle.nullDevice
            atsutil.standardError = FileHandle.nullDevice
            try? atsutil.run()
            atsutil.waitUntilExit()

            Thread.sleep(forTimeInterval: 2.0)

            DispatchQueue.main.async {
                self.refresh()
                if beforeUsed > self.usedRAM {
                    self.freedAmount = beforeUsed - self.usedRAM
                }
                self.isFreeing = false
            }
        }
    }

    static func formatBytes(_ bytes: UInt64) -> String {
        let gb = Double(bytes) / (1024 * 1024 * 1024)
        if gb >= 1.0 {
            return String(format: "%.1f GB", gb)
        }
        let mb = Double(bytes) / (1024 * 1024)
        return String(format: "%.0f MB", mb)
    }
}
