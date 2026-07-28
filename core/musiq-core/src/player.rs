//! Audio playback via `rodio`, plus a queue layered on top of it. `rodio`
//! itself only ever holds one loaded track at a time (each `play` clears and
//! replaces it) — "what comes next" is tracked entirely in `QueueState` here.
//! rodio has no playback-finished callback, so callers must poll
//! `advance_if_finished` periodically to get auto-advance behavior.

use std::fs::File;
use std::io::BufReader;
use std::sync::Mutex;

use rand::seq::SliceRandom;
use rodio::{Decoder, DeviceSinkBuilder, MixerDeviceSink, Player as RodioPlayer};

use crate::error::MusiqError;
use crate::streaming::HttpStreamReader;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum RepeatMode {
    Off,
    All,
    One,
}

struct QueueState {
    /// Track paths in their original (unshuffled) order.
    tracks: Vec<String>,
    /// A permutation of `0..tracks.len()` giving play order.
    play_order: Vec<usize>,
    /// Index into `play_order` of the currently loaded track, if any.
    position: Option<usize>,
    shuffle: bool,
    repeat: RepeatMode,
}

impl QueueState {
    fn empty() -> Self {
        Self {
            tracks: Vec::new(),
            play_order: Vec::new(),
            position: None,
            shuffle: false,
            repeat: RepeatMode::Off,
        }
    }

    fn set_tracks(&mut self, tracks: Vec<String>, start_index: usize) {
        self.tracks = tracks;
        self.rebuild_order(Some(start_index));
    }

    /// Recomputes `play_order` from `shuffle`, keeping `keep_track_index`
    /// (an index into `tracks`) as the current position — first when
    /// shuffled, at its natural spot otherwise. Used both when the shuffle
    /// flag changes and when a new queue is loaded.
    fn rebuild_order(&mut self, keep_track_index: Option<usize>) {
        let mut order: Vec<usize> = (0..self.tracks.len()).collect();

        if self.shuffle && order.len() > 1 {
            if let Some(keep) = keep_track_index {
                order.retain(|&i| i != keep);
                order.shuffle(&mut rand::rng());
                order.insert(0, keep);
            } else {
                order.shuffle(&mut rand::rng());
            }
        }

        self.position = keep_track_index.and_then(|idx| order.iter().position(|&i| i == idx));
        self.play_order = order;
    }
}

