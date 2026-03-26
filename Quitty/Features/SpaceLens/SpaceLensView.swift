import SwiftUI

struct SpaceLensView: View {
    @ObservedObject var analyzer: StorageAnalyzer

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Space Lens")
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 4)

            // Disk overview bar
            VStack(spacing: 6) {
                StorageBar(
                    items: [
                        ("Used", Double(analyzer.usedDiskSize), Color.blue),
                        ("Free", Double(analyzer.freeDiskSize), Color.secondary.opacity(0.2))
                    ],
                    total: Double(analyzer.totalDiskSize),
                    height: 14
                )

                HStack {
                    Text("\(StorageAnalyzer.formatBytes(analyzer.usedDiskSize)) used")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(StorageAnalyzer.formatBytes(analyzer.freeDiskSize)) free of \(StorageAnalyzer.formatBytes(analyzer.totalDiskSize))")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)

            // Breadcrumb navigation
            HStack(spacing: 4) {
                Button(action: { analyzer.navigateHome() }) {
                    Image(systemName: "house.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)

                if !analyzer.pathHistory.isEmpty {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)

                    Button(action: { analyzer.navigateBack() }) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 11))
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }

                Text(analyzer.currentPath.lastPathComponent)
                    .font(.system(size: 11, weight: .medium))
                    .lineLimit(1)
                    .truncationMode(.head)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 6)

            if analyzer.isScanning {
                Spacer()
                VStack(spacing: 8) {
                    ProgressView()
                    Text(analyzer.scanProgress)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                Spacer()
            } else if analyzer.items.isEmpty {
                Spacer()
                Text("Empty folder")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                Spacer()
            } else {
                // Items list with size bars
                let maxSize = analyzer.items.first?.size ?? 1

                List {
                    ForEach(analyzer.items) { item in
                        SpaceLensItemRow(item: item, maxSize: maxSize)
                            .contentShape(Rectangle())
                            .onTapGesture(count: 2) {
                                if item.isDirectory {
                                    analyzer.navigateInto(item)
                                }
                            }
                            .contextMenu {
                                Button("Reveal in Finder") {
                                    analyzer.revealInFinder(item.path)
                                }
                                if item.isDirectory {
                                    Button("Open") {
                                        analyzer.navigateInto(item)
                                    }
                                }
                            }
                            .listRowInsets(EdgeInsets(top: 2, leading: 16, bottom: 2, trailing: 16))
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }

            // Footer
            HStack {
                Button(action: { analyzer.scan() }) {
                    Label("Rescan", systemImage: "arrow.clockwise")
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
                
                Button(action: { exportReport() }) {
                    Label("Export", systemImage: "square.and.arrow.up")
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)

                Spacer()

                Text("\(analyzer.items.count) items")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .onAppear {
            if analyzer.items.isEmpty {
                analyzer.scan()
            }
        }
    }
    
    private func exportReport() {
        var rows: [[String]] = []
        for item in analyzer.items {
            rows.append([
                item.name,
                item.isDirectory ? "Folder" : "File",
                StorageAnalyzer.formatBytes(item.size),
                item.path.path
            ])
        }
        
        ReportExporter.shared.exportCSV(
            title: "Space Lens Report",
            headers: ["Name", "Type", "Size", "Path"],
            rows: rows
        )
    }
}

struct SpaceLensItemRow: View {
    let item: StorageItem
    let maxSize: UInt64

    var barFraction: CGFloat {
        guard maxSize > 0 else { return 0 }
        return CGFloat(item.size) / CGFloat(maxSize)
    }

    var body: some View {
        HStack(spacing: 10) {
            if let icon = item.icon {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 20, height: 20)
            } else {
                Image(systemName: item.isDirectory ? "folder.fill" : "doc.fill")
                    .foregroundColor(item.isDirectory ? .blue : .secondary)
                    .frame(width: 20, height: 20)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(item.name)
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(1)
                    .truncationMode(.middle)

                GeometryReader { geo in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(item.isDirectory ? Color.blue.opacity(0.4) : Color.secondary.opacity(0.3))
                        .frame(width: geo.size.width * barFraction, height: 4)
                }
                .frame(height: 4)
            }

            Text(StorageAnalyzer.formatBytes(item.size))
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.secondary)
                .frame(minWidth: 60, alignment: .trailing)
        }
        .padding(.vertical, 4)
    }
}
