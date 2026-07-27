use crate::{PluginCapability, PluginError};

/// Per-plugin-instance context handed to the wasmtime `Linker` as host
/// state. Every host function checks `granted` before doing anything, so a
/// plugin that lies in its manifest (or a manifest that was edited after
/// user consent) simply gets `CapabilityDenied` instead of silent access.
pub struct HostContext {
    pub plugin_id: String,
    pub granted: Vec<PluginCapability>,
}

impl HostContext {
    fn require(&self, needle: impl Fn(&PluginCapability) -> bool, name: &str) -> Result<(), PluginError> {
        if self.granted.iter().any(needle) {
            Ok(())
        } else {
            Err(PluginError::CapabilityDenied(name.to_string()))
        }
    }

    /// Host import: `env.host_fetch(url_ptr, url_len) -> result_ptr`.
    /// Only reachable if the manifest declared `Network` and `host` is in
    /// its `allowed_hosts`.
    pub fn host_fetch(&self, host: &str, _url: &str) -> Result<Vec<u8>, PluginError> {
        self.require(
            |c| matches!(c, PluginCapability::Network { allowed_hosts } if allowed_hosts.iter().any(|h| h == host)),
            "network",
        )?;
        Ok(Vec::new())
    }

    /// Host import: `env.host_write_download(name_ptr, name_len, bytes_ptr, bytes_len)`.
    /// Path is always joined against musiQ's managed downloads root — the
    /// plugin never receives or supplies an absolute path.
    pub fn host_write_download(&self, _filename: &str, _bytes: &[u8]) -> Result<(), PluginError> {
        self.require(|c| matches!(c, PluginCapability::DownloadsWrite), "downloads.write")?;
        Ok(())
    }

    /// Host import: `env.host_query_library(json_query_ptr, len) -> json_ptr`.
    pub fn host_query_library(&self, _query_json: &str) -> Result<String, PluginError> {
        self.require(|c| matches!(c, PluginCapability::LibraryRead), "library.read")?;
        Ok("[]".to_string())
    }
}
