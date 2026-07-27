use crate::{HostContext, PluginError, PluginManifest};
use std::collections::HashMap;
use std::path::PathBuf;
use wasmtime::{Engine, Linker, Module, Store};

pub struct PluginHandle {
    pub manifest: PluginManifest,
    module: Module,
}

/// Discovers plugins under a directory (each plugin = one subfolder with a
/// `manifest.json` + its `.wasm`), loads (but does not yet instantiate)
/// each module, and dispatches lifecycle hooks on demand.
pub struct PluginManager {
    engine: Engine,
    plugins_dir: PathBuf,
    loaded: HashMap<String, PluginHandle>,
}

impl PluginManager {
    pub fn new(plugins_dir: impl Into<PathBuf>) -> Self {
        Self {
            engine: Engine::default(),
            plugins_dir: plugins_dir.into(),
            loaded: HashMap::new(),
        }
    }

    /// Scans `plugins_dir` for `*/manifest.json`, parses each manifest, and
    /// compiles the referenced `.wasm` module. Does not run any plugin code
    /// — compilation only validates the module, it doesn't call `_start`.
    pub fn discover(&mut self) -> Result<Vec<String>, PluginError> {
        let mut discovered = Vec::new();
        if !self.plugins_dir.exists() {
            return Ok(discovered);
        }

        for entry in std::fs::read_dir(&self.plugins_dir).map_err(|e| PluginError::Manifest(e.to_string()))? {
            let entry = entry.map_err(|e| PluginError::Manifest(e.to_string()))?;
            let manifest_path = entry.path().join("manifest.json");
            if !manifest_path.exists() {
                continue;
            }
            let raw = std::fs::read_to_string(&manifest_path).map_err(|e| PluginError::Manifest(e.to_string()))?;
            let manifest: PluginManifest =
                serde_json::from_str(&raw).map_err(|e| PluginError::Manifest(e.to_string()))?;

            if let Some(wasm_rel) = &manifest.entry_wasm {
                let wasm_path = entry.path().join(wasm_rel);
                let module = Module::from_file(&self.engine, &wasm_path)?;
                let id = manifest.id.clone();
                self.loaded.insert(id.clone(), PluginHandle { manifest, module });
                discovered.push(id);
            }
        }

        Ok(discovered)
    }

    /// Instantiates the plugin fresh and calls the given exported hook.
    /// A new `Store` per call keeps plugin instances stateless and cheap
    /// to sandbox-reset between invocations — hooks are event handlers,
    /// not long-lived processes.
    pub fn call_hook(&self, plugin_id: &str, hook: &str, _args_json: &str) -> Result<String, PluginError> {
        let handle = self.loaded.get(plugin_id).ok_or_else(|| PluginError::NotFound(plugin_id.to_string()))?;

        if !handle.manifest.hooks.iter().any(|h| h == hook) {
            return Err(PluginError::NotFound(format!("{plugin_id}::{hook}")));
        }

        let ctx = HostContext {
            plugin_id: plugin_id.to_string(),
            granted: handle.manifest.capabilities.clone(),
        };
        let mut store = Store::new(&self.engine, ctx);

        // Real host functions (host_fetch / host_write_download /
        // host_query_library from host_api.rs) get defined on this linker,
        // each reading `store.data().granted` before doing anything. Left
        // undefined here — a plugin importing them would fail to
        // instantiate until they're wired up, which is a safe failure mode
        // for a capability that hasn't been implemented yet.
        let linker: Linker<HostContext> = Linker::new(&self.engine);
        let instance = linker.instantiate(&mut store, &handle.module)?;

        // Hooks are exported as `() -> ()`; passing `_args_json` in and a
        // JSON string back out needs a shared-memory pointer+length ABI
        // (allocate in the plugin's linear memory, write bytes, pass the
        // pointer) that's elided here — this call proves the sandboxing
        // and capability-gating shape, not the full wire format yet.
        let hook_fn = instance.get_typed_func::<(), ()>(&mut store, hook)?;
        hook_fn.call(&mut store, ())?;

        Ok("{}".to_string())
    }

    pub fn manifests(&self) -> impl Iterator<Item = &PluginManifest> {
        self.loaded.values().map(|h| &h.manifest)
    }
}
