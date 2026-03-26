import Foundation
import AppKit
import Combine

class ReportExporter {
    static let shared = ReportExporter()
    
    private init() {}
    
    func exportSystemReport() {
        var report = "Quitty System Report\n"
        report += "Generated: \(Date())\n"
        report += "=================================\n\n"
        
        // System Info
        report += "SYSTEM INFORMATION\n"
        report += "------------------\n"
        report += "macOS Version: \(ProcessInfo.processInfo.operatingSystemVersionString)\n"
        report += "Computer Name: \(Host.current().localizedName ?? "Unknown")\n"
        report += "RAM: \(ByteCountFormatter.string(fromByteCount: Int64(ProcessInfo.processInfo.physicalMemory), countStyle: .memory))\n\n"
        
        // RAM Stats
        report += "MEMORY USAGE\n"
        report += "------------\n"
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)
        
        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        
        if result == KERN_SUCCESS {
            let pageSize = UInt64(vm_page_size)
            let active = UInt64(stats.active_count) * pageSize
            let wired = UInt64(stats.wire_count) * pageSize
            let compressed = UInt64(stats.compressor_page_count) * pageSize
            let free = UInt64(stats.free_count) * pageSize
            
            report += "Active: \(ByteCountFormatter.string(fromByteCount: Int64(active), countStyle: .memory))\n"
            report += "Wired: \(ByteCountFormatter.string(fromByteCount: Int64(wired), countStyle: .memory))\n"
            report += "Compressed: \(ByteCountFormatter.string(fromByteCount: Int64(compressed), countStyle: .memory))\n"
            report += "Free: \(ByteCountFormatter.string(fromByteCount: Int64(free), countStyle: .memory))\n\n"
        }
        
        // Disk Space
        report += "DISK SPACE\n"
        report += "----------\n"
        if let homeURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            do {
                let values = try homeURL.resourceValues(forKeys: [.volumeAvailableCapacityKey, .volumeTotalCapacityKey])
                if let available = values.volumeAvailableCapacity, let total = values.volumeTotalCapacity {
                    report += "Total: \(ByteCountFormatter.string(fromByteCount: Int64(total), countStyle: .file))\n"
                    report += "Available: \(ByteCountFormatter.string(fromByteCount: Int64(available), countStyle: .file))\n"
                    report += "Used: \(ByteCountFormatter.string(fromByteCount: Int64(total - available), countStyle: .file))\n\n"
                }
            } catch {}
        }
        
        // Save report
        saveReport(report)
    }
    
    func exportCSV(title: String, headers: [String], rows: [[String]]) {
        var csv = headers.joined(separator: ",") + "\n"
        
        for row in rows {
            let escapedRow = row.map { "\"\($0)\"" }
            csv += escapedRow.joined(separator: ",") + "\n"
        }
        
        saveFile(content: csv, defaultName: "\(title.replacingOccurrences(of: " ", with: "_")).csv")
    }
    
    private func saveReport(_ content: String) {
        saveFile(content: content, defaultName: "Quitty_Report.txt")
    }
    
    private func saveFile(content: String, defaultName: String) {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = defaultName
        panel.canCreateDirectories = true
        
        if panel.runModal() == .OK, let url = panel.url {
            do {
                try content.write(to: url, atomically: true, encoding: .utf8)
                
                // Show success notification
                NotificationHelper.shared.sendNotification(
                    title: "Export Successful",
                    body: "Report saved to \(url.lastPathComponent)"
                )
                
                // Reveal in Finder
                NSWorkspace.shared.activateFileViewerSelecting([url])
            } catch {
                print("Failed to save report: \(error)")
            }
        }
    }
}
