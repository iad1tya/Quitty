import Foundation
import Combine
import AppKit

class TrashBinsManager: ObservableObject {
    @Published var trashSize: UInt64 = 0
    @Published var fileCount: Int = 0
    @Published var isScanning = false
    @Published var isEmptying = false
    @Published var items: [TrashItem] = []

    struct TrashItem: Identifiable {
        let id = UUID()
        let name: String
        let size: String
        let kind: String
    }

    init() {
        scan()
    }

    func scan() {
        isScanning = true
        DispatchQueue.global(qos: .userInitiated).async {
            // Use 'du' via Finder's trash path for size
            var totalSize: UInt64 = 0
            var count = 0
            var trashItems: [TrashItem] = []

            // Method 1: Try direct FileManager access
            let trashURL = FileManager.default.urls(for: .trashDirectory, in: .userDomainMask).first
                ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent(".Trash")

            let directAccess = self.scanDirectly(trashURL)

            if directAccess.count > 0 {
                totalSize = directAccess.totalSize
                count = directAccess.count
                trashItems = directAccess.items
            } else {
                // Method 2: Fallback to AppleScript via Finder
                let result = self.scanViaFinder()
                totalSize = result.totalSize
                count = result.count
                trashItems = result.items
            }

            DispatchQueue.main.async {
                self.trashSize = totalSize
                self.fileCount = count
                self.items = trashItems
                self.isScanning = false
            }
        }
    }

    private struct ScanResult {
        var totalSize: UInt64 = 0
        var count: Int = 0
        var items: [TrashItem] = []
    }

    private func scanDirectly(_ trashURL: URL) -> ScanResult {
        var result = ScanResult()
        let resourceKeys: Set<URLResourceKey> = [.fileSizeKey, .totalFileAllocatedSizeKey]

        guard let topLevel = try? FileManager.default.contentsOfDirectory(
            at: trashURL,
            includingPropertiesForKeys: Array(resourceKeys),
            options: []
        ), !topLevel.isEmpty else { return result }

        for url in topLevel {
            let size = Self.directorySize(url)
            result.totalSize += size
            result.count += 1
            result.items.append(TrashItem(
                name: url.lastPathComponent,
                size: Self.formatBytes(size),
                kind: url.pathExtension.isEmpty ? "Folder" : url.pathExtension.uppercased()
            ))
        }
        result.items.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        return result
    }

    private func scanViaFinder() -> ScanResult {
        var result = ScanResult()

        // Get item count and names via AppleScript
        let countScript = NSAppleScript(source: """
            tell application "System Events"
                set trashPath to (path to trash folder) as text
                set trashFolder to folder trashPath
                set itemCount to count of disk items of trashFolder
                set itemNames to {}
                repeat with anItem in disk items of trashFolder
                    set end of itemNames to name of anItem
                end repeat
                return (itemCount as text) & "|" & (itemNames as text)
            end tell
        """)

        var error: NSDictionary?
        if let descriptor = countScript?.executeAndReturnError(&error),
           let output = descriptor.stringValue {
            let parts = output.components(separatedBy: "|")
            result.count = Int(parts.first ?? "0") ?? 0

            if parts.count > 1 {
                let names = parts[1].components(separatedBy: ", ")
                for name in names {
                    let trimmed = name.trimmingCharacters(in: CharacterSet.whitespaces)
                    guard !trimmed.isEmpty else { continue }
                    result.items.append(TrashItem(
                        name: trimmed,
                        size: "",
                        kind: ""
                    ))
                }
            }
        }

        // Get total size via du command on trash
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/du")
        process.arguments = ["-sk", NSHomeDirectory() + "/.Trash"]
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                let sizeStr = output.trimmingCharacters(in: .whitespaces).components(separatedBy: "\t").first ?? "0"
                result.totalSize = (UInt64(sizeStr) ?? 0) * 1024 // du -sk gives KB
            }
        } catch {
            // Fallback: try ls approach
        }

        return result
    }

    func emptyTrash() {
        isEmptying = true
        DispatchQueue.global(qos: .userInitiated).async {
            // Use osascript directly — more reliable than NSAppleScript
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
            process.arguments = ["-e", "tell application \"Finder\" to empty the trash"]
            process.standardOutput = FileHandle.nullDevice
            process.standardError = FileHandle.nullDevice
            do {
                try process.run()
                process.waitUntilExit()
            } catch {
                print("Empty trash failed: \(error)")
            }

            Thread.sleep(forTimeInterval: 2.0)

            DispatchQueue.main.async {
                self.isEmptying = false
                self.scan()
            }
        }
    }

    static func directorySize(_ url: URL) -> UInt64 {
        let keys: Set<URLResourceKey> = [.totalFileAllocatedSizeKey, .fileSizeKey]
        var isDir: ObjCBool = false
        FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir)

        if isDir.boolValue {
            guard let enumerator = FileManager.default.enumerator(
                at: url,
                includingPropertiesForKeys: Array(keys),
                options: []
            ) else { return 0 }

            var total: UInt64 = 0
            for case let fileURL as URL in enumerator {
                let values = try? fileURL.resourceValues(forKeys: keys)
                total += UInt64(values?.totalFileAllocatedSize ?? values?.fileSize ?? 0)
            }
            return total
        } else {
            let values = try? url.resourceValues(forKeys: keys)
            return UInt64(values?.totalFileAllocatedSize ?? values?.fileSize ?? 0)
        }
    }

    static func formatBytes(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}
