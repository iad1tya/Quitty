import SwiftUI
import AppKit

enum SidebarItem: String, CaseIterable, Identifiable {
    case dashboard = "Dashboard"
    case apps = "Apps"
    case download = "Download"
    case systemJunk = "System Junk"
    case trashBins = "Trash Bins"
    case spaceLens = "Space Lens"
    case duplicates = "Duplicates"
    case largeFiles = "Large Files"
    case appUninstaller = "Uninstaller"
    case optimization = "Optimization"
    case ramBooster = "RAM Booster"
    case networkMonitor = "Network"
    case cpuMonitor = "CPU & Temp"
    case battery = "Battery"
    case startupAnalyzer = "Startup"
    case scheduledTasks = "Scheduler"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .dashboard: return "gauge.with.dots.needle.67percent"
        case .apps: return "square.grid.2x2"
        case .download: return "arrow.down.circle"
        case .systemJunk: return "trash.slash"
        case .trashBins: return "trash"
        case .spaceLens: return "internaldrive"
        case .duplicates: return "doc.on.doc"
        case .largeFiles: return "doc.text.magnifyingglass"
        case .appUninstaller: return "xmark.app"
        case .optimization: return "bolt.heart"
        case .ramBooster: return "memorychip"
        case .networkMonitor: return "network"
        case .cpuMonitor: return "cpu"
        case .battery: return "battery.100"
        case .startupAnalyzer: return "power"
        case .scheduledTasks: return "clock.arrow.circlepath"
        }
    }

    var color: Color {
        switch self {
        case .dashboard: return .purple
        case .apps: return .blue
        case .download: return .green
        case .systemJunk: return .orange
        case .trashBins: return .red
        case .spaceLens: return .purple
        case .duplicates: return .cyan
        case .largeFiles: return .indigo
        case .appUninstaller: return .pink
        case .optimization: return .green
        case .ramBooster: return .mint
        case .networkMonitor: return .teal
        case .cpuMonitor: return .orange
        case .battery: return .yellow
        case .startupAnalyzer: return .blue
        case .scheduledTasks: return .brown
        }
    }
}

struct ContentView: View {
    @State private var selectedItem: SidebarItem = .dashboard
    @Environment(\.openSettings) var openSettings

    // Persist managers across tab switches
    @StateObject private var trashManager = TrashBinsManager()
    @StateObject private var junkManager = SystemJunkManager()
    @StateObject private var ramManager = RAMBoosterManager()
    @StateObject private var batteryManager = BatteryManager()
    @StateObject private var optimizationManager = OptimizationManager()
    @StateObject private var storageAnalyzer = StorageAnalyzer()
    @StateObject private var duplicateFinder = DuplicateFinderManager()
    @StateObject private var largeFilesManager = LargeFilesManager()
    @StateObject private var uninstallerManager = AppUninstallerManager()
    @StateObject private var networkMonitor = NetworkMonitorManager()
    @StateObject private var cpuMonitor = CPUMonitorManager()
    @StateObject private var startupAnalyzer = StartupAnalyzerManager()
    @StateObject private var schedulerManager = SchedulerManager()

    var body: some View {
        NavigationSplitView {
            sidebarContent
        } detail: {
            detailContent
        }
        .frame(minWidth: 580, minHeight: 420)
    }

