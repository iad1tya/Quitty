import Foundation
import Combine
import SwiftUI
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

    func freeRAMAction() {
        isFreeing = true
        DispatchQueue.global(qos: .userInitiated).async {
            // Use memory_pressure to encourage the system to free memory
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/memory_pressure")
            process.arguments = ["-l", "warn"]
            process.standardOutput = FileHandle.nullDevice
            process.standardError = FileHandle.nullDevice
            try? process.run()
            process.waitUntilExit()

            Thread.sleep(forTimeInterval: 1.0)

            DispatchQueue.main.async {
                self.refresh()
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
