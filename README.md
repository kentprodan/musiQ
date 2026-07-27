# musiQ

A local-library manager (tags, batch editing, folder scanning — MusicBee/
Mp3Tag/iTunes territory) fused with a self-hosted streaming client (Plex,
Subsonic/Navidrome — Plexamp territory), built as one Rust core with a
native-feeling frontend on every platform.

## Monorepo layout

```
musiQ/
├── core/                       Rust workspace — all business logic
│   ├── musiq-core/              composition root (Library, scanning)
│   ├── musiq-db/                SQLite schema + queries (sqlx)
│   ├── musiq-metadata/          tag read/write (lofty), batch editing
│   ├── musiq-audio-engine/      playback (rodio/symphonia) + waveform gen
│   ├── musiq-net/                Plex + Subsonic/Navidrome clients
│   ├── musiq-plugins/            sandboxed WASM plugin host (wasmtime)
│   └── musiq-ffi/                UniFFI boundary for Swift/Kotlin
├── clients/
│   ├── desktop-tauri/            Windows, macOS, Linux (Tauri 2 + React)
│   ├── apple-native/              iOS, iPadOS, tvOS, watchOS, visionOS (SwiftUI)
│   └── android-native/            Android, Android TV (Jetpack Compose)
└── docs/
```

Only `clients/desktop-tauri` calls into `musiq-core` directly (in-process,
same language). The native clients never link `musiq-core` themselves —
they go through `musiq-ffi`'s UniFFI boundary, so Swift and Kotlin share
one generated contract instead of two hand-maintained ones.

## Design philosophy: one token set, no shared chrome

The desktop client renders the *same* React component tree on Windows,
macOS, and Linux — what changes per OS is a single `data-os` attribute on
`<html>`, set once at boot in
[`detectPlatform.ts`](clients/desktop-tauri/src/lib/detectPlatform.ts) from
a Tauri command ([`os_theme.rs`](clients/desktop-tauri/src-tauri/src/os_theme.rs)).
Every OS-specific stylesheet is a `[data-os="..."] { }` block of CSS
custom properties (materials, radii, motion curves, icon fonts); component
CSS never branches on platform directly, it only reads `var(--token)`:

| | Windows (Fluent 2) | macOS (HIG) | GNOME (Adwaita) | KDE (Breeze) |
|---|---|---|---|---|
| Material | Mica (native) + Acrylic (floating) | Vibrancy (native) + thick material | Flat, opaque | Semi-transparent + KWin blur passthrough |
| Motion | WinUI curves, connected animations, tilt | Spring-approximated easing, rubber-band scroll | GTK ease-out | Qt easing, denser spacing |
| Icons | Segoe Fluent Icons | SF Symbols | Symbolic icons | Breeze Icons |

See [`styles/tokens.css`](clients/desktop-tauri/src/styles/tokens.css) and
its four `os-*.css` siblings for the full token set.

## Signature features

- **Floating, hover-reactive player bar** — [`FloatingPlayerBar.tsx`](clients/desktop-tauri/src/components/player/FloatingPlayerBar.tsx):
  hovering the seekbar expands a thin progress line into a full
  interactive waveform ([`WaveformSeekbar.tsx`](clients/desktop-tauri/src/components/player/WaveformSeekbar.tsx),
  peaks precomputed once by [`musiq-audio-engine`](core/musiq-audio-engine/src/waveform.rs)),
  while every other control animates into a Gaussian blur.
- **CoverFlow revival** — [`CoverFlow.tsx`](clients/desktop-tauri/src/components/nowplaying/CoverFlow.tsx):
  the classic iTunes 3D carousel, built with plain CSS 3D transforms
  (`perspective`/`rotateY`/`translateZ`), mirror reflection included.
  SwiftUI (`CoverFlowView.swift`) and Compose (`NowPlayingScreen.kt`)
  reimplement the same distance-based rotate/scale/dim formula natively.
- **Sandboxed plugins** — [`musiq-plugins`](core/musiq-plugins/src): WASM
  modules run with zero ambient authority; every capability (network,
  managed-downloads write, library read/reorganize) is declared in the
  plugin's manifest and approved by the user in
  [`PluginsPanel.tsx`](clients/desktop-tauri/src/components/settings/PluginsPanel.tsx).
  Reference manifests for a downloader-category plugin (`tiddl`-style) and
  an organizer-category plugin (`tidarr`-style) live under
  [`core/musiq-plugins/examples`](core/musiq-plugins/examples).

## Status

This is an initial scaffold: the crate/module boundaries, the design-token
architecture, and the interaction models above are real and (where a
toolchain was available in this environment) build- or browser-verified.
Playback, library scanning, and remote sync are stubbed pending the next
pass. The Apple and Android projects have not been opened in Xcode/Android
Studio — this machine has neither installed — so treat those two as
structural, unverified starting points.
