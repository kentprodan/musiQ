import Foundation

/// Represents an item in the inbox (pending import)
struct InboxItem: Identifiable, Codable {
    let id: UUID
    let folderURL: URL
    let folderName: String
    let dateAdded: Date
    var trackCount: Int?
    var totalSize: Int64?
    var status: InboxStatus
    
    init(folderURL: URL) {
        self.id = UUID()
        self.folderURL = folderURL
        self.folderName = folderURL.lastPathComponent
        self.dateAdded = Date()
        self.status = .pending
    }
    
    enum InboxStatus: String, Codable {
        case pending = "Pending"
        case scanning = "Scanning"
        case ready = "Ready"
        case importing = "Importing"
        case failed = "Failed"
    }
}

/// Represents a track in the inbox (with metadata but not yet imported to library)
struct InboxTrack: Identifiable {
    let id = UUID()
    let inboxItemId: UUID
    let fileURL: URL
    let title: String
    let artist: String
    let album: String
    let duration: TimeInterval
    let genre: String?
    let year: Int?
    let trackNumber: Int?
    let format: String
    let fileSize: Int64
    
    // Convert to AudioEngine Track for playback
    func toTrack() -> Track {
        return Track(
            id: 0, // Temporary ID for inbox tracks
            title: title,
            artist: artist,
            album: album,
            duration: duration,
            fileURL: fileURL,
            bitrate: 0, // Unknown for inbox tracks
            sampleRate: 0, // Unknown for inbox tracks
            format: format
        )
    }
    
    // Format duration as MM:SS
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    // Format file size
    var formattedFileSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useKB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }
}
