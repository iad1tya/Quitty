# Quitty

**A macOS system optimization and cleanup utility.**

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-macOS-lightgrey.svg)](https://developer.apple.com/macos/)
[![Version](https://img.shields.io/badge/version-1.0.0-green.svg)](https://github.com/iad1tya/Quitty/releases)

[Download DMG](https://github.com/iad1tya/Quitty/releases/download/v1.0.0/Quitty-1.0.0.dmg) &nbsp;|&nbsp; [Report Issues](https://github.com/iad1tya/Quitty/issues) &nbsp;|&nbsp; [Discussions](https://github.com/iad1tya/Quitty/discussions)

---

## Overview

Quitty is an all-in-one macOS utility for system maintenance, performance optimization, and storage management. It provides real-time monitoring, automated cleaning, and advanced tools through a single, unified interface.

---

## Features

### System Dashboard
- Live CPU, RAM, disk, and battery statistics
- Visual charts and graphs for system metrics
- Smart recommendations for optimization
- One-click access to all tools

### System Cleaning
- Removes temporary files, caches, logs, and system junk
- Trash manager across all volumes and user accounts
- Smart detection to identify only safe-to-delete files
- Configurable categories for granular control

### File Management
- Duplicate file finder with full-system scan support
- Large files scanner with detailed size analysis
- Visual disk space map with interactive directory browsing
- Preview before deletion with file recovery options

### Performance Optimization
- RAM booster to free memory by terminating unnecessary processes
- Real-time CPU monitoring with per-process breakdown
- Startup manager to control login items
- Battery health monitoring and power usage tracking

### Network Monitoring
- Real-time upload and download speed tracking
- Per-application bandwidth usage
- Active connection analysis

### Automation and Scheduling
- Task scheduler for cleaning and optimization routines
- Daily, weekly, and monthly recurrence options
- Idle-time scheduling to minimize disruption
- Notifications on task completion

### Advanced Tools
- Full app uninstaller with leftover file detection
- Process manager for viewing and controlling running processes
- Detailed hardware and software system information
- Storage analyzer with file type breakdown and growth tracking

---

## Installation

### Option 1: DMG (Recommended)

1. Download the latest DMG from [Releases](https://github.com/iad1tya/Quitty/releases).
2. Mount the DMG file.
3. Drag `Quitty.app` to your Applications folder.
4. Launch Quitty from Applications.

### Option 2: Build from Source

```bash
# Clone the repository
git clone https://github.com/iad1tya/Quitty.git
cd Quitty

# Build the project
xcodebuild -project Bye.xcodeproj -scheme Quitty -configuration Release

# Copy to Applications
cp -R "/Users/$(whoami)/Library/Developer/Xcode/DerivedData/Bye-*/Build/Products/Release/Quitty.app" /Applications/
```

---

## Usage

### Getting Started

1. Open Quitty from your Applications folder.
2. The dashboard displays your system's current health and stats.
3. Use the sidebar to navigate between features.

### Dashboard

The main dashboard provides four status cards — RAM, CPU, Disk, and Battery — alongside quick action buttons for the most common tasks:

| Quick Action | Description |
|---|---|
| Clean Junk | Removes system and app cache, logs, and temp files |
| Empty Trash | Empties trash across all mounted volumes |
| Free RAM | Terminates unnecessary processes to free memory |
| Find Duplicates | Initiates a full duplicate file scan |
| Large Files | Scans for files above a configurable size threshold |
| Quit All Apps | Safely closes non-essential applications |

### System Cleaning

1. Navigate to **System Junk** in the sidebar.
2. Review detected categories: System Cache, User Cache, Log Files, Temporary Files.
3. Select the categories you want to clean.
4. Click **Clean Selected**.

### Duplicate Finder

1. Navigate to **Duplicates** in the sidebar.
2. Choose a scan location (full system or a specific folder).
3. Click **Start Scan**.
4. Review results and select files to remove. Use **Smart Selection** to retain the newest version automatically.

### Large Files Scanner

1. Navigate to **Large Files** in the sidebar.
2. Set a minimum file size threshold.
3. Select a scan location and review results.

### RAM Booster

1. Navigate to **RAM Booster** in the sidebar.
2. Review the current memory breakdown.
3. Click **Free RAM** to reclaim memory.

### Task Scheduler

1. Navigate to **Scheduler** in the sidebar.
2. Create a new task (Clean Junk, Empty Trash, Free RAM, or Find Duplicates).
3. Set the frequency and notification preferences.

---

## Configuration

Access settings via **Settings...** in the menu bar or from the sidebar.

| Setting | Description |
|---|---|
| Launch at Login | Start Quitty automatically on system startup |
| Background Monitoring | Keep system stats active while the app is in the background |
| Update Frequency | Control how often stats refresh |
| Safe Mode | Restrict cleaning to verified safe-to-delete files only |
| Custom Exclusions | Exclude specific files or folders from cleaning operations |
| Backup Options | Create backups before deletion |
| Notifications | Configure alerts for task completion and system warnings |

---

## System Requirements

| Requirement | Minimum |
|---|---|
| macOS | 14.6 (Sonoma) or later |
| Memory | 4 GB RAM (8 GB recommended) |
| Storage | 500 MB free space |
| Processor | Apple Silicon or Intel |

---

## Privacy and Safety

- Quitty collects no data and includes no telemetry.
- All operations are performed locally on your device.
- Safe Mode ensures only verified junk files are targeted.
- Backups can be created automatically before any destructive operation.

---

## Contributing

Contributions are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### Development Setup

```bash
# Clone the repository
git clone https://github.com/iad1tya/Quitty.git
cd Quitty

# Open in Xcode
open Bye.xcodeproj

# Build and run (Debug)
xcodebuild -project Bye.xcodeproj -scheme Quitty -configuration Debug
```

---

## Bug Reports and Feature Requests

- **Bug Reports**: [File an issue](https://github.com/iad1tya/Quitty/issues/new?template=bug_report.md)
- **Feature Requests**: [Suggest a feature](https://github.com/iad1tya/Quitty/issues/new?template=feature_request.md)
- **Questions**: [Start a discussion](https://github.com/iad1tya/Quitty/discussions)

---

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for a full history of changes.

---

## License

Quitty is open-source software licensed under the [MIT License](LICENSE).

---

## Links

- Website: [https://quitty.iad1tya.cyou](https://quitty.iad1tya.cyou)
- Documentation: [Wiki](https://github.com/iad1tya/Quitty/wiki)
- Twitter: [@xad1tya](https://x.com/xad1tya)
