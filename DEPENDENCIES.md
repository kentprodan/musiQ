# musiQ Dependencies

This project uses Swift Package Manager for dependency management.

## Core Dependencies

### GRDB.swift
High-performance SQLite wrapper with type-safe queries.
- **GitHub**: [groue/GRDB.swift](https://github.com/groue/GRDB.swift)
- **Version**: 6.24.0+
- **Purpose**: Database management for music library

To add GRDB to your Xcode project:
1. File → Add Package Dependencies
2. Enter: `https://github.com/groue/GRDB.swift`
3. Select version 6.24.0 or later

### BASS Audio Library
Professional audio playback engine (C library).
- **Website**: [un4seen.com/bass.html](https://www.un4seen.com/bass.html)
- **License**: Free for non-commercial use
- **Purpose**: Multi-format audio playback (FLAC, DSD, OGG, OPUS)

Required BASS components:
- **bass** - Core library
- **bassflac** - FLAC support
- **bassdsd** - DSD support  
- **bassopus** - OPUS support
- **basswv** - WavPack support

To add BASS to your Xcode project:

1. Download BASS libraries:
   ```bash
   cd Frameworks
   # Download from un4seen.com for macOS
   # Extract bass.framework, bassflac.framework, etc.
   ```

2. Add frameworks to Xcode:
   - Drag frameworks into project
   - Embed & Sign in General → Frameworks

3. Configure bridging header:
   - Build Settings → Objective-C Bridging Header
   - Set to: `musiQ/Engine/BASS-Bridging-Header.h`

4. Uncomment imports in `BASS-Bridging-Header.h`

## Installation Steps

### 1. Add GRDB
```bash
# In Xcode: File → Add Package Dependencies
# URL: https://github.com/groue/GRDB.swift
```

### 2. Download & Add BASS
```bash
cd /Users/kentprodan/Documents/musiQ/Frameworks

# Download BASS for macOS from un4seen.com
# Then add to Xcode project
```

### 3. Configure Build Settings
- Set bridging header path
- Add framework search paths if needed
- Ensure frameworks are embedded

## Build Configuration

The project uses:
- **Audio Engine**: BASS (C library) via bridging header
- **Database**: SQLite via GRDB.swift  
- **UI**: Hybrid AppKit + SwiftUI

See individual source files for implementation details.
