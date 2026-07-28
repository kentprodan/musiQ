# musiQ — To-do

Tracks remaining work across the whole project. See [`docs/architecture.md`](docs/architecture.md) for the architectural rationale behind each item.

## Phase 1 — Rust core + Windows shell (done)

- [x] Minimal `core/musiq-core`: SQLite persistence, folder scanning, tag reading (`lofty`)
- [x] `ffi/musiq-uniffi`: UniFFI contract (proc-macro style), C# bindings via `uniffi-bindgen-cs`
- [x] `clients/windows-winui`: WinUI3 shell — Mica backdrop, custom title bar, left `NavigationView`, Library/Now Playing/Sources/Settings pages
- [x] Real end-to-end verification: folder scan, tag read, SQLite persistence across restarts

## Core (Rust)

- [x] Tag *writing* / batch editing (title/artist/album, single + multi-track)
- [x] File rename/move on disk from tag patterns (`{artist}/{album}/{title}`-style, sanitized, subfolder-creating) — full Mp3Tag-parity feature now done
- [x] Audio playback engine (`rodio`) — single-track play/pause/resume/stop/volume
- [x] Playback queue management (next/previous, shuffle, repeat) — auto-advance on natural track end still needs multi-track hardware verification (only tested with a 1-track library so far)
- [x] Plex client (connect, browse music libraries, play tracks) — real streaming (HTTP range requests, no download-first step); browses artist → album → track (mirroring Plex's own hierarchy) instead of dumping every track in a library flat
- [x] Navidrome/Subsonic client (connect, browse folders → albums → songs, play) — real streaming (`format=raw` + range requests)
- [x] Shared `HttpStreamReader` (`Read`+`Seek` over HTTP ranges) so both Plex and Navidrome feed rodio's decoder directly, matching local-file playback — **neither client has been verified against a live server** (none available in this environment); only each one's error path (unreachable host, timeout) was exercised end-to-end. JSON-parsing logic has unit-test coverage against each API's documented response shape.
- [ ] **User to verify Plex + Navidrome against real servers** (connect, browse, play, confirm streaming actually starts before full download) — untested live as of 2026-07-28, see note above
- [x] Plex/Navidrome: queue support — playing a track queues the rest of the currently-shown library/album list around it (Next/Previous/shuffle/repeat all work), since `Player::set_queue` already treated paths generically and needed no core changes — **not yet verified against a live server**, see the verification item above
- [x] ~~Navidrome: regenerate the salt/token pair periodically~~ — decided against it: Subsonic tokens don't expire, so the only way to "regenerate" would be retaining the plaintext password in memory for the app's lifetime, a real security tradeoff for no practical benefit
- [ ] Sandboxed plugin host (WASM, capability-scoped manifests)
- [ ] Extend UniFFI contract as each of the above lands, regenerate Swift/Kotlin bindings alongside C#

## Native clients

- [ ] `clients/apple-native` — SwiftUI (Liquid Glass): macOS, iOS, iPadOS, tvOS, watchOS, visionOS, CarPlay
- [ ] `clients/android-native` — Jetpack Compose (Material 3 Expressive): phone, tablet, Android TV, Wear OS
- [ ] `clients/linux-gnome` — GTK4 + Libadwaita
- [ ] `clients/linux-kde` — Qt/Kirigami
- [ ] `clients/desktop-tauri` — interim Tauri/React bridge for macOS + Linux desktop, until their native clients above exist

## Windows shell polish

- [x] Now Playing page: real transport controls (Play/Pause/Stop, current track title+artist) wired to the rodio playback engine
- [x] Now Playing page: Shuffle/Previous/Next/Repeat controls wired to the queue engine
- [x] Now Playing: "up next" queue list view, current track highlighted, shuffle-aware (reads the queue's actual play order, not just the original list)
- [x] Now Playing: seek bar / elapsed-time display — real drag-to-seek (`rodio::Player::try_seek`), not just read-only progress
- [x] Sources page: Plex connection (server URL + token, library list, track list with Play)
- [x] Sources page: Navidrome connection (server URL + username/password, folder → album → song browsing, Play)
- [x] Plex/Navidrome: remember the connection (server URL + token/username/password) in Windows' Credential Locker (`PasswordVault`) and reconnect automatically on launch, with a "Forget" button to clear it
- [ ] Title bar: interactive content (e.g. search box) needs `InputNonClientPointerSource` passthrough regions
- [ ] Revisit `[ObservableProperty]` field-vs-partial-property pattern (CommunityToolkit.Mvvm 8.4 partial-property codegen didn't work in this toolchain combo — currently on the field-based pattern, which works but triggers an AOT/WinRT-marshalling advisory warning)
- [x] Tag editing UI: per-track edit dialog + multi-select ("Extended" selection) batch-edit dialog
- [ ] Library page: sorting/filtering, album art
- [x] Now Playing: click a track in "up next" to jump straight to it (`Player::play_at` jumps to any index in the current play order)
