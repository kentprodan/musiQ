//! musiq-net: clients for self-hosted streaming backends. musiQ treats these
//! as remote libraries that get mirrored (read-through) into the same
//! `musiq-db` schema as local files, so the rest of the app never branches
//! on "is this track local or remote" — it just resolves a `Track` and asks
//! `musiq-audio-engine` for either a file path or a stream URL.

pub mod plex;
pub mod subsonic;

use async_trait::async_trait;
use serde::{Deserialize, Serialize};

#[derive(thiserror::Error, Debug)]
pub enum NetError {
    #[error("http error: {0}")]
    Http(#[from] reqwest::Error),
    #[error("authentication failed")]
    AuthFailed,
    #[error("unexpected response shape: {0}")]
    BadResponse(String),
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RemoteAlbum {
    pub remote_id: String,
    pub title: String,
    pub artist: String,
    pub year: Option<i32>,
    pub cover_art_url: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RemoteTrack {
    pub remote_id: String,
    pub title: String,
    pub duration_ms: i64,
    pub stream_url: String,
}

/// Common surface both Plex and Subsonic/Navidrome clients implement, so
/// `musiq-core` can drive library sync and streaming without a per-backend
/// branch.
#[async_trait]
pub trait RemoteLibrary: Send + Sync {
    async fn list_albums(&self) -> Result<Vec<RemoteAlbum>, NetError>;
    async fn list_tracks(&self, album_remote_id: &str) -> Result<Vec<RemoteTrack>, NetError>;
    fn stream_url(&self, track_remote_id: &str) -> String;
}
