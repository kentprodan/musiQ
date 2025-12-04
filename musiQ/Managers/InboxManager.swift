import Foundation
import Combine
import AVFoundation

/// Manages the inbox for pending music imports
class InboxManager: ObservableObject {
    static let shared = InboxManager()
    
    @Published var inboxItems: [InboxItem] = []
    @Published var inboxTracks: [InboxTrack] = []
    
    private let inboxURL: URL
    private let metadataURL: URL
    private let fileManager = FileManager.default
    
    // MARK: - Initialization
    private init() {
        // Get inbox location from settings or use default
        let libraryLocation = SettingsManager.shared.libraryLocation
        let baseURL = libraryLocation ?? fileManager.urls(for: .musicDirectory, in: .userDomainMask).first!
        
        inboxURL = baseURL.appendingPathComponent("musiQ Inbox", isDirectory: true)
        metadataURL = inboxURL.appendingPathComponent(".inbox_metadata.json")
        
        // Create inbox directory
        try? fileManager.createDirectory(at: inboxURL, withIntermediateDirectories: true)
        
        // Load existing inbox items
        loadInboxItems()
    }
    
    // MARK: - Add to Inbox
    func addFolder(_ sourceURL: URL) {
        // Create inbox item
        var item = InboxItem(folderURL: sourceURL)
        
        // Start scanning in background
        item.status = .scanning
        inboxItems.append(item)
        saveInboxItems()
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let (trackCount, totalSize, tracks) = self?.scanFolderWithMetadata(sourceURL, itemId: item.id) ?? (0, 0, [])
            
            DispatchQueue.main.async {
                if let index = self?.inboxItems.firstIndex(where: { $0.id == item.id }) {
                    self?.inboxItems[index].trackCount = trackCount
                    self?.inboxItems[index].totalSize = totalSize
                    self?.inboxItems[index].status = trackCount > 0 ? .ready : .failed
                    self?.saveInboxItems()
                    
                    // Add tracks to inbox tracks list
                    self?.inboxTracks.append(contentsOf: tracks)
                }
            }
        }
        
        print("📥 Added to inbox: \(sourceURL.lastPathComponent)")
    }
    
    // MARK: - Scan Folder with Metadata Extraction
    private func scanFolderWithMetadata(_ url: URL, itemId: UUID) -> (trackCount: Int, totalSize: Int64, tracks: [InboxTrack]) {
        let audioExtensions = ["mp3", "flac", "wav", "aiff", "m4a", "ogg", "opus", "dsd", "dsf", "dff", "ape", "wv"]
        var trackCount = 0
        var totalSize: Int64 = 0
        var tracks: [InboxTrack] = []
        
        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey],
            options: [.skipsHiddenFiles]
        ) else {
            return (0, 0, [])
        }
        
        for case let fileURL as URL in enumerator {
            guard let resourceValues = try? fileURL.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey]),
                  let isRegularFile = resourceValues.isRegularFile,
                  isRegularFile else {
                continue
            }
            
            let fileExtension = fileURL.pathExtension.lowercased()
            if audioExtensions.contains(fileExtension) {
                trackCount += 1
                if let fileSize = resourceValues.fileSize {
                    totalSize += Int64(fileSize)
                }
                
                // Extract metadata
                if let track = extractTrackMetadata(from: fileURL, inboxItemId: itemId) {
                    tracks.append(track)
                }
            }
        }
        
        return (trackCount, totalSize, tracks)
    }
    
    // MARK: - Extract Track Metadata
    private func extractTrackMetadata(from url: URL, inboxItemId: UUID) -> InboxTrack? {
        let asset = AVURLAsset(url: url)
        
        // Get duration
        let duration = CMTimeGetSeconds(asset.duration)
        guard duration.isFinite, duration > 0 else { return nil }
        
        // Extract metadata
        var title = url.deletingPathExtension().lastPathComponent
        var artist = "Unknown Artist"
        var album = "Unknown Album"
        var genre: String?
        var year: Int?
        var trackNumber: Int?
        
        for format in asset.availableMetadataFormats {
            let metadata = asset.metadata(forFormat: format)
            
            for item in metadata {
                guard let key = item.commonKey?.rawValue,
                      let value = item.value else { continue }
                
                switch key {
                case "title":
                    if let titleValue = value as? String, !titleValue.isEmpty {
                        title = titleValue
                    }
                case "artist":
                    if let artistValue = value as? String, !artistValue.isEmpty {
                        artist = artistValue
                    }
                case "albumName":
                    if let albumValue = value as? String, !albumValue.isEmpty {
                        album = albumValue
                    }
                case "type":
                    if let genreValue = value as? String, !genreValue.isEmpty {
                        genre = genreValue
                    }
                case "creationDate":
                    if let dateString = value as? String {
                        year = Int(dateString.prefix(4))
                    }
                default:
                    break
                }
            }
        }
        
        // Get file info
        let fileSize = try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int64
        let format = url.pathExtension.uppercased()
        
        return InboxTrack(
            inboxItemId: inboxItemId,
            fileURL: url,
            title: title,
            artist: artist,
            album: album,
            duration: duration,
            genre: genre,
            year: year,
            trackNumber: trackNumber,
            format: format,
            fileSize: fileSize ?? 0
        )
    }
    
    // MARK: - Import from Inbox
    func importItem(_ item: InboxItem, progressHandler: ((Int, Int, String) -> Void)? = nil, completion: @escaping (Bool) -> Void) {
        guard let index = inboxItems.firstIndex(where: { $0.id == item.id }) else {
            completion(false)
            return
        }
        
        inboxItems[index].status = .importing
        saveInboxItems()
        
        // Use LibraryImporter to import the folder
        LibraryImporter.shared.importFolder(at: item.folderURL, progressHandler: progressHandler) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let count):
                    // Remove from inbox after successful import
                    self?.removeItem(item)
                    print("✅ Successfully imported \(count) tracks from: \(item.folderName)")
                    completion(true)
                    
                case .failure(let error):
                    // Mark as failed
                    if let index = self?.inboxItems.firstIndex(where: { $0.id == item.id }) {
                        self?.inboxItems[index].status = .failed
                        self?.saveInboxItems()
                    }
                    print("❌ Failed to import: \(item.folderName) - \(error.localizedDescription)")
                    completion(false)
                }
            }
        }
    }
    
    // MARK: - Remove from Inbox
    func removeItem(_ item: InboxItem) {
        inboxItems.removeAll { $0.id == item.id }
        inboxTracks.removeAll { $0.inboxItemId == item.id }
        saveInboxItems()
        print("🗑️ Removed from inbox: \(item.folderName)")
    }
    
    // MARK: - Get Tracks for Item
    func getTracks(for itemId: UUID) -> [InboxTrack] {
        return inboxTracks.filter { $0.inboxItemId == itemId }
    }
    
    // MARK: - Clear All
    func clearAll() {
        inboxItems.removeAll()
        saveInboxItems()
        print("🗑️ Cleared inbox")
    }
    
    // MARK: - Persistence
    private func loadInboxItems() {
        guard fileManager.fileExists(atPath: metadataURL.path),
              let data = try? Data(contentsOf: metadataURL),
              let items = try? JSONDecoder().decode([InboxItem].self, from: data) else {
            return
        }
        
        inboxItems = items
        print("📥 Loaded \(items.count) inbox items")
    }
    
    private func saveInboxItems() {
        guard let data = try? JSONEncoder().encode(inboxItems) else {
            return
        }
        
        try? data.write(to: metadataURL)
    }
    
    // MARK: - Utilities
    func formatSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
