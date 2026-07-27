import { useState } from "react";
import "./PluginsPanel.css";

type CapabilityKind = "network" | "downloads_write" | "library_read" | "library_reorganize" | "now_playing_read";

interface InstalledPlugin {
  id: string;
  name: string;
  version: string;
  description: string;
  enabled: boolean;
  capabilities: CapabilityKind[];
}

const CAPABILITY_LABELS: Record<CapabilityKind, string> = {
  network: "Network access",
  downloads_write: "Write to managed downloads folder",
  library_read: "Read library metadata",
  library_reorganize: "Reorganize library files/tags",
  now_playing_read: "Read now-playing state",
};

// Mirrors core/musiq-plugins/examples/{tiddl,tidarr}/manifest.json — the
// two reference categories the plugin manifest schema is designed around:
// a downloader (network + downloads-write) and an organizer (library-read
// + library-reorganize). Real data comes from `PluginManager::manifests`
// via a Tauri command once the plugin host is wired to the UI.
const INSTALLED_PLUGINS: InstalledPlugin[] = [
  {
    id: "community.tiddl-bridge",
    name: "Tiddl Bridge",
    version: "0.1.0",
    description: "Downloader-category plugin: saves tracks from a connected streaming subscription into your managed library folder.",
    enabled: false,
    capabilities: ["network", "downloads_write", "library_read"],
  },
  {
    id: "community.tidarr-organizer",
    name: "Tidarr Organizer",
    version: "0.1.0",
    description: "Organizer-category plugin: normalizes folder/tag layout for newly imported tracks, *arr-style.",
    enabled: true,
    capabilities: ["library_read", "library_reorganize"],
  },
];

/**
 * Every plugin runs sandboxed inside `musiq-plugins` (a wasmtime `Store`
 * per invocation, zero ambient authority — see
 * `core/musiq-plugins/src/host_api.rs`). This panel is the user-facing
 * side of that capability model: nothing a plugin can do is implicit,
 * every capability it was granted at install time is listed here and can
 * be revoked without uninstalling the plugin.
 */
export default function PluginsPanel() {
  const [plugins, setPlugins] = useState(INSTALLED_PLUGINS);

  const toggleEnabled = (id: string) => {
    setPlugins((prev) => prev.map((p) => (p.id === id ? { ...p, enabled: !p.enabled } : p)));
  };

  return (
    <div className="plugins-panel scroll-region">
      <div className="plugins-panel__header">
        <h2>Plugins</h2>
        <button className="plugins-panel__install-btn">Install from file…</button>
      </div>
      <p className="plugins-panel__intro">
        Plugins run in a sandboxed WASM runtime with no default access to your system — each capability below was
        explicitly granted when the plugin was installed.
      </p>

      <ul className="plugins-panel__list">
        {plugins.map((plugin) => (
          <li key={plugin.id} className="plugin-card">
            <div className="plugin-card__row">
              <div>
                <div className="plugin-card__name">
                  {plugin.name} <span className="plugin-card__version">v{plugin.version}</span>
                </div>
                <p className="plugin-card__description">{plugin.description}</p>
              </div>
              <label className="plugin-card__toggle">
                <input type="checkbox" checked={plugin.enabled} onChange={() => toggleEnabled(plugin.id)} />
                <span>{plugin.enabled ? "Enabled" : "Disabled"}</span>
              </label>
            </div>

            <div className="plugin-card__capabilities">
              {plugin.capabilities.map((cap) => (
                <span key={cap} className="plugin-capability-chip">
                  {CAPABILITY_LABELS[cap]}
                </span>
              ))}
            </div>
          </li>
        ))}
      </ul>
    </div>
  );
}
