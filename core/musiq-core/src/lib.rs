//! musiq-core: the one place library-management business logic lives —
//! SQLite persistence, folder scanning, and tag reading. `ffi/musiq-uniffi`
//! wraps this crate's public API for every native client (Swift/Kotlin/C#);
//! this crate itself has no FFI-specific code in it.

mod art;
mod db;
mod error;
mod navidrome;
mod player;
mod plex;
mod rename;
mod scan;
mod streaming;
mod tags;

pub use error::MusiqError;
pub use navidrome::{NavidromeAlbum, NavidromeArtist, NavidromeClient, NavidromeFolder, NavidromeSong};
pub use player::{Player, RepeatMode};
pub use plex::{PlexAlbum, PlexArtist, PlexClient, PlexLibrary, PlexTrack};

use rusqlite::Connection;
use std::path::{Path, PathBuf};

#[derive(Debug, Clone, PartialEq)]
pub struct Track {
    pub id: String,
    pub path: String,
    pub title: Option<String>,
    pub artist: Option<String>,
    pub album: Option<String>,
    pub duration_secs: Option<u32>,
}

pub struct Library {
    conn: Connection,
    art_cache_dir: PathBuf,
}

impl Library {
    /// Opens (creating if absent) the SQLite database at `db_path` and ensures
    /// its schema exists. Extracted album art is cached in an `art-cache`
    /// folder next to the database file.
    pub fn open(db_path: &Path) -> Result<Self, MusiqError> {
        let conn = db::open_connection(db_path)?;
        let art_cache_dir = db_path
            .parent()
            .map(|p| p.join("art-cache"))
            .unwrap_or_else(|| PathBuf::from("art-cache"));
        Ok(Self { conn, art_cache_dir })
    }

    /// Recursively scans `folder` for audio files, reads their tags, and
    /// upserts each one into the library. Returns the number of tracks
    /// scanned (inserted or updated).
    pub fn scan_folder(&self, folder: &Path) -> Result<u32, MusiqError> {
        let count = scan::scan_folder(&self.conn, folder)?;
        scan::record_scan_root(&self.conn, folder)?;
        Ok(count)
    }

    /// Lists every track currently in the library, ordered by artist then album then title.
    pub fn list_tracks(&self) -> Result<Vec<Track>, MusiqError> {
        let mut stmt = self.conn.prepare(
            "SELECT id, path, title, artist, album, duration_secs
             FROM tracks
             ORDER BY artist, album, title",
        )?;
        let rows = stmt.query_map([], |row| {
            Ok(Track {
                id: row.get(0)?,
                path: row.get(1)?,
                title: row.get(2)?,
                artist: row.get(3)?,
                album: row.get(4)?,
                duration_secs: row.get::<_, Option<u32>>(5)?,
            })
        })?;

        let mut tracks = Vec::new();
        for row in rows {
            tracks.push(row?);
        }
        Ok(tracks)
    }

    /// Returns a file path to `track_id`'s embedded cover art, extracting and
    /// caching it on first request. `Ok(None)` means the track has no
    /// embedded picture (not that it doesn't exist — an invalid `track_id`
    /// surfaces as an error from the underlying row lookup).
    pub fn track_art_path(&self, track_id: &str) -> Result<Option<String>, MusiqError> {
        let path: String = self.conn.query_row(
            "SELECT path FROM tracks WHERE id = ?1",
            [track_id],
            |row| row.get(0),
        )?;
        art::track_art_path(&self.art_cache_dir, track_id, Path::new(&path))
    }

    /// Writes `title`/`artist`/`album` (each `Some` value sets that field —
    /// an empty string clears it, `None` leaves it untouched) to every track
    /// in `track_ids`, both on disk and in the library database. Returns the
    /// number of tracks updated.
    pub fn update_tags(
        &self,
        track_ids: &[String],
        title: Option<String>,
        artist: Option<String>,
        album: Option<String>,
    ) -> Result<u32, MusiqError> {
        let update = tags::TagUpdate {
            title,
            artist,
            album,
        };
        let mut count = 0u32;
        for track_id in track_ids {
            let path: String = self.conn.query_row(
                "SELECT path FROM tracks WHERE id = ?1",
                [track_id],
                |row| row.get(0),
            )?;
            tags::update_track_tags(&self.conn, track_id, Path::new(&path), &update)?;
            count += 1;
        }
        Ok(count)
    }

    /// Moves each track in `track_ids` to `base_folder` joined with `pattern`
    /// (tag placeholders `{title}`/`{artist}`/`{album}` substituted, e.g.
    /// `"{artist}/{album}/{title}"`), preserving its original extension.
    /// Missing tags fall back the same way the UI displays them (filename
    /// for title, "Unknown Artist"/"Unknown Album"). Refuses to overwrite an
    /// existing file at the destination. Returns the number of tracks moved.
    pub fn rename_tracks(
        &self,
        track_ids: &[String],
        base_folder: &Path,
        pattern: &str,
    ) -> Result<u32, MusiqError> {
        let mut count = 0u32;
        for track_id in track_ids {
            let (path, title, artist, album): (
                String,
                Option<String>,
                Option<String>,
                Option<String>,
            ) = self.conn.query_row(
                "SELECT path, title, artist, album FROM tracks WHERE id = ?1",
                [track_id],
                |row| Ok((row.get(0)?, row.get(1)?, row.get(2)?, row.get(3)?)),
            )?;

            let old_path = PathBuf::from(&path);
            let ext = old_path.extension().and_then(|e| e.to_str()).unwrap_or("");

            let title_value = title.filter(|s| !s.is_empty()).unwrap_or_else(|| {
                old_path
                    .file_stem()
                    .map(|s| s.to_string_lossy().into_owned())
                    .unwrap_or_default()
            });
            let artist_value = artist
                .filter(|s| !s.is_empty())
                .unwrap_or_else(|| "Unknown Artist".to_string());
            let album_value = album
                .filter(|s| !s.is_empty())
                .unwrap_or_else(|| "Unknown Album".to_string());

            let relative = rename::apply_pattern(pattern, &title_value, &artist_value, &album_value);
            let mut new_path = base_folder.to_path_buf();
            for component in relative.split(['/', '\\']) {
                if !component.is_empty() {
                    new_path.push(component);
                }
            }
            new_path.set_extension(ext);

            if new_path == old_path {
                count += 1;
                continue;
            }
            if new_path.exists() {
                return Err(MusiqError::Rename(format!(
                    "target already exists: {}",
                    new_path.display()
                )));
            }
            if let Some(parent) = new_path.parent() {
                std::fs::create_dir_all(parent)?;
            }
            std::fs::rename(&old_path, &new_path)?;

            self.conn.execute(
                "UPDATE tracks SET path = ?1 WHERE id = ?2",
                rusqlite::params![new_path.to_string_lossy(), track_id],
            )?;
            count += 1;
        }
        Ok(count)
    }

