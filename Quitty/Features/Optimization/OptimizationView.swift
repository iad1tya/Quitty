import SwiftUI

struct OptimizationView: View {
    @ObservedObject var manager: OptimizationManager
    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            Text("Optimization")
                .font(.system(size: 16, weight: .semibold))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)

            // Tab picker
            Picker("", selection: $selectedTab) {
                Text("Launch Agents").tag(0)
                Text("Heavy Processes").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.bottom, 8)

            if manager.isScanning {
                Spacer()
                ProgressView("Scanning...")
                    .font(.system(size: 12))
                Spacer()
            } else if selectedTab == 0 {
                launchAgentsView
            } else {
                heavyProcessesView
            }

            // Footer
            HStack {
                Button(action: { manager.scan() }) {
                    Label("Refresh", systemImage: "arrow.clockwise")
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .onAppear { manager.scan() }
    }

    var launchAgentsView: some View {
        Group {
            if manager.launchItems.isEmpty {
                Spacer()
                Text("No launch agents found")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                Spacer()
            } else {
                List {
                    Section("User Agents") {
                        ForEach(manager.launchItems.filter { $0.isUserAgent }) { item in
                            LaunchItemRow(item: item) {
                                manager.toggleAgent(item)
                            }
                        }
                    }

                    Section("System Agents (read-only)") {
                        ForEach(manager.launchItems.filter { !$0.isUserAgent }) { item in
                            LaunchItemRow(item: item, readOnly: true) { }
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
    }

    var heavyProcessesView: some View {
        Group {
            if manager.heavyProcesses.isEmpty {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 28))
                        .foregroundColor(.green)
                    Text("No heavy processes")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                Spacer()
            } else {
                List {
                    ForEach(manager.heavyProcesses) { proc in
                        HStack(spacing: 10) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(proc.name)
                                    .font(.system(size: 12, weight: .medium))
                                    .lineLimit(1)
                                Text("PID: \(proc.id)")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 2) {
                                HStack(spacing: 4) {
                                    Image(systemName: "cpu")
                                        .font(.system(size: 9))
                                    Text(String(format: "%.1f%%", proc.cpuPercent))
                                        .font(.system(size: 11, design: .monospaced))
                                }
                                .foregroundColor(proc.cpuPercent > 50 ? .red : .secondary)

                                HStack(spacing: 4) {
                                    Image(systemName: "memorychip")
                                        .font(.system(size: 9))
                                    Text(String(format: "%.0f MB", proc.memoryMB))
                                        .font(.system(size: 11, design: .monospaced))
                                }
                                .foregroundColor(.secondary)
                            }

                            Button(action: { manager.killProcess(proc.id) }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red.opacity(0.7))
                            }
                            .buttonStyle(.plain)
                            .help("Terminate process")
                        }
                        .padding(.vertical, 2)
                        .listRowInsets(EdgeInsets(top: 2, leading: 16, bottom: 2, trailing: 16))
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
    }
}

struct LaunchItemRow: View {
    let item: LaunchItem
    var readOnly: Bool = false
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(item.isEnabled ? Color.green : Color.secondary.opacity(0.3))
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 1) {
                Text(item.name)
                    .font(.system(size: 12, weight: .medium))
                Text(item.label)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer()

            if !readOnly {
                Toggle("", isOn: Binding(
                    get: { item.isEnabled },
                    set: { _ in onToggle() }
                ))
                .toggleStyle(.switch)
                .controlSize(.small)
            } else {
                Text(item.isEnabled ? "Active" : "Disabled")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 2)
        .listRowInsets(EdgeInsets(top: 2, leading: 16, bottom: 2, trailing: 16))
    }
}
