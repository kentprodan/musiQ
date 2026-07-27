use crate::error::MusiqError;
use rusqlite::Connection;
use std::path::Path;

pub fn open_connection(db_path: &Path) -> Result<Connection, MusiqError> {
    let conn = Connection::open(db_path)?;
    conn.execute_batch(
        "CREATE TABLE IF NOT EXISTS tracks (
            id            TEXT PRIMARY KEY,
            path          TEXT NOT NULL UNIQUE,
            title         TEXT,
            artist        TEXT,
            album         TEXT,
            duration_secs INTEGER,
            added_at      TEXT NOT NULL
        );
        CREATE TABLE IF NOT EXISTS scan_roots (
            id       TEXT PRIMARY KEY,
            path     TEXT NOT NULL UNIQUE,
            added_at TEXT NOT NULL
        );",
    )?;
    Ok(conn)
}
