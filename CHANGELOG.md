# Changelog

## Version 2.0.0 - Major Feature Update

### 🎉 New Features

#### Dashboard
- Added unified system health dashboard with real-time stats
- Quick action buttons for common tasks
- Smart recommendations based on system status
- Export comprehensive system reports

#### Large Files Finder
- Scan for files over configurable size thresholds (50MB-5GB)
- Choose specific folders to scan
- Batch delete operations
- Export file listings to CSV

#### App Uninstaller
- Complete app removal including all related files
- Automatic detection of leftover files in ~/Library
- Shows total size including related files
- Expandable view to see all files before uninstalling

#### Network Monitor
- Real-time network activity per application
- Download/upload speed tracking
- Kill bandwidth-hogging processes
- Total system bandwidth display

#### CPU & Temperature Monitor
- Real-time CPU usage monitoring
- CPU temperature display (SMC access)
- Fan speed monitoring
- Top CPU-consuming processes list
- Process termination capability

#### Startup Analyzer
- Analyze boot time and startup impact
- List all login items and launch agents
- Toggle enable/disable for startup items
- Estimated boot time calculation
- Remove unwanted startup items

#### Scheduled Tasks
- Automate maintenance tasks
- Configurable frequency (daily/weekly/monthly/on startup)
- Execution log with timestamps
- Manual task execution
- 5 task types: Clean Junk, Empty Trash, Free RAM, Find Duplicates, Scan Large Files

### ⚡ Enhancements

#### Menu Bar
- **FIXED**: Menu bar icon no longer closes the app when clicked
- Added live stats display (RAM/CPU/Network/All)
- Configurable display options
- Auto-refresh every 2 seconds

#### Keyboard Shortcuts
- ⌘⇧Q: Quit All Apps
- ⌘⇧R: Free RAM
- ⌘⇧T: Empty Trash
- ⌘⇧K: Quick Actions (reserved)

#### Settings
- Reorganized into 5 tabs: General, Safe List, Presets, Shortcuts, About
- Added menu bar stats configuration
- Added notification preferences
- Added cleaning presets

#### Notifications
- Low disk space alerts (< 10GB)
- High RAM usage warnings (> 90%)
- Battery health notifications (< 80%)
- Configurable notification types

#### Export & Reports
- Export system health reports (TXT)
- Export scan results to CSV
- Added export buttons to:
  - System Junk
  - Duplicates
  - Large Files
  - Space Lens

#### Cleaning Presets
- Quick Tidy: Light cleaning
- Balanced: Recommended settings
- Deep Clean: Thorough cleaning
- Developer Mode: Xcode/npm/brew caches

### 🐛 Bug Fixes

- Fixed menu bar icon closing app when clicked
- Fixed window activation issues
- Improved permission request flow
- Better error handling throughout

### 🎨 UI/UX Improvements

- Consistent color coding across all features
- Better loading states and progress indicators
- Improved spacing and layout
- Enhanced visual feedback
- Smoother animations

### 📈 Performance

- Optimized file scanning algorithms
- Better memory management
- Async operations for all heavy tasks
- Cancellable long-running operations

### 🔒 Security & Privacy

- No data collection
- All processing happens locally
- Safe operations (Trash vs permanent delete)
- Proper permission handling

---

## Version 1.0.0 - Initial Release

### Core Features
- Process Manager with RAM monitoring
- System Junk Cleaner
- Trash Bins management
- Space Lens disk analyzer
- Duplicate Finder
- Optimization tools
- RAM Booster
- Battery Monitor
- Launch at login
- Safe List for protected apps
