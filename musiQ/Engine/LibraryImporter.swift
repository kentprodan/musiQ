import Foundation
import AVFoundation

/// Scans directories and imports music files into the database
class LibraryImporter {
    static let shared = LibraryImporter()
    
    // MARK: - Properties
    private var isImporting = false
    private let supportedExtensions = ["mp3", "flac", "wav", "aiff", "m4a", "ogg", "opus", "dsd", "dsf", "dff", "ape", "wv"]
    
    // Progress callback: (currentFile, totalFiles, currentTrack)
    typealias ProgressHandler = (Int, Int, String) -> Void
    
    // MARK: - Import
    func importFolder(at url: URL, progressHandler: ProgressHandler? = nil, completion: @escaping (Result<Int, Error>) -> Void) {
        guard !isImporting else {
            completion(.failure(ImportError.importInProgress))
            return
        }
        
        isImporting = true
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            do {
                // 1. Find all audio files
                let files = try self.findAudioFiles(in: url)
                print("🔍 Found \(files.count) audio files")
                
                var importedCount = 0
                var tracks: [TrackRecord] = []
                
                // 2. Extract metadata from each file
                for (index, fileURL) in files.enumerated() {
                    autoreleasepool {
                        let fileName = fileURL.lastPathComponent
                        progressHandler?(index + 1, files.count, fileName)
                        
                        if let track = self.extractMetadata(from: fileURL) {
                            tracks.append(track)
                            importedCount += 1
                            
                            // Batch insert every 100 tracks
                            if tracks.count >= 100 {
                                do {
                                    try DatabaseManager.shared.addTracks(tracks)
                                    print("📝 Batch inserted \(tracks.count) tracks")
                                } catch {
                                    print("❌ Batch insert failed: \(error)")
                                }
                                tracks.removeAll()
                                
                                // Notify UI
                                DispatchQueue.main.async {
                                    NotificationCenter.default.post(name: .databaseDidChange, object: nil)
                                }
                            }
                        } else {
                            print("⚠️ Skipped (no duration/metadata): \(fileURL.lastPathComponent)")
                        }
                    }
                }
                
                // 3. Insert remaining tracks
                if !tracks.isEmpty {
                    do {
                        try DatabaseManager.shared.addTracks(tracks)
                        print("📝 Final batch inserted \(tracks.count) tracks")
                    } catch {
                        print("❌ Final batch insert failed: \(error)")
                    }
                    
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: .databaseDidChange, object: nil)
                    }
                }
                
                self.isImporting = false
                
                DispatchQueue.main.async {
                    completion(.success(importedCount))
                }
                
