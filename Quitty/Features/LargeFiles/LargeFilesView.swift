import SwiftUI

struct LargeFilesView: View {
    @ObservedObject var manager: LargeFilesManager
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 40))
                        .foregroundColor(.indigo)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Large Files Finder")
                            .font(.title2.bold())
                        Text(manager.statusMessage)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if !manager.isScanning {
                        Picker("Min Size", selection: $manager.minimumSize) {
                            Text("50 MB").tag(UInt64(50 * 1024 * 1024))
                            Text("100 MB").tag(UInt64(100 * 1024 * 1024))
                            Text("500 MB").tag(UInt64(500 * 1024 * 1024))
                            Text("1 GB").tag(UInt64(1024 * 1024 * 1024))
                            Text("5 GB").tag(UInt64(5 * 1024 * 1024 * 1024))
                        }
                        .frame(width: 120)
                    }
                }
                
                HStack {
                    if manager.isScanning {
                        Button("Cancel") {
                            manager.cancelScan()
                        }
                        .buttonStyle(.bordered)
                    } else {
                        Button("Scan Home Folder") {
                            manager.startScan()
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button("Choose Folder...") {
                            let panel = NSOpenPanel()
                            panel.canChooseDirectories = true
                            panel.canChooseFiles = false
                            if panel.runModal() == .OK, let url = panel.url {
                                manager.startScan(in: url)
                            }
                        }
                        .buttonStyle(.bordered)
                        
                        if !manager.files.isEmpty {
                            Button("Export") {
                                exportReport()
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    
                    Spacer()
                    
                    if !manager.selectedFiles.isEmpty {
                        Button("Delete Selected (\(manager.selectedFiles.count))") {
                            manager.deleteSelectedFiles()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                    }
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Files List
            if manager.files.isEmpty && !manager.isScanning {
                VStack(spacing: 12) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("No large files found")
                        .font(.title3)
                        .foregroundColor(.secondary)
                    Text("Click 'Scan Home Folder' to find large files")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 1) {
                        ForEach(manager.files) { file in
                            LargeFileRow(
                                file: file,
                                isSelected: manager.selectedFiles.contains(file.id),
                                onToggle: {
                                    if manager.selectedFiles.contains(file.id) {
                                        manager.selectedFiles.remove(file.id)
                                    } else {
                                        manager.selectedFiles.insert(file.id)
                                    }
                                },
                                onReveal: {
                                    manager.revealInFinder(file)
                                }
                            )
                        }
                    }
                }
            }
        }
    }
    
    private func exportReport() {
        var rows: [[String]] = []
        for file in manager.files {
            rows.append([
                file.name,
                file.sizeFormatted,
                file.path,
                "\(file.modifiedDate)"
            ])
        }
        
        ReportExporter.shared.exportCSV(
            title: "Large Files Report",
            headers: ["Name", "Size", "Path", "Modified Date"],
            rows: rows
        )
    }
}

struct LargeFileRow: View {
    let file: LargeFile
    let isSelected: Bool
    let onToggle: () -> Void
    let onReveal: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Toggle("", isOn: .constant(isSelected))
                .toggleStyle(.checkbox)
                .labelsHidden()
                .onTapGesture { onToggle() }
            
            Image(nsImage: NSWorkspace.shared.icon(forFile: file.path))
                .resizable()
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(file.name)
                    .font(.system(size: 13))
                    .lineLimit(1)
                
                Text(file.path)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(file.sizeFormatted)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.indigo)
                
                Text(file.modifiedDate, style: .date)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            
            Button(action: onReveal) {
                Image(systemName: "arrow.right.circle")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .help("Reveal in Finder")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        .contentShape(Rectangle())
    }
}
