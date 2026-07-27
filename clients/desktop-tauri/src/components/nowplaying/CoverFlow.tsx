import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import "./CoverFlow.css";

interface CoverFlowAlbum {
  id: string;
  title: string;
  artist: string;
  coverUrl?: string;
}

// Placeholder queue — real data comes from the current play queue /
// album context once musiq-core's queue state is wired to the UI.
const PLACEHOLDER_ALBUMS: CoverFlowAlbum[] = Array.from({ length: 14 }, (_, i) => ({
  id: `cf-${i}`,
  title: `Album ${i + 1}`,
  artist: "Unknown Artist",
}));

const SIDE_ROTATION_DEG = 62;
const SIDE_TRANSLATE_Z = 220;
const SIDE_SPACING = 130;
const MAX_VISIBLE_DEPTH = 5;

/**
 * Revival of the original iTunes CoverFlow: a 3D carousel where the
 * centered album sits frontal at full scale, flanking albums rotate away
 * in perspective, dim and shrink with distance, and every cover casts a
 * fading mirror reflection on the "floor" beneath it. Built entirely with
 * CSS 3D transforms (`perspective` / `rotateY` / `translateZ`) — no WebGL
 * — driven by one `centerIndex` piece of state so wheel, drag, and
 * keyboard navigation all converge on the same transform math below.
 */
export default function CoverFlow() {
  const [centerIndex, setCenterIndex] = useState(0);
  const albums = PLACEHOLDER_ALBUMS;
  const dragState = useRef<{ startX: number; startIndex: number } | null>(null);

  const clamp = useCallback((i: number) => Math.max(0, Math.min(albums.length - 1, i)), [albums.length]);

  const onWheel = useCallback(
    (e: React.WheelEvent) => {
      const delta = Math.abs(e.deltaY) > Math.abs(e.deltaX) ? e.deltaY : e.deltaX;
      if (Math.abs(delta) < 12) return;
      setCenterIndex((i) => clamp(i + (delta > 0 ? 1 : -1)));
    },
    [clamp],
  );

  const onPointerDown = useCallback(
    (e: React.PointerEvent) => {
      dragState.current = { startX: e.clientX, startIndex: centerIndex };
      (e.target as HTMLElement).setPointerCapture(e.pointerId);
    },
    [centerIndex],
  );

  const onPointerMove = useCallback(
    (e: React.PointerEvent) => {
      if (!dragState.current) return;
      const deltaX = e.clientX - dragState.current.startX;
      const steps = Math.round(-deltaX / 90); // ~90px of drag per album
      setCenterIndex(clamp(dragState.current.startIndex + steps));
    },
    [clamp],
  );

  const onPointerUp = useCallback(() => {
    dragState.current = null;
  }, []);

  useEffect(() => {
    const onKeyDown = (e: KeyboardEvent) => {
      if (e.key === "ArrowRight") setCenterIndex((i) => clamp(i + 1));
      if (e.key === "ArrowLeft") setCenterIndex((i) => clamp(i - 1));
    };
    window.addEventListener("keydown", onKeyDown);
    return () => window.removeEventListener("keydown", onKeyDown);
  }, [clamp]);

  const items = useMemo(
    () =>
      albums.map((album, index) => ({
        album,
        offset: index - centerIndex,
      })),
    [albums, centerIndex],
  );

  return (
    <div
      className="coverflow"
      onWheel={onWheel}
      onPointerDown={onPointerDown}
      onPointerMove={onPointerMove}
      onPointerUp={onPointerUp}
      onPointerCancel={onPointerUp}
    >
      <div className="coverflow__stage">
        {items
          .filter((item) => Math.abs(item.offset) <= MAX_VISIBLE_DEPTH)
          .map(({ album, offset }) => (
            <CoverFlowItem key={album.id} album={album} offset={offset} onSelect={() => setCenterIndex(clamp(centerIndex + offset))} />
          ))}
      </div>

      <div className="coverflow__caption">
        <div className="coverflow__caption-title">{albums[centerIndex]?.title}</div>
        <div className="coverflow__caption-artist">{albums[centerIndex]?.artist}</div>
      </div>
    </div>
  );
}

function CoverFlowItem({
  album,
  offset,
  onSelect,
}: {
  album: CoverFlowAlbum;
  offset: number;
  onSelect: () => void;
}) {
  const isCenter = offset === 0;
  const sign = Math.sign(offset);
  const depth = Math.abs(offset);

  const transform = isCenter
    ? "translate3d(0, 0, 0) rotateY(0deg) scale(1)"
    : `translate3d(${sign * (SIDE_TRANSLATE_Z * 0.55 + depth * SIDE_SPACING)}px, 0, ${-SIDE_TRANSLATE_Z}px) rotateY(${-sign * SIDE_ROTATION_DEG}deg) scale(0.82)`;

  const brightness = isCenter ? 1 : Math.max(0.35, 1 - depth * 0.18);
  const opacity = Math.max(0, 1 - depth * 0.16);
  const zIndex = 100 - depth;

  return (
    <div
      className="coverflow-item"
      style={{ transform, zIndex, opacity, filter: `brightness(${brightness})` }}
      onClick={onSelect}
      aria-current={isCenter}
    >
      <div className="coverflow-item__art">{album.coverUrl && <img src={album.coverUrl} alt="" />}</div>
      {/* Mirror reflection: a vertically-flipped duplicate, faded via mask. */}
      <div className="coverflow-item__reflection" aria-hidden>
        {album.coverUrl && <img src={album.coverUrl} alt="" />}
      </div>
    </div>
  );
}
