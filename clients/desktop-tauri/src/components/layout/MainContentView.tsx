import type { ViewRoute } from "../../App";
import AlbumGrid from "../library/AlbumGrid";
import PluginsPanel from "../settings/PluginsPanel";
import "./MainContentView.css";

interface MainContentViewProps {
  route: ViewRoute;
  onNavigate: (route: ViewRoute) => void;
}

export default function MainContentView({ route }: MainContentViewProps) {
  return (
    <div className="main-content-view">
      <header className="app-header">
        <h1 className="main-content-view__title">{titleFor(route)}</h1>
      </header>

      <div className="main-content-view__body">
        {route.kind === "library" && route.section === "albums" && <AlbumGrid />}
        {route.kind === "library" && route.section !== "albums" && (
          <EmptySection label={route.section} />
        )}
        {route.kind === "playlist" && <EmptySection label="playlist" />}
        {route.kind === "settings" && <PluginsPanel />}
      </div>
    </div>
  );
}

function titleFor(route: ViewRoute): string {
  switch (route.kind) {
    case "library":
      return route.section[0].toUpperCase() + route.section.slice(1);
    case "playlist":
      return "Playlist";
    case "settings":
      return "Settings";
    case "now-playing":
      return "Now Playing";
  }
}

function EmptySection({ label }: { label: string }) {
  return <div className="main-content-view__empty">No {label} yet — connect a folder or streaming source to get started.</div>;
}
