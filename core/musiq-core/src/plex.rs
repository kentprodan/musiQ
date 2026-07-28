//! A minimal client for a self-hosted Plex Media Server's music library —
//! the "streaming client" half of musiQ, alongside the local library. Talks
//! directly to the Plex REST API (`X-Plex-Token` header auth, JSON via
//! `Accept: application/json` — Plex defaults to XML otherwise); there's no
//! official Rust SDK, so field access goes through `serde_json::Value`
//! rather than strict structs, so one unexpected field doesn't break parsing
//! of every other track.
//!
//! Playback is real streaming: `stream_url` is handed to `Player`, which
//! fetches it on demand via `crate::streaming::HttpStreamReader` rather than
//! downloading the whole file first.

use std::time::Duration;

use serde_json::Value;

use crate::error::MusiqError;

pub struct PlexLibrary {
    pub key: String,
    pub title: String,
}

pub struct PlexArtist {
    pub rating_key: String,
    pub name: String,
}

pub struct PlexAlbum {
    pub rating_key: String,
    pub name: String,
    pub artist: Option<String>,
    pub art_url: Option<String>,
}

pub struct PlexTrack {
    pub rating_key: String,
    pub title: String,
    pub artist: Option<String>,
    pub album: Option<String>,
    pub duration_secs: Option<u32>,
    pub stream_url: String,
}

pub struct PlexClient {
    base_url: String,
    token: String,
}

impl PlexClient {
    pub fn new(base_url: String, token: String) -> Self {
        Self {
            base_url: base_url.trim_end_matches('/').to_string(),
            token,
        }
    }

    fn agent() -> ureq::Agent {
        ureq::Agent::config_builder()
            .timeout_global(Some(Duration::from_secs(10)))
            .build()
            .into()
    }

    fn get_json(&self, path: &str) -> Result<Value, MusiqError> {
        let url = format!("{}{}", self.base_url, path);
        let body = Self::agent()
            .get(&url)
            .header("Accept", "application/json")
            .header("X-Plex-Token", &self.token)
            .call()
            .map_err(|e| MusiqError::Plex(e.to_string()))?
            .body_mut()
            .read_to_string()
            .map_err(|e| MusiqError::Plex(e.to_string()))?;
        serde_json::from_str(&body).map_err(|e| MusiqError::Plex(e.to_string()))
    }

    /// Verifies the server is reachable and the token is accepted.
    pub fn test_connection(&self) -> Result<(), MusiqError> {
        self.get_json("/identity")?;
        Ok(())
    }

    /// Lists music libraries (Plex calls them "sections"; music ones have
    /// `type: "artist"`).
    pub fn list_music_libraries(&self) -> Result<Vec<PlexLibrary>, MusiqError> {
        let json = self.get_json("/library/sections")?;
        Ok(Self::parse_libraries(&json))
    }

    fn parse_libraries(json: &Value) -> Vec<PlexLibrary> {
        json["MediaContainer"]["Directory"]
            .as_array()
            .cloned()
            .unwrap_or_default()
            .into_iter()
            .filter(|d| d["type"].as_str() == Some("artist"))
            .filter_map(|d| {
                Some(PlexLibrary {
                    key: d["key"].as_str()?.to_string(),
                    title: d["title"].as_str().unwrap_or("Music").to_string(),
                })
            })
            .collect()
    }

    /// Lists every artist in the music library `section_key` (`type=8` is
    /// Plex's numeric code for artists) — the top of the browse hierarchy,
    /// mirroring how Plex's own clients organize a music library rather than
    /// dumping every track in the library flat.
    pub fn list_artists(&self, section_key: &str) -> Result<Vec<PlexArtist>, MusiqError> {
        let path = format!("/library/sections/{section_key}/all?type=8");
        let json = self.get_json(&path)?;
        Ok(Self::items_of(&json)
            .into_iter()
            .filter_map(Self::parse_artist)
            .collect())
    }

    fn parse_artist(item: Value) -> Option<PlexArtist> {
        Some(PlexArtist {
            rating_key: item["ratingKey"].as_str()?.to_string(),
            name: item["title"].as_str().unwrap_or("Unknown Artist").to_string(),
        })
    }

    /// Lists the albums belonging to `artist_rating_key`. `/children` is
    /// Plex's generic "direct children of this item" endpoint — the same one
    /// `list_tracks` uses to list an album's tracks.
    pub fn list_albums(&self, artist_rating_key: &str) -> Result<Vec<PlexAlbum>, MusiqError> {
        let path = format!("/library/metadata/{artist_rating_key}/children");
        let json = self.get_json(&path)?;
        Ok(Self::items_of(&json)
            .into_iter()
            .filter_map(|item| self.parse_album(&item))
            .collect())
    }

    fn parse_album(&self, item: &Value) -> Option<PlexAlbum> {
        Some(PlexAlbum {
            rating_key: item["ratingKey"].as_str()?.to_string(),
            name: item["title"].as_str().unwrap_or("Untitled Album").to_string(),
            // The album's own parent is its artist, so (just like a track's
            // `parentTitle` is its album) an album's `parentTitle` is its artist.
            artist: item["parentTitle"].as_str().map(|s| s.to_string()),
            art_url: item["thumb"].as_str().map(|thumb| self.art_url(thumb)),
        })
    }

