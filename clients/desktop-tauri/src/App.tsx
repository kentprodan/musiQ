import { useState } from "react";
import Sidebar from "./components/layout/Sidebar";
import MainContentView from "./components/layout/MainContentView";
import FloatingPlayerBar from "./components/player/FloatingPlayerBar";
import CoverFlow from "./components/nowplaying/CoverFlow";
import "./App.css";

export type ViewRoute =
  | { kind: "library"; section: "albums" | "artists" | "tracks" | "genres" }
  | { kind: "playlist"; playlistId: string }
  | { kind: "now-playing" }
  | { kind: "settings" };

export default function App() {
  const [route, setRoute] = useState<ViewRoute>({ kind: "library", section: "albums" });

  return (
    <div className="app-shell">
      <Sidebar route={route} onNavigate={setRoute} />
      <div className="app-shell__content-area">
        {route.kind === "now-playing" ? (
          <CoverFlow />
        ) : (
          <MainContentView route={route} onNavigate={setRoute} />
        )}
        <FloatingPlayerBar onOpenNowPlaying={() => setRoute({ kind: "now-playing" })} />
      </div>
    </div>
  );
}
