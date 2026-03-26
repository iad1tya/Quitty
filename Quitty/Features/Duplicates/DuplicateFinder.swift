import Foundation
import Combine
import CryptoKit

struct DuplicateGroup: Identifiable {
    let id = UUID()
    let hash: String
    let fileSize: UInt64
    var files: [DuplicateFile]

    var wastedSpace: UInt64 {
        fileSize * UInt64(max(0, files.count - 1))
    }
}

struct DuplicateFile: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let path: URL
    let size: UInt64
    var isSelected: Bool = false

    func hash(into hasher: inout Hasher) {
        hasher.combine(path)
    }

    static func == (lhs: DuplicateFile, rhs: DuplicateFile) -> Bool {
        lhs.path == rhs.path
    }
}

class DuplicateFinderManager: ObservableObject {
    @Published var groups: [DuplicateGroup] = []
    @Published var isScanning = false
    @Published var isDeleting = false
    @Published var scanProgress: String = ""
    @Published var filesScanned: Int = 0
    @Published var scanPhase: ScanPhase = .idle
    @Published var hashProgress: Double = 0 // 0.0 to 1.0

    enum ScanPhase {
        case idle, indexing, comparing, done
    }
    @Published var searchPath: URL = FileManager.default.homeDirectoryForCurrentUser
    @Published var minFileSize: UInt64 = 1024 * 1024 // 1 MB minimum

    private var cancelled = false

    var totalWastedSpace: UInt64 {
        groups.reduce(0) { $0 + $1.wastedSpace }
    }

    var selectedCount: Int {
        groups.reduce(0) { $0 + $1.files.filter { $0.isSelected }.count }
    }

    var selectedSize: UInt64 {
        groups.reduce(0) { total, group in
            total + group.files.filter { $0.isSelected }.reduce(0) { $0 + $1.size }
        }
    }

    func cancelScan() {
        cancelled = true
    }

    func scan() {
        cancelled = false
        isScanning = true
        groups = []
        filesScanned = 0
        hashProgress = 0
        scanPhase = .indexing

        DispatchQueue.global(qos: .userInitiated).async {
            // Pass 1: Group files by size
            DispatchQueue.main.async { self.scanProgress = "Indexing files..." }

            var sizeMap: [UInt64: [URL]] = [:]
            let keys: Set<URLResourceKey> = [.fileSizeKey, .isDirectoryKey, .isRegularFileKey]

            guard let enumerator = FileManager.default.enumerator(
                at: self.searchPath,
                includingPropertiesForKeys: Array(keys),
                options: [.skipsHiddenFiles, .skipsPackageDescendants]
            ) else {
                DispatchQueue.main.async {
                    self.isScanning = false
                    self.scanProgress = ""
                }
                return
            }

            // Skip folders that trigger permission prompts or are not useful
            let skipPrefixes = [
                "Music", "Photos", "Movies", "Library",
                ".Trash", ".cache", "node_modules",
                "Pictures/Photos Library.photoslibrary",
                "Applications"
            ]

            var count = 0
            let basePath = self.searchPath.path + "/"
            for case let url as URL in enumerator {
                if self.cancelled { break }

                // Skip protected/noisy directories
                let fullPath = url.path
                if fullPath.hasPrefix(basePath) {
                    let relative = String(fullPath.dropFirst(basePath.count))
                    let shouldSkip = skipPrefixes.contains { prefix in
                        relative == prefix || relative.hasPrefix(prefix + "/")
                    }
                    if shouldSkip {
                        enumerator.skipDescendants()
                        continue
                    }
                }

                let values = try? url.resourceValues(forKeys: keys)
                guard values?.isRegularFile == true else { continue }
                let size = UInt64(values?.fileSize ?? 0)
                guard size >= self.minFileSize else { continue }

                sizeMap[size, default: []].append(url)
                count += 1

                if count % 500 == 0 {
                    DispatchQueue.main.async { self.filesScanned = count }
                }
            }

            if self.cancelled {
                DispatchQueue.main.async {
                    self.isScanning = false
                    self.scanProgress = ""
                    self.scanPhase = .idle
                }
                return
            }

            DispatchQueue.main.async {
                self.filesScanned = count
                self.scanPhase = .comparing
            }

            // Pass 2: Hash only files with matching sizes
            let candidates = sizeMap.filter { $0.value.count >= 2 }
            let totalToHash = candidates.values.reduce(0) { $0 + $1.count }
            var hashMap: [String: [URL]] = [:]
            var hashed = 0

            DispatchQueue.main.async {
                self.scanProgress = "Comparing \(totalToHash) files..."
            }

            for (_, urls) in candidates {
                if self.cancelled { break }
                for url in urls {
                    if self.cancelled { break }
                    if let hash = self.hashFile(url) {
                        hashMap[hash, default: []].append(url)
                    }
                    hashed += 1
                    if hashed % 10 == 0 {
                        let progress = totalToHash > 0 ? Double(hashed) / Double(totalToHash) : 0
                        DispatchQueue.main.async {
                            self.hashProgress = progress
                            self.scanProgress = "Comparing files... \(hashed)/\(totalToHash)"
                        }
                    }
                }
            }

            if self.cancelled {
                DispatchQueue.main.async {
                    self.isScanning = false
                    self.scanProgress = ""
                    self.scanPhase = .idle
                }
                return
            }

            // Build groups
            let duplicateGroups = hashMap
                .filter { $0.value.count >= 2 }
                .map { (hash, urls) -> DuplicateGroup in
                    let size = (try? urls.first?.resourceValues(forKeys: [.fileSizeKey]))?.fileSize.map { UInt64($0) } ?? 0
                    let files = urls.map { url in
                        DuplicateFile(name: url.lastPathComponent, path: url, size: size ?? 0)
                    }
                    return DuplicateGroup(hash: hash, fileSize: size ?? 0, files: files)
                }
                .sorted { $0.wastedSpace > $1.wastedSpace }

            DispatchQueue.main.async {
                self.groups = duplicateGroups
                self.isScanning = false
                self.scanProgress = ""
                self.scanPhase = .done
                self.hashProgress = 1.0
            }
        }
    }

