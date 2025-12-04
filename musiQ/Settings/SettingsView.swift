import SwiftUI
import AppKit

struct SettingsView: View {
    @ObservedObject var settingsManager = SettingsManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab: SettingsTab = .general
    @State private var tempLibraryLocation: URL?
    @State private var tempMusicLocation: URL?
    @State private var tempShouldCopyMusic: Bool = false
    @State private var showResetAlert: Bool = false
    @State private var hasChanges: Bool = false
    
    enum SettingsTab: String, CaseIterable {
        case general = "General"
        case library = "Library"
        case playback = "Playback"
        case advanced = "Advanced"
        
        var icon: String {
            switch self {
            case .general: return "gearshape.fill"
            case .library: return "music.note.house.fill"
            case .playback: return "play.circle.fill"
            case .advanced: return "slider.horizontal.3"
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Sidebar
            VStack(alignment: .leading, spacing: 0) {
                // Header
                Text("Settings")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 16)
                
                // Tabs
                ForEach(SettingsTab.allCases, id: \.self) { tab in
                    Button(action: { selectedTab = tab }) {
                        HStack(spacing: 12) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 16))
                                .foregroundColor(selectedTab == tab ? .white : .white.opacity(0.6))
                                .frame(width: 24)
                            
                            Text(tab.rawValue)
                                .font(.system(size: 14, weight: selectedTab == tab ? .semibold : .regular))
                                .foregroundColor(selectedTab == tab ? .white : .white.opacity(0.7))
                            
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            selectedTab == tab ?
                            Color.white.opacity(0.15) :
                            Color.clear
                        )
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 12)
                }
                
