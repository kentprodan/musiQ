import Foundation
import GRDB

/// Track database record
struct TrackRecord: Codable, FetchableRecord, PersistableRecord, Identifiable {
    var id: Int64?
    var title: String
    var artist: String
    var album: String
    var albumArtist: String?
    var genre: String?
    var year: Int?
    var trackNumber: Int?
    var discNumber: Int?
    var duration: TimeInterval
    var bitrate: Int?
    var sampleRate: Int?
    var format: String
    var fileURL: String
    var fileSize: Int64?
    var dateAdded: Date
    var dateModified: Date?
    var playCount: Int
    var rating: Int
    var lastPlayed: Date?
    
    // Table definition
    static let databaseTableName = "tracks"
    
    // Convert to Track for AudioEngine
    func toTrack() -> Track {
        Track(
            id: id ?? 0,
            title: title,
            artist: artist,
            album: album,
            duration: duration,
            fileURL: URL(string: fileURL),
            bitrate: bitrate ?? 0,
            sampleRate: sampleRate ?? 0,
            format: format
        )
    }
}

/// Album database record
struct AlbumRecord: Codable, FetchableRecord, PersistableRecord {
    var id: Int64?
    var title: String
    var artist: String
    var year: Int?
    var genre: String?
    var artworkPath: String?
    var trackCount: Int
    
    static let databaseTableName = "albums"
}

/// Artist database record
struct ArtistRecord: Codable, FetchableRecord, PersistableRecord {
    var id: Int64?
    var name: String
    var sortName: String?
    var albumCount: Int
    var trackCount: Int
    
    static let databaseTableName = "artists"
}

/// Playlist database record
struct PlaylistRecord: Codable, FetchableRecord, PersistableRecord {
    var id: Int64?
    var name: String
    var dateCreated: Date
    var dateModified: Date?
    var trackCount: Int
    
    static let databaseTableName = "playlists"
}

/// PlaylistTrack junction record
struct PlaylistTrackRecord: Codable, FetchableRecord, PersistableRecord {
    var playlistId: Int64
    var trackId: Int64
    var position: Int
    
    static let databaseTableName = "playlistTracks"
}
