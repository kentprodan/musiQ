use serde::{Deserialize, Serialize};
use uuid::Uuid;

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct Track {
    pub id: Uuid,
    pub title: String,
    pub artist_id: Option<Uuid>,
    pub album_id: Option<Uuid>,
    pub genre: Option<String>,
    pub track_no: Option<i32>,
    pub disc_no: Option<i32>,
    pub duration_ms: i64,
    pub year: Option<i32>,
    pub file_path: Option<String>,
    /// Set when the track is a read-through reference to a remote source
    /// (Plex rating key, Subsonic id, etc.) rather than a local file.
    pub remote_source_id: Option<Uuid>,
    pub remote_ref: Option<String>,
    pub bitrate_kbps: Option<i32>,
    pub sample_rate_hz: Option<i32>,
    pub replaygain_track_db: Option<f64>,
    pub replaygain_album_db: Option<f64>,
    /// Precomputed waveform peaks (min/max pairs, i8) used by the floating
    /// player's interactive seekbar. Generated once by musiq-audio-engine.
    pub waveform_peaks: Option<Vec<u8>>,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct Album {
    pub id: Uuid,
    pub title: String,
    pub artist_id: Option<Uuid>,
    pub year: Option<i32>,
    pub cover_art_path: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct Artist {
    pub id: Uuid,
    pub name: String,
    pub image_path: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct Playlist {
    pub id: Uuid,
    pub name: String,
    pub is_smart: bool,
    /// JSON-encoded rule tree, only present when `is_smart` is true.
    pub smart_rules: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct RemoteSource {
    pub id: Uuid,
    pub kind: String, // "plex" | "subsonic" | "navidrome"
    pub label: String,
    pub base_url: String,
    /// Secret token lives in the OS keychain, not in SQLite; this only
    /// stores the keychain lookup key.
    pub credential_ref: String,
}
