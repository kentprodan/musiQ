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
    #[error("tag error: {message}")]
    Tag { message: String },
    #[error("rename error: {message}")]
    Rename { message: String },
    #[error("plex error: {message}")]
    Plex { message: String },
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
            CoreError::Tag(p) => MusiqError::Tag { message: p },
            CoreError::Rename(p) => MusiqError::Rename { message: p },
            CoreError::Plex(p) => MusiqError::Plex { message: p },
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

    /// `Some(value)` sets that field on every track in `track_ids` (an empty
    /// string clears it); `None` leaves it untouched. Returns the number of
    /// tracks updated.
    pub fn update_tags(
        &self,
        track_ids: Vec<String>,
        title: Option<String>,
        artist: Option<String>,
        album: Option<String>,
    ) -> Result<u32, MusiqError> {
        let library = self.inner.lock().unwrap();
        Ok(library.update_tags(&track_ids, title, artist, album)?)
    }

    /// Moves each track in `track_ids` to `base_folder` joined with
    /// `pattern` (`{title}`/`{artist}`/`{album}` placeholders), renaming it
    /// on disk and updating its stored path. Returns the number of tracks moved.
    pub fn rename_tracks(
        &self,
        track_ids: Vec<String>,
        base_folder: String,
        pattern: String,
    ) -> Result<u32, MusiqError> {
        let library = self.inner.lock().unwrap();
        Ok(library.rename_tracks(&track_ids, &PathBuf::from(base_folder), &pattern)?)
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

#[derive(uniffi::Record)]
pub struct PlexLibrary {
    pub key: String,
    pub title: String,
}

impl From<musiq_core::PlexLibrary> for PlexLibrary {
    fn from(l: musiq_core::PlexLibrary) -> Self {
        PlexLibrary {
            key: l.key,
            title: l.title,
        }
    }
}

#[derive(uniffi::Record)]
pub struct PlexTrack {
    pub rating_key: String,
    pub title: String,
    pub artist: Option<String>,
    pub album: Option<String>,
    pub duration_secs: Option<u32>,
    pub stream_url: String,
    pub file_extension: String,
}

impl From<musiq_core::PlexTrack> for PlexTrack {
    fn from(t: musiq_core::PlexTrack) -> Self {
        PlexTrack {
            rating_key: t.rating_key,
            title: t.title,
            artist: t.artist,
            album: t.album,
            duration_secs: t.duration_secs,
            stream_url: t.stream_url,
            file_extension: t.file_extension,
        }
    }
}

impl From<PlexTrack> for musiq_core::PlexTrack {
    fn from(t: PlexTrack) -> Self {
        musiq_core::PlexTrack {
            rating_key: t.rating_key,
            title: t.title,
            artist: t.artist,
            album: t.album,
            duration_secs: t.duration_secs,
            stream_url: t.stream_url,
            file_extension: t.file_extension,
        }
    }
}

/// A connection to a self-hosted Plex Media Server. Holds no interior
/// mutability (just a base URL and a token), so unlike `Library`/`Player`
/// there's no `Mutex` to wrap — it's `Send + Sync` on its own.
#[derive(uniffi::Object)]
pub struct PlexClient {
    inner: musiq_core::PlexClient,
}

#[uniffi::export]
impl PlexClient {
    #[uniffi::constructor]
    pub fn new(base_url: String, token: String) -> Arc<Self> {
        Arc::new(Self {
            inner: musiq_core::PlexClient::new(base_url, token),
        })
    }

    pub fn test_connection(&self) -> Result<(), MusiqError> {
        Ok(self.inner.test_connection()?)
    }

    pub fn list_music_libraries(&self) -> Result<Vec<PlexLibrary>, MusiqError> {
        Ok(self
            .inner
            .list_music_libraries()?
            .into_iter()
            .map(PlexLibrary::from)
            .collect())
    }

    pub fn list_tracks(&self, section_key: String) -> Result<Vec<PlexTrack>, MusiqError> {
        Ok(self
            .inner
            .list_tracks(&section_key)?
            .into_iter()
            .map(PlexTrack::from)
            .collect())
    }

    /// Downloads `track` into `dest_dir`, returning the local file path.
    pub fn download_track(&self, track: PlexTrack, dest_dir: String) -> Result<String, MusiqError> {
        let core_track: musiq_core::PlexTrack = track.into();
        let path = self.inner.download_track(&core_track, &PathBuf::from(dest_dir))?;
        Ok(path.to_string_lossy().into_owned())
    }
}

uniffi::setup_scaffolding!();
