//! musiq-uniffi: the one FFI boundary every native client (Swift, Kotlin,
//! and — via uniffi-bindgen-cs — C#) calls through. This crate holds no
//! business logic of its own; it only adapts `musiq-core`'s plain-Rust API
//! to UniFFI's proc-macro contract.

use std::path::PathBuf;
use std::sync::{Arc, Mutex};

use musiq_core::MusiqError as CoreError;

#[derive(uniffi::Record)]
pub struct Track {
    pub id: String,
    pub path: String,
    pub title: Option<String>,
    pub artist: Option<String>,
    pub album: Option<String>,
    pub duration_secs: Option<u32>,
}

impl From<musiq_core::Track> for Track {
    fn from(t: musiq_core::Track) -> Self {
        Track {
            id: t.id,
            path: t.path,
            title: t.title,
            artist: t.artist,
            album: t.album,
            duration_secs: t.duration_secs,
        }
    }
}

#[derive(uniffi::Error, thiserror::Error, Debug)]
pub enum MusiqError {
    #[error("io error: {message}")]
    Io { message: String },
    #[error("database error: {message}")]
    Db { message: String },
    #[error("invalid path: {message}")]
    InvalidPath { message: String },
    #[error("playback error: {message}")]
    Playback { message: String },
}

impl From<CoreError> for MusiqError {
    fn from(err: CoreError) -> Self {
        match err {
            CoreError::Io(e) => MusiqError::Io {
                message: e.to_string(),
            },
            CoreError::Db(e) => MusiqError::Db {
                message: e.to_string(),
            },
            CoreError::InvalidPath(p) => MusiqError::InvalidPath { message: p },
            CoreError::Playback(p) => MusiqError::Playback { message: p },
        }
    }
}

/// A handle to an open library. Wraps `musiq_core::Library` in a `Mutex`
/// because `rusqlite::Connection` is `!Sync`, while C#/Swift/Kotlin callers
/// may hold this `Arc<Library>` across threads (UI thread + background work).
#[derive(uniffi::Object)]
pub struct Library {
    inner: Mutex<musiq_core::Library>,
}

#[uniffi::export]
impl Library {
    #[uniffi::constructor]
    pub fn open(db_path: String) -> Result<Arc<Self>, MusiqError> {
        let inner = musiq_core::Library::open(&PathBuf::from(db_path))?;
        Ok(Arc::new(Self {
            inner: Mutex::new(inner),
        }))
    }

    pub fn scan_folder(&self, folder_path: String) -> Result<u32, MusiqError> {
        let library = self.inner.lock().unwrap();
        Ok(library.scan_folder(&PathBuf::from(folder_path))?)
    }

    pub fn list_tracks(&self) -> Result<Vec<Track>, MusiqError> {
        let library = self.inner.lock().unwrap();
        let tracks = library.list_tracks()?;
        Ok(tracks.into_iter().map(Track::from).collect())
    }

    pub fn list_scan_roots(&self) -> Result<Vec<String>, MusiqError> {
        let library = self.inner.lock().unwrap();
        Ok(library.list_scan_roots()?)
    }
}

#[derive(uniffi::Enum, Debug, Clone, Copy, PartialEq, Eq)]
pub enum RepeatMode {
    Off,
    All,
    One,
}

impl From<musiq_core::RepeatMode> for RepeatMode {
    fn from(mode: musiq_core::RepeatMode) -> Self {
        match mode {
            musiq_core::RepeatMode::Off => RepeatMode::Off,
            musiq_core::RepeatMode::All => RepeatMode::All,
            musiq_core::RepeatMode::One => RepeatMode::One,
        }
    }
}

impl From<RepeatMode> for musiq_core::RepeatMode {
    fn from(mode: RepeatMode) -> Self {
        match mode {
            RepeatMode::Off => musiq_core::RepeatMode::Off,
            RepeatMode::All => musiq_core::RepeatMode::All,
            RepeatMode::One => musiq_core::RepeatMode::One,
        }
    }
}

/// A handle to a single-track audio player. Wrapped in a `Mutex` for the same
/// reason as `Library`: callers (C#/Swift/Kotlin) may hold this `Arc<Player>`
/// across threads.
#[derive(uniffi::Object)]
pub struct Player {
    inner: Mutex<musiq_core::Player>,
}

#[uniffi::export]
impl Player {
    #[uniffi::constructor]
    pub fn new() -> Result<Arc<Self>, MusiqError> {
        let inner = musiq_core::Player::new()?;
        Ok(Arc::new(Self {
            inner: Mutex::new(inner),
        }))
    }

    pub fn play(&self, path: String) -> Result<(), MusiqError> {
        let player = self.inner.lock().unwrap();
        Ok(player.play(&PathBuf::from(path))?)
    }

    pub fn pause(&self) {
        self.inner.lock().unwrap().pause();
    }

    pub fn resume(&self) {
        self.inner.lock().unwrap().resume();
    }

    pub fn stop(&self) {
        self.inner.lock().unwrap().stop();
    }

    pub fn set_volume(&self, volume: f32) {
        self.inner.lock().unwrap().set_volume(volume);
    }

    pub fn is_paused(&self) -> bool {
        self.inner.lock().unwrap().is_paused()
    }

    pub fn has_track(&self) -> bool {
        self.inner.lock().unwrap().has_track()
    }

    pub fn current_track_path(&self) -> Option<String> {
        self.inner.lock().unwrap().current_track_path()
    }

    pub fn set_queue(&self, tracks: Vec<String>, start_index: u32) -> Result<(), MusiqError> {
        let player = self.inner.lock().unwrap();
        Ok(player.set_queue(tracks, start_index as usize)?)
    }

    pub fn next(&self) -> Result<bool, MusiqError> {
        Ok(self.inner.lock().unwrap().next()?)
    }

    pub fn previous(&self) -> Result<bool, MusiqError> {
        Ok(self.inner.lock().unwrap().previous()?)
    }

    /// Call periodically from the UI layer to auto-advance once the current
    /// track finishes on its own — rodio has no completion callback.
    pub fn advance_if_finished(&self) -> Result<bool, MusiqError> {
        Ok(self.inner.lock().unwrap().advance_if_finished()?)
    }

    pub fn set_shuffle(&self, shuffle: bool) {
        self.inner.lock().unwrap().set_shuffle(shuffle);
    }

    pub fn is_shuffled(&self) -> bool {
        self.inner.lock().unwrap().is_shuffled()
    }

    pub fn set_repeat_mode(&self, mode: RepeatMode) {
        self.inner.lock().unwrap().set_repeat_mode(mode.into());
    }

    pub fn repeat_mode(&self) -> RepeatMode {
        self.inner.lock().unwrap().repeat_mode().into()
    }

    pub fn queue_position(&self) -> Option<u32> {
        self.inner.lock().unwrap().queue_position()
    }

    pub fn queue_len(&self) -> u32 {
        self.inner.lock().unwrap().queue_len()
    }
}

uniffi::setup_scaffolding!();
