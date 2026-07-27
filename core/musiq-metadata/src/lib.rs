//! musiq-metadata: reads and writes audio tags (ID3v2, Vorbis Comments,
//! MP4 atoms, APEv2, ...) via `lofty`, and normalizes them into musiQ's
//! internal `TagSet`. This is the crate that gives musiQ its MusicBee/Mp3Tag
//! grade tag-editing capability (batch edit, tag-from-filename, cover art
//! embed/extract, ReplayGain read/write).

mod tagset;
mod batch;

pub use tagset::TagSet;
pub use batch::{BatchEditPlan, BatchField, FilenamePattern};

use lofty::error::LoftyError;
use std::path::Path;

#[derive(thiserror::Error, Debug)]
pub enum MetadataError {
    #[error("lofty error: {0}")]
    Lofty(#[from] LoftyError),
    #[error("unsupported container for file: {0}")]
    UnsupportedContainer(String),
}

pub fn read_tags(path: &Path) -> Result<TagSet, MetadataError> {
    use lofty::probe::Probe;
    use lofty::file::{AudioFile, TaggedFileExt};

    let tagged_file = Probe::open(path)?.read()?;
    let tag = tagged_file.primary_tag().or_else(|| tagged_file.first_tag());
    Ok(TagSet::from_lofty(tag, tagged_file.properties()))
}

pub fn write_tags(path: &Path, tags: &TagSet) -> Result<(), MetadataError> {
    tags.write_to(path)
}
