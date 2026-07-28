//! A client for Navidrome and any other server implementing the Subsonic
//! API (`u`/`t`/`s`/`v`/`c` token auth: `t = md5(password + salt)`, so the
//! plaintext password is only ever hashed, never sent or stored). Unlike
//! Plex there's no single "list every track" endpoint, so browsing goes
//! music folder -> albums -> songs, mirroring how Subsonic itself organizes
//! a library. Playback streams directly via `/rest/stream.view?...&format=raw`
//! (the same real-streaming `Player` path Plex uses), not download-then-play.

use std::time::Duration;

use rand::Rng;
use serde_json::Value;

use crate::error::MusiqError;

const API_VERSION: &str = "1.16.1";
const CLIENT_NAME: &str = "musiQ";

pub struct NavidromeFolder {
    pub id: String,
    pub name: String,
}

pub struct NavidromeAlbum {
    pub id: String,
    pub name: String,
    pub artist: Option<String>,
}

pub struct NavidromeSong {
    pub id: String,
    pub title: String,
    pub artist: Option<String>,
    pub album: Option<String>,
    pub duration_secs: Option<u32>,
    pub stream_url: String,
}

pub struct NavidromeClient {
    base_url: String,
    username: String,
    salt: String,
    /// `md5(password + salt)`, computed once at construction — the
    /// plaintext password itself is never retained.
    token: String,
}

impl NavidromeClient {
    pub fn new(base_url: String, username: String, password: String) -> Self {
        let salt = Self::random_salt();
        let token = format!("{:x}", md5::compute(format!("{password}{salt}").as_bytes()));
        Self {
            base_url: base_url.trim_end_matches('/').to_string(),
            username,
            salt,
            token,
        }
    }

    fn random_salt() -> String {
        let mut bytes = [0u8; 8];
        rand::rng().fill_bytes(&mut bytes);
        bytes.iter().map(|b| format!("{b:02x}")).collect()
    }

    fn agent() -> ureq::Agent {
        ureq::Agent::config_builder()
            .timeout_global(Some(Duration::from_secs(10)))
            .build()
            .into()
    }

    fn auth_query(&self) -> String {
        format!(
            "u={}&t={}&s={}&v={API_VERSION}&c={CLIENT_NAME}",
            self.username, self.token, self.salt
        )
    }

    /// Calls `/rest/{endpoint}.view`, returning the inner
    /// `subsonic-response` object (Subsonic wraps every response in that
    /// envelope).
    fn get_json(&self, endpoint: &str, extra_params: &str) -> Result<Value, MusiqError> {
        let sep = if extra_params.is_empty() { "" } else { "&" };
        let url = format!(
            "{}/rest/{endpoint}.view?{}{sep}{extra_params}&f=json",
            self.base_url,
            self.auth_query()
        );

        let body = Self::agent()
            .get(&url)
            .call()
            .map_err(|e| MusiqError::Navidrome(e.to_string()))?
            .body_mut()
            .read_to_string()
            .map_err(|e| MusiqError::Navidrome(e.to_string()))?;
        let json: Value =
            serde_json::from_str(&body).map_err(|e| MusiqError::Navidrome(e.to_string()))?;

        let response = json["subsonic-response"].clone();
        Self::check_status(&response)?;
        Ok(response)
    }

    /// Subsonic servers return HTTP 200 even for auth failures, embedding
    /// the real error in the body — this is the only way to catch them.
    fn check_status(response: &Value) -> Result<(), MusiqError> {
        if response["status"].as_str() == Some("ok") {
            return Ok(());
        }
        let message = response["error"]["message"]
            .as_str()
            .unwrap_or("request failed")
            .to_string();
        Err(MusiqError::Navidrome(message))
    }

    pub fn test_connection(&self) -> Result<(), MusiqError> {
        self.get_json("ping", "")?;
        Ok(())
    }

    pub fn list_music_folders(&self) -> Result<Vec<NavidromeFolder>, MusiqError> {
        let response = self.get_json("getMusicFolders", "")?;
        Ok(Self::parse_folders(&response))
    }

    fn parse_folders(response: &Value) -> Vec<NavidromeFolder> {
        response["musicFolders"]["musicFolder"]
            .as_array()
            .cloned()
            .unwrap_or_default()
            .into_iter()
            .filter_map(|f| {
                Some(NavidromeFolder {
                    id: value_to_id_string(&f["id"])?,
                    name: f["name"].as_str().unwrap_or("Music").to_string(),
                })
            })
            .collect()
    }

    pub fn list_albums(&self, folder_id: &str) -> Result<Vec<NavidromeAlbum>, MusiqError> {
        let params = format!("type=alphabeticalByName&size=500&musicFolderId={folder_id}");
        let response = self.get_json("getAlbumList2", &params)?;
        Ok(Self::parse_albums(&response))
    }

