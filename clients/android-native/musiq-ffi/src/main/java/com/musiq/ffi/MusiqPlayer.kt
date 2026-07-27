package com.musiq.ffi

// Placeholder for the UniFFI-generated Kotlin bindings. Once musiq-ffi is
// cross-compiled for Android (arm64-v8a / armeabi-v7a / x86_64) via
// `cargo ndk`, regenerate this file with:
//
//   uniffi-bindgen generate core/musiq-ffi/src/musiq.udl \
//     --language kotlin --out-dir clients/android-native/musiq-ffi/src/main/java
//
// which produces the real JNA-backed `MusiqPlayer`, matching the
// `interface MusiqPlayer` declared in `musiq.udl` — the same contract
// the Apple bindings (`MusiqFFI.swift`) target, so Compose and SwiftUI
// call an identical surface.

enum class PlaybackState { STOPPED, PLAYING, PAUSED, BUFFERING }

data class FfiTrack(
    val id: String,
    val title: String,
    val artist: String,
    val album: String,
    val durationMs: ULong,
)

interface PlaybackObserver {
    fun onStateChanged(state: PlaybackState)
    fun onPositionChanged(positionMs: ULong)
    fun onTrackChanged(track: FfiTrack)
}

class MusiqPlayer(libraryDbPath: String) {
    fun play() {}
    fun pause() {}
    fun seek(positionMs: ULong) {}
    fun skipNext() {}
    fun skipPrevious() {}
    fun setVolume(volume: Float) {}
    fun listQueue(): List<FfiTrack> = emptyList()
    fun registerObserver(observer: PlaybackObserver) {}
}
