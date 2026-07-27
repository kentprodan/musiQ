use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum PluginKind {
    /// A `.wasm` module, sandboxed by `musiq-plugins::manager`.
    Wasm,
    /// A first-party plugin shipped as a native Rust crate and statically
    /// linked at build time (no sandboxing needed — reviewed like any
    /// other core crate). Reserved for musiQ's own bundled integrations.
    Native,
}

/// One entry in a plugin's requested-capabilities list. The install-time
/// consent dialog in `PluginsPanel.tsx` renders this list verbatim so the
/// user approves (or rejects) the exact host functions the plugin gets
/// linked against — nothing is available by default.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(tag = "type", rename_all = "snake_case")]
pub enum PluginCapability {
    /// Outbound HTTP restricted to this allowlist of hosts.
    Network { allowed_hosts: Vec<String> },
    /// Write access scoped to musiQ's managed downloads directory only —
    /// never an arbitrary filesystem path.
    DownloadsWrite,
    /// Read-only access to library metadata (tracks/albums/artists).
    LibraryRead,
    /// Ability to move/rename files inside folders musiQ already manages
    /// and to propose tag edits (still subject to normal undo history).
    LibraryReorganize,
    /// Read the currently playing track / queue state (for Discord-rich-
    /// presence-style companion plugins).
    NowPlayingRead,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PluginManifest {
    pub id: String,
    pub name: String,
    pub version: String,
    pub author: String,
    pub description: String,
    pub kind: PluginKind,
    /// Relative path to the `.wasm` entry point, resolved against the
    /// plugin's install directory. Ignored for `PluginKind::Native`.
    pub entry_wasm: Option<String>,
    pub capabilities: Vec<PluginCapability>,
    /// Lifecycle hooks this plugin implements, e.g. `on_track_added`,
    /// `on_library_scan_complete`, `on_settings_panel_render`.
    pub hooks: Vec<String>,
}
