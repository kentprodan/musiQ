import Foundation
import GRDB

/// Database manager for music library
/// Uses GRDB for type-safe, high-performance SQLite access
class DatabaseManager {
    static let shared = DatabaseManager()
    
    private var dbQueue: DatabaseQueue?
    private let databaseURL: URL
    
    // MARK: - Initialization
    private init() {
        // Get database path from settings manager
        let dbPath = SettingsManager.shared.getDatabasePath()
        databaseURL = URL(fileURLWithPath: dbPath)
        
        // Create directory if needed
        let dbDirectory = databaseURL.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: dbDirectory, withIntermediateDirectories: true)
        
        setupDatabase()
    }
    
    // MARK: - Database Setup
    private func setupDatabase() {
        do {
            dbQueue = try DatabaseQueue(path: databaseURL.path)
            try migrator.migrate(dbQueue!)
            print("💾 Database initialized at: \(databaseURL.path)")
        } catch {
            print("❌ Database initialization failed: \(error)")
        }
    }
    
    // MARK: - Migrations
    private var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()
        
        // v1: Initial schema
        migrator.registerMigration("v1_initial_schema") { db in
            // Tracks table
            try db.create(table: "tracks") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("title", .text).notNull()
                t.column("artist", .text).notNull()
                t.column("album", .text).notNull()
                t.column("albumArtist", .text)
                t.column("genre", .text)
                t.column("year", .integer)
                t.column("trackNumber", .integer)
                t.column("discNumber", .integer)
                t.column("duration", .double).notNull()
                t.column("bitrate", .integer)
                t.column("sampleRate", .integer)
                t.column("format", .text).notNull()
                t.column("fileURL", .text).notNull().unique()
                t.column("fileSize", .integer)
                t.column("dateAdded", .datetime).notNull()
                t.column("dateModified", .datetime)
                t.column("playCount", .integer).notNull().defaults(to: 0)
                t.column("rating", .integer).defaults(to: 0)
                t.column("lastPlayed", .datetime)
            }
            
            // Albums table
            try db.create(table: "albums") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("title", .text).notNull()
                t.column("artist", .text).notNull()
                t.column("year", .integer)
                t.column("genre", .text)
                t.column("artworkPath", .text)
                t.column("trackCount", .integer).notNull().defaults(to: 0)
            }
            
            // Artists table
            try db.create(table: "artists") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("name", .text).notNull().unique()
                t.column("sortName", .text)
                t.column("albumCount", .integer).notNull().defaults(to: 0)
                t.column("trackCount", .integer).notNull().defaults(to: 0)
            }
            
            // Playlists table
            try db.create(table: "playlists") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("name", .text).notNull()
                t.column("dateCreated", .datetime).notNull()
                t.column("dateModified", .datetime)
                t.column("trackCount", .integer).notNull().defaults(to: 0)
            }
            
            // PlaylistTracks junction table
            try db.create(table: "playlistTracks") { t in
                t.column("playlistId", .integer).notNull().references("playlists", onDelete: .cascade)
                t.column("trackId", .integer).notNull().references("tracks", onDelete: .cascade)
                t.column("position", .integer).notNull()
                t.primaryKey(["playlistId", "trackId"])
            }
            
            // Indexes for performance
            try db.create(index: "idx_tracks_artist", on: "tracks", columns: ["artist"])
            try db.create(index: "idx_tracks_album", on: "tracks", columns: ["album"])
            try db.create(index: "idx_tracks_genre", on: "tracks", columns: ["genre"])
            try db.create(index: "idx_tracks_dateAdded", on: "tracks", columns: ["dateAdded"])
            try db.create(index: "idx_albums_artist", on: "albums", columns: ["artist"])
            try db.create(index: "idx_playlistTracks_playlist", on: "playlistTracks", columns: ["playlistId"])
        }
        
        return migrator
    }
    
    // MARK: - Track Operations
    func addTrack(_ track: TrackRecord) throws {
        try dbQueue?.write { db in
            try track.insert(db)
        }
    }
    
    func updateTrack(_ track: TrackRecord) throws {
        try dbQueue?.write { db in
            try track.update(db)
        }
    }
    
    func deleteTrack(id: Int64) throws {
        try dbQueue?.write { db in
            try TrackRecord.deleteOne(db, key: id)
        }
    }
    
    func getAllTracks() throws -> [TrackRecord] {
        guard let dbQueue = dbQueue else { return [] }
        return try dbQueue.read { db in
            try TrackRecord.fetchAll(db)
        }
    }
    
    func searchTracks(query: String) throws -> [TrackRecord] {
        guard let dbQueue = dbQueue else { return [] }
        let pattern = "%\(query)%"
        return try dbQueue.read { db in
            try TrackRecord
                .filter(Column("title").like(pattern) ||
                       Column("artist").like(pattern) ||
                       Column("album").like(pattern))
                .fetchAll(db)
        }
    }
    
    func getTracksByArtist(_ artist: String) throws -> [TrackRecord] {
        guard let dbQueue = dbQueue else { return [] }
        return try dbQueue.read { db in
            try TrackRecord.filter(Column("artist") == artist).fetchAll(db)
        }
    }
    
    func getTracksByAlbum(_ album: String) throws -> [TrackRecord] {
        guard let dbQueue = dbQueue else { return [] }
        return try dbQueue.read { db in
            try TrackRecord.filter(Column("album") == album).fetchAll(db)
        }
    }
    
    // MARK: - Recently Added
    func getRecentlyAddedTracks(limit: Int = 100) throws -> [TrackRecord] {
        guard let dbQueue = dbQueue else { return [] }
        return try dbQueue.read { db in
            try TrackRecord
                .order(Column("dateAdded").desc)
                .limit(limit)
                .fetchAll(db)
        }
    }
    
    // MARK: - Artists & Albums
    func getAllArtists() throws -> [(artist: String, trackCount: Int)] {
        guard let dbQueue = dbQueue else { return [] }
        return try dbQueue.read { db in
            let rows = try Row.fetchAll(db, sql: """
                SELECT artist, COUNT(*) as count
                FROM tracks
                GROUP BY artist
                ORDER BY artist
            """)
            return rows.map { ($0["artist"] as String, $0["count"] as Int) }
        }
    }
    
    func getAllAlbums() throws -> [(album: String, artist: String, trackCount: Int, year: Int?)] {
        guard let dbQueue = dbQueue else { return [] }
        return try dbQueue.read { db in
            let rows = try Row.fetchAll(db, sql: """
                SELECT album, artist, COUNT(*) as count, year
                FROM tracks
                GROUP BY album, artist
                ORDER BY artist, album
            """)
            return rows.map { 
                ($0["album"] as String, 
                 $0["artist"] as String, 
                 $0["count"] as Int,
                 $0["year"] as Int?)
            }
        }
    }
    
    // MARK: - Statistics
    func getTotalTrackCount() throws -> Int {
        guard let dbQueue = dbQueue else { return 0 }
        return try dbQueue.read { db in
            try TrackRecord.fetchCount(db)
        }
    }
    
    func getTotalDuration() throws -> TimeInterval {
        guard let dbQueue = dbQueue else { return 0 }
        return try dbQueue.read { db in
            try Double.fetchOne(db, sql: "SELECT SUM(duration) FROM tracks") ?? 0
        }
    }
    
    // MARK: - Batch Operations
    func addTracks(_ tracks: [TrackRecord], progressHandler: ((Int, Int) -> Void)? = nil) throws {
        guard let dbQueue = dbQueue else {
            print("❌ Database queue is nil, cannot add tracks")
            throw NSError(domain: "DatabaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Database not initialized"])
        }
        
        print("📥 Adding \(tracks.count) tracks to database at: \(databaseURL.path)")
        
        try dbQueue.write { db in
            for (index, track) in tracks.enumerated() {
                try track.insert(db)
                progressHandler?(index + 1, tracks.count)
            }
        }
        
        // Verify tracks were added
        let totalCount = try getAllTracks().count
        print("✅ Database now contains \(totalCount) total tracks")
    }
}
