//! musiq-plugins: sandboxed community plugin runtime.
//!
//! Plugins are WASM modules (compiled from Rust, AssemblyScript, or plain
//! JS via a JS-in-WASM engine) that run inside a `wasmtime` store with no
//! ambient authority — every capability (network, filesystem, database
//! read) is a host function the plugin must declare in its manifest and
//! that the user approves at install time, mirroring `wasmtime-wasi`'s
//! capability model rather than exposing raw WASI.
//!
//! Two reference plugins define the category shapes the manifest schema
//! has to support (see `examples/`):
//!   - `tiddl`-style downloader plugins: request `network` (to the
//!     configured streaming backend) + `downloads.write` capabilities to
//!     save tracks a user already has legitimate access to.
//!   - `tidarr`-style organizer plugins: request `library.read` +
//!     `library.reorganize` to automate folder/tag layout, *arr-style.

mod manifest;
mod manager;
mod host_api;

pub use manifest::{PluginCapability, PluginKind, PluginManifest};
pub use manager::{PluginHandle, PluginManager};
pub use host_api::HostContext;

#[derive(thiserror::Error, Debug)]
pub enum PluginError {
    #[error("manifest error: {0}")]
    Manifest(String),
    #[error("wasm engine error: {0}")]
    Wasm(#[from] wasmtime::Error),
    #[error("capability '{0}' was not granted to this plugin")]
    CapabilityDenied(String),
    #[error("plugin '{0}' not found")]
    NotFound(String),
}
