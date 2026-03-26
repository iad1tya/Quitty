import Foundation
import AppKit
import Combine

struct LargeFile: Identifiable {
    let id = UUID()
    let url: URL
    let size: UInt64
    let modifiedDate: Date
    
    var name: String { url.lastPathComponent }
    var path: String { url.path }
    var sizeFormatted: String {
        ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)
    }
}

class LargeFilesManager: ObservableObject {
    @Published var files: [LargeFile] = []
    @Published var isScanning = false
    @Published var progress: Double = 0
    @Published var statusMessage = "Ready to scan"
    @Published var minimumSize: UInt64 = 100 * 1024 * 1024 // 100 MB default
    @Published var selectedFiles: Set<UUID> = []
    
    private var scanTask: Task<Void, Never>?
    
    func startScan(in directory: URL = FileManager.default.homeDirectoryForCurrentUser) {
        guard !isScanning else { return }
        
        isScanning = true
        files = []
        progress = 0
        statusMessage = "Scanning for large files..."
        
        scanTask = Task {
            await scanDirectory(directory)
            
            await MainActor.run {
                isScanning = false
                statusMessage = "Found \(files.count) large files"
            }
        }
    }
    
    func cancelScan() {
        scanTask?.cancel()
        isScanning = false
        statusMessage = "Scan cancelled"
    }
    
    private func scanDirectory(_ directory: URL) async {
        let fileManager = FileManager.default
        guard let enumerator = fileManager.enumerator(
            at: directory,
            includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey, .isDirectoryKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else { return }
        
        var foundFiles: [LargeFile] = []
        var scannedCount = 0
        
        for case let fileURL as URL in enumerator {
            if Task.isCancelled { break }
            
            scannedCount += 1
            if scannedCount % 100 == 0 {
                await MainActor.run {
                    statusMessage = "Scanned \(scannedCount) items..."
                }
            }
            
            do {
                let resourceValues = try fileURL.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey, .isDirectoryKey])
                
                guard let isDirectory = resourceValues.isDirectory, !isDirectory else { continue }
                guard let size = resourceValues.fileSize, UInt64(size) >= minimumSize else { continue }
                guard let modifiedDate = resourceValues.contentModificationDate else { continue }
                
                let largeFile = LargeFile(url: fileURL, size: UInt64(size), modifiedDate: modifiedDate)
                foundFiles.append(largeFile)
                
            } catch {
                continue
            }
        }
        
        // Sort by size descending
        foundFiles.sort { $0.size > $1.size }
        
        await MainActor.run {
            self.files = foundFiles
        }
    }
    
    func deleteSelectedFiles() {
        let filesToDelete = files.filter { selectedFiles.contains($0.id) }
        
        for file in filesToDelete {
            do {
                try FileManager.default.trashItem(at: file.url, resultingItemURL: nil)
            } catch {
                print("Failed to delete \(file.name): \(error)")
            }
        }
        
        files.removeAll { selectedFiles.contains($0.id) }
        selectedFiles.removeAll()
        statusMessage = "Deleted \(filesToDelete.count) files"
    }
    
    func revealInFinder(_ file: LargeFile) {
        NSWorkspace.shared.activateFileViewerSelecting([file.url])
    }
}
