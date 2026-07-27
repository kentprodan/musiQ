//! musiq-db: SQLite persistence layer for the musiQ library.
//!
//! Owns the schema for tracks, albums, artists, genres, playlists (manual + smart),
//! watched folders, and remote source bindings (Plex / Subsonic / Navidrome libraries
//! mirrored locally as read-through caches).

mod models;
mod repo;

pub use models::*;
pub use repo::Repository;

use sqlx::sqlite::{SqliteConnectOptions, SqlitePoolOptions};
use sqlx::SqlitePool;
use std::path::Path;
use std::str::FromStr;

#[derive(thiserror::Error, Debug)]
pub enum DbError {
    #[error("sqlx error: {0}")]
    Sqlx(#[from] sqlx::Error),
    #[error("migration error: {0}")]
    Migrate(#[from] sqlx::migrate::MigrateError),
}

pub async fn connect(db_path: &Path) -> Result<SqlitePool, DbError> {
    let uri = format!("sqlite://{}", db_path.display());
    let options = SqliteConnectOptions::from_str(&uri)?
        .create_if_missing(true)
        .foreign_keys(true)
        .journal_mode(sqlx::sqlite::SqliteJournalMode::Wal);

    let pool = SqlitePoolOptions::new()
        .max_connections(8)
        .connect_with(options)
        .await?;

    sqlx::migrate!("./src/migrations").run(&pool).await?;
    Ok(pool)
}
