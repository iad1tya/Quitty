
import SwiftUI

@main
struct QuittyApp: App {
    
    var body: some Scene {
        MenuBarExtra("Quitty", image: "MenuBarIcon") {
            ContentView()
        }
        .menuBarExtraStyle(.window)
        
        Settings {
            SettingsView()
        }
    }
}
