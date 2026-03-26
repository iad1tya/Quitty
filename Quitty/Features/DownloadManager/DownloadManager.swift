import Foundation
import AppKit
import Combine

class DownloadManager: ObservableObject {
    @Published var isDownloading = false
    @Published var downloadProgress: Double = 0.0
    @Published var errorMessage: String?
    
    func downloadQuittyFromHomebrew() {
        guard !isDownloading else { return }
        
        isDownloading = true
        downloadProgress = 0.0
        errorMessage = nil
        
        DispatchQueue.global(qos: .userInitiated).async {
            let success = self.performHomebrewDownload()
            
            DispatchQueue.main.async {
                self.isDownloading = false
                if success {
                    self.downloadProgress = 1.0
                    self.showDownloadSuccessAlert()
                } else {
                    self.errorMessage = "Failed to download Quitty from Homebrew"
                }
            }
        }
    }
    
    private func performHomebrewDownload() -> Bool {
        // Check if Homebrew is installed
        guard isHomebrewInstalled() else {
            DispatchQueue.main.async {
                self.errorMessage = "Homebrew is not installed. Please install Homebrew first by running:\n/bin/bash -c \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
            }
            return false
        }
        
        // Try to install Quitty via Homebrew using the simple command
        let process = Process()
        let pipe = Pipe()
        let errorPipe = Pipe()
        
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = [
            "-c",
            """
            # First add the tap, then install Quitty
            brew tap iad1tya/quitty 2>/dev/null || true
            brew install quitty
            """
        ]
        
        process.standardOutput = pipe
        process.standardError = errorPipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let output = pipe.fileHandleForReading.readDataToEndOfFile()
            let errorOutput = errorPipe.fileHandleForReading.readDataToEndOfFile()
            
            if process.terminationStatus == 0 {
                print("Homebrew installation successful: \(String(data: output, encoding: .utf8) ?? "")")
                return true
            } else {
                let errorMsg = String(data: errorOutput, encoding: .utf8) ?? "Unknown error"
                print("Homebrew installation failed: \(errorMsg)")
                return false
            }
        } catch {
            print("Error during Homebrew installation: \(error)")
            return false
        }
    }
    
    private func isHomebrewInstalled() -> Bool {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = ["brew"]
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice
        
        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }
    
    private func showDownloadSuccessAlert() {
        let alert = NSAlert()
        alert.messageText = "Quitty Downloaded Successfully!"
        alert.informativeText = "Quitty has been installed via Homebrew. You can now run it from your Applications folder or by using 'open /Applications/Quitty.app' command in terminal."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    func openHomebrewPage() {
        let url = URL(string: "https://github.com/iad1tya/Quitty")
        if let url = url {
            NSWorkspace.shared.open(url)
        }
    }
    
    func showTerminalInstructions() {
        let alert = NSAlert()
        alert.messageText = "Terminal Installation Instructions"
        alert.informativeText = """
        To install Quitty via Homebrew, run these commands in your terminal:
        
        1. Install Homebrew (if not already installed):
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        2. Install Quitty:
        brew install quitty
        
        3. Run Quitty:
        open /Applications/Quitty.app
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Copy Commands")
        alert.addButton(withTitle: "OK")
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString("""
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew install quitty
open /Applications/Quitty.app
""", forType: .string)
        }
    }
}
