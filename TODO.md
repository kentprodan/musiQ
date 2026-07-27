# musiQ — To-do

Tracks remaining work across the whole project. See [`docs/architecture.md`](docs/architecture.md) for the architectural rationale behind each item.

## Phase 1 — Rust core + Windows shell (done)

- [x] Minimal `core/musiq-core`: SQLite persistence, folder scanning, tag reading (`lofty`)
- [x] `ffi/musiq-uniffi`: UniFFI contract (proc-macro style), C# bindings via `uniffi-bindgen-cs`
- [x] `clients/windows-winui`: WinUI3 shell — Mica backdrop, custom title bar, left `NavigationView`, Library/Now Playing/Sources/Settings pages
- [x] Real end-to-end verification: folder scan, tag read, SQLite persistence across restarts

## Core (Rust)

- [ ] Tag *writing* / batch editing (Mp3Tag-parity: multi-file edit, rename patterns)
- [ ] Audio playback engine (`rodio`/`symphonia`) + queue management
- [ ] Plex client (`musiq-net` equivalent)
- [ ] Subsonic/Navidrome client
- [ ] Sandboxed plugin host (WASM, capability-scoped manifests)
- [ ] Extend UniFFI contract as each of the above lands, regenerate Swift/Kotlin bindings alongside C#

## Native clients

- [ ] `clients/apple-native` — SwiftUI (Liquid Glass): macOS, iOS, iPadOS, tvOS, watchOS, visionOS, CarPlay
- [ ] `clients/android-native` — Jetpack Compose (Material 3 Expressive): phone, tablet, Android TV, Wear OS
- [ ] `clients/linux-gnome` — GTK4 + Libadwaita
- [ ] `clients/linux-kde` — Qt/Kirigami
- [ ] `clients/desktop-tauri` — interim Tauri/React bridge for macOS + Linux desktop, until their native clients above exist

## Windows shell polish

- [ ] Now Playing page: real transport controls once the audio engine exists (currently an honest "nothing playing yet" placeholder)
- [ ] Sources page: support remote sources (Plex/Subsonic/Navidrome), not just local scanned folders
- [ ] Title bar: interactive content (e.g. search box) needs `InputNonClientPointerSource` passthrough regions
- [ ] Revisit `[ObservableProperty]` field-vs-partial-property pattern (CommunityToolkit.Mvvm 8.4 partial-property codegen didn't work in this toolchain combo — currently on the field-based pattern, which works but triggers an AOT/WinRT-marshalling advisory warning)
- [ ] Tag editing UI (once core batch-editing lands)
- [ ] Library page: sorting/filtering, album art, multi-select
