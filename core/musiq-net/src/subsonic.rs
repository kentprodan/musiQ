use crate::{NetError, RemoteAlbum, RemoteLibrary, RemoteTrack};
use async_trait::async_trait;

/// Subsonic-API client (also speaks Navidrome, Airsonic, Gonic — anything
/// implementing the same REST contract). Auth uses the token+salt scheme
/// (`t`/`s` params) rather than sending the password on every request.
pub struct SubsonicClient {
    http: reqwest::Client,
    base_url: String,
    username: String,
    token: String,
    salt: String,
}

impl SubsonicClient {
    pub fn new(base_url: impl Into<String>, username: impl Into<String>, token: impl Into<String>, salt: impl Into<String>) -> Self {
        Self {
            http: reqwest::Client::new(),
            base_url: base_url.into(),
            username: username.into(),
            token: token.into(),
            salt: salt.into(),
        }
    }

    fn auth_query(&self) -> String {
        format!(
            "u={}&t={}&s={}&v=1.16.1&c=musiQ&f=json",
            self.username, self.token, self.salt
        )
    }
}

#[async_trait]
impl RemoteLibrary for SubsonicClient {
    async fn list_albums(&self) -> Result<Vec<RemoteAlbum>, NetError> {
        let url = format!("{}/rest/getAlbumList2?type=alphabeticalByName&{}", self.base_url, self.auth_query());
        let _response = self.http.get(&url).send().await?;
        // TODO: parse the Subsonic JSON envelope -> RemoteAlbum.
        Ok(Vec::new())
    }

    async fn list_tracks(&self, album_remote_id: &str) -> Result<Vec<RemoteTrack>, NetError> {
        let url = format!("{}/rest/getAlbum?id={}&{}", self.base_url, album_remote_id, self.auth_query());
        let _response = self.http.get(&url).send().await?;
        // TODO: parse the Subsonic JSON envelope -> RemoteTrack.
        Ok(Vec::new())
    }

    fn stream_url(&self, track_remote_id: &str) -> String {
        format!("{}/rest/stream?id={}&{}", self.base_url, track_remote_id, self.auth_query())
    }
}
