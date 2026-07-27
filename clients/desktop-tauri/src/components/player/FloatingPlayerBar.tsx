import { useState } from "react";
import WaveformSeekbar from "./WaveformSeekbar";
import "./FloatingPlayerBar.css";

interface FloatingPlayerBarProps {
  onOpenNowPlaying: () => void;
}

// Placeholder now-playing state — replaced by a subscription to
// musiq-audio-engine's playback events once the transport is wired up.
const PLACEHOLDER_PEAKS = new Int8Array(1600);

/**
 * Floating, bottom-centered transport bar (see os-*.css for the
 * Acrylic/Vibrancy/flat surface treatment). The signature interaction:
 * hovering the seekbar expands it from a thin progress line into the full
 * interactive waveform, while every *other* control in the bar animates
 * into a Gaussian blur so the waveform reads as the sole focal point.
 *
 * Both effects key off one piece of state (`seekHovered`) so they always
 * animate in lockstep — see `.floating-player-bar[data-seek-hover]` in
 * FloatingPlayerBar.css for the blur, and `WaveformSeekbar`'s `expanded`
 * prop for the waveform reveal.
 */
export default function FloatingPlayerBar({ onOpenNowPlaying }: FloatingPlayerBarProps) {
  const [seekHovered, setSeekHovered] = useState(false);
  const [progress, setProgress] = useState(0.32);
  const [playing, setPlaying] = useState(false);

  return (
    <div className="floating-player-bar surface-acrylic surface-vibrancy surface-blur" data-seek-hover={seekHovered}>
      <button className="player-now-playing" onClick={onOpenNowPlaying}>
        <div className="player-now-playing__cover" />
        <div className="player-now-playing__meta">
          <div className="player-now-playing__title">Nothing playing</div>
          <div className="player-now-playing__artist">—</div>
        </div>
      </button>

      <div
        className="player-seek-zone"
        onMouseEnter={() => setSeekHovered(true)}
        onMouseLeave={() => setSeekHovered(false)}
      >
        <WaveformSeekbar
          peaks={PLACEHOLDER_PEAKS}
          progress={progress}
          expanded={seekHovered}
          onSeek={setProgress}
        />
      </div>

      <div className="player-controls">
        <button className="player-controls__btn" aria-label="Previous track">
          ⏮
        </button>
        <button className="player-controls__btn player-controls__btn--primary" onClick={() => setPlaying((p) => !p)} aria-label={playing ? "Pause" : "Play"}>
          {playing ? "⏸" : "▶"}
        </button>
        <button className="player-controls__btn" aria-label="Next track">
          ⏭
        </button>
        <input
          className="player-controls__volume"
          type="range"
          min={0}
          max={1}
          step={0.01}
          defaultValue={0.8}
          aria-label="Volume"
        />
      </div>
    </div>
  );
}
