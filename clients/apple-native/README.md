# musiQ — Apple clients (iOS, iPadOS, tvOS, watchOS, visionOS)

Shared SwiftUI code lives in this Swift package; each platform still needs
its own Xcode **App** target (see `Sources/MusiqApp/ExampleApp.swift` for
the ~10 lines that target adds).

- `MusiqFFI` — hand-written placeholder standing in for the bindings
  `uniffi-bindgen` generates from [`core/musiq-ffi/src/musiq.udl`](../../core/musiq-ffi/src/musiq.udl).
  Regenerate with:
  ```
  uniffi-bindgen generate core/musiq-ffi/src/musiq.udl --language swift \
    --out-dir clients/apple-native/Sources/MusiqFFI
  ```
- `MusiqUI` — the shared root view (`MusiqRootView`), the floating
  `PlayerBarView`, and the 3D `CoverFlowView` — the same interaction
  language as the desktop client (hover/drag-to-scrub blurs the
  transport controls; CoverFlow uses `rotation3DEffect` where the web
  client uses CSS 3D transforms).

## Opening this in Xcode

This machine has no Xcode installed, so none of this has been build- or
run-verified — treat it as a structural starting point, not a tested app.
To pick it up on macOS:

1. Create one App target per platform (iOS, tvOS, watchOS, visionOS).
2. Add this folder as a local Swift package dependency to each target.
3. Link `MusiqUI` and replace the target's `@main` App struct per
   `ExampleApp.swift`.
4. Build `core/musiq-ffi` as an XCFramework for the relevant Apple
   triples and regenerate `MusiqFFI` from the real `.udl` before wiring
   up actual playback.
