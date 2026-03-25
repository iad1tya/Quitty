import Foundation
import Combine
import AppKit

struct StorageItem: Identifiable {
    let id = UUID()
    let name: String
    let path: URL
    let size: UInt64
    let isDirectory: Bool
    let icon: NSImage?
    var children: [StorageItem]?
}

class StorageAnalyzer: ObservableObject {
    @Published var items: [StorageItem] = []
    @Published var currentPath: URL = FileManager.default.homeDirectoryForCurrentUser
    @Published var pathHistory: [URL] = []
    @Published var isScanning = false
    @Published var scanProgress: String = ""
    @Published var totalDiskSize: UInt64 = 0
    @Published var usedDiskSize: UInt64 = 0
    @Published var freeDiskSize: UInt64 = 0

    init() {
        refreshDiskInfo()
    }

    func refreshDiskInfo() {
        do {
            let attrs = try FileManager.default.attributesOfFileSystem(forPath: "/")
            totalDiskSize = (attrs[.systemSize] as? UInt64) ?? 0
            freeDiskSize = (attrs[.systemFreeSize] as? UInt64) ?? 0
            usedDiskSize = totalDiskSize - freeDiskSize
        } catch {
            print("Failed to get disk info: \(error)")
        }
    }

    func scan(at url: URL? = nil) {
        let targetURL = url ?? currentPath
        isScanning = true
        scanProgress = "Scanning \(targetURL.lastPathComponent)..."

        DispatchQueue.global(qos: .userInitiated).async {
            let results = self.analyzeDirectory(targetURL)

            DispatchQueue.main.async {
                self.currentPath = targetURL
                self.items = results.sorted { $0.size > $1.size }
                self.isScanning = false
                self.scanProgress = ""
            }
        }
    }

    func navigateInto(_ item: StorageItem) {
        guard item.isDirectory else { return }
        pathHistory.append(currentPath)
        scan(at: item.path)
    }

    func navigateBack() {
        guard let previous = pathHistory.popLast() else { return }
        scan(at: previous)
    }

    func navigateHome() {
        pathHistory.removeAll()
        scan(at: FileManager.default.homeDirectoryForCurrentUser)
    }

    func revealInFinder(_ url: URL) {
        NSWorkspace.shared.selectFile(url.path, inFileViewerRootedAtPath: url.deletingLastPathComponent().path)
    }

    private func analyzeDirectory(_ url: URL) -> [StorageItem] {
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey, .totalFileAllocatedSizeKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }

        var items: [StorageItem] = []

        for itemURL in contents {
            let values = try? itemURL.resourceValues(forKeys: [.isDirectoryKey])
            let isDir = values?.isDirectory ?? false

            let size: UInt64
            if isDir {
                size = Self.directorySize(itemURL)
            } else {
                let fileValues = try? itemURL.resourceValues(forKeys: [.totalFileAllocatedSizeKey, .fileSizeKey])
                size = UInt64(fileValues?.totalFileAllocatedSize ?? fileValues?.fileSize ?? 0)
            }

            let icon = NSWorkspace.shared.icon(forFile: itemURL.path)
            icon.size = NSSize(width: 20, height: 20)

            items.append(StorageItem(
                name: itemURL.lastPathComponent,
                path: itemURL,
                size: size,
                isDirectory: isDir,
                icon: icon
            ))
        }

        return items
    }

    static func directorySize(_ url: URL) -> UInt64 {
        let keys: Set<URLResourceKey> = [.totalFileAllocatedSizeKey, .fileSizeKey]
        guard let enumerator = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: Array(keys),
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else { return 0 }

        var total: UInt64 = 0
        for case let fileURL as URL in enumerator {
            let values = try? fileURL.resourceValues(forKeys: keys)
            total += UInt64(values?.totalFileAllocatedSize ?? values?.fileSize ?? 0)
        }
        return total
    }

    static func formatBytes(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}