    private var sidebarContent: some View {
        List(SidebarItem.allCases, selection: $selectedItem) { item in
            Label {
                Text(item.rawValue)
                    .font(.system(size: 12, weight: .medium))
            } icon: {
                Image(systemName: item.icon)
                    .foregroundColor(item.color)
                    .font(.system(size: 13))
            }
            .tag(item)
            .padding(.vertical, 3)
        }
        .listStyle(.sidebar)
        .navigationSplitViewColumnWidth(min: 160, ideal: 180, max: 200)
        .safeAreaInset(edge: .bottom) {
            HStack {
                Button(action: {
                    openSettings()
                    NSApplication.shared.activate(ignoringOtherApps: true)
                }) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Settings")

                Spacer()

                Button(action: {
                    NSApplication.shared.terminate(nil)
                }) {
                    Text("Quit")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }

    @ViewBuilder
    private var detailContent: some View {
        switch selectedItem {
        case .dashboard:
            DashboardView(
                ramManager: ramManager,
                batteryManager: batteryManager,
                cpuMonitor: cpuMonitor,
                storageAnalyzer: storageAnalyzer,
                junkManager: junkManager,
                trashManager: trashManager,
                duplicateFinder: duplicateFinder,
                largeFilesManager: largeFilesManager
            )
        case .apps:
            AppsView()
        case .download:
            DownloadView()
        case .systemJunk:
            SystemJunkView(manager: junkManager)
        case .trashBins:
            TrashBinsView(manager: trashManager)
        case .spaceLens:
            SpaceLensView(analyzer: storageAnalyzer)
        case .duplicates:
            DuplicatesView(finder: duplicateFinder)
        case .largeFiles:
            LargeFilesView(manager: largeFilesManager)
        case .appUninstaller:
            AppUninstallerView(manager: uninstallerManager)
        case .optimization:
            OptimizationView(manager: optimizationManager)
        case .ramBooster:
            RAMBoosterView(manager: ramManager)
        case .networkMonitor:
            NetworkMonitorView(manager: networkMonitor)
        case .cpuMonitor:
            CPUMonitorView(manager: cpuMonitor)
        case .battery:
            BatteryView(manager: batteryManager)
        case .startupAnalyzer:
            StartupAnalyzerView(manager: startupAnalyzer)
        case .scheduledTasks:
            SchedulerView(manager: schedulerManager)
        }
    }
}

struct DashboardView: View {
    @ObservedObject var ramManager: RAMBoosterManager
    @ObservedObject var batteryManager: BatteryManager
    @ObservedObject var cpuMonitor: CPUMonitorManager
    @ObservedObject var storageAnalyzer: StorageAnalyzer
    @ObservedObject var junkManager: SystemJunkManager
    @ObservedObject var trashManager: TrashBinsManager
    @ObservedObject var duplicateFinder: DuplicateFinderManager
    @ObservedObject var largeFilesManager: LargeFilesManager
    
    private func quitAllApps() {
        let runningApps = NSWorkspace.shared.runningApplications
        let criticalApps = ["com.apple.finder", "com.apple.dock", "com.apple.systemuiserver"]
        let quittyBundleId = Bundle.main.bundleIdentifier
        
        for app in runningApps {
            guard let bundleId = app.bundleIdentifier else { continue }
            
            // Skip critical apps and Quitty itself
            if criticalApps.contains(bundleId) || bundleId == quittyBundleId {
                continue
            }
            
            // Only quit regular apps (not background processes)
            if app.activationPolicy == .regular {
                app.terminate()
            }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("System Dashboard")
                            .font(.title.bold())
                        Text("Overview of your Mac's health")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        ReportExporter.shared.exportSystemReport()
                    }) {
                        Label("Export Report", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.horizontal)
                .padding(.top)
                
                // Quick Stats Grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    DashboardCard(
                        icon: "memorychip",
                        title: "RAM Usage",
                        value: String(format: "%.1f%%", ramManager.usagePercentage),
                        subtitle: "\(ramManager.usedMemoryFormatted) / \(ramManager.totalMemoryFormatted)",
                        color: ramManager.usagePercentage > 80 ? .red : .mint,
                        action: nil
                    )
                    
                    DashboardCard(
                        icon: "cpu",
                        title: "CPU Usage",
                        value: String(format: "%.1f%%", cpuMonitor.cpuUsage),
                        subtitle: "\(cpuMonitor.topProcesses.count) active processes",
                        color: cpuMonitor.cpuUsage > 80 ? .red : .orange,
                        action: nil
                    )
                    
                    DashboardCard(
                        icon: "internaldrive",
                        title: "Disk Space",
                        value: storageAnalyzer.usagePercentageFormatted,
                        subtitle: "\(StorageAnalyzer.formatBytes(storageAnalyzer.freeDiskSize)) free",
                        color: storageAnalyzer.usagePercentage > 90 ? .red : .purple,
                        action: nil
                    )
                    
                    DashboardCard(
                        icon: "battery.100",
                        title: "Battery Health",
                        value: "\(batteryManager.health)%",
                        subtitle: "\(batteryManager.cycleCount) cycles",
                        color: batteryManager.health < 80 ? .red : .yellow,
                        action: nil
                    )
                }
                .padding(.horizontal)
                
                // Quick Actions
                VStack(alignment: .leading, spacing: 12) {
                    Text("Quick Actions")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        QuickActionButton(
                            icon: "trash.slash",
                            title: "Clean Junk",
                            color: .orange
                        ) {
                            junkManager.clean()
                        }
                        
                        QuickActionButton(
                            icon: "trash",
                            title: "Empty Trash",
                            color: .red
                        ) {
                            trashManager.emptyTrash()
                        }
                        
                        QuickActionButton(
                            icon: "memorychip",
                            title: "Free RAM",
                            color: .mint
                        ) {
                            ramManager.freeRAMAction()
                        }
                        
                        QuickActionButton(
                            icon: "doc.on.doc",
                            title: "Find Duplicates",
                            color: .cyan
                        ) {
                            duplicateFinder.scan()
                        }
                        
                        QuickActionButton(
                            icon: "doc.text.magnifyingglass",
                            title: "Large Files",
                            color: .indigo
                        ) {
                            largeFilesManager.startScan()
                        }
                        
                        QuickActionButton(
                            icon: "square.grid.2x2",
                            title: "Quit All Apps",
                            color: .blue
                        ) {
                            quitAllApps()
                        }
                    }
                    .padding(.horizontal)
                }
                
                // System Recommendations
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recommendations")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    VStack(spacing: 8) {
                        if ramManager.usagePercentage > 80 {
                            RecommendationCard(
                                icon: "memorychip",
                                title: "High RAM Usage",
                                message: "Consider freeing memory to improve performance",
                                color: .red
                            )
                        }
                        
                        if storageAnalyzer.usagePercentage > 90 {
                            RecommendationCard(
                                icon: "internaldrive",
                                title: "Low Disk Space",
                                message: "Less than 10% disk space remaining",
                                color: .red
                            )
                        }
                        
                        if batteryManager.health < 80 {
                            RecommendationCard(
                                icon: "battery.100",
                                title: "Battery Health Low",
                                message: "Consider servicing your battery",
                                color: .orange
                            )
                        }
                        
                        if ramManager.usagePercentage <= 80 && storageAnalyzer.usagePercentage <= 90 && batteryManager.health >= 80 {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("System is running smoothly")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .padding(.bottom)
        }
        .onAppear {
            // Start monitoring for dashboard
            if !cpuMonitor.isMonitoring {
                cpuMonitor.startMonitoring()
            }
        }
    }
}

struct DashboardCard: View {
    let icon: String
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let action: String?
    let onAction: (() -> Void)?
    
    init(icon: String, title: String, value: String, subtitle: String, color: Color, action: String?, onAction: (() -> Void)? = nil) {
        self.icon = icon
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.color = color
        self.action = action
        self.onAction = onAction
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(subtitle)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            if let action = action, let onAction = onAction {
                Button(action: onAction) {
                    Text(action)
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(12)
    }
}

struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.secondary.opacity(0.05))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

struct RecommendationCard: View {
    let icon: String
    let title: String
    let message: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                
                Text(message)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}
