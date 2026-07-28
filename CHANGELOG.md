# Changelog

All notable changes to musiQ are documented in this file.

## [Unreleased]

### Added
- `TODO.md` tracking remaining work across the whole project (core, native clients, Windows shell polish).

## 2026-07-28 — Tag writing and batch editing

### Added
- **`core/musiq-core::tags`**: writes title/artist/album via `lofty` (`Tag::set_*`/`remove_*` + `save_to_path`), then mirrors the tag's final on-disk state back into the `tracks` row — the DB always reflects the file, not just what the caller asked to change. `Library::update_tags(track_ids, title, artist, album)` applies to one or many tracks in a single call: `Some(value)` sets a field (empty string clears it), `None` leaves it untouched. New `MusiqError::Tag` variant.
- **`ffi/musiq-uniffi`**: mirrors `update_tags`, regenerated into the C# bindings.
- **WinUI3 shell**:
  - `TrackItem` now carries the track's DB id plus raw (un-fallback'd) title/artist/album, so edit dialogs can pre-fill honestly instead of writing UI placeholders like "Unknown Artist" into real files.
  - **Library page**: a per-row Edit (pencil) button opens a `ContentDialog` to edit one track's Title/Artist/Album. The `ListView` is now `SelectionMode="Extended"` (click/ctrl-click/shift-click, no checkboxes — the documented desktop-appropriate mode) with an "Edit Selected…" button opening a second dialog that batch-writes Artist/Album (never Title) across the selection; a blank field there means "leave untouched," not "clear."
- Verified end-to-end on the Windows desktop via computer-use, including confirming the write reaches the actual audio file (not just the DB) by rescanning the folder from disk after editing, and confirming the "clear" path (`remove_title`/`remove_artist`/`remove_album`) by blanking all fields and saving.

### Descoped
- File rename/move-on-disk from tag patterns (the other half of "Mp3Tag-parity: multi-file edit, rename patterns" from `TODO.md`) — out of scope for this pass, tracked separately in `TODO.md`.

## 2026-07-28 — Playback queue: next/previous, shuffle, repeat

### Added
- **`core/musiq-core::Player`**: queue support layered on top of single-track playback — `set_queue`, `next`/`previous`, `advance_if_finished` (polled, since rodio has no completion callback), `set_shuffle`/`is_shuffled`, `set_repeat_mode`/`repeat_mode` (`Off`/`All`/`One`), `queue_position`/`queue_len`. Shuffle keeps the current track in place and randomizes the rest (via `rand`); repeat-one replays the current track on natural completion, repeat-all wraps `next`/`previous` at the queue boundary, repeat-off stops there.
- **`ffi/musiq-uniffi`**: mirrors the above (`RepeatMode` as a `uniffi::Enum`), regenerated into the C# bindings.
- **WinUI3 shell**: `LibraryService` now drives the queue and polls `advance_if_finished` every 500ms via a `DispatcherQueueTimer` (per Microsoft's `DispatcherQueueTimer` reference) to auto-advance when a track ends on its own.
  - **Library page**: the per-row Play button now queues the entire currently-displayed track list starting at that row, instead of playing a single track in isolation.
  - **Now Playing page**: added Shuffle, Previous, Next, and Repeat (cycling Off → All → One) buttons, glyphs and codepoints from Microsoft's Segoe Fluent Icons reference, with opacity reflecting on/off state.
- Verified end-to-end on the Windows desktop via computer-use: shuffle/repeat toggle correctly, repeat-all wraps Next/Previous instead of stopping, repeat-one/repeat-off correctly stop at the queue boundary. (Only one track exists in the scanned library on this machine, so true multi-track traversal and natural-end auto-advance weren't directly observed — the code path is shared with the verified wrap-around logic.)

### Fixed
- `NowPlayingViewModel` initially failed to compile (`CS0053`, inconsistent accessibility): the generated `RepeatMode` FFI enum is `internal`, but `[ObservableProperty]` generates a `public` property. Fixed by introducing a public `RepeatModeOption` wrapper enum in the ViewModel layer, mirroring how `TrackItem` already shields the FFI's `Track` type from XAML.

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