                Spacer()
            }
            .frame(width: 200)
            .background(Color.black.opacity(0.3))
            
            // Content
            VStack(spacing: 0) {
                // Tab Content
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        switch selectedTab {
                        case .general:
                            generalSettings
                        case .library:
                            librarySettings
                        case .playback:
                            playbackSettings
                        case .advanced:
                            advancedSettings
                        }
                    }
                    .padding(32)
                }
                
                // Bottom bar with action buttons
                if hasChanges {
                    HStack {
                        Button("Reset Changes") {
                            resetChanges()
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        
                        Spacer()
                        
                        Button("Apply") {
                            applyChanges()
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }
                    .padding(16)
                    .background(Color.black.opacity(0.3))
                }
            }
        }
        .frame(width: 800, height: 600)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            loadCurrentSettings()
        }
        .alert("Reset Settings", isPresented: $showResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                settingsManager.resetSettings()
            }
        } message: {
            Text("This will reset all settings to defaults. The app will need to be reconfigured on next launch.")
        }
    }
    
    // MARK: - Settings Sections
    
    private var generalSettings: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("General")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 16) {
                SettingsRow(title: "Application", icon: "app.fill") {
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle("Launch at login", isOn: .constant(false))
                        Toggle("Show menu bar icon", isOn: .constant(true))
                        Toggle("Minimize to menu bar", isOn: .constant(false))
                    }
                }
                
                SettingsRow(title: "Appearance", icon: "paintbrush.fill") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Theme:")
                                .frame(width: 100, alignment: .leading)
                            Picker("", selection: .constant("System")) {
                                Text("System").tag("System")
                                Text("Light").tag("Light")
                                Text("Dark").tag("Dark")
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 200)
                        }
                        
                        Toggle("Show album artwork in sidebar", isOn: .constant(true))
                    }
                }
            }
        }
    }
    
    private var librarySettings: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Library")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 16) {
                SettingsRow(title: "Library Location", icon: "folder.fill") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(tempLibraryLocation?.path ?? "Not set")
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                            
                            Spacer()
                            
                            Button("Change") {
                                selectLibraryLocation()
                            }
                            .buttonStyle(SecondaryButtonStyle())
                        }
                        
                        Text("This is where musiQ stores its database, artwork cache, and optionally music files.")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
                
                SettingsRow(title: "Music Location", icon: "music.note.list") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(tempMusicLocation?.path ?? "Not set")
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                            
                            Spacer()
                            
                            Button("Change") {
                                selectMusicLocation()
                            }
                            .buttonStyle(SecondaryButtonStyle())
                        }
                        
                        Text("The folder where your music files are stored.")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
                
                SettingsRow(title: "Music Management", icon: "square.and.arrow.down") {
                    VStack(alignment: .leading, spacing: 12) {
                        Picker("", selection: $tempShouldCopyMusic) {
                            Text("Read from current location").tag(false)
                            Text("Copy to library folder").tag(true)
                        }
                        .pickerStyle(.radioGroup)
                        .onChange(of: tempShouldCopyMusic) { _, _ in
                            hasChanges = true
                        }
                        
                        if tempShouldCopyMusic {
                            Text("⚠️ Copying large libraries may take significant disk space.")
                                .font(.system(size: 11))
                                .foregroundColor(.orange)
                        } else {
                            Text("Music files will remain in their current location.")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                SettingsRow(title: "Import Settings", icon: "square.and.arrow.down.on.square") {
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle("Watch folder for changes", isOn: .constant(false))
                        Toggle("Organize files by artist/album", isOn: .constant(false))
                        Toggle("Extract embedded artwork", isOn: .constant(true))
                    }
                }
            }
        }
    }
    
    private var playbackSettings: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Playback")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 16) {
                SettingsRow(title: "Audio Output", icon: "speaker.wave.3.fill") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Output Device:")
                                .frame(width: 120, alignment: .leading)
                            Picker("", selection: .constant("Default")) {
                                Text("System Default").tag("Default")
                            }
                            .frame(width: 250)
                        }
                        
                        HStack {
                            Text("Sample Rate:")
                                .frame(width: 120, alignment: .leading)
                            Picker("", selection: .constant("44100")) {
                                Text("44.1 kHz").tag("44100")
                                Text("48 kHz").tag("48000")
                                Text("96 kHz").tag("96000")
                                Text("192 kHz").tag("192000")
                            }
                            .frame(width: 250)
                        }
                        
                        Toggle("Exclusive mode (WASAPI)", isOn: .constant(false))
                        Toggle("Gapless playback", isOn: .constant(true))
                    }
                }
                
                SettingsRow(title: "Crossfade", icon: "waveform") {
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle("Enable crossfade", isOn: .constant(false))
                        
                        HStack {
                            Text("Duration:")
                                .frame(width: 120, alignment: .leading)
                            Slider(value: .constant(5), in: 1...10)
                            Text("5s")
                                .frame(width: 40, alignment: .trailing)
                        }
                    }
                }
                
                SettingsRow(title: "DSP Effects", icon: "slider.horizontal.3") {
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle("Equalizer", isOn: .constant(false))
                        Toggle("Reverb", isOn: .constant(false))
                        Toggle("Normalize volume", isOn: .constant(false))
                    }
                }
            }
        }
    }
    
    private var advancedSettings: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Advanced")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 16) {
                SettingsRow(title: "Database", icon: "cylinder.fill") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Database size:")
                                .frame(width: 140, alignment: .leading)
                            Text(getDatabaseSize())
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Button("Optimize") {
                                optimizeDatabase()
                            }
                            .buttonStyle(SecondaryButtonStyle())
                        }
                        
                        HStack {
                            Text("Cache size:")
                                .frame(width: 140, alignment: .leading)
                            Text("Unknown")
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Button("Clear Cache") {
                                clearCache()
                            }
                            .buttonStyle(SecondaryButtonStyle())
                        }
                    }
                }
                
                SettingsRow(title: "Performance", icon: "speedometer") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Memory cache:")
                                .frame(width: 140, alignment: .leading)
                            Slider(value: .constant(256), in: 64...1024, step: 64)
                            Text("256 MB")
                                .frame(width: 70, alignment: .trailing)
                        }
                        
                        Toggle("Preload next track", isOn: .constant(true))
                        Toggle("Background processing", isOn: .constant(true))
                    }
                }
                
                SettingsRow(title: "Danger Zone", icon: "exclamationmark.triangle.fill") {
                    VStack(alignment: .leading, spacing: 12) {
                        Button("Reset All Settings") {
                            showResetAlert = true
                        }
                        .buttonStyle(DangerButtonStyle())
                        
                        Text("This will reset all settings and require initial setup on next launch.")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func loadCurrentSettings() {
        tempLibraryLocation = settingsManager.libraryLocation
        tempMusicLocation = settingsManager.musicLocation
        tempShouldCopyMusic = settingsManager.shouldCopyMusic
    }
    
    private func selectLibraryLocation() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Choose library location"
        panel.prompt = "Select"
        
        if panel.runModal() == .OK {
            tempLibraryLocation = panel.url
            hasChanges = true
        }
    }
    
    private func selectMusicLocation() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = false
        panel.allowsMultipleSelection = false
        panel.message = "Choose music folder"
        panel.prompt = "Select"
        
        if panel.runModal() == .OK {
            tempMusicLocation = panel.url
            hasChanges = true
        }
    }
    
    private func applyChanges() {
        if let libraryLocation = tempLibraryLocation,
           let musicLocation = tempMusicLocation {
            settingsManager.libraryLocation = libraryLocation
            settingsManager.musicLocation = musicLocation
            settingsManager.shouldCopyMusic = tempShouldCopyMusic
            settingsManager.saveSettings()
            hasChanges = false
            
            print("✅ Settings applied")
        }
    }
    
    private func resetChanges() {
        loadCurrentSettings()
        hasChanges = false
    }
    
    private func getDatabaseSize() -> String {
        let dbPath = settingsManager.getDatabasePath()
        if let attributes = try? FileManager.default.attributesOfItem(atPath: dbPath),
           let size = attributes[.size] as? Int64 {
            let formatter = ByteCountFormatter()
            formatter.allowedUnits = [.useMB, .useKB]
            formatter.countStyle = .file
            return formatter.string(fromByteCount: size)
        }
        return "Unknown"
    }
    
    private func optimizeDatabase() {
        // TODO: Implement database optimization
        print("🔧 Optimizing database...")
    }
    
    private func clearCache() {
        // TODO: Implement cache clearing
        print("🗑️ Clearing cache...")
    }
}

// MARK: - Supporting Views

struct SettingsRow<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(.blue)
                
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
            }
            
            content
                .padding(.leading, 24)
        }
        .padding(16)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
    }
}

struct DangerButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.red.opacity(configuration.isPressed ? 0.8 : 1.0))
            .cornerRadius(6)
    }
}

#Preview {
    SettingsView()
}
