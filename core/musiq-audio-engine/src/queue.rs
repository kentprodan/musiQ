use serde::{Deserialize, Serialize};
use uuid::Uuid;

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum RepeatMode {
    Off,
    One,
    All,
}

#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct PlayQueue {
    pub track_ids: Vec<Uuid>,
    pub cursor: Option<usize>,
    pub shuffle: bool,
    pub repeat: Option<RepeatMode>,
}

impl PlayQueue {
    pub fn current(&self) -> Option<Uuid> {
        self.cursor.and_then(|i| self.track_ids.get(i).copied())
    }

    pub fn advance(&mut self) -> Option<Uuid> {
        let next = match self.cursor {
            Some(i) if i + 1 < self.track_ids.len() => Some(i + 1),
            Some(_) if matches!(self.repeat, Some(RepeatMode::All)) => Some(0),
            None if !self.track_ids.is_empty() => Some(0),
            _ => None,
        };
        self.cursor = next;
        self.current()
    }
}
