use crate::error::MusiqError;
use lofty::file::{AudioFile, TaggedFileExt};
use lofty::probe::Probe;
use lofty::tag::Accessor;
use rusqlite::{params, Connection};
use std::path::Path;
use walkdir::WalkDir;

const AUDIO_EXTENSIONS: &[&str] = &["mp3", "flac", "m4a", "ogg", "opus", "wav"];

/// Walks `folder` recursively, reads tags from every recognized audio file,
/// and upserts each one into `tracks` keyed by its (unique) path.
/// Files that fail to parse are skipped rather than aborting the whole scan,
/// since a single corrupt/DRM'd file shouldn't block scanning the rest of a library.
pub fn scan_folder(conn: &Connection, folder: &Path) -> Result<u32, MusiqError> {
    if !folder.is_dir() {
        return Err(MusiqError::InvalidPath(folder.display().to_string()));
    }

    let mut count = 0u32;
    for entry in WalkDir::new(folder)
        .into_iter()
        .filter_map(|entry| entry.ok())
    {
        if !entry.file_type().is_file() {
            continue;
        }
        let path = entry.path();
        let Some(ext) = path.extension().and_then(|e| e.to_str()) else {
            continue;
        };
        if !AUDIO_EXTENSIONS.contains(&ext.to_ascii_lowercase().as_str()) {
            continue;
        }

        let Ok(tagged_file) = Probe::open(path).and_then(|p| p.read()) else {
            continue;
        };

        let tag = tagged_file.primary_tag().or_else(|| tagged_file.first_tag());
        let title = tag.and_then(|t| t.title()).map(|s| s.into_owned());
        let artist = tag.and_then(|t| t.artist()).map(|s| s.into_owned());
        let album = tag.and_then(|t| t.album()).map(|s| s.into_owned());
        let year = tag.and_then(|t| t.date()).map(|d| u32::from(d.year));
        let genre = tag.and_then(|t| t.genre()).map(|s| s.into_owned());
        let duration_secs = tagged_file.properties().duration().as_secs() as u32;

        let id = uuid::Uuid::new_v4().to_string();
        let added_at = time::OffsetDateTime::now_utc()
            .format(&time::format_description::well_known::Rfc3339)
            .unwrap_or_default();
        let path_str = path.to_string_lossy().into_owned();

        conn.execute(
            "INSERT INTO tracks (id, path, title, artist, album, duration_secs, year, genre, added_at)
             VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9)
             ON CONFLICT(path) DO UPDATE SET
                title = excluded.title,
                artist = excluded.artist,
                album = excluded.album,
                duration_secs = excluded.duration_secs,
                year = excluded.year,
                genre = excluded.genre",
            params![id, path_str, title, artist, album, duration_secs, year, genre, added_at],
        )?;
        count += 1;
    }

    Ok(count)
}

/// Records `folder` as a known scan root (idempotent — re-scanning the same
/// folder doesn't create a duplicate entry), so the Sources page can show
/// exactly what the user chose to scan rather than an approximation.
pub fn record_scan_root(conn: &Connection, folder: &Path) -> Result<(), MusiqError> {
    let id = uuid::Uuid::new_v4().to_string();
    let path_str = folder.to_string_lossy().into_owned();
    let added_at = time::OffsetDateTime::now_utc()
        .format(&time::format_description::well_known::Rfc3339)
        .unwrap_or_default();

    conn.execute(
        "INSERT INTO scan_roots (id, path, added_at) VALUES (?1, ?2, ?3)
         ON CONFLICT(path) DO NOTHING",
        params![id, path_str, added_at],
    )?;
    Ok(())
}