    /// Builds a full, authenticated URL for a `thumb`/cover-art relative
    /// path, the same auth pattern `parse_track` uses for stream URLs.
    fn art_url(&self, thumb_path: &str) -> String {
        format!("{}{}?X-Plex-Token={}", self.base_url, thumb_path, self.token)
    }

    /// Lists the tracks belonging to `album_rating_key` via the same
    /// `/children` endpoint used by `list_albums`.
    pub fn list_tracks(&self, album_rating_key: &str) -> Result<Vec<PlexTrack>, MusiqError> {
        let path = format!("/library/metadata/{album_rating_key}/children");
        let json = self.get_json(&path)?;
        Ok(Self::items_of(&json)
            .into_iter()
            .filter_map(|item| self.parse_track(&item))
            .collect())
    }

    fn items_of(json: &Value) -> Vec<Value> {
        json["MediaContainer"]["Metadata"].as_array().cloned().unwrap_or_default()
    }

    fn parse_track(&self, item: &Value) -> Option<PlexTrack> {
        let rating_key = item["ratingKey"].as_str()?.to_string();
        let title = item["title"].as_str().unwrap_or("Untitled").to_string();
        let artist = item["grandparentTitle"].as_str().map(|s| s.to_string());
        let album = item["parentTitle"].as_str().map(|s| s.to_string());
        let duration_secs = item["duration"].as_u64().map(|ms| (ms / 1000) as u32);

        let part_key = item["Media"]
            .as_array()?
            .first()?["Part"]
            .as_array()?
            .first()?["key"]
            .as_str()?;
        let stream_url = format!("{}{}?X-Plex-Token={}", self.base_url, part_key, self.token);

        Some(PlexTrack {
            rating_key,
            title,
            artist,
            album,
            duration_secs,
            stream_url,
        })
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::json;

    // Field names and nesting per the Plex REST API's documented shape
    // (MediaContainer > Metadata[] > Media[] > Part[]), since there's no
    // official schema to compile against and no live server in this
    // environment to verify against directly.
    fn sample_track_json() -> Value {
        json!({
            "ratingKey": "12345",
            "title": "Song Title",
            "grandparentTitle": "Artist Name",
            "parentTitle": "Album Name",
            "duration": 185000,
            "Media": [
                {
                    "Part": [
                        { "key": "/library/parts/46618/1389985872/file.mp3" }
                    ]
                }
            ]
        })
    }

    #[test]
    fn parses_a_well_formed_track() {
        let client = PlexClient::new("http://plex.local:32400".to_string(), "tok".to_string());
        let track = client.parse_track(&sample_track_json()).unwrap();

        assert_eq!(track.rating_key, "12345");
        assert_eq!(track.title, "Song Title");
        assert_eq!(track.artist.as_deref(), Some("Artist Name"));
        assert_eq!(track.album.as_deref(), Some("Album Name"));
        assert_eq!(track.duration_secs, Some(185));
        assert_eq!(
            track.stream_url,
            "http://plex.local:32400/library/parts/46618/1389985872/file.mp3?X-Plex-Token=tok"
        );
    }

    #[test]
    fn falls_back_when_artist_and_album_are_missing() {
        let client = PlexClient::new("http://plex.local:32400".to_string(), "tok".to_string());
        let mut item = sample_track_json();
        item.as_object_mut().unwrap().remove("grandparentTitle");
        item.as_object_mut().unwrap().remove("parentTitle");

        let track = client.parse_track(&item).unwrap();
        assert_eq!(track.artist, None);
        assert_eq!(track.album, None);
    }

    #[test]
    fn skips_a_track_with_no_playable_part() {
        let client = PlexClient::new("http://plex.local:32400".to_string(), "tok".to_string());
        let item = json!({ "ratingKey": "1", "title": "No Media" });

        assert!(client.parse_track(&item).is_none());
    }

    #[test]
    fn parses_an_artist() {
        let item = json!({ "ratingKey": "art1", "title": "AC/DC" });
        let artist = PlexClient::parse_artist(item).unwrap();
        assert_eq!(artist.rating_key, "art1");
        assert_eq!(artist.name, "AC/DC");
    }

    #[test]
    fn parses_an_album_with_its_artist_from_parent_title() {
        let client = PlexClient::new("http://plex.local:32400".to_string(), "tok".to_string());
        let item = json!({
            "ratingKey": "alb1",
            "title": "Back in Black",
            "parentTitle": "AC/DC",
            "thumb": "/library/metadata/alb1/thumb/162"
        });
        let album = client.parse_album(&item).unwrap();
        assert_eq!(album.rating_key, "alb1");
        assert_eq!(album.name, "Back in Black");
        assert_eq!(album.artist.as_deref(), Some("AC/DC"));
        assert_eq!(
            album.art_url.as_deref(),
            Some("http://plex.local:32400/library/metadata/alb1/thumb/162?X-Plex-Token=tok")
        );
    }

    #[test]
    fn only_music_sections_are_kept() {
        let container = json!({
            "MediaContainer": {
                "Directory": [
                    { "key": "1", "title": "Movies", "type": "movie" },
                    { "key": "2", "title": "Music", "type": "artist" },
                ]
            }
        });

        let libraries = PlexClient::parse_libraries(&container);

        assert_eq!(libraries.len(), 1);
        assert_eq!(libraries[0].key, "2");
        assert_eq!(libraries[0].title, "Music");
    }
}
