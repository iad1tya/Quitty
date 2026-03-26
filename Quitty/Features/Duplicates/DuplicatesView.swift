import SwiftUI

struct DuplicatesView: View {
    @ObservedObject var finder: DuplicateFinderManager
    @State private var showDeleteConfirmation = false

    var body: some View {
        VStack(spacing: 0) {
            Text("Duplicate Finder")
                .font(.system(size: 16, weight: .semibold))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)

            if finder.isScanning {
                Spacer()
                VStack(spacing: 16) {
                    // Animated scanning icon
                    ScanningAnimation(phase: finder.scanPhase)
                        .frame(height: 80)

                    // Progress bar for comparing phase
                    if finder.scanPhase == .comparing {
                        VStack(spacing: 6) {
                            ProgressView(value: finder.hashProgress)
                                .progressViewStyle(.linear)
                                .frame(width: 200)
                                .tint(.cyan)

                            Text("\(Int(finder.hashProgress * 100))%")
                                .font(.system(size: 20, weight: .bold, design: .monospaced))
                                .foregroundColor(.cyan)
                        }
                    }

                    VStack(spacing: 4) {
                        Text(finder.scanProgress)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        Text("\(finder.filesScanned) files scanned")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary.opacity(0.7))
                    }

                    Button("Cancel") {
                        finder.cancelScan()
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.red)
                    .font(.system(size: 12))
                }
                Spacer()
            } else if finder.groups.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)

                    if finder.filesScanned > 0 {
                        Text("No duplicates found!")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    } else {
                        Text("Scan your files to find duplicates")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }

                    // Min size picker
                    HStack {
                        Text("Min size:")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        Picker("", selection: $finder.minFileSize) {
                            Text("100 KB").tag(UInt64(1024 * 100))
                            Text("1 MB").tag(UInt64(1024 * 1024))
                            Text("10 MB").tag(UInt64(1024 * 1024 * 10))
                            Text("50 MB").tag(UInt64(1024 * 1024 * 50))
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 250)
                    }

                    Button("Scan for Duplicates") {
                        finder.scan()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.regular)
                }
                Spacer()
            } else {
                // Summary
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(finder.groups.count) duplicate groups")
                            .font(.system(size: 13, weight: .medium))
                        Text("\(DuplicateFinderManager.formatBytes(finder.totalWastedSpace)) wasted")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Button("Select All Duplicates") {
                        finder.selectAllDuplicates()
                    }
                    .font(.system(size: 11))
                    .buttonStyle(.plain)
                    .foregroundColor(.blue)

                    Button("Deselect") {
                        finder.deselectAll()
                    }
                    .font(.system(size: 11))
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 6)

                // Duplicate groups
                List {
                    ForEach(Array(finder.groups.enumerated()), id: \.element.id) { groupIdx, group in
                        Section {
                            ForEach(Array(group.files.enumerated()), id: \.element.id) { fileIdx, file in
                                HStack(spacing: 8) {
                                    Image(systemName: file.isSelected ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(file.isSelected ? .blue : .secondary.opacity(0.3))
                                        .font(.system(size: 14))
                                        .onTapGesture {
                                            finder.groups[groupIdx].files[fileIdx].isSelected.toggle()
                                        }

                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(file.name)
                                            .font(.system(size: 11, weight: .medium))
                                            .lineLimit(1)
                                        Text(file.path.deletingLastPathComponent().path)
                                            .font(.system(size: 9))
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                            .truncationMode(.head)
                                    }

                                    Spacer()

                                    if fileIdx == 0 {
                                        Text("Original")
                                            .font(.system(size: 9, weight: .medium))
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.green.opacity(0.15))
                                            .foregroundColor(.green)
                                            .cornerRadius(4)
                                    }
                                }
                                .padding(.vertical, 2)
                                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                            }
                        } header: {
                            HStack {
                                Text(DuplicateFinderManager.formatBytes(group.fileSize))
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                Text("x\(group.files.count)")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("Wasted: \(DuplicateFinderManager.formatBytes(group.wastedSpace))")
                                    .font(.system(size: 10))
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)

                // Footer
                HStack {
                    Button(action: { finder.scan() }) {
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

                    if finder.selectedCount > 0 {
                        Text("\(finder.selectedCount) selected (\(DuplicateFinderManager.formatBytes(finder.selectedSize)))")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }

                    Button(action: { showDeleteConfirmation = true }) {
                        HStack {
                            if finder.isDeleting {
                                ProgressView().controlSize(.small).padding(.trailing, 4)
                            }
                            Text(finder.isDeleting ? "Deleting..." : "Move to Trash")
                                .font(.system(size: 13, weight: .medium))
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .controlSize(.regular)
                    .disabled(finder.selectedCount == 0 || finder.isDeleting)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
        }
        .alert("Delete Duplicates?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Move to Trash", role: .destructive) { finder.deleteSelected() }
        } message: {
            Text("\(finder.selectedCount) files (\(DuplicateFinderManager.formatBytes(finder.selectedSize))) will be moved to Trash.")
        }
    }
    
    private func exportReport() {
        var rows: [[String]] = []
        for group in finder.groups {
            for file in group.files {
                rows.append([
                    file.name,
                    DuplicateFinderManager.formatBytes(file.size),
                    file.path.path,
                    group.hash
                ])
            }
        }
        
        ReportExporter.shared.exportCSV(
            title: "Duplicate Files Report",
            headers: ["Name", "Size", "Path", "Hash"],
            rows: rows
        )
    }
}

struct ScanningAnimation: View {
    let phase: DuplicateFinderManager.ScanPhase
    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 1.0
    @State private var opacity1: Double = 0.3
    @State private var opacity2: Double = 0.6
    @State private var opacity3: Double = 0.9

    var body: some View {
        ZStack {
            // Outer pulsing ring
            Circle()
                .stroke(Color.cyan.opacity(opacity1), lineWidth: 2)
                .frame(width: 70, height: 70)
                .scaleEffect(scale)

            // Middle rotating ring
            Circle()
                .trim(from: 0, to: 0.7)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [.cyan.opacity(0), .cyan]),
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .frame(width: 50, height: 50)
                .rotationEffect(.degrees(rotation))

            // Center icon
            Image(systemName: phase == .indexing ? "folder.fill" : "doc.on.doc.fill")
                .font(.system(size: 20))
                .foregroundColor(.cyan)
                .scaleEffect(scale > 1.05 ? 0.9 : 1.0)
        }
        .onAppear {
            withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                rotation = 360
            }
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                scale = 1.15
                opacity1 = 0.6
            }
        }
    }
}
