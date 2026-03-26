import Foundation
import Combine

struct JunkCategory: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let color: String
    var size: UInt64 = 0
    var files: [JunkFile] = []
    var isSelected: Bool = true
}

struct JunkFile: Identifiable {
    let id = UUID()
    let name: String
    let path: URL
    let size: UInt64
}

class SystemJunkManager: ObservableObject {
    @Published var categories: [JunkCategory] = []
    @Published var isScanning = false
    @Published var isCleaning = false
    @Published var scanProgress: String = ""

    var totalSize: UInt64 {
        categories.reduce(0) { $0 + $1.size }
    }

    var selectedSize: UInt64 {
        categories.filter { $0.isSelected }.reduce(0) { $0 + $1.size }
    }

    func scan() {
        isScanning = true
        categories = []

        DispatchQueue.global(qos: .userInitiated).async {
            let home = FileManager.default.homeDirectoryForCurrentUser

            var results: [JunkCategory] = []

            // 1. User Caches
            DispatchQueue.main.async { self.scanProgress = "Scanning caches..." }
            let caches = self.scanDirectory(
                home.appendingPathComponent("Library/Caches"),
                maxDepth: 1
            )
            results.append(JunkCategory(name: "User Caches", icon: "folder.fill", color: "blue", size: caches.totalSize, files: caches.files))

            // 2. User Logs
            DispatchQueue.main.async { self.scanProgress = "Scanning logs..." }
            let logs = self.scanDirectory(
                home.appendingPathComponent("Library/Logs"),
                maxDepth: 2
            )
            results.append(JunkCategory(name: "User Logs", icon: "doc.text.fill", color: "orange", size: logs.totalSize, files: logs.files))

            // 3. Crash Reports
            DispatchQueue.main.async { self.scanProgress = "Scanning crash reports..." }
            let crashes = self.scanDirectory(
                home.appendingPathComponent("Library/Logs/DiagnosticReports"),
                maxDepth: 1
            )
            results.append(JunkCategory(name: "Crash Reports", icon: "exclamationmark.triangle.fill", color: "red", size: crashes.totalSize, files: crashes.files))

            // 4. Temporary Files
            DispatchQueue.main.async { self.scanProgress = "Scanning temp files..." }
            let tmp = self.scanDirectory(
                URL(fileURLWithPath: NSTemporaryDirectory()),
                maxDepth: 1
            )
            results.append(JunkCategory(name: "Temporary Files", icon: "clock.fill", color: "purple", size: tmp.totalSize, files: tmp.files))

            // 5. Xcode DerivedData (if exists)
            let derivedData = home.appendingPathComponent("Library/Developer/Xcode/DerivedData")
            if FileManager.default.fileExists(atPath: derivedData.path) {
                DispatchQueue.main.async { self.scanProgress = "Scanning Xcode data..." }
                let xcode = self.scanDirectory(derivedData, maxDepth: 1)
                results.append(JunkCategory(name: "Xcode DerivedData", icon: "hammer.fill", color: "cyan", size: xcode.totalSize, files: xcode.files))
            }

            // 6. Downloads (old files > 30 days)
            DispatchQueue.main.async { self.scanProgress = "Scanning old downloads..." }
            let downloads = self.scanOldFiles(
                home.appendingPathComponent("Downloads"),
                olderThanDays: 30
            )
            results.append(JunkCategory(name: "Old Downloads (30+ days)", icon: "arrow.down.circle.fill", color: "green", size: downloads.totalSize, files: downloads.files, isSelected: false))

            DispatchQueue.main.async {
                self.categories = results.filter { $0.size > 0 }
                self.isScanning = false
                self.scanProgress = ""
            }
        }
    }

    func clean() {
        isCleaning = true
        let toClean = categories.filter { $0.isSelected }

        DispatchQueue.global(qos: .userInitiated).async {
            for category in toClean {
                for file in category.files {
                    try? FileManager.default.removeItem(at: file.path)
                }
            }

            DispatchQueue.main.async {
                self.isCleaning = false
                self.scan()
            }
        }
    }

    private struct ScanResult {
        var totalSize: UInt64 = 0
        var files: [JunkFile] = []
    }

    private func scanDirectory(_ url: URL, maxDepth: Int) -> ScanResult {
        var result = ScanResult()
        guard FileManager.default.fileExists(atPath: url.path) else { return result }

        let contents = (try? FileManager.default.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey, .totalFileAllocatedSizeKey],
            options: [.skipsHiddenFiles]
        )) ?? []

        for item in contents {
            let size = Self.itemSize(item)
            result.totalSize += size
            result.files.append(JunkFile(name: item.lastPathComponent, path: item, size: size))
        }

        result.files.sort { $0.size > $1.size }
        return result
    }

    private func scanOldFiles(_ url: URL, olderThanDays days: Int) -> ScanResult {
        var result = ScanResult()
        guard FileManager.default.fileExists(atPath: url.path) else { return result }
        let cutoff = Date().addingTimeInterval(-Double(days) * 86400)

        let contents = (try? FileManager.default.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey, .totalFileAllocatedSizeKey],
            options: [.skipsHiddenFiles]
        )) ?? []

        for item in contents {
            let values = try? item.resourceValues(forKeys: [.contentModificationDateKey])
            guard let modDate = values?.contentModificationDate, modDate < cutoff else { continue }
            let size = Self.itemSize(item)
            result.totalSize += size
            result.files.append(JunkFile(name: item.lastPathComponent, path: item, size: size))
        }

        result.files.sort { $0.size > $1.size }
        return result
    }

    static func itemSize(_ url: URL) -> UInt64 {
        var isDir: ObjCBool = false
        FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir)

        if isDir.boolValue {
            let keys: Set<URLResourceKey> = [.totalFileAllocatedSizeKey, .fileSizeKey]
            guard let enumerator = FileManager.default.enumerator(
                at: url,
                includingPropertiesForKeys: Array(keys),
                options: [.skipsHiddenFiles]
            ) else { return 0 }

            var total: UInt64 = 0
            for case let fileURL as URL in enumerator {
                let values = try? fileURL.resourceValues(forKeys: keys)
                total += UInt64(values?.totalFileAllocatedSize ?? values?.fileSize ?? 0)
            }
            return total
        } else {
            let values = try? url.resourceValues(forKeys: [.totalFileAllocatedSizeKey, .fileSizeKey])
            return UInt64(values?.totalFileAllocatedSize ?? values?.fileSize ?? 0)
        }
    }

    static func formatBytes(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}
