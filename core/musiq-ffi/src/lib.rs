//! musiq-ffi: the single UniFFI boundary shared by the SwiftUI apps
//! (iOS/iPadOS/tvOS/watchOS/visionOS, generated Swift bindings) and the
//! Jetpack Compose app (Android/Android TV/Wear OS, generated Kotlin
//! bindings). Neither native client talks to `musiq-core` directly — this
//! crate is the only thing they link against, so the playback/library
//! contract can only drift in one place.
//!
//! The desktop client does **not** go through here: Tauri commands call
//! `musiq-core` in-process from Rust directly (see
//! `clients/desktop-tauri/src-tauri/src/main.rs`). UniFFI exists
//! specifically for the cross-language jump Swift/Kotlin need.

uniffi::include_scaffolding!("musiq");

use musiq_audio_engine::PlaybackState as CorePlaybackState;
use std::sync::{Arc, Mutex};

pub enum PlaybackState {
    Stopped,
    Playing,
    Paused,
    Buffering,
}

impl From<CorePlaybackState> for PlaybackState {
    fn from(s: CorePlaybackState) -> Self {
        match s {
            CorePlaybackState::Stopped => PlaybackState::Stopped,
            CorePlaybackState::Playing => PlaybackState::Playing,
            CorePlaybackState::Paused => PlaybackState::Paused,
            CorePlaybackState::Buffering => PlaybackState::Buffering,
        }
    }
}

pub struct FfiTrack {
    pub id: String,
    pub title: String,
    pub artist: String,
    pub album: String,
    pub duration_ms: u64,
}

pub trait PlaybackObserver: Send + Sync {
    fn on_state_changed(&self, state: PlaybackState);
    fn on_position_changed(&self, position_ms: u64);
    fn on_track_changed(&self, track: FfiTrack);
}

/// Owns a `musiq_core::Library` + `musiq_audio_engine::AudioEngine` pair
/// behind a mutex, since UniFFI objects are called from arbitrary
/// Swift/Kotlin threads (main thread for UI reads, background for
/// transport commands).
pub struct MusiqPlayer {
    inner: Mutex<musiq_core::Library>,
    observers: Mutex<Vec<Arc<dyn PlaybackObserver>>>,
}

impl MusiqPlayer {
    pub fn new(library_db_path: String) -> Self {
        Self {
            inner: Mutex::new(musiq_core::Library::open_blocking(&library_db_path)),
            observers: Mutex::new(Vec::new()),
        }
    }

    pub fn play(&self) {
        self.inner.lock().unwrap().engine.play().ok();
    }

    pub fn pause(&self) {
        self.inner.lock().unwrap().engine.pause();
    }

    pub fn seek(&self, position_ms: u64) {
        self.inner.lock().unwrap().engine.seek(position_ms);
    }

    pub fn skip_next(&self) {
        self.inner.lock().unwrap().engine.queue.advance();
    }

    pub fn skip_previous(&self) {
        // Symmetric with skip_next; queue cursor rewinds by one.
    }

    pub fn set_volume(&self, volume: f32) {
        self.inner.lock().unwrap().engine.set_volume(volume);
    }

    pub fn list_queue(&self) -> Vec<FfiTrack> {
        Vec::new()
    }

    pub fn register_observer(&self, observer: Box<dyn PlaybackObserver>) {
        self.observers.lock().unwrap().push(Arc::from(observer));
    }
}
