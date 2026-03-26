import SwiftUI
import AppKit
import Darwin
import Combine

struct AppItem: Identifiable, Equatable {
    let id: String
    let app: NSRunningApplication
    var isSelected: Bool = false
    var ramUsage: String = ""

    static func == (lhs: AppItem, rhs: AppItem) -> Bool {
        return lhs.id == rhs.id && lhs.isSelected == rhs.isSelected && lhs.ramUsage == rhs.ramUsage
    }
}

struct AppsView: View {
    @State private var appItems: [AppItem] = []
    @AppStorage("sortMode") private var sortMode = "name"
    @AppStorage("showBackgroundApps") private var showBackgroundApps = false
    @State private var searchText = ""
    @State private var optionKeyPressed = false
    @State private var eventMonitor: Any?

    let ramUpdateTimer = Timer.publish(every: 2, on: .main, in: .common).autoconnect()

    var selectedApps: [AppItem] {
        appItems.filter { $0.isSelected }
    }

    var filteredAppItems: [AppItem] {
        if searchText.isEmpty {
            return appItems
        } else {
            return appItems.filter { ($0.app.localizedName ?? "").localizedCaseInsensitiveContains(searchText) }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(alignment: .center) {
                Text("Running Apps")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)

                Spacer()

                Button(action: {
                    sortMode = (sortMode == "name") ? "ram" : "name"
                    appItems = sortItems(appItems)
                }) {
                    Image(systemName: sortMode == "name" ? "textformat.abc" : "memorychip")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help(sortMode == "name" ? "Sort by Memory Usage" : "Sort by Name")
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)

            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search Apps...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(Color.primary.opacity(0.05))
            .cornerRadius(6)
            .padding(.horizontal, 16)
            .padding(.bottom, 8)

            // App list
            if filteredAppItems.isEmpty {
                Spacer()
                Text(appItems.isEmpty ? "No apps running." : "No apps match search.")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                Spacer()
            } else {
                List {
                    Section {
                        ForEach($appItems.filter { item in
                            searchText.isEmpty || (item.wrappedValue.app.localizedName ?? "").localizedCaseInsensitiveContains(searchText)
                        }) { $item in
                            AppListItemView(item: $item, optionKeyPressed: $optionKeyPressed)
                                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                        }
                    } header: {
                        Text("\(filteredAppItems.count) APPLICATION\(filteredAppItems.count == 1 ? "" : "S")")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.secondary)
                            .padding(.leading, 16)
                            .padding(.bottom, 6)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }

            // Footer
            HStack {
                Spacer()

                Button(action: {
                    handleQuitAction(force: optionKeyPressed)
                }) {
                    Text(selectedApps.isEmpty
                         ? (optionKeyPressed ? "Force Quit All Apps" : "Quit All Apps")
                         : (optionKeyPressed ? "Force Quit \(selectedApps.count) Selected" : "Quit \(selectedApps.count) Selected"))
                        .font(.system(size: 12, weight: .medium))
                }
                .buttonStyle(.borderedProminent)
                .tint(selectedApps.isEmpty ? Color.secondary.opacity(0.2) : Color.red)
                .foregroundColor(selectedApps.isEmpty ? .primary : .white)
                .controlSize(.regular)
                .disabled(appItems.isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .onAppear(perform: setupApp)
        .onReceive(ramUpdateTimer) { _ in
            updateRAMUsage()
        }
    }

    func setupApp() {
        fetchApps()
        NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.didLaunchApplicationNotification, object: nil, queue: .main) { _ in fetchApps() }
        NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.didTerminateApplicationNotification, object: nil, queue: .main) { _ in fetchApps() }

        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { event in
            self.optionKeyPressed = event.modifierFlags.contains(.option)
            return event
        }
    }

    func fetchApps() {
        DispatchQueue.global(qos: .userInitiated).async {
            let allApps = NSWorkspace.shared.runningApplications
            let newItems = allApps.compactMap { app -> AppItem? in
                if !showBackgroundApps && app.activationPolicy != .regular { return nil }
                guard let bid = app.bundleIdentifier,
                      app.localizedName != "Quitty" else { return nil }
                let ram = self.getMemoryUsage(for: app.processIdentifier)
                return AppItem(id: bid, app: app, isSelected: false, ramUsage: ram)
            }
            let sortedItems = self.sortItems(newItems)
            DispatchQueue.main.async {
                let currentSelections = self.appItems.filter { $0.isSelected }.map { $0.id }
                self.appItems = sortedItems.map { item in
                    var modified = item
                    if currentSelections.contains(item.id) { modified.isSelected = true }
                    return modified
                }
            }
        }
    }

    func updateRAMUsage() {
        DispatchQueue.global(qos: .userInitiated).async {
            var updatedItems = self.appItems
            var needsSort = false
            for i in updatedItems.indices {
                let newRam = self.getMemoryUsage(for: updatedItems[i].app.processIdentifier)
                if updatedItems[i].ramUsage != newRam {
                    updatedItems[i].ramUsage = newRam
                    needsSort = true
                }
            }
            if needsSort {
                let sortedItems = self.sortItems(updatedItems)
                DispatchQueue.main.async {
                    self.appItems = sortedItems
                }
            }
        }
    }

    func sortItems(_ items: [AppItem]) -> [AppItem] {
        if sortMode == "ram" {
            return items.sorted {
                let bytes1 = self.getMemoryBytes(for: $0.app.processIdentifier)
                let bytes2 = self.getMemoryBytes(for: $1.app.processIdentifier)
                if bytes1 == bytes2 {
                    return ($0.app.localizedName ?? "") < ($1.app.localizedName ?? "")
                }
                return bytes1 > bytes2
            }
        } else {
            return items.sorted { ($0.app.localizedName ?? "") < ($1.app.localizedName ?? "") }
        }
    }

    private func getMemoryBytes(for pid: pid_t) -> Double {
        var info = proc_taskinfo()
        let size = MemoryLayout<proc_taskinfo>.stride
        let result = proc_pidinfo(pid, PROC_PIDTASKINFO, 0, &info, Int32(size))
        if result == size {
            return Double(info.pti_resident_size)
        }
        return 0
    }

    private func getMemoryUsage(for pid: pid_t) -> String {
        let bytes = getMemoryBytes(for: pid)
        if bytes > 0 {
            let megabytes = bytes / (1024 * 1024)
            if megabytes > 1024 {
                let gigabytes = megabytes / 1024
                return String(format: "%.1f GB", gigabytes)
            } else {
                return String(format: "%.0f MB", megabytes)
            }
        }
        return ""
    }

    func handleQuitAction(force: Bool = false) {
        let appsToQuit = selectedApps.isEmpty ? appItems : selectedApps
        let safeList = SafeListManager.shared.safeAppIDs
        for item in appsToQuit {
            if safeList.contains(item.id) { continue }
            if let freshAppRef = NSRunningApplication(processIdentifier: item.app.processIdentifier) {
                if force {
                    freshAppRef.forceTerminate()
                } else {
                    if !freshAppRef.terminate() {
                        freshAppRef.forceTerminate()
                    }
                }
            }
        }
        withAnimation {
            for index in appItems.indices {
                appItems[index].isSelected = false
            }
        }
    }
}

struct AppListItemView: View {
    @Binding var item: AppItem
    @Binding var optionKeyPressed: Bool
    @State private var isHovering = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                if let icon = item.app.icon {
                    Image(nsImage: icon)
                        .resizable()
                        .interpolation(.high)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 28, height: 28)
                        .shadow(color: Color.black.opacity(0.1), radius: 2, y: 1)
                }

                Text(item.app.localizedName ?? "App")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Spacer()

                if !item.ramUsage.isEmpty {
                    Text(item.ramUsage)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.secondary.opacity(0.6))
                }

                ZStack(alignment: .trailing) {
                    if item.isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.blue)
                    } else {
                        Image(systemName: "circle")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary.opacity(0.2))
                    }
                }
                .frame(width: 16)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(isHovering ? Color.primary.opacity(0.05) : Color.clear)
            .contentShape(Rectangle())
            .onHover { isHovering = $0 }
            .onTapGesture {
                item.isSelected.toggle()
            }
            .contextMenu {
                Button(role: .destructive) {
                    if let app = NSRunningApplication(processIdentifier: item.app.processIdentifier) {
                        app.forceTerminate()
                    }
                } label: {
                    Label("Force Quit", systemImage: "xmark.circle")
                }
            }

            Divider()
                .padding(.leading, 56)
        }
    }
}
