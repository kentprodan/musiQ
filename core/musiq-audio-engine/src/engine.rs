use crate::{EngineError, PlayQueue};
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum PlaybackState {
    Stopped,
    Playing,
    Paused,
    Buffering,
}

/// Owns the rodio `OutputStream`/`Sink` pair and the current decode
/// pipeline. Exposed to every frontend (Tauri commands, UniFFI for
/// Apple/Android) through the same handful of transport methods so
/// SMTC / MPRIS / MPNowPlayingInfoCenter integrations all drive one
/// source of truth.
pub struct AudioEngine {
    pub queue: PlayQueue,
    pub state: PlaybackState,
    pub position_ms: u64,
    pub volume: f32,
}

impl AudioEngine {
    pub fn new() -> Self {
        Self {
            queue: PlayQueue::default(),
            state: PlaybackState::Stopped,
            position_ms: 0,
            volume: 1.0,
        }
    }

    pub fn play(&mut self) -> Result<(), EngineError> {
        if self.queue.current().is_none() {
            return Err(EngineError::NoTrackLoaded);
        }
        self.state = PlaybackState::Playing;
        Ok(())
    }

    pub fn pause(&mut self) {
        if self.state == PlaybackState::Playing {
            self.state = PlaybackState::Paused;
        }
    }

    pub fn seek(&mut self, position_ms: u64) {
        self.position_ms = position_ms;
    }

    pub fn set_volume(&mut self, volume: f32) {
        self.volume = volume.clamp(0.0, 1.0);
    }
}

impl Default for AudioEngine {
    fn default() -> Self {
        Self::new()
    }
}
