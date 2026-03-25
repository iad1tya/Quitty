import SwiftUI

struct TrashBinsView: View {
    @ObservedObject var manager: TrashBinsManager
    @State private var hasAccess = PermissionHelper.hasFullDiskAccess

    var body: some View {
        VStack(spacing: 0) {
            Text("Trash Bins")
                .font(.system(size: 16, weight: .semibold))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)

            if !hasAccess {
                Spacer()
                PermissionRequestView(
                    icon: "trash.fill",
                    title: "Full Disk Access Required",
                    message: "Quitty needs Full Disk Access to read and manage your Trash.",
                    onGrant: {
                        PermissionHelper.openFullDiskAccessSettings()
                    },
                    onCheck: {
                        hasAccess = PermissionHelper.hasFullDiskAccess
                        if hasAccess { manager.scan() }
                    }
                )
                Spacer()
            } else {
                // Summary card
                HStack(spacing: 16) {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 32))
                        .foregroundColor(manager.trashSize > 0 ? .orange : .secondary)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(TrashBinsManager.formatBytes(manager.trashSize))
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                        Text("\(manager.fileCount) items in trash")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(16)
                .background(Color.primary.opacity(0.03))
                .cornerRadius(8)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)

                if manager.isScanning {
                    Spacer()
                    ProgressView("Scanning trash...")
                        .font(.system(size: 12))
                    Spacer()
                } else if manager.items.isEmpty {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 32))
                            .foregroundColor(.green)
                        Text("Trash is empty")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    List {
                        ForEach(manager.items) { item in
                            HStack(spacing: 10) {
                                Image(systemName: "doc.fill")
                                    .foregroundColor(.secondary)
                                    .frame(width: 24, height: 24)
                                Text(item.name)
                                    .font(.system(size: 12))
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                                Spacer()
                                if !item.size.isEmpty {
                                    Text(item.size)
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundColor(.secondary)
                                }
                            }
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }

                // Actions
                HStack {
                    Button(action: { manager.scan() }) {
                        Label("Rescan", systemImage: "arrow.clockwise")
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)

                    Spacer()

                    Button(action: { manager.emptyTrash() }) {
                        HStack {
                            if manager.isEmptying {
                                ProgressView()
                                    .controlSize(.small)
                                    .padding(.trailing, 4)
                            }
                            Text(manager.isEmptying ? "Emptying..." : "Empty Trash")
                                .font(.system(size: 13, weight: .medium))
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                    .controlSize(.regular)
                    .disabled(manager.trashSize == 0 || manager.isEmptying)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
        }
    }
}
