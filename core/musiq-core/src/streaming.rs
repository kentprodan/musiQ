//! A `Read + Seek` adapter over an HTTP resource, fetching bytes on demand
//! via `Range` requests rather than downloading the whole file up front —
//! lets rodio's `Decoder` treat a remote URL (Plex, Navidrome/Subsonic, ...)
//! like a local file, so playback can start before the track has fully
//! downloaded. Shared by every streaming-source client in this crate.
//!
//! Seeking is lazy: `seek()` only updates a position counter; the next
//! `read()` reopens an HTTP range request only if that position doesn't
//! match where the currently-open response left off. Sequential playback
//! (the overwhelmingly common case) therefore opens exactly one connection.

use std::io::{self, Read, Seek, SeekFrom};
use std::time::Duration;

pub struct HttpStreamReader {
    agent: ureq::Agent,
    url: String,
    total_len: u64,
    position: u64,
    reader: Option<Box<dyn Read + Send + Sync>>,
    /// Absolute stream position the next byte out of `reader` corresponds to.
    reader_pos: u64,
}

impl HttpStreamReader {
    /// Opens `url`, confirming range-request support and learning the
    /// resource's total length via `Content-Range` on a 1-byte probe request.
    pub fn open(url: &str) -> io::Result<Self> {
        let agent = Self::build_agent();
        let response = agent
            .get(url)
            .header("Range", "bytes=0-0")
            .call()
            .map_err(to_io_error)?;

        let total_len = response
            .headers()
            .get("Content-Range")
            .and_then(|v| v.to_str().ok())
            .and_then(|s| s.rsplit('/').next())
            .and_then(|s| s.parse::<u64>().ok())
            .ok_or_else(|| {
                io::Error::new(
                    io::ErrorKind::Unsupported,
                    "server did not report Content-Range — range requests may be unsupported",
                )
            })?;

        Ok(Self {
            agent,
            url: url.to_string(),
            total_len,
            position: 0,
            reader: None,
            reader_pos: 0,
        })
    }

    fn build_agent() -> ureq::Agent {
        ureq::Agent::config_builder()
            .timeout_global(Some(Duration::from_secs(15)))
            .build()
            .into()
    }

    fn open_range_at(&mut self, pos: u64) -> io::Result<()> {
        let response = self
            .agent
            .get(&self.url)
            .header("Range", format!("bytes={pos}-"))
            .call()
            .map_err(to_io_error)?;
        let reader: Box<dyn Read + Send + Sync> = Box::new(response.into_body().into_reader());
        self.reader = Some(reader);
        self.reader_pos = pos;
        Ok(())
    }
}

fn to_io_error(e: ureq::Error) -> io::Error {
    io::Error::new(io::ErrorKind::Other, e.to_string())
}

impl Read for HttpStreamReader {
    fn read(&mut self, buf: &mut [u8]) -> io::Result<usize> {
        if self.position >= self.total_len {
            return Ok(0);
        }
        if self.reader.is_none() || self.reader_pos != self.position {
            self.open_range_at(self.position)?;
        }

        let n = self.reader.as_mut().expect("just opened above").read(buf)?;
        if n == 0 {
            // Server closed the connection early; don't keep retrying it.
            self.reader = None;
            return Ok(0);
        }
        self.position += n as u64;
        self.reader_pos += n as u64;
        Ok(n)
    }
}

impl Seek for HttpStreamReader {
    fn seek(&mut self, pos: SeekFrom) -> io::Result<u64> {
        let new_pos = match pos {
            SeekFrom::Start(offset) => offset as i64,
            SeekFrom::End(offset) => self.total_len as i64 + offset,
            SeekFrom::Current(offset) => self.position as i64 + offset,
        };

        if new_pos < 0 {
            return Err(io::Error::new(
                io::ErrorKind::InvalidInput,
                "seek to a negative position",
            ));
        }

        self.position = new_pos as u64;
        Ok(self.position)
    }
}
