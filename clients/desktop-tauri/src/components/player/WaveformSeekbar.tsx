import { useEffect, useRef } from "react";

interface WaveformSeekbarProps {
  peaks: Int8Array;
  progress: number; // 0..1
  expanded: boolean;
  onSeek: (progress: number) => void;
}

/**
 * Renders as a thin discrete line at rest; when `expanded` is true (driven
 * by the parent's hover state — see FloatingPlayerBar.tsx) it paints the
 * full min/max waveform into a canvas sized to the container. The canvas
 * is redrawn on every resize/expand rather than kept permanently at full
 * resolution, since the collapsed state never needs per-sample detail.
 */
export default function WaveformSeekbar({ peaks, progress, expanded, onSeek }: WaveformSeekbarProps) {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const containerRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!expanded) return;
    const canvas = canvasRef.current;
    const container = containerRef.current;
    if (!canvas || !container) return;

    const dpr = window.devicePixelRatio || 1;
    const { width, height } = container.getBoundingClientRect();
    canvas.width = width * dpr;
    canvas.height = height * dpr;

    const ctx = canvas.getContext("2d");
    if (!ctx) return;
    ctx.scale(dpr, dpr);
    ctx.clearRect(0, 0, width, height);

    // Canvas fillStyle can't parse CSS custom properties directly, so the
    // played/unplayed colors are resolved from the cascade once per draw —
    // this is what makes the waveform pick up each OS's `--accent` token
    // (Segoe blue, SF blue, Adwaita blue, Breeze blue) without the drawing
    // code knowing which platform it's running on.
    const computed = getComputedStyle(container);
    const playedColor = computed.getPropertyValue("--accent").trim() || "#6c5ce7";
    const unplayedColor = computed.getPropertyValue("--text-secondary").trim() || "rgba(255,255,255,0.28)";

    drawWaveform(ctx, peaks, width, height, progress, playedColor, unplayedColor);
  }, [expanded, peaks, progress]);

  const handleClick = (e: React.MouseEvent<HTMLDivElement>) => {
    const rect = e.currentTarget.getBoundingClientRect();
    const ratio = (e.clientX - rect.left) / rect.width;
    onSeek(Math.min(1, Math.max(0, ratio)));
  };

  return (
    <div
      ref={containerRef}
      className="waveform-seekbar"
      data-expanded={expanded}
      onClick={handleClick}
      role="slider"
      aria-label="Seek"
      aria-valuemin={0}
      aria-valuemax={1}
      aria-valuenow={progress}
    >
      {expanded ? (
        <canvas ref={canvasRef} className="waveform-seekbar__canvas" />
      ) : (
        <div className="waveform-seekbar__line">
          <div className="waveform-seekbar__line-progress" style={{ width: `${progress * 100}%` }} />
        </div>
      )}
    </div>
  );
}

function drawWaveform(
  ctx: CanvasRenderingContext2D,
  peaks: Int8Array,
  width: number,
  height: number,
  progress: number,
  playedColor: string,
  unplayedColor: string,
) {
  const pairCount = Math.max(1, Math.floor(peaks.length / 2));
  const barsToRender = Math.max(1, Math.floor(width / 3)); // ~3px per bar including gap
  const samplesPerBar = pairCount / barsToRender;
  const midY = height / 2;
  const playedX = width * progress;

  for (let i = 0; i < barsToRender; i++) {
    const start = Math.floor(i * samplesPerBar);
    const end = Math.max(start + 1, Math.floor((i + 1) * samplesPerBar));

    let min = 127;
    let max = -128;
    for (let s = start; s < end && s < pairCount; s++) {
      const lo = peaks[s * 2] ?? 0;
      const hi = peaks[s * 2 + 1] ?? 0;
      if (lo < min) min = lo;
      if (hi > max) max = hi;
    }
    if (min > max) {
      min = 0;
      max = 0;
    }

    const x = i * (width / barsToRender);
    const barWidth = Math.max(1, width / barsToRender - 1);
    const barTop = midY - (max / 127) * midY * 0.9;
    const barHeight = Math.max(2, ((max - min) / 254) * height * 0.9);

    ctx.fillStyle = x <= playedX ? playedColor : unplayedColor;
    ctx.fillRect(x, barTop, barWidth, barHeight);
  }
}
