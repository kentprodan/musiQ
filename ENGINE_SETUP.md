# musiQ Engine Setup Guide

## Architecture Overview

musiQ uses a three-tier architecture optimized for performance:

```
┌─────────────────────────────────────────┐
│          UI Layer (Hybrid)              │
│  ┌────────────┐      ┌──────────────┐  │
│  │  SwiftUI   │      │   AppKit     │  │
│  │  (Chrome)  │      │ (NSTableView)│  │
│  └────────────┘      └──────────────┘  │
└─────────────────────────────────────────┘
                 │
┌─────────────────────────────────────────┐
│         Business Logic Layer            │
│  ┌────────────┐      ┌──────────────┐  │
│  │AudioEngine │      │DatabaseManager│ │
│  │  (BASS)    │      │  (GRDB)      │  │
│  └────────────┘      └──────────────┘  │
└─────────────────────────────────────────┘
                 │
┌─────────────────────────────────────────┐
│          Storage Layer                  │
│  ┌────────────┐      ┌──────────────┐  │
│  │    BASS    │      │   SQLite     │  │
│  │  Library   │      │  Database    │  │
│  └────────────┘      └──────────────┘  │
└─────────────────────────────────────────┘
```

## Component Details

### 1. AudioEngine (`musiQ/Engine/AudioEngine.swift`)
**Purpose**: High-performance audio playback using BASS library

**Features**:
- Multi-format support (FLAC, DSD, OGG, OPUS, MP3, WAV)
- DSP plugin support
- Gapless playback
- Real-time position tracking
- Volume control

**Key Methods**:
```swift
AudioEngine.shared.play(track: Track)
AudioEngine.shared.pause()
AudioEngine.shared.resume()
AudioEngine.shared.seek(to: TimeInterval)
AudioEngine.shared.setVolume(Float)
```

### 2. DatabaseManager (`musiQ/Database/DatabaseManager.swift`)
**Purpose**: SQLite database management via GRDB

**Features**:
- Type-safe queries
- Automatic migrations
- Batch operations
- Full-text search
- Optimized indexing

**Schema**:
- `tracks` - Main music library (title, artist, album, duration, etc.)
- `albums` - Album metadata with artwork paths
- `artists` - Artist aggregations
- `playlists` - User-created playlists
- `playlistTracks` - Playlist-track relationships

**Key Methods**:
```swift
DatabaseManager.shared.getAllTracks()
DatabaseManager.shared.addTrack(TrackRecord)
DatabaseManager.shared.searchTracks(query: String)
DatabaseManager.shared.addTracks([TrackRecord], progressHandler:)
```

### 3. LibraryViewController (`musiQ/Views/LibraryViewController.swift`)
**Purpose**: AppKit-based high-performance table view

**Features**:
- Handles 50k+ rows smoothly
- Column sorting
- Multi-selection
- Double-click to play
- Real-time search filtering

**Why AppKit**:
- SwiftUI List struggles with large datasets
- NSTableView is battle-tested for massive data
- Native macOS performance

### 4. PlayerView (`musiQ/Views/PlayerView.swift`)
**Purpose**: SwiftUI player controls

**Features**:
- Play/pause/skip controls
- Progress bar with seek
- Volume control
- Track metadata display
- Album artwork (placeholder)

### 5. HybridMainView (`musiQ/Views/HybridMainView.swift`)
**Purpose**: Coordinator between AppKit and SwiftUI

**Features**:
- Wraps NSViewController in SwiftUI
- Manages view transitions
- Search binding synchronization
- Tab switching (Library/Albums/Artists/Playlists)

## Setup Instructions

### Step 1: Add GRDB Dependency

1. Open `musiQ.xcodeproj` in Xcode
2. File → Add Package Dependencies
3. Enter URL: `https://github.com/groue/GRDB.swift`
4. Select version: 6.24.0 or later
5. Add to target: `musiQ`

### Step 2: Download BASS Frameworks

```bash
cd /Users/kentprodan/Documents/musiQ/Frameworks

# Visit https://www.un4seen.com/
# Download for macOS (ARM64 for Apple Silicon):
# - BASS (core)
# - BASSFLAC
# - BASSDSD
# - BASSOPUS
# - BASSWV (optional)

# Extract .framework files to this directory
```

### Step 3: Add BASS to Xcode

1. Drag frameworks from `Frameworks/` into Xcode project navigator
2. Select: Copy items if needed, Add to target: musiQ
3. Go to target settings → General → Frameworks, Libraries, and Embedded Content
4. Change all BASS frameworks to "Embed & Sign"

### Step 4: Configure Bridging Header

1. Select musiQ target → Build Settings
2. Search for "Objective-C Bridging Header"
3. Set to: `$(SRCROOT)/musiQ/Engine/BASS-Bridging-Header.h`
4. Open `BASS-Bridging-Header.h` and uncomment the imports

### Step 5: Integrate into Your App

Update `ContentView.swift` or create new main view:

```swift
import SwiftUI

@main
struct musiQApp: App {
    var body: some Scene {
        WindowGroup {
            HybridMainView()
                .frame(minWidth: 1000, minHeight: 600)
        }
    }
}
```

## Project Structure

```
musiQ/
├── Engine/
│   ├── AudioEngine.swift              # BASS wrapper
│   └── BASS-Bridging-Header.h         # C library bridge
├── Database/
│   ├── DatabaseManager.swift          # GRDB manager
│   └── DatabaseModels.swift           # Database records
├── Views/
│   ├── LibraryViewController.swift    # AppKit table view
│   ├── PlayerView.swift               # SwiftUI player
│   └── HybridMainView.swift           # Hybrid coordinator
├── Assets.xcassets/
└── musiQApp.swift
```

## Next Steps

1. **Import Library**: Build file scanner to populate database
2. **Album Art**: Add artwork extraction and caching
3. **Queue Management**: Implement play queue with shuffle/repeat
4. **Keyboard Shortcuts**: Add media key support
5. **DSP Effects**: Integrate BASS DSP plugins (EQ, reverb, etc.)
6. **Playlists**: Complete playlist CRUD operations
7. **Smart Playlists**: Add rule-based dynamic playlists

## Performance Notes

- **Database**: SQLite handles millions of tracks effortlessly
- **UI**: NSTableView renders 50k+ rows without lag
- **Audio**: BASS uses minimal CPU (<1% for most formats)
- **Memory**: Lazy loading keeps RAM usage low

## Testing

Build and run the app. You should see:
- Empty library (no tracks yet)
- Functional player UI (inactive)
- Tab switching
- Search bar (searches empty library)

Next, implement library import to populate the database.

---

**Built with**: BASS Audio Library + GRDB.swift + AppKit + SwiftUI