                print("✅ Imported \(importedCount) tracks")
                
            } catch {
                self.isImporting = false
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    // MARK: - File Discovery
    private func findAudioFiles(in directory: URL) throws -> [URL] {
        let fileManager = FileManager.default
        var isDirectory: ObjCBool = false
        if fileManager.fileExists(atPath: directory.path, isDirectory: &isDirectory) {
            // If a single file URL was provided, return it when supported
            if !isDirectory.boolValue {
                let ext = directory.pathExtension.lowercased()
                return supportedExtensions.contains(ext) ? [directory] : []
            }
        }

        var audioFiles: [URL] = []

        guard let enumerator = fileManager.enumerator(
            at: directory,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else {
            throw ImportError.cannotAccessDirectory
        }
        
        for case let fileURL as URL in enumerator {
            let fileExtension = fileURL.pathExtension.lowercased()
            if supportedExtensions.contains(fileExtension) {
                audioFiles.append(fileURL)
            }
        }
        
        return audioFiles
    }
    
    // MARK: - Metadata Extraction
    private func extractMetadata(from url: URL) -> TrackRecord? {
        let asset = AVURLAsset(url: url)
        
        // Basic file info
        let fileAttributes = try? FileManager.default.attributesOfItem(atPath: url.path)
        let fileSize = fileAttributes?[.size] as? Int64 ?? 0
        let fileExtension = url.pathExtension.lowercased()
        
        // Duration
        let duration = CMTimeGetSeconds(asset.duration)
        guard duration.isFinite, duration > 0 else { return nil }
        
        // Extract metadata
        let metadata = asset.metadata
        
        let title = extractString(from: metadata, key: .commonKeyTitle) ?? url.deletingPathExtension().lastPathComponent
        let artist = extractString(from: metadata, key: .commonKeyArtist) ?? "Unknown Artist"
        let album = extractString(from: metadata, key: .commonKeyAlbumName) ?? "Unknown Album"
        let albumArtist = extractString(from: metadata, key: .iTunesMetadataKeyAlbumArtist)
        let genre = extractString(from: metadata, key: .iTunesMetadataKeyGenreID) ?? extractString(from: metadata, key: .commonKeyType)
        
        // Track number
        let trackNumberString = extractString(from: metadata, key: .iTunesMetadataKeyTrackNumber)
        let trackNumber = trackNumberString != nil ? Int(trackNumberString!) : nil
        
        // Disc number
        let discNumberString = extractString(from: metadata, key: .iTunesMetadataKeyDiscNumber)
        let discNumber = discNumberString != nil ? Int(discNumberString!) : nil
        
        // Year
        let dateString = extractString(from: metadata, key: .commonKeyCreationDate)
        let year = extractYear(from: dateString)
        
        // Audio properties
        let tracks = asset.tracks(withMediaType: .audio)
        var bitrate: Int?
        var sampleRate: Int?
        
        if let audioTrack = tracks.first {
            bitrate = Int(audioTrack.estimatedDataRate)
            
            if let formatDescriptions = audioTrack.formatDescriptions as? [CMFormatDescription],
               let formatDescription = formatDescriptions.first {
                let audioStreamBasicDescription = CMAudioFormatDescriptionGetStreamBasicDescription(formatDescription)
                if let asbd = audioStreamBasicDescription {
                    sampleRate = Int(asbd.pointee.mSampleRate)
                }
            }
        }
        
        return TrackRecord(
            id: nil,
            title: title,
            artist: artist,
            album: album,
            albumArtist: albumArtist,
            genre: genre,
            year: year,
            trackNumber: trackNumber,
            discNumber: discNumber,
            duration: duration,
            bitrate: bitrate,
            sampleRate: sampleRate,
            format: fileExtension,
            fileURL: url.path,
            fileSize: fileSize,
            dateAdded: Date(),
            dateModified: fileAttributes?[.modificationDate] as? Date,
            playCount: 0,
            rating: 0,
            lastPlayed: nil
        )
    }
    
    // MARK: - Metadata Helpers
    private func extractString(from metadata: [AVMetadataItem], key: AVMetadataKey) -> String? {
        let items = AVMetadataItem.metadataItems(from: metadata, filteredByIdentifier: AVMetadataIdentifier(rawValue: key.rawValue))
        return items.first?.stringValue?.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func extractYear(from dateString: String?) -> Int? {
        guard let dateString = dateString else { return nil }
        
        // Try to extract 4-digit year
        let yearPattern = "\\d{4}"
        if let regex = try? NSRegularExpression(pattern: yearPattern),
           let match = regex.firstMatch(in: dateString, range: NSRange(dateString.startIndex..., in: dateString)),
           let range = Range(match.range, in: dateString) {
            return Int(dateString[range])
        }
        
        return nil
    }
}

// MARK: - Import Error
enum ImportError: LocalizedError {
    case importInProgress
    case cannotAccessDirectory
    case noFilesFound
    
    var errorDescription: String? {
        switch self {
        case .importInProgress:
            return "An import operation is already in progress"
        case .cannotAccessDirectory:
            return "Cannot access the specified directory"
        case .noFilesFound:
            return "No audio files found in the specified directory"
        }
    }
}
