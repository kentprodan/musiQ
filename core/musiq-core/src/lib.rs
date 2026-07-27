//! musiq-core: composition root. Wires `musiq-db` (persistence),
//! `musiq-metadata` (tag read/write), `musiq-audio-engine` (playback +
//! waveform), `musiq-net` (Plex/Subsonic remote libraries), and
//! `musiq-plugins` (sandboxed community plugins) into the one `Library`
//! type every frontend holds a handle to — Tauri commands call it
//! in-process, `musiq-ffi` wraps it for Swift/Kotlin.

pub mod library;
pub mod scan;

pub use library::Library;

#[derive(thiserror::Error, Debug)]
pub enum CoreError {
    #[error("db error: {0}")]
    Db(#[from] musiq_db::DbError),
    #[error("engine error: {0}")]
    Engine(#[from] musiq_audio_engine::EngineError),
}
