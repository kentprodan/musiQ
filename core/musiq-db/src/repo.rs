use crate::{DbError, Track};
use sqlx::SqlitePool;
use uuid::Uuid;

/// Thin query layer over the pool. Kept deliberately small here — the goal
/// of this scaffold is to fix the shape of the boundary, not to implement
/// every query musiQ will eventually need.
pub struct Repository {
    pool: SqlitePool,
}

impl Repository {
    pub fn new(pool: SqlitePool) -> Self {
        Self { pool }
    }

    pub async fn get_track(&self, id: Uuid) -> Result<Option<Track>, DbError> {
        let track = sqlx::query_as::<_, Track>("SELECT * FROM tracks WHERE id = ?")
            .bind(id)
            .fetch_optional(&self.pool)
            .await?;
        Ok(track)
    }

    pub async fn list_tracks_by_album(&self, album_id: Uuid) -> Result<Vec<Track>, DbError> {
        let tracks = sqlx::query_as::<_, Track>(
            "SELECT * FROM tracks WHERE album_id = ? ORDER BY disc_no, track_no",
        )
        .bind(album_id)
        .fetch_all(&self.pool)
        .await?;
        Ok(tracks)
    }
}
