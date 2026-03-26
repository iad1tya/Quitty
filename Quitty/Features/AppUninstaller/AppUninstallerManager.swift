import Foundation
import AppKit
import Combine

struct InstalledApp: Identifiable {
    let id = UUID()
    let name: String
    let bundleIdentifier: String
    let url: URL
    let size: UInt64
    let version: String
    let icon: NSImage
    
    var sizeFormatted: String {
        ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)
    }
    
    var relatedFiles: [URL] = []
    var totalSize: UInt64 = 0
}

class AppUninstallerManager: ObservableObject {
    @Published var apps: [InstalledApp] = []
    @Published var isScanning = false
    @Published var statusMessage = "Ready to scan"
    @Published var selectedApp: InstalledApp?
    @Published var showingDeleteConfirmation = false
    
    func scanInstalledApps() {
        isScanning = true
        statusMessage = "Scanning installed applications..."
        apps = []
        
        Task {
            var foundApps: [InstalledApp] = []
            let fileManager = FileManager.default
            
            // Scan /Applications and ~/Applications
            let appFolders = [
                URL(fileURLWithPath: "/Applications"),
                fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Applications")
            ]
            
            for folder in appFolders {
                guard let enumerator = fileManager.enumerator(
                    at: folder,
                    includingPropertiesForKeys: [.isDirectoryKey],
                    options: [.skipsHiddenFiles]
                ) else { continue }
                
                for case let fileURL as URL in enumerator {
                    if fileURL.pathExtension == "app" {
                        if let app = await createInstalledApp(from: fileURL) {
                            foundApps.append(app)
                        }
                        enumerator.skipDescendants()
                    }
                }
            }
            
            foundApps.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            
            await MainActor.run {
                self.apps = foundApps
                self.isScanning = false
                self.statusMessage = "Found \(foundApps.count) applications"
            }
        }
    }
    
    private func createInstalledApp(from url: URL) async -> InstalledApp? {
        guard let bundle = Bundle(url: url) else { return nil }
        guard let bundleID = bundle.bundleIdentifier else { return nil }
        
        let name = bundle.infoDictionary?["CFBundleName"] as? String ?? url.deletingPathExtension().lastPathComponent
        let version = bundle.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let icon = NSWorkspace.shared.icon(forFile: url.path)
        
        let size = directorySize(url: url)
        
        var app = InstalledApp(
            name: name,
            bundleIdentifier: bundleID,
            url: url,
            size: size,
            version: version,
            icon: icon
        )
        
        // Find related files
        app.relatedFiles = findRelatedFiles(for: bundleID)
        app.totalSize = size + app.relatedFiles.reduce(0) { $0 + directorySize(url: $1) }
        
        return app
    }
    
    private func findRelatedFiles(for bundleID: String) -> [URL] {
        var files: [URL] = []
        let fileManager = FileManager.default
        let libraryURL = fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Library")
        
        let searchPaths = [
            "Application Support",
            "Caches",
            "Preferences",
            "Logs",
            "Saved Application State",
            "Containers",
            "Group Containers"
        ]
        
        for path in searchPaths {
            let searchURL = libraryURL.appendingPathComponent(path)
            guard let enumerator = fileManager.enumerator(
                at: searchURL,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants]
            ) else { continue }
            
            for case let fileURL as URL in enumerator {
                let fileName = fileURL.lastPathComponent
                if fileName.contains(bundleID) || fileName.lowercased().contains(bundleID.lowercased()) {
                    files.append(fileURL)
                }
            }
        }
        
        return files
    }
    
    private func directorySize(url: URL) -> UInt64 {
        let fileManager = FileManager.default
        var size: UInt64 = 0
        
        if let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey],
            options: []
        ) {
            for case let fileURL as URL in enumerator {
                if let fileSize = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                    size += UInt64(fileSize)
                }
            }
        }
        
        return size
    }
    
    func uninstallApp(_ app: InstalledApp, selectedFiles: Set<String>) {
        let fileManager = FileManager.default
        
        // Delete main app
        do {
            try fileManager.trashItem(at: app.url, resultingItemURL: nil)
        } catch {
            print("Failed to delete app: \(error)")
            return
        }
        
        // Delete only selected related files
        for fileURL in app.relatedFiles where selectedFiles.contains(fileURL.path) {
            try? fileManager.trashItem(at: fileURL, resultingItemURL: nil)
        }
        
        // Remove from list
        apps.removeAll { $0.id == app.id }
        selectedApp = nil
        statusMessage = "Uninstalled \(app.name)"
    }
    
    func revealInFinder(_ app: InstalledApp) {
        NSWorkspace.shared.activateFileViewerSelecting([app.url])
    }
}
