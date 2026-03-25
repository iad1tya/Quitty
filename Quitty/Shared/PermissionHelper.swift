import Foundation
import AppKit

struct PermissionHelper {
    /// Check if app has Full Disk Access by trying to read ~/.Trash
    static var hasFullDiskAccess: Bool {
        let trashPath = NSHomeDirectory() + "/.Trash"
        return FileManager.default.isReadableFile(atPath: trashPath)
    }

    /// Open System Settings → Full Disk Access
    static func openFullDiskAccessSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles") {
            NSWorkspace.shared.open(url)
        }
    }
}
