# musiQ Installation Checklist

Complete these steps to get musiQ running with full audio capabilities.

## ☐ Prerequisites

- [ ] macOS 14.0 (Sonoma) or later
- [ ] Xcode 15.0 or later installed
- [ ] Internet connection (for SPM)
- [ ] ~50MB free disk space (for frameworks)

## ☐ Step 1: Add GRDB Dependency (5 minutes)

1. [ ] Open `musiQ.xcodeproj` in Xcode
2. [ ] Go to: **File** → **Add Package Dependencies**
3. [ ] Enter URL: `https://github.com/groue/GRDB.swift`
4. [ ] Select version: **6.24.0** or later
5. [ ] Add to target: **musiQ**
6. [ ] Wait for package resolution
7. [ ] Verify: See GRDB in Project Navigator under "Package Dependencies"

**✅ Test**: Build project (⌘B) - should compile without errors

## ☐ Step 2: Download BASS Frameworks (10 minutes)

1. [ ] Visit [https://www.un4seen.com/](https://www.un4seen.com/)
2. [ ] Download **BASS** for macOS (choose ARM64 for Apple Silicon, or x64 for Intel)
3. [ ] Download **BASSFLAC** (FLAC support)
4. [ ] Download **BASSDSD** (DSD support)
5. [ ] Download **BASSOPUS** (OPUS support)
6. [ ] Optional: **BASSWV** (WavPack support)

**Extract frameworks:**
```bash
cd /Users/kentprodan/Documents/musiQ/Frameworks

# Extract each downloaded archive
# You should now have:
# - bass.framework
# - bassflac.framework  
# - bassdsd.framework
# - bassopus.framework
```

**License Note**: BASS is free for non-commercial use. For commercial use, purchase a license from un4seen.com.

## ☐ Step 3: Add BASS to Xcode (5 minutes)

1. [ ] In Xcode, right-click on project root
2. [ ] Select **Add Files to "musiQ"**
3. [ ] Navigate to `Frameworks/` folder
4. [ ] Select all `.framework` files
5. [ ] Check: **"Copy items if needed"**
6. [ ] Check: **"Add to targets: musiQ"**
7. [ ] Click **Add**

**Configure embedding:**
1. [ ] Select **musiQ** target in Project Navigator
2. [ ] Go to **General** tab
3. [ ] Scroll to **Frameworks, Libraries, and Embedded Content**
4. [ ] For each BASS framework, change dropdown from **"Do Not Embed"** to **"Embed & Sign"**

**✅ Test**: Frameworks should appear in project with "Embed & Sign" status

## ☐ Step 4: Configure Bridging Header (3 minutes)

1. [ ] Select **musiQ** target
2. [ ] Go to **Build Settings** tab
3. [ ] Search for: **"Objective-C Bridging Header"**
4. [ ] Set value to: `$(SRCROOT)/musiQ/Engine/BASS-Bridging-Header.h`

**Uncomment imports:**
1. [ ] Open `musiQ/Engine/BASS-Bridging-Header.h`
2. [ ] Uncomment these lines:
```objc
#import "bass.h"
#import "bassflac.h"
#import "bassdsd.h"
#import "bassopus.h"
// #import "basswv.h"  // Only if you downloaded it
```

**✅ Test**: Build project (⌘B) - should compile without errors

## ☐ Step 5: Enable BASS in AudioEngine (2 minutes)

1. [ ] Open `musiQ/Engine/AudioEngine.swift`
2. [ ] Find `initializeBASS()` method
3. [ ] Uncomment the BASS initialization:
```swift
private func initializeBASS() {
    // Uncomment this line:
    BASS_Init(-1, 44100, 0, nil, nil)
    print("⚡️ Audio Engine initialized")
}
```

4. [ ] Find other `BASS_` comments throughout the file
5. [ ] Uncomment all BASS function calls:
   - `BASS_StreamCreateFile`
   - `BASS_ChannelPlay`
   - `BASS_ChannelPause`
   - `BASS_ChannelStop`
   - `BASS_ChannelSetPosition`
   - `BASS_ChannelGetPosition`
   - `BASS_ChannelSetAttribute`
   - `BASS_Free`

**✅ Test**: Build project (⌘B) - should compile without errors

## ☐ Step 6: Build and Run (2 minutes)

1. [ ] Select target: **My Mac** (or your Mac's name)
2. [ ] Press **⌘R** to build and run
3. [ ] App should launch with:
   - Empty library view
   - Player controls (inactive)
   - Search bar
   - Tab switcher

**✅ Test**: No crashes, UI visible

## ☐ Step 7: Import Music Library (5 minutes)

**Option A: Use ImportView**
1. [ ] Add import view to your ContentView
2. [ ] Click "Choose Folder"
3. [ ] Select a folder with music files
4. [ ] Watch import progress
5. [ ] See tracks appear in library

**Option B: Programmatically**
```swift
let musicFolder = URL(fileURLWithPath: "/Users/yourname/Music")

LibraryImporter.shared.importFolder(at: musicFolder) { current, total, filename in
    print("Importing \(current)/\(total): \(filename)")
} completion: { result in
    switch result {
    case .success(let count):
        print("✅ Imported \(count) tracks")
    case .failure(let error):
        print("❌ Error: \(error)")
    }
}
```

**✅ Test**: Tracks appear in library grid

## ☐ Step 8: Play Music (1 minute)

1. [ ] Double-click any track in library
2. [ ] Player should activate
3. [ ] Progress bar should move
4. [ ] Time should update
5. [ ] Audio should play through speakers

**✅ Test**: Music plays, controls work

## 🎉 Installation Complete!

You now have a fully functional music player engine running on your Mac.

## 🐛 Troubleshooting

### Build Errors

**Error: "No such module 'GRDB'"**
- Solution: File → Packages → Resolve Package Versions

**Error: "'bass.h' file not found"**
- Solution: Check bridging header path in Build Settings
- Verify framework files are in project

**Error: "Undefined symbol: _BASS_Init"**
- Solution: Ensure frameworks are set to "Embed & Sign"
- Clean build folder (⌘⇧K) and rebuild

### Runtime Errors

**Error: "dyld: Library not loaded: @rpath/bass.framework"**
- Solution: Frameworks must be "Embed & Sign", not "Do Not Embed"

**Audio doesn't play**
- Check: BASS_Init was called successfully
- Check: File path is valid URL
- Check: System volume is not muted
- Check: AudioEngine uncommented all BASS calls

### Performance Issues

**Library loads slowly**
- Normal for first load with many tracks
- Database creates indexes on first run
- Subsequent loads should be <500ms

**UI freezes during import**
- LibraryImporter runs on background thread
- UI updates in batches of 100 tracks
- This is normal behavior

## 📚 Next Steps

Now that your engine is running:

1. **Customize UI**: Modify PlayerView, add your own style
2. **Add Features**: Album art, queue management, playlists
3. **Keyboard Shortcuts**: Implement media key support
4. **DSP Effects**: Add BASS DSP plugins for EQ/effects
5. **Cloud Sync**: Implement iCloud library syncing

See **[QUICK_REFERENCE.md](QUICK_REFERENCE.md)** for API documentation.

## 🆘 Need Help?

- **BASS Issues**: Check un4seen.com forum
- **GRDB Issues**: Check GRDB.swift GitHub issues
- **General Issues**: Check IMPLEMENTATION_SUMMARY.md

---

**Time to complete**: ~30 minutes  
**Difficulty**: Intermediate  
**Result**: Fully functional music player engine 🎵
