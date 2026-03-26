import Foundation
import UserNotifications
import AppKit
import Combine

class NotificationHelper {
    static let shared = NotificationHelper()
    
    private init() {}
    
    func sendNotification(title: String, body: String, identifier: String = UUID().uuidString) {
        guard UserDefaults.standard.bool(forKey: "enableNotifications") else { return }
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
    
    func checkDiskSpace() {
        guard UserDefaults.standard.bool(forKey: "notifyLowDiskSpace") else { return }
        
        if let homeURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            do {
                let values = try homeURL.resourceValues(forKeys: [.volumeAvailableCapacityKey])
                if let available = values.volumeAvailableCapacity {
                    let availableGB = Double(available) / 1_073_741_824
                    
                    if availableGB < 10 {
                        sendNotification(
                            title: "Low Disk Space",
                            body: String(format: "Only %.1f GB remaining. Consider cleaning up files.", availableGB),
                            identifier: "low-disk-space"
                        )
                    }
                }
            } catch {
                print("Failed to check disk space: \(error)")
            }
        }
    }
    
    func checkRAMUsage() {
        guard UserDefaults.standard.bool(forKey: "notifyHighRAM") else { return }
        
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)
        
        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        
        guard result == KERN_SUCCESS else { return }
        
        let used = UInt64(stats.active_count + stats.wire_count + stats.compressor_page_count) * UInt64(vm_page_size)
        let total = ProcessInfo.processInfo.physicalMemory
        let usagePercent = Double(used) / Double(total) * 100.0
        
        if usagePercent > 90 {
            sendNotification(
                title: "High RAM Usage",
                body: String(format: "RAM usage is at %.0f%%. Consider freeing memory.", usagePercent),
                identifier: "high-ram-usage"
            )
        }
    }
    
    func checkBatteryHealth(health: Int) {
        guard UserDefaults.standard.bool(forKey: "notifyBatteryHealth") else { return }
        
        if health < 80 {
            sendNotification(
                title: "Battery Health Warning",
                body: "Battery health is at \(health)%. Consider servicing your battery.",
                identifier: "battery-health-warning"
            )
        }
    }
}
