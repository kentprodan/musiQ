//! Single-track audio playback via `rodio`. Deliberately simple for this
//! pass: one active source at a time, no persistent queue — the native UI
//! layer owns "what's next" and calls `play` again when it wants a new track.

use std::fs::File;
use std::io::BufReader;
use std::path::Path;
use std::sync::Mutex;

use rodio::{Decoder, DeviceSinkBuilder, MixerDeviceSink, Player as RodioPlayer};

use crate::error::MusiqError;

pub struct Player {
    // Must stay alive for the lifetime of the `Player` below — dropping it
    // tears down the output device and silences playback.
    _device: MixerDeviceSink,
    inner: RodioPlayer,
    current_path: Mutex<Option<String>>,
}

impl Player {
    /// Opens the system's default audio output device.
    pub fn new() -> Result<Self, MusiqError> {
        let device = DeviceSinkBuilder::open_default_sink()
            .map_err(|e| MusiqError::Playback(e.to_string()))?;
        let inner = RodioPlayer::connect_new(device.mixer());
        Ok(Self {
            _device: device,
            inner,
            current_path: Mutex::new(None),
        })
    }

    /// Stops whatever is playing and starts `path` from the beginning.
    pub fn play(&self, path: &Path) -> Result<(), MusiqError> {
        let file = File::open(path)?;
        let decoder = Decoder::try_from(BufReader::new(file))
            .map_err(|e| MusiqError::Playback(e.to_string()))?;

        self.inner.clear();
        self.inner.append(decoder);
        self.inner.play();
        *self.current_path.lock().unwrap() = Some(path.to_string_lossy().into_owned());
        Ok(())
    }

    pub fn pause(&self) {
        self.inner.pause();
    }

    /// Resumes a paused track. No-op if nothing is loaded or already playing.
    pub fn resume(&self) {
        self.inner.play();
    }

    pub fn stop(&self) {
        self.inner.clear();
        *self.current_path.lock().unwrap() = None;
    }

    pub fn set_volume(&self, volume: f32) {
        self.inner.set_volume(volume);
    }

    /// True once a track has been loaded via `play` and hasn't finished or
    /// been stopped yet (regardless of paused state).
    pub fn has_track(&self) -> bool {
        !self.inner.empty()
    }

    pub fn is_paused(&self) -> bool {
        self.inner.is_paused()
    }

    /// The path passed to the most recent `play` call, or `None` if nothing
    /// has been loaded, playback was `stop`ped, or the track finished on its
    /// own (rodio has no "finished" callback, so this is polled via `empty`).
    pub fn current_track_path(&self) -> Option<String> {
        if self.has_track() {
            self.current_path.lock().unwrap().clone()
        } else {
            None
        }
    }
}
