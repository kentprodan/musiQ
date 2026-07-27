use crate::{NetError, RemoteAlbum, RemoteLibrary, RemoteTrack};
use async_trait::async_trait;

/// Plex Media Server client, authenticated via `X-Plex-Token`. Talks to the
/// `/library/sections/{id}/all` and `/library/metadata/{ratingKey}/children`
/// endpoints and maps Plex's XML/JSON music metadata into `RemoteAlbum` /
/// `RemoteTrack`.
pub struct PlexClient {
    http: reqwest::Client,
    base_url: String,
    token: String,
    music_section_id: String,
}

impl PlexClient {
    pub fn new(base_url: impl Into<String>, token: impl Into<String>, music_section_id: impl Into<String>) -> Self {
        Self {
            http: reqwest::Client::new(),
            base_url: base_url.into(),
            token: token.into(),
            music_section_id: music_section_id.into(),
        }
    }
}

#[async_trait]
impl RemoteLibrary for PlexClient {
    async fn list_albums(&self) -> Result<Vec<RemoteAlbum>, NetError> {
        let url = format!(
            "{}/library/sections/{}/all?type=9&X-Plex-Token={}",
            self.base_url, self.music_section_id, self.token
        );
        let _response = self.http.get(&url).send().await?;
        // TODO: parse MediaContainer.Metadata[] -> RemoteAlbum.
        Ok(Vec::new())
    }

    async fn list_tracks(&self, album_remote_id: &str) -> Result<Vec<RemoteTrack>, NetError> {
        let url = format!(
            "{}/library/metadata/{}/children?X-Plex-Token={}",
            self.base_url, album_remote_id, self.token
        );
        let _response = self.http.get(&url).send().await?;
        // TODO: parse MediaContainer.Metadata[] -> RemoteTrack.
        Ok(Vec::new())
    }

    fn stream_url(&self, track_remote_id: &str) -> String {
        format!(
            "{}/library/parts/{}/file.mp3?X-Plex-Token={}",
            self.base_url, track_remote_id, self.token
        )
    }
}
