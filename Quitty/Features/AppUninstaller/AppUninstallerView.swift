import SwiftUI

struct AppUninstallerView: View {
    @ObservedObject var manager: AppUninstallerManager
    @State private var searchText = ""
    @State private var selectedRelatedFiles: Set<String> = []
    
    var filteredApps: [InstalledApp] {
        if searchText.isEmpty {
            return manager.apps
        }
        return manager.apps.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "xmark.app")
                        .font(.system(size: 40))
                        .foregroundColor(.pink)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("App Uninstaller")
                            .font(.title2.bold())
                        Text(manager.statusMessage)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                
                HStack {
                    if manager.isScanning {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Button("Scan Applications") {
                            manager.scanInstalledApps()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    
                    Spacer()
                    
                    if !manager.apps.isEmpty {
                        TextField("Search apps...", text: $searchText)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 200)
                    }
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Apps List
            if filteredApps.isEmpty && !manager.isScanning {
                VStack(spacing: 12) {
                    Image(systemName: "xmark.app")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary.opacity(0.5))
                    Text(manager.apps.isEmpty ? "No applications scanned" : "No matching applications")
                        .font(.title3)
                        .foregroundColor(.secondary)
                    Text("Click 'Scan Applications' to find installed apps")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 1) {
                        ForEach(filteredApps) { app in
                            AppUninstallerRow(
                                app: app,
                                onUninstall: {
                                    manager.selectedApp = app
                                    manager.showingDeleteConfirmation = true
                                },
                                onReveal: {
                                    manager.revealInFinder(app)
                                }
                            )
                        }
                    }
                }
            }
        }
        .alert("Uninstall \(manager.selectedApp?.name ?? "App")?", isPresented: $manager.showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                selectedRelatedFiles.removeAll()
            }
            Button("Uninstall", role: .destructive) {
                if let app = manager.selectedApp {
                    manager.uninstallApp(app, selectedFiles: selectedRelatedFiles)
                    selectedRelatedFiles.removeAll()
                }
            }
        } message: {
            if let app = manager.selectedApp {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Select which files to remove:")
                    
                    Toggle("App Bundle (\(app.sizeFormatted))", isOn: .constant(true))
                        .disabled(true)
                    
                    ForEach(app.relatedFiles.prefix(10), id: \.path) { fileURL in
                        Toggle(fileURL.lastPathComponent, isOn: Binding(
                            get: { selectedRelatedFiles.contains(fileURL.path) },
                            set: { isSelected in
                                if isSelected {
                                    selectedRelatedFiles.insert(fileURL.path)
                                } else {
                                    selectedRelatedFiles.remove(fileURL.path)
                                }
                            }
                        ))
                        .font(.caption)
                    }
                    
                    if app.relatedFiles.count > 10 {
                        Text("... and \(app.relatedFiles.count - 10) more files")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Button("Select All Related Files") {
                        selectedRelatedFiles = Set(app.relatedFiles.map { $0.path })
                    }
                    .font(.caption)
                }
            }
        }
    }
}

struct AppUninstallerRow: View {
    let app: InstalledApp
    let onUninstall: () -> Void
    let onReveal: () -> Void
    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(nsImage: app.icon)
                    .resizable()
                    .frame(width: 40, height: 40)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(app.name)
                        .font(.system(size: 14, weight: .medium))
                    
                    Text("v\(app.version) • \(app.bundleIdentifier)")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(app.sizeFormatted)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.pink)
                    
                    if !app.relatedFiles.isEmpty {
                        Text("+\(app.relatedFiles.count) files (\(ByteCountFormatter.string(fromByteCount: Int64(app.totalSize - app.size), countStyle: .file)))")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
                
                Button(action: { isExpanded.toggle() }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Show Details")
                
                Button(action: onReveal) {
                    Image(systemName: "arrow.right.circle")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Reveal in Finder")
                
                Button(action: onUninstall) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
                .help("Uninstall")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            
            if isExpanded && !app.relatedFiles.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Related Files:")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("Select files to remove:")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 4)
                    
                    ForEach(app.relatedFiles, id: \.path) { fileURL in
                        HStack(spacing: 8) {
                            Image(systemName: "doc.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                            
                            Text(fileURL.path.replacingOccurrences(of: NSHomeDirectory(), with: "~"))
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                            
                            Spacer()
                            
                            Button(action: {
                                NSWorkspace.shared.activateFileViewerSelecting([fileURL])
                            }) {
                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.blue)
                            }
                            .buttonStyle(.plain)
                            .help("Reveal in Finder")
                        }
                        .padding(.vertical, 2)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.secondary.opacity(0.05))
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
    }
}
