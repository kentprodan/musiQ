CREATE TABLE artists (
    id          BLOB PRIMARY KEY,
    name        TEXT NOT NULL,
    image_path  TEXT
);

CREATE TABLE albums (
    id              BLOB PRIMARY KEY,
    title           TEXT NOT NULL,
    artist_id       BLOB REFERENCES artists(id) ON DELETE SET NULL,
    year            INTEGER,
    cover_art_path  TEXT
);

CREATE TABLE remote_sources (
    id              BLOB PRIMARY KEY,
    kind            TEXT NOT NULL,
    label           TEXT NOT NULL,
    base_url        TEXT NOT NULL,
    credential_ref  TEXT NOT NULL
);

CREATE TABLE tracks (
    id                      BLOB PRIMARY KEY,
    title                   TEXT NOT NULL,
    artist_id               BLOB REFERENCES artists(id) ON DELETE SET NULL,
    album_id                BLOB REFERENCES albums(id) ON DELETE SET NULL,
    genre                   TEXT,
    track_no                INTEGER,
    disc_no                 INTEGER,
    duration_ms             INTEGER NOT NULL,
    year                    INTEGER,
    file_path               TEXT,
    remote_source_id        BLOB REFERENCES remote_sources(id) ON DELETE CASCADE,
    remote_ref               TEXT,
    bitrate_kbps            INTEGER,
    sample_rate_hz          INTEGER,
    replaygain_track_db     REAL,
    replaygain_album_db     REAL,
    waveform_peaks          BLOB,
    CHECK ((file_path IS NOT NULL) OR (remote_source_id IS NOT NULL))
);

CREATE INDEX idx_tracks_album ON tracks(album_id);
CREATE INDEX idx_tracks_artist ON tracks(artist_id);

CREATE TABLE playlists (
    id           BLOB PRIMARY KEY,
    name         TEXT NOT NULL,
    is_smart     INTEGER NOT NULL DEFAULT 0,
    smart_rules  TEXT
);

CREATE TABLE playlist_tracks (
    playlist_id  BLOB NOT NULL REFERENCES playlists(id) ON DELETE CASCADE,
    track_id     BLOB NOT NULL REFERENCES tracks(id) ON DELETE CASCADE,
    position     INTEGER NOT NULL,
    PRIMARY KEY (playlist_id, track_id)
);

CREATE TABLE watched_folders (
    id     BLOB PRIMARY KEY,
    path   TEXT NOT NULL UNIQUE
);
