import SwiftUI

struct NetworkMonitorView: View {
    @ObservedObject var manager: NetworkMonitorManager
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "network")
                        .font(.system(size: 40))
                        .foregroundColor(.teal)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Network Monitor")
                            .font(.title2.bold())
                        Text(manager.statusMessage)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.down.circle.fill")
                                .foregroundColor(.green)
                            Text(ByteCountFormatter.string(fromByteCount: Int64(manager.totalDownload), countStyle: .file) + "/s")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.circle.fill")
                                .foregroundColor(.orange)
                            Text(ByteCountFormatter.string(fromByteCount: Int64(manager.totalUpload), countStyle: .file) + "/s")
                                .font(.system(size: 13, weight: .semibold))
                        }
                    }
                }
                
                HStack {
                    if manager.isMonitoring {
                        Button("Stop Monitoring") {
                            manager.stopMonitoring()
                        }
                        .buttonStyle(.bordered)
                    } else {
                        Button("Start Monitoring") {
                            manager.startMonitoring()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    
                    Spacer()
                    
                    Text("\(manager.processes.count) active connections")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Process List
            if manager.processes.isEmpty && !manager.isMonitoring {
                VStack(spacing: 12) {
                    Image(systemName: "network")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("Network monitoring inactive")
                        .font(.title3)
                        .foregroundColor(.secondary)
                    Text("Start monitoring to see network activity")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 1) {
                        ForEach(manager.processes) { process in
                            NetworkProcessRow(
                                process: process,
                                onKill: {
                                    manager.killProcess(process)
                                }
                            )
                        }
                    }
                }
            }
        }
    }
}

struct NetworkProcessRow: View {
    let process: NetworkProcess
    let onKill: () -> Void
    @State private var showingKillConfirmation = false
    
    var body: some View {
        HStack(spacing: 12) {
            Image(nsImage: process.icon)
                .resizable()
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(process.name)
                    .font(.system(size: 13, weight: .medium))
                
                if let bundleID = process.bundleIdentifier {
                    Text(bundleID)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.down")
                        .font(.system(size: 9))
                        .foregroundColor(.green)
                    Text(process.downloadSpeed)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.green)
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 9))
                        .foregroundColor(.orange)
                    Text(process.uploadSpeed)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.orange)
                }
            }
            .frame(width: 120, alignment: .trailing)
            
            Button(action: { showingKillConfirmation = true }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain)
            .help("Kill Process")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor))
        .alert("Kill \(process.name)?", isPresented: $showingKillConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Kill", role: .destructive) { onKill() }
        } message: {
            Text("This will force quit the application.")
        }
    }
}
