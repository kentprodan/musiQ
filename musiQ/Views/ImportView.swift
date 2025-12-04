import SwiftUI

/// SwiftUI view for importing music library
struct ImportView: View {
    @State private var isImporting = false
    @State private var progress: Double = 0
    @State private var currentFile: String = ""
    @State private var totalFiles: Int = 0
    @State private var currentFileIndex: Int = 0
    @State private var importResult: String = ""
    @State private var showResult = false
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "folder.badge.plus")
                    .font(.system(size: 60))
                    .foregroundColor(.accentColor)
                
                Text("Import Music Library")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Select a folder to scan for audio files")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 40)
            
            Spacer()
            
            // Import button or progress
            if isImporting {
                VStack(spacing: 16) {
                    ProgressView(value: progress)
                        .progressViewStyle(.linear)
                        .frame(width: 300)
                    
                    VStack(spacing: 4) {
                        Text("Importing: \(currentFileIndex) of \(totalFiles)")
                            .font(.headline)
                        
                        Text(currentFile)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .frame(width: 400)
                    }
                    
                    Button("Cancel") {
                        // TODO: Implement cancel
                    }
                    .foregroundColor(.red)
                }
            } else {
                Button(action: selectFolder) {
                    HStack {
                        Image(systemName: "folder.badge.plus")
                        Text("Choose Folder")
                    }
                    .font(.headline)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
            }
            
            Spacer()
            
            // Stats
            if let stats = getLibraryStats() {
                VStack(spacing: 8) {
                    Divider()
                        .padding(.horizontal, 40)
                    
                    HStack(spacing: 40) {
                        StatView(label: "Tracks", value: "\(stats.trackCount)")
                        StatView(label: "Duration", value: formatDuration(stats.totalDuration))
                        StatView(label: "Size", value: "~\(formatFileSize(stats.estimatedSize))")
                    }
                    .padding(.bottom, 20)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .alert("Import Complete", isPresented: $showResult) {
            Button("OK") {
                showResult = false
            }
        } message: {
            Text(importResult)
        }
    }
    
    // MARK: - Actions
    private func selectFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Import"
        panel.message = "Select a folder containing your music files"
        
        if panel.runModal() == .OK, let url = panel.url {
            startImport(from: url)
        }
    }
    
    private func startImport(from url: URL) {
        isImporting = true
        progress = 0
        currentFile = ""
        currentFileIndex = 0
        totalFiles = 0
        
        LibraryImporter.shared.importFolder(at: url, progressHandler: { current, total, filename in
            DispatchQueue.main.async {
                currentFileIndex = current
                totalFiles = total
                currentFile = filename
                progress = Double(current) / Double(total)
            }
        }) { result in
            DispatchQueue.main.async {
                isImporting = false
                
                switch result {
                case .success(let count):
                    importResult = "Successfully imported \(count) tracks"
                    showResult = true
                case .failure(let error):
                    importResult = "Import failed: \(error.localizedDescription)"
                    showResult = true
                }
            }
        }
    }
    
    // MARK: - Stats
    private func getLibraryStats() -> (trackCount: Int, totalDuration: TimeInterval, estimatedSize: Int64)? {
        do {
            let count = try DatabaseManager.shared.getTotalTrackCount()
            guard count > 0 else { return nil }
            
            let duration = try DatabaseManager.shared.getTotalDuration()
            let estimatedSize = Int64(duration * 320000 / 8) // Estimate based on 320kbps
            
            return (count, duration, estimatedSize)
        } catch {
            return nil
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    private func formatFileSize(_ bytes: Int64) -> String {
        let gb = Double(bytes) / 1_073_741_824
        if gb > 1 {
            return String(format: "%.1f GB", gb)
        } else {
            let mb = Double(bytes) / 1_048_576
            return String(format: "%.0f MB", mb)
        }
    }
}

// MARK: - Stat View
struct StatView: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.semibold)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Preview
struct ImportView_Previews: PreviewProvider {
    static var previews: some View {
        ImportView()
            .frame(width: 600, height: 500)
    }
}
