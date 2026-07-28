#[derive(thiserror::Error, Debug)]
pub enum MusiqError {
    #[error("io error: {0}")]
    Io(#[from] std::io::Error),
    #[error("database error: {0}")]
    Db(#[from] rusqlite::Error),
    #[error("invalid path: {0}")]
    InvalidPath(String),
    #[error("playback error: {0}")]
    Playback(String),
    #[error("tag error: {0}")]
    Tag(String),
}
