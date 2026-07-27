# musiQ — Android clients (phone, tablet, Android TV, Wear OS)

One Activity (`MainActivity`) branches at runtime between three layouts —
see `MainActivity.kt`:

- **Phone** (`MusiqMobileApp`, compact width) — bottom `NavigationBar` +
  `ModalNavigationDrawer` for the full library tree.
- **Tablet / landscape** (`MusiqMobileApp`, medium+ width) — `NavigationRail`
  instead of the bottom bar.
- **Android TV** (`MusiqTvApp`, detected via `UiModeManager`) — a D-Pad-first
  grid using `androidx.tv:tv-material`'s focus-aware `Card`.

Wear OS is intentionally not scaffolded here — it needs its own Wear
Compose module (`androidx.wear.compose`) rather than reusing phone
layouts; the `musiq-ffi` module below is written so a future `wear`
module can depend on it exactly like `app` does.

- `musiq-ffi/` — hand-written placeholder standing in for the Kotlin
  bindings `uniffi-bindgen` generates from
  [`core/musiq-ffi/src/musiq.udl`](../../core/musiq-ffi/src/musiq.udl).
  Regenerate with:
  ```
  uniffi-bindgen generate core/musiq-ffi/src/musiq.udl --language kotlin \
    --out-dir clients/android-native/musiq-ffi/src/main/java
  ```
  The native `.so` itself is built separately via `cargo ndk` (see the
  comment in `musiq-ffi/build.gradle.kts`) and is not part of this repo.

## Building this

This machine has no Android SDK/Gradle/JDK installed, so none of this has
been build- or run-verified — treat it as a structural starting point.
Open the `clients/android-native/` folder in Android Studio, let it
install the SDK/NDK it asks for, and sync Gradle.
