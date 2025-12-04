# Settings System Documentation

## Overview

musiQ now includes a comprehensive settings system that manages application configuration, library locations, and user preferences. The settings system includes:

1. **Initial Setup Flow** - First-launch wizard for configuring the app
2. **Settings Manager** - Persistent storage of user preferences
3. **Settings View** - Full-featured settings interface accessible from the app menu and sidebar

## Components

### 1. SettingsManager (`musiQ/Settings/SettingsManager.swift`)

A singleton class that manages all application settings with persistent storage via UserDefaults.

**Key Properties:**
```swift
@Published var libraryLocation: URL?        // Where musiQ stores its data
@Published var musicLocation: URL?          // Where music files are located
@Published var shouldCopyMusic: Bool        // Copy to library vs read from location
@Published var hasCompletedInitialSetup: Bool  // First-launch flag
```

**Key Methods:**
- `completeInitialSetup(libraryLocation:musicLocation:shouldCopy:)` - Finalize first-launch setup
- `saveSettings()` - Persist current settings to UserDefaults
- `getDatabasePath()` - Get database path based on library location
- `getArtworkPath()` - Get artwork cache path
- `getMusicPath()` - Get music path (library or original location)
- `resetSettings()` - Reset all settings (requires reconfiguration)

**Library Structure:**
When a library location is selected, the following structure is created:
```
Library Location/
├── Music/          # Copied music files (if shouldCopyMusic = true)
├── Artwork/        # Album artwork cache
├── Database/       # SQLite database
│   └── musiQ.sqlite
└── Playlists/      # Exported playlists
```

### 2. InitialSetupView (`musiQ/Settings/InitialSetupView.swift`)

A 4-step wizard shown on first launch:

**Step 1: Library Location**
- Select where musiQ will store its data
- Creates Library/Music/Artwork/Database/Playlists folders

**Step 2: Music Location**
- Select where existing music files are stored
- Can be same or different from library location

**Step 3: Music Management**
- **Copy to Library**: Music files copied to library folder (good for organization)
- **Read from Location**: Music files stay where they are (saves disk space) ✓ Recommended

**Step 4: Confirmation**
- Review settings before completing setup
- Shows all selected paths and options

**UI Features:**
- Dark themed with liquid glass aesthetics
- Progress indicator showing current step
- Back/Continue navigation
- Validation preventing incomplete setup
- NSOpenPanel for folder selection

### 3. SettingsView (`musiQ/Settings/SettingsView.swift`)

Full settings interface with tabbed navigation:

#### General Tab
- **Application Settings**:
  - Launch at login
  - Show menu bar icon
  - Minimize to menu bar
- **Appearance**:
  - Theme selection (System/Light/Dark)
  - Show album artwork in sidebar

#### Library Tab
- **Library Location**: Change where musiQ stores data
- **Music Location**: Change music folder
- **Music Management**: Switch between copy/read modes
- **Import Settings**:
  - Watch folder for changes
  - Organize files by artist/album
  - Extract embedded artwork

#### Playback Tab
- **Audio Output**:
  - Output device selection
  - Sample rate (44.1kHz, 48kHz, 96kHz, 192kHz)
  - Exclusive mode (WASAPI)
  - Gapless playback
- **Crossfade**:
  - Enable/disable crossfade
  - Duration slider (1-10 seconds)
- **DSP Effects**:
  - Equalizer
  - Reverb
  - Normalize volume

#### Advanced Tab
- **Database**:
  - Database size display
  - Optimize database
  - Clear cache
- **Performance**:
  - Memory cache size (64-1024 MB)
  - Preload next track
  - Background processing
- **Danger Zone**:
  - Reset all settings (requires confirmation)

**UI Features:**
- Sidebar navigation with 4 tabs
- Apply/Reset buttons for unsaved changes
- NSOpenPanel integration for path selection
- Validation and change tracking
- Confirmation alerts for destructive actions

## Integration Points

### 1. App Launch (`musiQApp.swift`)

The main app checks `hasCompletedInitialSetup` on launch:
```swift
@StateObject private var settingsManager = SettingsManager.shared

var body: some Scene {
    WindowGroup {
        Group {
            if !settingsManager.hasCompletedInitialSetup {
                InitialSetupView()  // Show setup wizard
            } else {
                ContentView()       // Show main app
            }
        }
    }
}
```

### 2. App Menu

Settings accessible via macOS app menu:
- **musiQ → Settings...** (⌘,)

Implemented in `CommandGroup(replacing: .appSettings)` in `musiQApp.swift`

### 3. Sidebar

