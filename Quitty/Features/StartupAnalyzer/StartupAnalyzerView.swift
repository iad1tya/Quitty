import SwiftUI

struct StartupAnalyzerView: View {
    @ObservedObject var manager: StartupAnalyzerManager
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "power")
                        .font(.system(size: 40))
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Startup Analyzer")
                            .font(.title2.bold())
                        Text(manager.statusMessage)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                
                // Boot time stats
                HStack(spacing: 16) {
                    VStack(spacing: 4) {
                        Text("System Uptime")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(formatUptime(manager.bootTime))
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.secondary.opacity(0.05))
                    .cornerRadius(8)
                    
                    VStack(spacing: 4) {
                        Text("Estimated Boot Time")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(String(format: "%.1f seconds", manager.estimatedBootTime))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(manager.estimatedBootTime > 30 ? .red : .green)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.secondary.opacity(0.05))
                    .cornerRadius(8)
                    
                    VStack(spacing: 4) {
                        Text("Startup Items")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(manager.startupItems.filter { $0.isEnabled }.count)")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.secondary.opacity(0.05))
                    .cornerRadius(8)
                }
                
                HStack {
                    if manager.isScanning {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Button("Scan Startup Items") {
                            manager.scanStartupItems()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    
                    Spacer()
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Startup Items List
            if manager.startupItems.isEmpty && !manager.isScanning {
                VStack(spacing: 12) {
                    Image(systemName: "power")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("No startup items scanned")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 1) {
                        ForEach(manager.startupItems) { item in
                            StartupItemRow(
                                item: item,
                                onToggle: {
                                    manager.toggleStartupItem(item)
                                },
                                onRemove: {
                                    manager.removeStartupItem(item)
                                }
                            )
                        }
                    }
                }
            }
        }
    }
    
    private func formatUptime(_ seconds: TimeInterval) -> String {
        let days = Int(seconds) / 86400
        let hours = (Int(seconds) % 86400) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        
        if days > 0 {
            return "\(days)d \(hours)h"
        } else if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

struct StartupItemRow: View {
    let item: StartupItem
    let onToggle: () -> Void
    let onRemove: () -> Void
    @State private var showingRemoveConfirmation = false
    
    var body: some View {
        HStack(spacing: 12) {
            Toggle("", isOn: .constant(item.isEnabled))
                .toggleStyle(.checkbox)
                .labelsHidden()
                .onTapGesture { onToggle() }
            
            Image(nsImage: item.icon)
                .resizable()
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.system(size: 13, weight: .medium))
                
                HStack(spacing: 8) {
                    Text(item.type.rawValue)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text(item.estimatedImpact.rawValue + " Impact")
                        .font(.system(size: 10))
                        .foregroundColor(item.estimatedImpact.color)
                }
            }
            
            Spacer()
            
            Button(action: { showingRemoveConfirmation = true }) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain)
            .help("Remove from Startup")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor))
        .opacity(item.isEnabled ? 1.0 : 0.5)
        .alert("Remove \(item.name)?", isPresented: $showingRemoveConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Remove", role: .destructive) { onRemove() }
        } message: {
            Text("This will prevent \(item.name) from starting automatically.")
        }
    }
}
