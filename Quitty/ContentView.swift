import SwiftUI
import AppKit

enum SidebarItem: String, CaseIterable, Identifiable {
    case apps = "Apps"
    case systemJunk = "System Junk"
    case trashBins = "Trash Bins"
    case spaceLens = "Space Lens"
    case duplicates = "Duplicates"
    case optimization = "Optimization"
    case ramBooster = "RAM Booster"
    case battery = "Battery"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .apps: return "square.grid.2x2"
        case .systemJunk: return "trash.slash"
        case .trashBins: return "trash"
        case .spaceLens: return "internaldrive"
        case .duplicates: return "doc.on.doc"
        case .optimization: return "bolt.heart"
        case .ramBooster: return "memorychip"
        case .battery: return "battery.100"
        }
    }

    var color: Color {
        switch self {
        case .apps: return .blue
        case .systemJunk: return .orange
        case .trashBins: return .red
        case .spaceLens: return .purple
        case .duplicates: return .cyan
        case .optimization: return .green
        case .ramBooster: return .pink
        case .battery: return .yellow
        }
    }
}

struct ContentView: View {
    @State private var selectedItem: SidebarItem = .apps
    @Environment(\.openSettings) var openSettings

    // Persist managers across tab switches
    @StateObject private var trashManager = TrashBinsManager()
    @StateObject private var junkManager = SystemJunkManager()
    @StateObject private var ramManager = RAMBoosterManager()
    @StateObject private var batteryManager = BatteryManager()
    @StateObject private var optimizationManager = OptimizationManager()
    @StateObject private var storageAnalyzer = StorageAnalyzer()
    @StateObject private var duplicateFinder = DuplicateFinderManager()

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
        case .apps:
            AppsView()
        case .systemJunk:
            SystemJunkView(manager: junkManager)
        case .trashBins:
            TrashBinsView(manager: trashManager)
        case .spaceLens:
            SpaceLensView(analyzer: storageAnalyzer)
        case .duplicates:
            DuplicatesView(finder: duplicateFinder)
        case .optimization:
            OptimizationView(manager: optimizationManager)
        case .ramBooster:
            RAMBoosterView(manager: ramManager)
        case .battery:
            BatteryView(manager: batteryManager)
        }
    }
}