    /// Lists every folder that has been passed to `scan_folder`, in the order
    /// it was first scanned.
    pub fn list_scan_roots(&self) -> Result<Vec<String>, MusiqError> {
        let mut stmt = self
            .conn
            .prepare("SELECT path FROM scan_roots ORDER BY added_at")?;
        let rows = stmt.query_map([], |row| row.get::<_, String>(0))?;

        let mut roots = Vec::new();
        for row in rows {
            roots.push(row?);
        }
        Ok(roots)
    }

    /// Forgets `folder` as a scan root and deletes every track whose path
    /// falls under it. Filtering in Rust (rather than a SQL `LIKE` prefix
    /// match) sidesteps having to escape `%`/`_`/`\` wildcard characters
    /// that can legitimately appear in a real file path.
    pub fn remove_scan_root(&self, folder: &str) -> Result<u32, MusiqError> {
        let prefix = if folder.ends_with(std::path::MAIN_SEPARATOR) {
            folder.to_string()
        } else {
            format!("{folder}{}", std::path::MAIN_SEPARATOR)
        };

        let mut stmt = self.conn.prepare("SELECT id, path FROM tracks")?;
        let rows = stmt.query_map([], |row| Ok((row.get::<_, String>(0)?, row.get::<_, String>(1)?)))?;
        let mut ids_to_remove = Vec::new();
        for row in rows {
            let (id, path) = row?;
            if path == folder || path.starts_with(&prefix) {
                ids_to_remove.push(id);
            }
        }
        drop(stmt);

        for id in &ids_to_remove {
            self.conn.execute("DELETE FROM tracks WHERE id = ?1", rusqlite::params![id])?;
        }
        self.conn
            .execute("DELETE FROM scan_roots WHERE path = ?1", rusqlite::params![folder])?;

        Ok(ids_to_remove.len() as u32)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn open_creates_schema_and_starts_empty() {
        let dir = tempfile::tempdir().unwrap();
        let db_path = dir.path().join("library.sqlite3");

        let library = Library::open(&db_path).unwrap();
        let tracks = library.list_tracks().unwrap();

        assert!(tracks.is_empty());
        assert!(db_path.exists());
    }

    #[test]
    fn scan_folder_rejects_non_directory() {
        let dir = tempfile::tempdir().unwrap();
        let db_path = dir.path().join("library.sqlite3");
        let library = Library::open(&db_path).unwrap();

        let not_a_dir = dir.path().join("does-not-exist");
        let result = library.scan_folder(&not_a_dir);

        assert!(matches!(result, Err(MusiqError::InvalidPath(_))));
    }

    #[test]
    fn scan_folder_finds_no_tracks_in_empty_folder() {
        let dir = tempfile::tempdir().unwrap();
        let db_path = dir.path().join("library.sqlite3");
        let library = Library::open(&db_path).unwrap();

        let empty_music_dir = dir.path().join("music");
        std::fs::create_dir(&empty_music_dir).unwrap();

        let count = library.scan_folder(&empty_music_dir).unwrap();
        assert_eq!(count, 0);
        assert!(library.list_tracks().unwrap().is_empty());
    }

    #[test]
    fn scan_folder_records_root_once_even_if_rescanned() {
        let dir = tempfile::tempdir().unwrap();
        let db_path = dir.path().join("library.sqlite3");
        let library = Library::open(&db_path).unwrap();

        let music_dir = dir.path().join("music");
        std::fs::create_dir(&music_dir).unwrap();

        library.scan_folder(&music_dir).unwrap();
        library.scan_folder(&music_dir).unwrap();

        let roots = library.list_scan_roots().unwrap();
        assert_eq!(roots, vec![music_dir.to_string_lossy().into_owned()]);
    }

    #[test]
    fn remove_scan_root_forgets_root_and_its_tracks_only() {
        let dir = tempfile::tempdir().unwrap();
        let db_path = dir.path().join("library.sqlite3");
        let library = Library::open(&db_path).unwrap();

        let removed_dir = dir.path().join("removed");
        let kept_dir = dir.path().join("kept");
        std::fs::create_dir(&removed_dir).unwrap();
        std::fs::create_dir(&kept_dir).unwrap();
        library.scan_folder(&removed_dir).unwrap();
        library.scan_folder(&kept_dir).unwrap();

        library
            .remove_scan_root(&removed_dir.to_string_lossy())
            .unwrap();

        let roots = library.list_scan_roots().unwrap();
        assert_eq!(roots, vec![kept_dir.to_string_lossy().into_owned()]);
    }
}
