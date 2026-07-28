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

    // Added after the original schema — existing databases need these two
    // columns added on top rather than created fresh, since `CREATE TABLE IF
    // NOT EXISTS` above is a no-op once the table already exists.
    add_column_if_missing(&conn, "tracks", "year", "INTEGER")?;
    add_column_if_missing(&conn, "tracks", "genre", "TEXT")?;

    Ok(conn)
}

fn add_column_if_missing(
    conn: &Connection,
    table: &str,
    column: &str,
    sql_type: &str,
) -> Result<(), MusiqError> {
    let already_exists: bool = conn
        .prepare(&format!("SELECT {column} FROM {table} LIMIT 0"))
        .is_ok();
    if !already_exists {
        conn.execute(&format!("ALTER TABLE {table} ADD COLUMN {column} {sql_type}"), [])?;
    }
    Ok(())
}
