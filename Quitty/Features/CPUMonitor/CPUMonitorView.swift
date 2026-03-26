import SwiftUI

struct CPUMonitorView: View {
    @ObservedObject var manager: CPUMonitorManager
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with stats
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "cpu")
                        .font(.system(size: 40))
                        .foregroundColor(.orange)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("CPU & Temperature")
                            .font(.title2.bold())
                        Text(manager.statusMessage)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                
                // Stats Cards
                HStack(spacing: 16) {
                    StatCard(
                        icon: "cpu.fill",
                        title: "CPU Usage",
                        value: String(format: "%.1f%%", manager.cpuUsage),
                        color: cpuColor(manager.cpuUsage)
                    )
                    
                    StatCard(
                        icon: "thermometer.medium",
                        title: "Temperature",
                        value: String(format: "%.0f°C", manager.cpuTemperature),
                        color: tempColor(manager.cpuTemperature)
                    )
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
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Top Processes
            if manager.topProcesses.isEmpty && !manager.isMonitoring {
                VStack(spacing: 12) {
                    Image(systemName: "cpu")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("CPU monitoring inactive")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Top CPU Processes")
                        .font(.headline)
                        .padding(.horizontal)
                        .padding(.top, 12)
                    
                    ScrollView {
                        LazyVStack(spacing: 1) {
                            ForEach(manager.topProcesses) { process in
                                CPUProcessRow(
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
    
    private func cpuColor(_ usage: Double) -> Color {
        if usage > 80 { return .red }
        if usage > 50 { return .orange }
        return .green
    }
    
    private func tempColor(_ temp: Double) -> Color {
        if temp > 80 { return .red }
        if temp > 60 { return .orange }
        return .green
    }
}

struct StatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(color)
            
            Text(title)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(8)
    }
}

struct CPUProcessRow: View {
    let process: CPUProcess
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
                
                Text("PID: \(process.pid)")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(String(format: "%.1f%%", process.cpuUsage))
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(process.cpuUsage > 50 ? .red : .orange)
                .frame(width: 60, alignment: .trailing)
            
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
        }
    }
}