Settings button at bottom of sidebar:
- Replaces user profile section
- Opens settings sheet when clicked
- Gear icon with "Settings" label and chevron

### 4. DatabaseManager Integration

DatabaseManager now uses SettingsManager for database location:
```swift
private init() {
    let dbPath = SettingsManager.shared.getDatabasePath()
    databaseURL = URL(fileURLWithPath: dbPath)
    // ...
}
```

This allows the database to be stored in the user-configured library location instead of a hardcoded Application Support path.

## User Workflows

### First Launch
1. User opens musiQ for the first time
2. InitialSetupView appears automatically
3. User completes 4-step setup wizard
4. Settings saved, app shows main interface
5. Database and library structure created

### Accessing Settings Later
Three ways to open settings:
1. **App Menu**: musiQ → Settings... (⌘,)
2. **Sidebar**: Click "Settings" button at bottom
3. **Keyboard**: Press ⌘, from anywhere in app

### Changing Library Location
1. Open Settings
2. Go to Library tab
3. Click "Change" next to Library Location
4. Select new folder
5. Click "Apply"
6. ⚠️ Existing data must be manually moved

### Resetting Settings
1. Open Settings
2. Go to Advanced tab
3. Click "Reset All Settings" in Danger Zone
4. Confirm in alert dialog
5. App shows initial setup wizard on next launch

## Technical Details

### Persistence
- Uses `UserDefaults` for all settings storage
- Keys prefixed internally (e.g., "libraryLocation")
- Synchronizes immediately after save
- Settings survive app restarts

### Notifications
Settings system uses NotificationCenter for communication:
```swift
extension Notification.Name {
    static let openSettings = Notification.Name("openSettings")
}
```

Any component can trigger settings:
```swift
NotificationCenter.default.post(name: .openSettings, object: nil)
```

### Sheet Presentation
Settings displayed as a sheet overlay:
- Non-modal (can interact with main window)
- Dismissible with Esc key
- 800x600 pixel window
- Scrollable content areas

### Button Styles
Custom SwiftUI button styles for consistency:
- `PrimaryButtonStyle` - Blue gradient for primary actions
- `SecondaryButtonStyle` - White outline for secondary actions
- `DangerButtonStyle` - Red background for destructive actions

### File System Safety
- Directory creation with `withIntermediateDirectories: true`
- Try/catch for all file operations
- Fallback to Application Support if library location not set
- Path validation before saving

## Future Enhancements

### Planned Features
- [ ] iCloud sync for settings
- [ ] Import/export settings profiles
- [ ] Library migration wizard when changing locations
- [ ] Auto-backup before settings changes
- [ ] Settings search/filter
- [ ] Keyboard shortcut customization
- [ ] Theme customization (accent colors)
- [ ] Plugin/extension settings

### Potential Improvements
- Watch folders with FSEvents for auto-import
- Multiple library support (switch between libraries)
- Per-library settings (different preferences per library)
- Settings validation with user feedback
- Undo/redo for settings changes
- Settings history/audit log

## Troubleshooting

### Settings Not Persisting
**Cause**: UserDefaults not synchronizing
**Solution**: Check `saveSettings()` is called after changes

### Database Path Not Found
**Cause**: Library location not set or invalid
**Solution**: SettingsManager falls back to Application Support

### Initial Setup Loops
**Cause**: `hasCompletedInitialSetup` not saved
**Solution**: Verify `completeInitialSetup()` calls `saveSettings()`

### Settings Sheet Won't Open
**Cause**: Notification not reaching app
**Solution**: Check NotificationCenter observer in `musiQApp.swift`

### Library Structure Missing
**Cause**: Folder creation failed
**Solution**: Check write permissions for selected library location

## Code Examples

### Opening Settings Programmatically
```swift
Button("Open Settings") {
    NotificationCenter.default.post(name: .openSettings, object: nil)
}
```

### Accessing Current Settings
```swift
let settingsManager = SettingsManager.shared

if let libraryPath = settingsManager.libraryLocation {
    print("Library: \(libraryPath)")
}

if settingsManager.shouldCopyMusic {
    // Copy files to library
} else {
    // Read files from original location
}
```

### Checking First Launch
```swift
if !SettingsManager.shared.hasCompletedInitialSetup {
    // Show onboarding or setup
} else {
    // Normal app flow
}
```

### Resetting Settings
```swift
SettingsManager.shared.resetSettings()
// App will show initial setup on next launch
```

## See Also
- `ARCHITECTURE.md` - Overall app architecture
- `DATABASE_MANAGER.md` - Database integration
- `ENGINE_SETUP.md` - Audio engine configuration
- `IMPLEMENTATION_SUMMARY.md` - Complete feature list
