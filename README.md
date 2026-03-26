<p align="center">
  <img src="assets/banner.png" alt="Quitty" width="1600" height="1200">
</p>
<div align="center">

# Quitty
**Quitty** is a powerful macOS system utility for power users. Monitor RAM, clean junk, find duplicates, manage startup items, track battery health, and visualize disk usage — all from a clean, native SwiftUI interface with sidebar navigation.

</div>

## Features

### Core — Process Manager
| Feature | Description |
|---|---|
| **Launch at Login** | Integrates with macOS login items to start silently on boot. |
| **Live RAM Monitoring** | Memory usage updates dynamically for every running app. |
| **Smart Sorting** | Toggle between alphabetical and highest-memory-first ordering. |
| **Advanced Filtering** | Search bar to quickly locate specific processes across all open apps. |
| **Safe List (Whitelist)** | Protect apps from being closed when using "Quit All." |
| **Background Process Visibility** | Reveal and manage hidden menu bar extensions and daemons. |

### System Junk Cleaner
Scans and removes cached files, logs, crash reports, Xcode DerivedData, and old downloads from `~/Library`. Shows breakdown by category with selective cleaning.

### Trash Bins
Shows current Trash size and file count. One-click "Empty Trash" via Finder automation. Requires Full Disk Access permission (prompted automatically).

### Space Lens
Visual disk usage analyzer with drill-down navigation. Displays directory sizes as proportional bars with color coding. Navigate into folders to find what's eating your disk space.

### Duplicate Finder
Two-pass scan: groups files by size, then compares SHA-256 hashes. Animated progress with cancel support. Configurable minimum file size (100KB–50MB). Select duplicates and move to Trash.

### Optimization
Manage Launch Agents — toggle enable/disable for user agents, view system agents. Shows app icons and human-readable descriptions for known services (Steam, Spotify, Adobe, Docker, etc.). Monitor and terminate heavy processes by CPU/memory usage.

### RAM Booster
Real-time RAM usage with circular gauge. Shows active, wired, compressed, and free memory via `host_statistics64()`. "Free RAM" terminates hidden high-memory apps and clears system caches.

### Battery Monitor
Battery charge, health percentage, cycle count, temperature, and charging status via IOKit. Circular gauge with color-coded thresholds. Shows time remaining and power source.

## Installation

### Option 1 — Direct Download (Recommended)
Download the latest version of Quitty directly from the official site:

**[Download Quitty](https://quitty.iad1tya.cyou)**

1. Download and open the `.dmg` file.
2. Drag **Quitty.app** into the **Applications** folder.
3. Launch Quitty from Launchpad or your Applications folder.

### Option 2 — GitHub Releases
Go to the [Releases](../../releases) page and download `Quitty.dmg`, then follow the same steps above.

### "App is Damaged" or "Cannot Be Opened"
Quitty is not signed with an Apple Developer certificate, so macOS Gatekeeper may block it on first launch. **Quitty is fully open-source and collects no data.** To allow it to run:

1. Open **Terminal** (`⌘ Space` → type "Terminal").
2. Run the following command:
```bash
   xattr -rd com.apple.quarantine /Applications/Quitty.app
```
3. Launch Quitty normally.

## Building from Source
**Requirements:** Xcode 14+, macOS 14.6+ (Sonoma or Sequoia)
```bash
git clone https://github.com/iad1tya/Quitty.git
```

1. Open `Bye.xcodeproj` in Xcode.
2. Select your Mac as the build destination.
3. Press `⌘ R` to build and run.

## Contributing
Issues, pull requests, and feature suggestions are welcome. Open an issue or submit a PR to get started.

## Support the Project
  <a href="https://buymeacoffee.com/iad1tya"><img src="assets/bmac.png" width="140"/></a>
  &nbsp;
  <a href="https://intradeus.github.io/http-protocol-redirector/?r=upi://pay?pa=iad1tya@upi&pn=Aditya%20Yadav&am=&tn=Thank%20You"><img src="assets/upi.svg" width="100"/></a>
</div>

## License
Quitty is open-source and free to use.