    func deleteSelected() {
        isDeleting = true
        DispatchQueue.global(qos: .userInitiated).async {
            for group in self.groups {
                for file in group.files where file.isSelected {
                    try? FileManager.default.trashItem(at: file.path, resultingItemURL: nil)
                }
            }

            DispatchQueue.main.async {
                // Remove deleted files from groups
                self.groups = self.groups.compactMap { group in
                    var updated = group
                    updated.files.removeAll { $0.isSelected }
                    return updated.files.count >= 2 ? updated : nil
                }
                self.isDeleting = false
            }
        }
    }

    func selectAllDuplicates() {
        for i in groups.indices {
            // Select all except the first file in each group (keep original)
            for j in groups[i].files.indices {
                groups[i].files[j].isSelected = j > 0
            }
        }
    }

    func deselectAll() {
        for i in groups.indices {
            for j in groups[i].files.indices {
                groups[i].files[j].isSelected = false
            }
        }
    }

    private func hashFile(_ url: URL, bytesToRead: Int = 4096) -> String? {
        // Use DispatchSemaphore to timeout if file read blocks (e.g. permission prompts)
        var result: String?
        let semaphore = DispatchSemaphore(value: 0)

        DispatchQueue.global(qos: .utility).async {
            guard let handle = try? FileHandle(forReadingFrom: url) else {
                semaphore.signal()
                return
            }
            defer { try? handle.close() }

            let data = handle.readData(ofLength: bytesToRead)
            guard !data.isEmpty else {
                semaphore.signal()
                return
            }

            let digest = SHA256.hash(data: data)
            result = digest.compactMap { String(format: "%02x", $0) }.joined()
            semaphore.signal()
        }

        // Wait max 2 seconds per file — skip if it blocks
        let timeout = semaphore.wait(timeout: .now() + 2)
        if timeout == .timedOut {
            return nil
        }
        return result
    }

    static func formatBytes(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}
