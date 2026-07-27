use serde::{Deserialize, Serialize};

/// Which `TagSet` field a batch operation targets.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum BatchField {
    Title,
    Artist,
    Album,
    AlbumArtist,
    Genre,
    Year,
    TrackNo,
    DiscNo,
    Comment,
}

/// A tokenized "tag from filename" / "filename from tag" pattern, e.g.
/// `%track% - %artist% - %title%`, mirroring the pattern language Mp3Tag
/// and MusicBee users already know.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FilenamePattern(pub String);

/// A queued batch edit: apply `field` = `value` (literal or pattern-derived)
/// across every track id in `track_ids`. The executor lives in musiq-core,
/// which resolves track ids to file paths and calls `write_tags` for each.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BatchEditPlan {
    pub track_ids: Vec<uuid::Uuid>,
    pub field: BatchField,
    pub value: String,
}
