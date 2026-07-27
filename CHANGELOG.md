# Changelog

All notable changes to musiQ are documented in this file.

## [Unreleased]

### Added
- `TODO.md` tracking remaining work across the whole project (core, native clients, Windows shell polish).

## 2026-07-28 — Audio playback engine + real Now Playing controls

### Added
- **`core/musiq-core::Player`** — single-track playback via `rodio` 0.22 (`DeviceSinkBuilder::open_default_sink` + `Player::connect_new`): `play`/`pause`/`resume`/`stop`/`set_volume`/`is_paused`/`has_track`/`current_track_path`. New `MusiqError::Playback` variant.
- **`ffi/musiq-uniffi::Player`** — exposes the above as a `uniffi::Object` (same `Mutex`-wrapping pattern as `Library`), regenerated into the C# bindings.
- **WinUI3 shell**: `LibraryService` now owns a `Player` alongside `Library`, tracking the currently-playing `TrackItem` and raising a `CurrentTrackChanged` event.
  - **Library page**: each row has a real Play button (Segoe Fluent Icons glyph, per official reference) wired to a `PlayTrackCommand`.
  - **Now Playing page**: no longer a placeholder — shows the current track's title/artist and real Play/Pause (toggle, glyph-swapping) and Stop transport buttons, sourced from Microsoft's Segoe Fluent Icons documentation rather than memorized glyph codes.
- Verified end-to-end on the Windows desktop via computer-use: scanned track played with audible output (confirmed via the taskbar audio indicator), Pause/Resume/Stop all correctly update the UI and the underlying player state.

### Fixed
- `LibraryPage`'s per-row Play button initially did nothing: its `{Binding ElementName=..., Path=DataContext.PlayTrackCommand}` resolved to a `null` `DataContext`, because this codebase binds exclusively through `x:Bind` (which doesn't use `DataContext`) and never set one. Fixed by explicitly setting `LibraryPageRoot.DataContext = ViewModel` in the page's constructor.

## 2026-07-27 — Phase 1 restart: Rust core + native Windows shell

### Added
- **`core/musiq-core`** — minimal Rust library: open/create a SQLite library database (`rusqlite`), recursively scan a folder for audio files, read tags (`lofty`: title/artist/album/duration), list tracks back out. Tracks which folders have been scanned (`scan_roots` table) so the UI can show real sources instead of an approximation.
- **`ffi/musiq-uniffi`** — the single FFI boundary crate, written against UniFFI's proc-macro API (no legacy `.udl` file). Exposes `Library::open/scan_folder/list_tracks/list_scan_roots`. C# bindings generated via the community [`uniffi-bindgen-cs`](https://github.com/NordSecurity/uniffi-bindgen-cs) generator, pinned to a matching `uniffi` version.
- **`clients/windows-winui/MusiqWindows`** — native WinUI 3 (Fluent Design 2) desktop shell, scaffolded from Microsoft's official `winui-navview` template:
  - Mica backdrop (`Window.SystemBackdrop`) and a custom title bar (`ExtendsContentIntoTitleBar`/`SetTitleBar`).
  - Left `NavigationView` with four real pages: **Library** (folder picker, real scan, track list), **Now Playing** (honest "nothing playing yet" state — no playback engine exists yet), **Sources** (lists actually-scanned folders), **Settings** (real DB path + app version).
  - MVVM via CommunityToolkit.Mvvm; a `LibraryService` singleton owns the `Library` FFI handle and wraps every native call in `Task.Run`.
- **`scripts/gen-bindings-cs.ps1`** — regenerates the C# bindings and copies the native `musiq_uniffi.dll` into the WinUI3 project on every build (wired in via an MSBuild `BeforeBuild` target).
- **`docs/architecture.md`** — target monorepo architecture and the reasoning behind it (one Rust core, one UniFFI boundary, native shell per OS, Tauri as a temporary desktop bridge only).
- Placeholder `README.md`s for `clients/apple-native`, `clients/android-native`, `clients/linux-gnome`, `clients/linux-kde`, `clients/desktop-tauri` describing their planned role without pretending any code exists yet.

### Fixed
- **Crash on navigating to Settings** (`DllNotFoundException` → native fault inside `Microsoft.UI.Xaml.dll`, `STATUS_STOWED_EXCEPTION`): `musiq_uniffi.dll` was being copied to `runtimes\win-x64\native\`, a path .NET's native-library resolver only probes automatically for framework-dependent (non-packaged) apps via `deps.json`. An MSIX-packaged app falls back to plain OS `LoadLibrary` search, which only checks the executable's own directory. Fixed by adding `<Link>musiq_uniffi.dll</Link>` to the `Content` item so the DLL also lands in the app's output root, next to `MusiqWindows.exe`.
- Added a global `Application.UnhandledException` handler that logs to `crash.log` in the app's local data folder — this is what surfaced the exact exception above; kept in place for future diagnosability.

### Removed
- The previous six-crate Rust workspace (`musiq-core`/`musiq-db`/`musiq-metadata`/`musiq-audio-engine`/`musiq-net`/`musiq-plugins`/`musiq-ffi`), the working Tauri 2 + React desktop client, and the Apple/Android native stubs — all preserved on the `legacy-scaffold-backup` git branch. Removed and rebuilt from scratch at the user's explicit request after discovering the repo wasn't empty as assumed going in.
