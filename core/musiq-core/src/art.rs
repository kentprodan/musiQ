//! Embedded album-art extraction for local files, via `lofty`'s picture
//! support. Extracted bytes are cached to disk once per track (rather than
//! re-probed on every UI refresh) since WinUI's `Image.Source` binds to a
//! file path/URL, not raw bytes.

use crate::error::MusiqError;
use lofty::file::TaggedFileExt;
use lofty::picture::MimeType;
use lofty::probe::Probe;
use std::path::Path;

/// Returns a cached file path to `track_id`'s embedded cover art, extracting
/// and caching it into `cache_dir` first if this is the first request for it.
/// `Ok(None)` means the file has a readable tag but no embedded picture.
pub fn track_art_path(
    cache_dir: &Path,
    track_id: &str,
    audio_path: &Path,
) -> Result<Option<String>, MusiqError> {
    std::fs::create_dir_all(cache_dir)?;

    for ext in ["jpg", "png", "bmp", "gif", "tiff"] {
        let cached = cache_dir.join(format!("{track_id}.{ext}"));
        if cached.exists() {
            return Ok(Some(cached.to_string_lossy().into_owned()));
        }
    }

    let tagged_file = Probe::open(audio_path)
        .and_then(|probe| probe.read())
        .map_err(|e| MusiqError::Tag(e.to_string()))?;

    let Some(tag) = tagged_file.primary_tag() else {
        return Ok(None);
    };
    let Some(picture) = tag.pictures().first() else {
        return Ok(None);
    };

    let ext = match picture.mime_type() {
        Some(MimeType::Png) => "png",
        Some(MimeType::Bmp) => "bmp",
        Some(MimeType::Gif) => "gif",
        Some(MimeType::Tiff) => "tiff",
        // Jpeg and anything unrecognized both decode fine as .jpg for display purposes.
        _ => "jpg",
    };

    let cached = cache_dir.join(format!("{track_id}.{ext}"));
    std::fs::write(&cached, picture.data())?;

    Ok(Some(cached.to_string_lossy().into_owned()))
}
