use crate::MetadataError;
use lofty::prelude::*;
use lofty::tag::Tag;
use serde::{Deserialize, Serialize};
use std::path::Path;

/// Normalized view over whatever tag format the source file actually uses.
/// All editors in the UI (single-track and batch) read/write this shape;
/// container-specific quirks are absorbed at the `read_tags`/`write_to`
/// boundary so the rest of the app never has to know about ID3 vs Vorbis.
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct TagSet {
    pub title: Option<String>,
    pub artist: Option<String>,
    pub album: Option<String>,
    pub album_artist: Option<String>,
    pub genre: Option<String>,
    pub year: Option<u32>,
    pub track_no: Option<u32>,
    pub track_total: Option<u32>,
    pub disc_no: Option<u32>,
    pub comment: Option<String>,
    pub replaygain_track_db: Option<f64>,
    pub replaygain_album_db: Option<f64>,
    pub duration_ms: u64,
    pub bitrate_kbps: Option<u32>,
    pub sample_rate_hz: Option<u32>,
    pub has_cover_art: bool,
}

impl TagSet {
    pub fn from_lofty(tag: Option<&Tag>, properties: &lofty::properties::FileProperties) -> Self {
        let mut set = TagSet {
            duration_ms: properties.duration().as_millis() as u64,
            bitrate_kbps: properties.audio_bitrate(),
            sample_rate_hz: properties.sample_rate(),
            ..Default::default()
        };

        if let Some(tag) = tag {
            set.title = tag.title().map(|s| s.to_string());
            set.artist = tag.artist().map(|s| s.to_string());
            set.album = tag.album().map(|s| s.to_string());
            set.genre = tag.genre().map(|s| s.to_string());
            set.year = tag.year();
            set.track_no = tag.track();
            set.track_total = tag.track_total();
            set.disc_no = tag.disk();
            set.comment = tag.comment().map(|s| s.to_string());
            set.has_cover_art = !tag.pictures().is_empty();
        }

        set
    }

    pub fn write_to(&self, _path: &Path) -> Result<(), MetadataError> {
        // Opens the file's existing tag (or creates the primary tag type for
        // the container), writes normalized fields back, and saves in place.
        // Left as a stub in this scaffold — the shape of the boundary is
        // what matters here, not the lofty call sequence.
        Ok(())
    }
}
