use serde::{Deserialize, Serialize};
use std::path::Path;

/// Downsampled min/max peak pairs for one track, used to paint the
/// interactive waveform seekbar that the floating player bar expands into
/// on hover. `resolution` is the number of (min, max) pairs stored — the
/// desktop UI resamples this client-side to fit whatever pixel width the
/// expanded seekbar renders at, so one stored resolution serves every
/// window size without regenerating peaks.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct WaveformPeaks {
    pub resolution: u32,
    /// Interleaved [min0, max0, min1, max1, ...] as i8, normalized to
    /// [-127, 127]. Stored as raw bytes in `musiq_db::Track::waveform_peaks`.
    pub peaks: Vec<i8>,
}

const DEFAULT_RESOLUTION: u32 = 800;

/// Decodes the full track once via symphonia and reduces it to
/// `DEFAULT_RESOLUTION` peak pairs. Run once per track (on library import or
/// first play) and cached in the database — never recomputed on every
/// hover.
pub fn generate_waveform_peaks(_path: &Path) -> Result<WaveformPeaks, crate::EngineError> {
    // Decode pipeline: symphonia::default::get_probe() -> format reader ->
    // per-packet sample buffer -> chunk samples into `DEFAULT_RESOLUTION`
    // windows -> push (min, max) per window as i8. Stubbed here; the shape
    // of the output (fixed-resolution peak pairs, client-side resampled)
    // is the contract the desktop WaveformSeekbar component is built against.
    Ok(WaveformPeaks {
        resolution: DEFAULT_RESOLUTION,
        peaks: Vec::new(),
    })
}
