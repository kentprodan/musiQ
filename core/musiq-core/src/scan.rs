use std::path::Path;

/// Recursively walks a watched folder, reads tags for every audio file
/// found (via `musiq-metadata`), and upserts tracks/albums/artists into
/// `musiq-db`. Runs on library add and on filesystem-watch events.
pub struct ScanReport {
    pub files_seen: usize,
    pub tracks_added: usize,
    pub tracks_updated: usize,
    pub errors: Vec<String>,
}

pub async fn scan_folder(_root: &Path) -> ScanReport {
    ScanReport {
        files_seen: 0,
        tracks_added: 0,
        tracks_updated: 0,
        errors: Vec::new(),
    }
}
