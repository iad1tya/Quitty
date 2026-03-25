import SwiftUI

struct SystemJunkView: View {
    @ObservedObject var manager: SystemJunkManager
    @State private var showConfirmation = false

    var body: some View {
        VStack(spacing: 0) {
            Text("System Junk")
                .font(.system(size: 16, weight: .semibold))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)

            if manager.isScanning {
                Spacer()
                VStack(spacing: 12) {
                    ProgressView()
                        .controlSize(.regular)
                    Text(manager.scanProgress)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                Spacer()
            } else if manager.categories.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 32))
                        .foregroundColor(.green)
                    Text("System is clean!")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)

                    Button("Scan") {
                        manager.scan()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.regular)
                }
                Spacer()
            } else {
                // Summary
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(SystemJunkManager.formatBytes(manager.totalSize))
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                        Text("junk found")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    if manager.selectedSize != manager.totalSize {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(SystemJunkManager.formatBytes(manager.selectedSize))
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(.blue)
                            Text("selected")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)

                // Categories list
                List {
                    ForEach(Array(manager.categories.enumerated()), id: \.element.id) { index, category in
                        HStack(spacing: 10) {
                            Image(systemName: category.isSelected ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(category.isSelected ? .blue : .secondary.opacity(0.3))
                                .font(.system(size: 16))
                                .onTapGesture {
                                    manager.categories[index].isSelected.toggle()
                                }

                            Image(systemName: category.icon)
                                .foregroundColor(.secondary)
                                .frame(width: 20)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(category.name)
                                    .font(.system(size: 12, weight: .medium))
                                Text("\(category.files.count) items")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Text(SystemJunkManager.formatBytes(category.size))
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .foregroundColor(.primary)
                        }
                        .padding(.vertical, 4)
                        .listRowInsets(EdgeInsets(top: 2, leading: 16, bottom: 2, trailing: 16))
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)

                // Actions
                HStack {
                    Button(action: { manager.scan() }) {
                        Label("Rescan", systemImage: "arrow.clockwise")
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)

                    Spacer()

                    Button(action: { showConfirmation = true }) {
                        HStack {
                            if manager.isCleaning {
                                ProgressView()
                                    .controlSize(.small)
                                    .padding(.trailing, 4)
                            }
                            Text(manager.isCleaning ? "Cleaning..." : "Clean \(SystemJunkManager.formatBytes(manager.selectedSize))")
                                .font(.system(size: 13, weight: .medium))
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    .controlSize(.regular)
                    .disabled(manager.selectedSize == 0 || manager.isCleaning)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
        }
        .alert("Clean System Junk?", isPresented: $showConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Clean", role: .destructive) { manager.clean() }
        } message: {
            Text("This will permanently delete \(SystemJunkManager.formatBytes(manager.selectedSize)) of junk files. This cannot be undone.")
        }
    }
}
