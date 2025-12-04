# musiQ Engine - Quick Reference

## 🎵 AudioEngine (Singleton)

```swift
// Access
let engine = AudioEngine.shared

// Playback
engine.play(track: Track)
engine.pause()
engine.resume()
engine.stop()

// Position
engine.seek(to: 120.0) // Seek to 2 minutes

// Volume (0.0 - 1.0)
engine.setVolume(0.75)

// State (Published)
engine.isPlaying      // Bool
engine.currentTrack   // Track?
engine.currentTime    // TimeInterval
engine.duration       // TimeInterval
engine.volume         // Float

// Supported formats
engine.getSupportedFormats()
// → ["mp3", "flac", "wav", "aiff", "m4a", "ogg", "opus", "dsd", "dsf", "dff"]
```

## 💾 DatabaseManager (Singleton)

```swift
// Access
let db = DatabaseManager.shared

// Add tracks
try db.addTrack(trackRecord)
try db.addTracks([trackRecord1, trackRecord2]) { current, total in
    print("Progress: \(current)/\(total)")
}

// Query
let allTracks = try db.getAllTracks()
let results = try db.searchTracks(query: "Beethoven")
let artistTracks = try db.getTracksByArtist("Miles Davis")
let albumTracks = try db.getTracksByAlbum("Kind of Blue")

// Update
try db.updateTrack(modifiedTrack)

// Delete
try db.deleteTrack(id: 123)

// Stats
let count = try db.getTotalTrackCount()
let totalDuration = try db.getTotalDuration()
```

## 📊 Database Models

```swift
// Track Record
var track = TrackRecord(
    id: nil,                          // Auto-generated
    title: "Bohemian Rhapsody",
    artist: "Queen",
    album: "A Night at the Opera",
    albumArtist: "Queen",
    genre: "Rock",
    year: 1975,
    trackNumber: 11,
    discNumber: 1,
    duration: 354.0,                  // seconds
    bitrate: 320000,                  // bits/sec
    sampleRate: 44100,                // Hz
    format: "mp3",
    fileURL: "file:///path/to/file.mp3",
    fileSize: 8500000,                // bytes
    dateAdded: Date(),
    dateModified: nil,
    playCount: 0,
    rating: 5,                        // 0-5 stars
    lastPlayed: nil
)

// Convert to AudioEngine Track
let playableTrack = track.toTrack()
```

## 🖥️ LibraryViewController (AppKit)

```swift
// Create and embed
let libraryVC = LibraryViewController()
addChild(libraryVC)
view.addSubview(libraryVC.view)

// Search
libraryVC.search(query: "jazz")

// Get selection
let selected = libraryVC.getSelectedTracks()
```

## 🎨 SwiftUI Integration

```swift
// Use LibraryViewWrapper
struct MyView: View {
    @State var searchText = ""
    
    var body: some View {
        VStack {
            LibraryViewWrapper(searchText: $searchText)
            PlayerView()
        }
    }
}

// Or use complete hybrid view
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            HybridMainView()
        }
    }
}
```

## 🔄 Notifications

```swift
// Listen for database changes
NotificationCenter.default.addObserver(
    forName: .databaseDidChange,
    object: nil,
    queue: .main
) { _ in
    // Reload UI
}

// Post database change
NotificationCenter.default.post(name: .databaseDidChange, object: nil)
```

## 🎯 Combine Publishers

```swift
import Combine

// Observe AudioEngine
AudioEngine.shared.$isPlaying
    .sink { isPlaying in
        print("Playing: \(isPlaying)")
    }
    .store(in: &cancellables)

AudioEngine.shared.$currentTime
    .sink { time in
        updateProgressBar(time)
    }
    .store(in: &cancellables)
```

## 🏗️ Architecture Pattern

```swift
// 1. Import/scan files → TrackRecord
let metadata = extractMetadata(from: fileURL)
let track = TrackRecord(/* metadata */)

// 2. Save to database
try DatabaseManager.shared.addTrack(track)

// 3. Load in UI
let tracks = try DatabaseManager.shared.getAllTracks()
libraryVC.reload(with: tracks)

// 4. User selects → Play
let track = selectedTrack.toTrack()
AudioEngine.shared.play(track: track)

// 5. Update stats
track.playCount += 1
track.lastPlayed = Date()
try DatabaseManager.shared.updateTrack(track)
```

## ⚡️ Performance Tips

```swift
// Batch inserts
try db.addTracks(largeTrackArray) { current, total in
    // Show progress
}

// Async database operations
DispatchQueue.global(qos: .userInitiated).async {
    let tracks = try? DatabaseManager.shared.getAllTracks()
    DispatchQueue.main.async {
        updateUI(tracks)
    }
}

// AppKit for large datasets
// ✅ NSTableView handles 50k+ rows
// ❌ SwiftUI List struggles beyond 5k
```

## 🐛 Common Gotchas

```swift
// ❌ Don't create TrackRecord without ID when updating
var track = existingTrack  // Has ID
track.playCount += 1
try db.updateTrack(track)   // ✅

// ❌ Don't forget to convert TrackRecord → Track
let record: TrackRecord = ...
AudioEngine.shared.play(track: record.toTrack())  // ✅

// ❌ Don't block main thread with database ops
DispatchQueue.global().async {
    try? db.addTracks(manyTracks)  // ✅
}

// ❌ BASS must be initialized before use
// Uncomment BASS_Init in AudioEngine.initializeBASS()
```

## 📦 File Organization

```
musiQ/
├── Engine/
│   ├── AudioEngine.swift              # Playback
│   └── BASS-Bridging-Header.h         # C bridge
├── Database/
│   ├── DatabaseManager.swift          # CRUD ops
│   └── DatabaseModels.swift           # Records
└── Views/
    ├── LibraryViewController.swift    # AppKit table
    ├── PlayerView.swift               # SwiftUI player
    └── HybridMainView.swift           # Integration
```

## 🔧 Build Requirements

1. **Xcode 15+** with Swift 5.9+
2. **GRDB.swift** via SPM
3. **BASS frameworks** in project (download from un4seen.com)
4. **Bridging header** configured in build settings

---

**Ready to build?** See `ENGINE_SETUP.md` for complete instructions.
