import Foundation
import Combine

/// Manages app settings and preferences
class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    // MARK: - Published Properties
    @Published var libraryLocation: URL?
    @Published var musicLocation: URL?
    @Published var shouldCopyMusic: Bool = false
    @Published var hasCompletedInitialSetup: Bool = false
    
    // MARK: - UserDefaults Keys
    private enum Keys {
        static let libraryLocation = "libraryLocation"
        static let musicLocation = "musicLocation"
        static let shouldCopyMusic = "shouldCopyMusic"
        static let hasCompletedInitialSetup = "hasCompletedInitialSetup"
    }
    
    // MARK: - Initialization
    private init() {
        loadSettings()
    }
    
    // MARK: - Load Settings
    private func loadSettings() {
        // Load library location
        if let libraryPath = UserDefaults.standard.string(forKey: Keys.libraryLocation) {
            libraryLocation = URL(fileURLWithPath: libraryPath)
        }
        
        // Load music location
        if let musicPath = UserDefaults.standard.string(forKey: Keys.musicLocation) {
            musicLocation = URL(fileURLWithPath: musicPath)
        }
        
        // Load preferences
        shouldCopyMusic = UserDefaults.standard.bool(forKey: Keys.shouldCopyMusic)
        hasCompletedInitialSetup = UserDefaults.standard.bool(forKey: Keys.hasCompletedInitialSetup)
    }
    
    // MARK: - Save Settings
    func saveSettings() {
        if let libraryPath = libraryLocation?.path {
            UserDefaults.standard.set(libraryPath, forKey: Keys.libraryLocation)
        }
        
        if let musicPath = musicLocation?.path {
            UserDefaults.standard.set(musicPath, forKey: Keys.musicLocation)
        }
        
        UserDefaults.standard.set(shouldCopyMusic, forKey: Keys.shouldCopyMusic)
        UserDefaults.standard.set(hasCompletedInitialSetup, forKey: Keys.hasCompletedInitialSetup)
        
        UserDefaults.standard.synchronize()
        
        print("💾 Settings saved")
    }
    
    // MARK: - Complete Initial Setup
    func completeInitialSetup(libraryLocation: URL, musicLocation: URL, shouldCopy: Bool) {
        self.libraryLocation = libraryLocation
        self.musicLocation = musicLocation
        self.shouldCopyMusic = shouldCopy
        self.hasCompletedInitialSetup = true
        
        // Create library directory if needed
        createLibraryStructure()
        
        saveSettings()
    }
    
    // MARK: - Library Structure
    private func createLibraryStructure() {
        guard let libraryLocation = libraryLocation else { return }
        
        let fileManager = FileManager.default
        
        // Create main library folder
        try? fileManager.createDirectory(at: libraryLocation, withIntermediateDirectories: true)
        
        // Create subfolders
        let subfolders = ["Music", "Artwork", "Database", "Playlists"]
        for folder in subfolders {
            let folderURL = libraryLocation.appendingPathComponent(folder)
            try? fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true)
        }
        
        print("📁 Library structure created at: \(libraryLocation.path)")
    }
    
    // MARK: - Get Paths
    func getDatabasePath() -> String {
        // Always use Application Support directory for database
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let bundleID = Bundle.main.bundleIdentifier ?? "com.musiQ"
        let appFolder = appSupport.appendingPathComponent(bundleID)
        
        // Create app folder if needed
        try? FileManager.default.createDirectory(at: appFolder, withIntermediateDirectories: true)
        
        return appFolder.appendingPathComponent("musiQ.sqlite").path
    }
    
    func getArtworkPath() -> URL? {
        return libraryLocation?.appendingPathComponent("Artwork")
    }
    
    func getMusicPath() -> URL? {
        if shouldCopyMusic {
            return libraryLocation?.appendingPathComponent("Music")
        } else {
            return musicLocation
        }
    }
    
    // MARK: - Reset Settings
    func resetSettings() {
        libraryLocation = nil
        musicLocation = nil
        shouldCopyMusic = false
        hasCompletedInitialSetup = false
        
        // Clear UserDefaults
        UserDefaults.standard.removeObject(forKey: Keys.libraryLocation)
        UserDefaults.standard.removeObject(forKey: Keys.musicLocation)
        UserDefaults.standard.removeObject(forKey: Keys.shouldCopyMusic)
        UserDefaults.standard.removeObject(forKey: Keys.hasCompletedInitialSetup)
        UserDefaults.standard.synchronize()
        
        print("🔄 Settings reset")
    }
}