    fn parse_albums(response: &Value) -> Vec<NavidromeAlbum> {
        response["albumList2"]["album"]
            .as_array()
            .cloned()
            .unwrap_or_default()
            .into_iter()
            .filter_map(|a| {
                Some(NavidromeAlbum {
                    id: value_to_id_string(&a["id"])?,
                    name: a["name"].as_str().unwrap_or("Untitled Album").to_string(),
                    artist: a["artist"].as_str().map(|s| s.to_string()),
                })
            })
            .collect()
    }

    pub fn list_songs(&self, album_id: &str) -> Result<Vec<NavidromeSong>, MusiqError> {
        let params = format!("id={album_id}");
        let response = self.get_json("getAlbum", &params)?;
        let items = response["album"]["song"].as_array().cloned().unwrap_or_default();
        Ok(items.into_iter().filter_map(|item| self.parse_song(&item)).collect())
    }

    fn parse_song(&self, item: &Value) -> Option<NavidromeSong> {
        let id = value_to_id_string(&item["id"])?;
        let title = item["title"].as_str().unwrap_or("Untitled").to_string();
        let artist = item["artist"].as_str().map(|s| s.to_string());
        let album = item["album"].as_str().map(|s| s.to_string());
        let duration_secs = item["duration"].as_u64().map(|s| s as u32);
        let stream_url = self.stream_url(&id);

        Some(NavidromeSong {
            id,
            title,
            artist,
            album,
            duration_secs,
            stream_url,
        })
    }

    /// `format=raw` disables server-side transcoding — we want the original
    /// file, decoded locally, not whatever the server would re-encode it to.
    fn stream_url(&self, song_id: &str) -> String {
        format!(
            "{}/rest/stream.view?{}&format=raw&id={song_id}",
            self.base_url,
            self.auth_query()
        )
    }
}

/// Subsonic IDs are usually strings, but some server implementations emit
/// bare JSON numbers — accept either rather than silently dropping items.
fn value_to_id_string(v: &Value) -> Option<String> {
    match v {
        Value::String(s) => Some(s.clone()),
        Value::Number(n) => Some(n.to_string()),
        _ => None,
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::json;

    fn ok_envelope(inner: Value) -> Value {
        let mut response = json!({ "status": "ok", "version": API_VERSION });
        for (key, value) in inner.as_object().unwrap() {
            response[key] = value.clone();
        }
        response
    }

    #[test]
    fn parses_music_folders() {
        let response = ok_envelope(json!({
            "musicFolders": {
                "musicFolder": [
                    { "id": "1", "name": "Music" },
                    { "id": 2, "name": "Podcasts" }
                ]
            }
        }));

        let folders = NavidromeClient::parse_folders(&response);
        assert_eq!(folders.len(), 2);
        assert_eq!(folders[0].id, "1");
        assert_eq!(folders[1].id, "2"); // numeric id coerced to string
        assert_eq!(folders[1].name, "Podcasts");
    }

    #[test]
    fn parses_albums() {
        let response = ok_envelope(json!({
            "albumList2": {
                "album": [
                    { "id": "al1", "name": "Back in Black", "artist": "AC/DC" }
                ]
            }
        }));

        let albums = NavidromeClient::parse_albums(&response);
        assert_eq!(albums.len(), 1);
        assert_eq!(albums[0].id, "al1");
        assert_eq!(albums[0].artist.as_deref(), Some("AC/DC"));
    }

    #[test]
    fn parses_songs_and_builds_stream_url_with_raw_format() {
        let client = NavidromeClient {
            base_url: "http://navidrome.local:4533".to_string(),
            username: "kent".to_string(),
            salt: "abc123".to_string(),
            token: "deadbeef".to_string(),
        };
        let item = json!({
            "id": "sg1",
            "title": "Song Title",
            "artist": "Artist Name",
            "album": "Album Name",
            "duration": 245
        });

        let song = client.parse_song(&item).unwrap();
        assert_eq!(song.title, "Song Title");
        assert_eq!(song.duration_secs, Some(245));
        assert!(song.stream_url.starts_with("http://navidrome.local:4533/rest/stream.view?"));
        assert!(song.stream_url.contains("format=raw"));
        assert!(song.stream_url.contains("id=sg1"));
        assert!(song.stream_url.contains("u=kent"));
        assert!(song.stream_url.contains("t=deadbeef"));
        assert!(song.stream_url.contains("s=abc123"));
    }

    #[test]
    fn treats_a_non_ok_status_as_an_error() {
        let response = json!({
            "status": "failed",
            "error": { "code": 40, "message": "Wrong username or password" }
        });

        let err = NavidromeClient::check_status(&response).unwrap_err();
        assert!(matches!(err, MusiqError::Navidrome(ref m) if m == "Wrong username or password"));
    }

    #[test]
    fn ok_status_passes() {
        let response = json!({ "status": "ok" });
        assert!(NavidromeClient::check_status(&response).is_ok());
    }
}
