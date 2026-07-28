//! A minimal client for a self-hosted Plex Media Server's music library —
//! the "streaming client" half of musiQ, alongside the local library. Talks
//! directly to the Plex REST API (`X-Plex-Token` header auth, JSON via
//! `Accept: application/json` — Plex defaults to XML otherwise); there's no
//! official Rust SDK, so field access goes through `serde_json::Value`
//! rather than strict structs, so one unexpected field doesn't break parsing
//! of every other track.
//!
//! Playback works by downloading a track to a local temp file and handing
//! that to the same `Player` used for local files — there's no true
//! streaming (progressive download / range requests) yet, so playback
//! starts only once the whole file has downloaded. Good enough for a first
//! pass; real streaming is future work.

use std::path::{Path, PathBuf};
use std::time::Duration;

use serde_json::Value;

use crate::error::MusiqError;

pub struct PlexLibrary {
    pub key: String,
    pub title: String,
}

pub struct PlexTrack {
    pub rating_key: String,
    pub title: String,
    pub artist: Option<String>,
    pub album: Option<String>,
    pub duration_secs: Option<u32>,
    pub stream_url: String,
    /// File extension inferred from the Part's server-relative path (e.g.
    /// "mp3"), so downloaded temp files keep a real extension.
    pub file_extension: String,
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

    /// Lists every track in the music library `section_key` (flat, no
    /// artist/album grouping — `type=10` is Plex's numeric code for tracks).
    pub fn list_tracks(&self, section_key: &str) -> Result<Vec<PlexTrack>, MusiqError> {
        let path = format!("/library/sections/{section_key}/all?type=10");
        let json = self.get_json(&path)?;
        let items = json["MediaContainer"]["Metadata"]
            .as_array()
            .cloned()
            .unwrap_or_default();

        Ok(items.into_iter().filter_map(|item| self.parse_track(&item)).collect())
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
        let file_extension = Path::new(part_key)
            .extension()
            .and_then(|e| e.to_str())
            .unwrap_or("audio")
            .to_string();
        let stream_url = format!("{}{}?X-Plex-Token={}", self.base_url, part_key, self.token);

        Some(PlexTrack {
            rating_key,
            title,
            artist,
            album,
            duration_secs,
            stream_url,
            file_extension,
        })
    }

    /// Downloads `track` into `dest_dir` (named after its rating key, so
    /// repeat plays reuse the same file instead of re-downloading) and
    /// returns the local path. Playback only starts once this completes —
    /// there's no progressive streaming yet.
    pub fn download_track(&self, track: &PlexTrack, dest_dir: &Path) -> Result<PathBuf, MusiqError> {
        std::fs::create_dir_all(dest_dir)?;
        let dest = dest_dir.join(format!("{}.{}", track.rating_key, track.file_extension));
        if dest.exists() {
            return Ok(dest);
        }

        let mut response = Self::agent()
            .get(&track.stream_url)
            .call()
            .map_err(|e| MusiqError::Plex(e.to_string()))?;
        let mut reader = response.body_mut().as_reader();
        let mut file = std::fs::File::create(&dest)?;
        std::io::copy(&mut reader, &mut file)?;

        Ok(dest)
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
        assert_eq!(track.file_extension, "mp3");
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
