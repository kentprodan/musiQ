import { useCallback, useRef, useState } from "react";
import type { ViewRoute } from "../../App";
import "./Sidebar.css";

interface SidebarProps {
  route: ViewRoute;
  onNavigate: (route: ViewRoute) => void;
}

const LIBRARY_SECTIONS: Array<{ id: "albums" | "artists" | "tracks" | "genres"; label: string; icon: string }> = [
  { id: "albums", label: "Albums", icon: "" },
  { id: "artists", label: "Artists", icon: "" },
  { id: "tracks", label: "Tracks", icon: "" },
  { id: "genres", label: "Genres", icon: "" },
];

// Placeholder data — real playlists/folders/remote sources come from
// musiq-core via Tauri commands once the data layer is wired up.
const PLAYLISTS = [
  { id: "recently-added", name: "Recently Added", smart: true },
  { id: "road-trip", name: "Road Trip", smart: false },
];
const REMOTE_SOURCES = [
  { id: "plex-home", label: "Plex — Home Server", kind: "plex" },
  { id: "navidrome-nas", label: "Navidrome — NAS", kind: "navidrome" },
];

/**
 * Mirrors WinUI 3's `NavigationView` pane-display-modes (compact/expanded)
 * on Windows, `SplitView` on macOS, and a plain collapsible column on
 * Linux — all through the same resize + collapse state, since the visual
 * differences are entirely CSS (see os-*.css `.sidebar` rules).
 */
export default function Sidebar({ route, onNavigate }: SidebarProps) {
  const [collapsed, setCollapsed] = useState(false);
  const [width, setWidth] = useState(260);
  const resizing = useRef(false);

  const onResizeStart = useCallback((e: React.MouseEvent) => {
    e.preventDefault();
    resizing.current = true;

    const onMove = (moveEvent: MouseEvent) => {
      if (!resizing.current) return;
      const next = Math.min(360, Math.max(200, moveEvent.clientX));
      setWidth(next);
    };
    const onUp = () => {
      resizing.current = false;
      window.removeEventListener("mousemove", onMove);
      window.removeEventListener("mouseup", onUp);
    };
    window.addEventListener("mousemove", onMove);
    window.addEventListener("mouseup", onUp);
  }, []);

  return (
    <nav
      className="sidebar"
      data-collapsed={collapsed}
      style={{ width: collapsed ? "var(--sidebar-width-compact)" : width }}
    >
      <div className="sidebar__header">
        <span className="sidebar__brand">{collapsed ? "m" : "musiQ"}</span>
        <button
          className="sidebar__collapse-toggle"
          onClick={() => setCollapsed((c) => !c)}
          aria-label={collapsed ? "Expand sidebar" : "Collapse sidebar"}
        >
          ⟨⟩
        </button>
      </div>

      <SidebarSection label="Library" collapsed={collapsed}>
        {LIBRARY_SECTIONS.map((s) => (
          <SidebarItem
            key={s.id}
            icon={s.icon}
            label={s.label}
            collapsed={collapsed}
            active={route.kind === "library" && route.section === s.id}
            onClick={() => onNavigate({ kind: "library", section: s.id })}
          />
        ))}
      </SidebarSection>

      <SidebarSection label="Playlists" collapsed={collapsed}>
        {PLAYLISTS.map((p) => (
          <SidebarItem
            key={p.id}
            icon={p.smart ? "" : ""}
            label={p.name}
            collapsed={collapsed}
            active={route.kind === "playlist" && route.playlistId === p.id}
            onClick={() => onNavigate({ kind: "playlist", playlistId: p.id })}
          />
        ))}
      </SidebarSection>

      <SidebarSection label="Streaming" collapsed={collapsed}>
        {REMOTE_SOURCES.map((r) => (
          <SidebarItem key={r.id} icon="" label={r.label} collapsed={collapsed} onClick={() => {}} />
        ))}
      </SidebarSection>

      <div className="sidebar__footer">
        <SidebarItem
          icon=""
          label="Settings"
          collapsed={collapsed}
          active={route.kind === "settings"}
          onClick={() => onNavigate({ kind: "settings" })}
        />
      </div>

      <div className="sidebar__resizer" onMouseDown={onResizeStart} />
    </nav>
  );
}

function SidebarSection({ label, collapsed, children }: { label: string; collapsed: boolean; children: React.ReactNode }) {
  return (
    <div className="sidebar__section">
      {!collapsed && <div className="sidebar__section-label">{label}</div>}
      {children}
    </div>
  );
}

function SidebarItem({
  icon,
  label,
  collapsed,
  active,
  onClick,
}: {
  icon: string;
  label: string;
  collapsed: boolean;
  active?: boolean;
  onClick: () => void;
}) {
  return (
    <button className="sidebar-item tiltable" data-active={!!active} onClick={onClick} title={collapsed ? label : undefined}>
      <span className="sidebar-item__icon" aria-hidden>
        {icon}
      </span>
      {!collapsed && <span className="sidebar-item__label">{label}</span>}
    </button>
  );
}
