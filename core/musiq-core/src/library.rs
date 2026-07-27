use musiq_audio_engine::AudioEngine;
use musiq_db::Repository;
use musiq_plugins::PluginManager;
use sqlx::SqlitePool;
use std::path::Path;

/// The one object every frontend holds: local library state, the audio
/// engine, and the plugin host. `Library::open_blocking` exists alongside
/// the async `open` because UniFFI's generated Swift/Kotlin constructors
/// are synchronous — Tauri's async commands should prefer `open` directly.
pub struct Library {
    pub repo: Repository,
    pub engine: AudioEngine,
    pub plugins: PluginManager,
}

impl Library {
    pub async fn open(db_path: &Path, plugins_dir: &Path) -> Result<Self, crate::CoreError> {
        let pool: SqlitePool = musiq_db::connect(db_path).await?;
        Ok(Self {
            repo: Repository::new(pool),
            engine: AudioEngine::new(),
            plugins: PluginManager::new(plugins_dir),
        })
    }

    pub fn open_blocking(db_path: &str) -> Self {
        let rt = tokio::runtime::Runtime::new().expect("tokio runtime");
        rt.block_on(Self::open(Path::new(db_path), Path::new("plugins")))
            .expect("failed to open library")
    }
}
