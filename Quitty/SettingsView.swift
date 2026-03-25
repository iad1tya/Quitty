import SwiftUI
import Combine
import UniformTypeIdentifiers

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }
            
            SafeListSettingsView()
                .tabItem {
                    Label("Safe List", systemImage: "shield.fill")
                }
            
            AboutSettingsView()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 450)
    }
}

struct GeneralSettingsView: View {
    @StateObject private var launchHelper = LaunchHelper.shared
    @StateObject private var updater = UpdateChecker()
    @AppStorage("showBackgroundApps") private var showBackgroundApps = false
    
    var body: some View {
        Form {
            Section {
                Toggle("Start Quitty when I log in", isOn: $launchHelper.isLaunchAtLoginEnabled)
                    .toggleStyle(.checkbox)
                    .onChange(of: launchHelper.isLaunchAtLoginEnabled) { oldValue, newValue in
                        launchHelper.setLaunchAtLogin(enabled: newValue)
                    }
                
                Text("Show Quitty in the menu bar automatically when your computer starts.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    
                Toggle("Show Menu Bar & Background Apps", isOn: $showBackgroundApps)
                    .toggleStyle(.checkbox)
                
                Text("Advanced: Display utilities and helpers that run in the background.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section {
                Button(action: {
                    updater.checkForUpdates()
                }) {
                    HStack {
                        Text(updater.isChecking ? "Checking for Updates..." : "Check for Updates")
                        if updater.isChecking {
                            Spacer()
                            ProgressView().controlSize(.small)
                        }
                    }
                }
                .disabled(updater.isChecking)
                .alert(isPresented: $updater.showingAlert) {
                    Alert(title: Text(updater.alertTitle), message: Text(updater.alertMessage), dismissButton: .default(Text("OK")))
                }
            }
            
            Section {
                Button(role: .destructive) {
                    NSApplication.shared.terminate(nil)
                } label: {
                    Text("Quit the Quitty App Immediately")
                }
            }
        }
        .formStyle(.grouped)
        .padding()
        .frame(height: 300)
    }
}

class UpdateChecker: ObservableObject {
    @Published var isChecking = false
    @Published var showingAlert = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""
    
    func checkForUpdates() {
        isChecking = true
        guard let url = URL(string: "https://quitty.iad1tya.cyou/update.json") else {
            DispatchQueue.main.async { self.isChecking = false }
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                self.isChecking = false
                guard let data = data, error == nil else {
                    self.alertTitle = "Error"
                    self.alertMessage = "Failed to check for updates."
                    self.showingAlert = true
                    return
                }
                
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: String],
                   let remoteVersion = json["version"] {
                    let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
                    
                    if remoteVersion.compare(currentVersion, options: .numeric) == .orderedDescending {
                        if let url = URL(string: "https://quitty.iad1tya.cyou") {
                            NSWorkspace.shared.open(url)
                        }
                    } else {
                        self.alertTitle = "Up to Date"
                        self.alertMessage = "Quitty is on the latest version (\\(currentVersion))."
                        self.showingAlert = true
                    }
                } else {
                    self.alertTitle = "Error"
                    self.alertMessage = "Invalid update response format."
                    self.showingAlert = true
                }
            }
        }.resume()
    }
}

class SafeListManager: ObservableObject {
    static let shared = SafeListManager()
    @Published var safeAppIDs: [String] {
        didSet {
            UserDefaults.standard.set(safeAppIDs, forKey: "safeAppIDs")
        }
    }
    
    init() {
        self.safeAppIDs = UserDefaults.standard.stringArray(forKey: "safeAppIDs") ?? []
    }
    
    func addApp(_ id: String) {
        if !safeAppIDs.contains(id) { safeAppIDs.append(id) }
    }
    func removeApp(_ id: String) {
        safeAppIDs.removeAll { $0 == id }
    }
}

struct SafeListSettingsView: View {
    @StateObject private var safeList = SafeListManager.shared
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Apps listed here will NOT be affected when you click 'Quit All'.")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 10)
                .padding(.horizontal)
            
            List {
                ForEach(safeList.safeAppIDs, id: \.self) { bundleID in
                    HStack {
                        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID),
                           let bundle = Bundle(url: url) {
                            Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
                                .resizable()
                                .frame(width: 24, height: 24)
                            Text(bundle.infoDictionary?["CFBundleName"] as? String ?? bundleID)
                        } else {
                            Text(bundleID)
                        }
                        Spacer()
                        Button(action: { safeList.removeApp(bundleID) }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 4)
                }
            }
            .border(Color.secondary.opacity(0.2))
            .padding(.horizontal)
            
            HStack {
                Spacer()
                Button("Add App...") {
                    let panel = NSOpenPanel()
                    panel.allowedContentTypes = [.application]
                    panel.allowsMultipleSelection = true
                    panel.canChooseDirectories = false
                    if panel.runModal() == .OK {
                        for url in panel.urls {
                            if let bundle = Bundle(url: url), let bid = bundle.bundleIdentifier {
                                safeList.addApp(bid)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 10)
        }
        .frame(height: 300)
    }
}

struct AboutSettingsView: View {
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 6) {
                Text("Quitty")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("Version 1.0")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.secondary.opacity(0.15))
                    .cornerRadius(6)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 30)
            .background(Color(NSColor.controlBackgroundColor))
            
            VStack(spacing: 0) {
                VStack(spacing: 0) {
                    LinkRow(customIcon: "github", text: "View Source Code", url: "https://github.com/iad1tya/Quitty")
                    LinkRow(customIcon: "buymeacoffee", text: "Buy Me a Coffee", url: "https://buymeacoffee.com/iad1tya")
                }
                .padding(.top, 15)
                
                Spacer()
                
                Text("Part of Pixel Sphere")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 20)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 150)
            .background(Color(NSColor.windowBackgroundColor))
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

struct LinkRow: View {
    var systemIcon: String? = nil
    var customIcon: String? = nil
    let text: String
    let url: String
    
    @State private var isHovered = false
    
    var body: some View {
        Link(destination: URL(string: url)!) {
            HStack {
                if let systemIcon = systemIcon {
                    Image(systemName: systemIcon)
                        .frame(width: 20)
                        .foregroundColor(isHovered ? .blue : .secondary)
                } else if let customIcon = customIcon {
                    Image(customIcon)
                        .resizable()
                        .renderingMode(.template)
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .foregroundColor(isHovered ? .blue : .primary)
                }
                
                Text(text)
                    .foregroundColor(isHovered ? .blue : .primary)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.caption)
                    .foregroundColor(.secondary.opacity(0.5))
            }
            .padding(.horizontal, 40)
            .padding(.vertical, 8)
            .background(isHovered ? Color.secondary.opacity(0.1) : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
