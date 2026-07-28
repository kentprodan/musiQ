//! Tag *writing* — the counterpart to `scan.rs`'s read-only pass. Writes go
//! to the audio file itself via `lofty`, then the DB row is updated to match
//! whatever ended up on disk (rather than trusting the caller's input),
//! keeping the library table an accurate mirror of file state.

use crate::error::MusiqError;
use lofty::config::WriteOptions;
use lofty::file::TaggedFileExt;
use lofty::probe::Probe;
use lofty::tag::{Accessor, Tag, TagExt};
use rusqlite::{params, Connection};
use std::path::Path;

/// `Some(value)` sets that field (an empty string clears it); `None` leaves
/// it untouched.
pub struct TagUpdate {
    pub title: Option<String>,
    pub artist: Option<String>,
    pub album: Option<String>,
}

pub fn update_track_tags(
    conn: &Connection,
    track_id: &str,
    path: &Path,
    update: &TagUpdate,
) -> Result<(), MusiqError> {
    let mut tagged_file = Probe::open(path)
        .and_then(|probe| probe.read())
        .map_err(|e| MusiqError::Tag(e.to_string()))?;

    let primary_type = tagged_file.primary_tag_type();
    if tagged_file.primary_tag_mut().is_none() {
        tagged_file.insert_tag(Tag::new(primary_type));
    }
    let tag = tagged_file
        .primary_tag_mut()
        .expect("a primary tag was just inserted if one was missing");

    if let Some(title) = &update.title {
        if title.is_empty() {
            tag.remove_title();
        } else {
            tag.set_title(title.clone());
        }
    }
    if let Some(artist) = &update.artist {
        if artist.is_empty() {
            tag.remove_artist();
        } else {
            tag.set_artist(artist.clone());
        }
    }
    if let Some(album) = &update.album {
        if album.is_empty() {
            tag.remove_album();
        } else {
            tag.set_album(album.clone());
        }
    }

    tag.save_to_path(path, WriteOptions::default())
        .map_err(|e| MusiqError::Tag(e.to_string()))?;

    // Read the final values back from the tag we just saved, rather than
    // from `update`, so the DB reflects the file's actual state even for
    // fields this call didn't touch.
    let final_title = tag.title().map(|s| s.into_owned());
    let final_artist = tag.artist().map(|s| s.into_owned());
    let final_album = tag.album().map(|s| s.into_owned());

    conn.execute(
        "UPDATE tracks SET title = ?1, artist = ?2, album = ?3 WHERE id = ?4",
        params![final_title, final_artist, final_album, track_id],
    )?;

    Ok(())
}
