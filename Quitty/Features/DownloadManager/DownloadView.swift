import SwiftUI

struct DownloadView: View {
    @StateObject private var downloadManager = DownloadManager()
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "arrow.down.circle")
                        .font(.system(size: 40))
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Download Quitty")
                            .font(.title2.bold())
                        Text("Get the latest version of Quitty for your Mac")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                
                // Download section
                VStack(spacing: 12) {
                    Button(action: {
                        downloadManager.downloadQuittyFromHomebrew()
                    }) {
                        HStack(spacing: 12) {
                            if downloadManager.isDownloading {
                                ProgressView()
                                    .controlSize(.small)
                                Text("Downloading via Homebrew...")
                                    .font(.caption)
                            } else {
                                Image(systemName: "arrow.down.circle.fill")
                                    .font(.system(size: 16))
                                Text("Download via Homebrew")
                                    .font(.caption)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .disabled(downloadManager.isDownloading)
                    }
                    
                    if downloadManager.isDownloading {
                        VStack(spacing: 8) {
                            ProgressView(value: downloadManager.downloadProgress)
                                .progressViewStyle(LinearProgressViewStyle())
                            
                            Text("\(Int(downloadManager.downloadProgress * 100))% Complete")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                    }
                    
                    if let errorMessage = downloadManager.errorMessage {
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(.red)
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                
                // Alternative download options
                VStack(spacing: 8) {
                    Text("Terminal Installation")
                        .font(.headline)
                        .padding(.top)
                    
                    VStack(spacing: 8) {
                        Button("Show Terminal Commands") {
                            downloadManager.showTerminalInstructions()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                        
                        Text("Get exact commands to copy and paste in terminal")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Divider()
                    
                    Text("Alternative Installation Methods")
                        .font(.headline)
                        .padding(.top)
                    
                    VStack(spacing: 8) {
                        Button("Open GitHub Repository") {
                            downloadManager.openHomebrewPage()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        
                        Text("Download directly from GitHub releases")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
