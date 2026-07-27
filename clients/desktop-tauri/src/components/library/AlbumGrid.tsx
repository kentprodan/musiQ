import "./AlbumGrid.css";

export interface AlbumSummary {
  id: string;
  title: string;
  artist: string;
  coverUrl?: string;
}

// Placeholder library data — replaced by a `list_albums` Tauri command
// once musiq-core's repository queries are wired to the UI.
const PLACEHOLDER_ALBUMS: AlbumSummary[] = Array.from({ length: 18 }, (_, i) => ({
  id: `album-${i}`,
  title: `Untitled Album ${i + 1}`,
  artist: "Unknown Artist",
}));

export default function AlbumGrid({ onOpenAlbum }: { onOpenAlbum?: (id: string) => void }) {
  return (
    <div className="album-grid scroll-region">
      {PLACEHOLDER_ALBUMS.map((album, index) => (
        <button
          key={album.id}
          className="album-card tiltable stagger-item"
          style={{ ["--stagger-index" as string]: index }}
          onClick={() => onOpenAlbum?.(album.id)}
          // Shared view-transition name powers the Windows "connected
          // animation" from grid tile -> detail hero (see os-windows.css).
          data-view-transition-name={`album-${album.id}`}
        >
          <div className="album-card__cover">{album.coverUrl ? <img src={album.coverUrl} alt="" /> : null}</div>
          <div className="album-card__title">{album.title}</div>
          <div className="album-card__artist">{album.artist}</div>
        </button>
      ))}
    </div>
  );
}
