//! musiq-audio-engine: gapless playback (rodio output sink over a symphonia
//! decode pipeline), the play queue / now-playing state machine, and
//! waveform peak extraction for the floating player's interactive seekbar.

mod engine;
mod queue;
mod waveform;

pub use engine::{AudioEngine, PlaybackState};
pub use queue::PlayQueue;
pub use waveform::{generate_waveform_peaks, WaveformPeaks};

#[derive(thiserror::Error, Debug)]
pub enum EngineError {
    #[error("decode error: {0}")]
    Decode(String),
    #[error("output device error: {0}")]
    Output(String),
    #[error("no track loaded")]
    NoTrackLoaded,
}