pub struct Player {
    // Must stay alive for the lifetime of the `Player` below — dropping it
    // tears down the output device and silences playback.
    _device: MixerDeviceSink,
    inner: RodioPlayer,
    current_path: Mutex<Option<String>>,
    queue: Mutex<QueueState>,
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
            queue: Mutex::new(QueueState::empty()),
        })
    }

    /// Stops whatever is playing and starts `source` from the beginning —
    /// either a local file path, or an `http(s)://` URL, streamed on demand
    /// via range requests rather than downloaded up front. Does not touch
    /// the queue — prefer `set_queue`/`next`/`previous` from UI code so
    /// polling-based auto-advance and shuffle/repeat stay coherent.
    pub fn play(&self, source: &str) -> Result<(), MusiqError> {
        if source.starts_with("http://") || source.starts_with("https://") {
            let reader =
                HttpStreamReader::open(source).map_err(|e| MusiqError::Playback(e.to_string()))?;
            let decoder =
                Decoder::new(reader).map_err(|e| MusiqError::Playback(e.to_string()))?;
            self.inner.clear();
            self.inner.append(decoder);
            self.inner.play();
        } else {
            let file = File::open(source)?;
            let decoder = Decoder::try_from(BufReader::new(file))
                .map_err(|e| MusiqError::Playback(e.to_string()))?;
            self.inner.clear();
            self.inner.append(decoder);
            self.inner.play();
        }

        *self.current_path.lock().unwrap() = Some(source.to_string());
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
        // Clears the queue's "currently playing" marker so a stale poll
        // (`advance_if_finished`) doesn't resurrect playback after an
        // explicit stop.
        self.queue.lock().unwrap().position = None;
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

    /// Replaces the queue with `tracks` and starts playing the one at
    /// `start_index`.
    pub fn set_queue(&self, tracks: Vec<String>, start_index: usize) -> Result<(), MusiqError> {
        if tracks.is_empty() || start_index >= tracks.len() {
            return Err(MusiqError::InvalidPath(format!(
                "queue start index {start_index} out of range for {} track(s)",
                tracks.len()
            )));
        }
        let path = tracks[start_index].clone();
        self.queue.lock().unwrap().set_tracks(tracks, start_index);
        self.play(&path)
    }

    /// Manually advances to the next track. Returns `false` (and leaves
    /// playback stopped) if there's no queue, or the queue has ended and
    /// isn't set to repeat.
    pub fn next(&self) -> Result<bool, MusiqError> {
        self.advance(1)
    }

    /// Manually moves to the previous track, per the same end-of-queue rules
    /// as `next`.
    pub fn previous(&self) -> Result<bool, MusiqError> {
        self.advance(-1)
    }

    fn advance(&self, delta: isize) -> Result<bool, MusiqError> {
        let path = {
            let mut queue = self.queue.lock().unwrap();
            let Some(pos) = queue.position else {
                return Ok(false);
            };
            let len = queue.play_order.len() as isize;
            let mut new_pos = pos as isize + delta;

            if new_pos < 0 {
                if queue.repeat == RepeatMode::All {
                    new_pos = len - 1;
                } else {
                    queue.position = None;
                    return Ok(false);
                }
            } else if new_pos >= len {
                if queue.repeat == RepeatMode::All {
                    new_pos = 0;
                } else {
                    queue.position = None;
                    return Ok(false);
                }
            }

            queue.position = Some(new_pos as usize);
            let track_index = queue.play_order[new_pos as usize];
            queue.tracks[track_index].clone()
        };

        self.play(&path)?;
        Ok(true)
    }

    /// Call periodically (rodio has no completion callback) to let the queue
    /// auto-advance once the current track finishes on its own. No-ops while
    /// something is still loaded/playing/paused, and after an explicit
    /// `stop()`. Returns `true` if a new track was started.
    pub fn advance_if_finished(&self) -> Result<bool, MusiqError> {
        if self.has_track() {
            return Ok(false);
        }

        let repeat_current = {
            let queue = self.queue.lock().unwrap();
            match queue.position {
                Some(pos) if queue.repeat == RepeatMode::One => {
                    let track_index = queue.play_order[pos];
                    Some(queue.tracks[track_index].clone())
                }
                _ => None,
            }
        };

        if let Some(path) = repeat_current {
            self.play(&path)?;
            return Ok(true);
        }

        self.advance(1)
    }

    pub fn set_shuffle(&self, shuffle: bool) {
        let mut queue = self.queue.lock().unwrap();
        queue.shuffle = shuffle;
        let keep = queue.position.map(|p| queue.play_order[p]);
        queue.rebuild_order(keep);
    }

    pub fn is_shuffled(&self) -> bool {
        self.queue.lock().unwrap().shuffle
    }

    pub fn set_repeat_mode(&self, mode: RepeatMode) {
        self.queue.lock().unwrap().repeat = mode;
    }

    pub fn repeat_mode(&self) -> RepeatMode {
        self.queue.lock().unwrap().repeat
    }

    /// Index of the currently playing track within the queue's *original*
    /// (unshuffled) order — the order the UI displays tracks in.
    pub fn queue_position(&self) -> Option<u32> {
        let queue = self.queue.lock().unwrap();
        queue
            .position
            .map(|p| queue.play_order[p] as u32)
    }

    pub fn queue_len(&self) -> u32 {
        self.queue.lock().unwrap().tracks.len() as u32
    }
}
