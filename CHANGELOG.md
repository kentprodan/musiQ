# Changelog

All notable changes to musiQ are documented in this file.

## [Unreleased]

### Added
- `TODO.md` tracking remaining work across the whole project (core, native clients, Windows shell polish).

## 2026-07-28 — Now Playing: click-to-jump on the up-next list

### Added
- **`core/musiq-core::Player::play_at(track_index)`**: jumps directly to any track in the current play order (looked up by its position within `play_order`, so it respects shuffle) instead of only stepping relatively via `next`/`previous`. Returns `false` if the index isn't in the queue rather than erroring, since a stale click (queue changed since the row was rendered) is an expected no-op, not a failure.
- **`ffi/musiq-uniffi`**: mirrors `play_at`, regenerated into the C# bindings.
- **WinUI3 Now Playing page**: the "up next" `ListView` is now clickable (`IsItemClickEnabled`) — tapping a row calls `LibraryService.PlayQueueItemAsync`, which resolves the clicked track back to its queue index and calls `play_at`.
- Verified end-to-end on the Windows desktop: with a track partway through playback, clicking its own row in "up next" restarted it from 0:00 and playback continued counting up normally afterward.

## 2026-07-28 — Now Playing: seek bar and up-next queue list

### Added
- **`core/musiq-core::Player`**: `position_secs` (rodio's `get_pos`), `seek_to_secs` (`try_seek`, works for both local files and streamed Plex/Navidrome sources since `HttpStreamReader` implements `Seek`), and `queue_order` (the queue's current play order — reflects shuffle — as indices into the original track list, for an accurate "up next" view).
- **`ffi/musiq-uniffi`**: mirrors all three, regenerated into the C# bindings.
- **WinUI3 Now Playing page**: a real seek bar (`Slider`, per Microsoft's guidance that media seek bars are an explicitly-endorsed slider use case) with drag-to-seek — tracks whether the user is actively dragging via `PointerPressed`/`PointerCaptureLost` so a 500ms position-poll timer doesn't fight the drag — plus a live elapsed/duration readout ("1:45 / 3:04"). Below that, an "up next" list showing the queue in its actual (shuffle-aware) play order with the current track highlighted.
- `TrackItem` gained a numeric `DurationSecs` (alongside the existing pre-formatted `Duration` string) so the seek bar has a real `Maximum`.
- Verified end-to-end on the Windows desktop: elapsed time updates live, dragging the slider actually repositions playback (confirmed position continues counting up from the seeked point, not the pre-seek one), and the up-next list shows the current queue.

### Fixed
- The Play/Pause and Repeat glyphs on the Now Playing page rendered blank after a `NowPlayingViewModel.cs` rewrite silently dropped the embedded Segoe Fluent Icons glyph characters — a recurring hazard with raw private-use-area Unicode characters in source, now written as explicit C# backslash-u escapes instead of literal characters. Also fixed the seek bar itself rendering at its default ~20px width instead of filling its container, because a shrink-to-fit `StackPanel` doesn't stretch children that have no explicit `Width`.

## 2026-07-28 — Real streaming for Plex, plus a Navidrome client

### Added
- **`core/musiq-core::streaming::HttpStreamReader`**: a shared `Read`+`Seek` adapter over HTTP, fetching bytes on demand via `Range` requests instead of downloading a file up front. Seeking is lazy — it only updates a position counter, and the next read reopens a range request only if that position doesn't match where the currently-open response left off, so ordinary sequential playback opens exactly one connection. `Player::play` now accepts either a local path or an `http(s)://` URL and dispatches accordingly, so remote tracks play through the exact same queue/pause/stop/shuffle/repeat machinery as local ones.
- **Plex** now streams directly through `stream_url` — the temp-file download step from the previous pass is gone entirely (`PlexClient::download_track` removed, along with the now-unused `file_extension` field it existed for).
- **`core/musiq-core::navidrome`**: a new client for Navidrome and any other Subsonic-API server. Token auth (`t = md5(password + salt)`, password never retained past hashing). Since Subsonic has no single "list every track" endpoint (unlike Plex), browsing goes music folder → albums → songs, mirroring how the API itself is organized. Streaming URLs use `format=raw` to disable server-side transcoding. New `MusiqError::Navidrome` variant. 5 unit tests against fixture JSON built from Subsonic's documented response shape (folder/album/song parsing, numeric-vs-string ID coercion, the `status: "ok"` envelope check Subsonic uses instead of HTTP status codes for auth failures).
- **`ffi/musiq-uniffi`**: mirrors the updated `PlexTrack` (no `file_extension`) and the new `NavidromeClient`/`NavidromeFolder`/`NavidromeAlbum`/`NavidromeSong`, regenerated into the C# bindings.
- **WinUI3 shell**: the Sources page gets a "Navidrome" section (server URL, username, password via `PasswordBox`) alongside Plex's, with folder and album buttons leading to a song list with Play. `TrackItem` gained a `FromNavidrome` factory alongside `FromPlex`.

### Known limitation
- **Neither Plex nor Navidrome has been verified against a live server** — none was available in this environment/session, same caveat as the original Plex pass. Only each client's failure path (unreachable host → timeout → clean error in the UI, no crash) was exercised end-to-end on the Windows desktop; local-library playback was re-verified working after the `Player::play` refactor. Treat both as implemented-but-unverified until tried against a real server.

## 2026-07-28 — Plex client

### Added
- **`core/musiq-core::plex`**: a minimal client for a self-hosted Plex Media Server, built on `ureq` + `serde_json` (no official Rust SDK exists, and responses are parsed field-by-field via `serde_json::Value` rather than strict structs, so one unexpected field doesn't break parsing of every other track). `PlexClient::test_connection`/`list_music_libraries`/`list_tracks`/`download_track`. Auth via `X-Plex-Token` header; JSON responses via `Accept: application/json` (Plex defaults to XML). New `MusiqError::Plex` variant.
- **`ffi/musiq-uniffi`**: mirrors `PlexClient`, `PlexTrack`, `PlexLibrary`, regenerated into the C# bindings.
- **WinUI3 shell**: the Sources page gets a "Plex" section — server URL + token (`PasswordBox`, since a Plex token is a credential) to connect, then a list of music libraries and a track list with a Play button per row.
- Playback works by **downloading a track to a temp file, then handing it to the existing local-file `Player`** (reusing 100% of the queue/pause/stop machinery — a Plex track is technically a length-1 queue). This is a deliberate simplification: there's no true progressive streaming yet, so playback doesn't start until the whole file has downloaded. Tracked as a follow-up in `TODO.md`, along with queue support for Plex libraries (currently a Plex track plays solo).
- 10 unit tests for the JSON-parsing logic (well-formed tracks, missing artist/album, tracks with no playable media, section-type filtering) using fixture JSON built from Plex's documented response shape.

### Known limitation
- **Not verified against a live Plex Media Server** — none was available in this environment/session. Only the failure path (unreachable host → timeout → clean error surfaced in the UI, no crash) was exercised end-to-end on the Windows desktop. The JSON-parsing logic is unit-tested against the documented API shape, but the actual endpoints, field names, and auth flow haven't been confirmed against a real server's real response. Treat this as implemented-but-unverified until someone with a real Plex server tries it.

## 2026-07-28 — Rename on disk (Mp3Tag-parity complete)

### Added
- **`core/musiq-core::rename`**: substitutes `{title}`/`{artist}`/`{album}` into a pattern (own `/`/`\` separators preserved, only the substituted values are sanitized for illegal filesystem characters). `Library::rename_tracks(track_ids, base_folder, pattern)` resolves each track's final path under `base_folder`, creates any needed subfolders, moves the file (`std::fs::rename`), and updates its stored path — refusing to overwrite an existing file at the destination. Missing tags fall back the same way the UI displays them (filename for title, "Unknown Artist"/"Unknown Album"). New `MusiqError::Rename` variant.
- **`ffi/musiq-uniffi`**: mirrors `rename_tracks`, regenerated into the C# bindings.
- **WinUI3 shell**: a "Rename Selected…" button on the Library page — pick a destination folder (reusing the same `FolderPicker` flow as Scan Folder), then a pattern dialog (default `{artist}/{album}/{title}`, helper text listing placeholders) — applies to the current multi-selection.
- Verified end-to-end on the Windows desktop: renamed the scanned track into a fresh nested folder structure, confirmed the file physically moved (old path gone, new path holds it) and playback still works from the new path, then reverted everything (moved the file back, rescanned) to leave the test library exactly as it was.

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
