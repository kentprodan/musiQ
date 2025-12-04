import SwiftUI

struct InboxView: View {
    @ObservedObject var inboxManager = InboxManager.shared
    @ObservedObject var audioEngine = AudioEngine.shared
    @State private var isDraggingOver = false
    @State private var showImportProgress = false
    @State private var importingItem: InboxItem?
    @State private var importProgress: (current: Int, total: Int, track: String) = (0, 0, "")
    @State private var selectedItem: InboxItem?
    @State private var searchText: String = ""
    
    var filteredTracks: [InboxTrack] {
        guard let selectedItem = selectedItem else { return [] }
        let tracks = inboxManager.getTracks(for: selectedItem.id)
        
        if searchText.isEmpty {
            return tracks
        } else {
            return tracks.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.artist.localizedCaseInsensitiveContains(searchText) ||
                $0.album.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Inbox")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.primary)
                    
                    if let selectedItem = selectedItem {
                        Text("\(filteredTracks.count) track\(filteredTracks.count == 1 ? "" : "s") in \(selectedItem.folderName)")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    } else {
                        Text("\(inboxManager.inboxItems.count) pending import\(inboxManager.inboxItems.count == 1 ? "" : "s")")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Search box when viewing tracks
                if selectedItem != nil {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                            .font(.system(size: 13))
                        
                        TextField("Search tracks...", text: $searchText)
                            .textFieldStyle(.plain)
                            .frame(width: 200)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                }
                
                if selectedItem != nil {
                    Button("Back to Folders") {
                        selectedItem = nil
                        searchText = ""
                    }
                    .buttonStyle(SecondaryButtonStyle())
                } else if !inboxManager.inboxItems.isEmpty {
                    Button("Clear All") {
                        inboxManager.clearAll()
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 16)
            
            Divider()
            
            // Content
            if inboxManager.inboxItems.isEmpty {
                emptyState
            } else if let selectedItem = selectedItem {
                // Show tracks for selected folder
                InboxTracksTable(tracks: filteredTracks, onPlay: { track in
                    print("🎵 InboxView: Double-clicked track: \(track.title)")
                    print("📁 File URL: \(track.fileURL.path)")
                    let playTrack = track.toTrack()
                    print("🔄 Converted track - ID: \(playTrack.id), Title: \(playTrack.title), FileURL: \(playTrack.fileURL?.path ?? "nil")")
                    audioEngine.play(track: playTrack)
                })
            } else {
                // Show folder list
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(inboxManager.inboxItems) { item in
                            InboxItemRow(item: item, onSelect: {
                                selectedItem = item
                            }, onImport: {
                                importingItem = item
                                showImportProgress = true
                                inboxManager.importItem(item, progressHandler: { current, total, track in
                                    importProgress = (current, total, track)
                                }, completion: { success in
                                    showImportProgress = false
                                    importingItem = nil
                                })
                            }, onRemove: {
                                inboxManager.removeItem(item)
                            })
                        }
                    }
                    .padding(24)
                }
            }
        }
        .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
        .onDrop(of: ["public.file-url"], isTargeted: $isDraggingOver) { providers in
            handleDrop(providers: providers)
        }
        .overlay(
            Group {
                if isDraggingOver {
                    dropOverlay
                }
            }
        )
        .sheet(isPresented: $showImportProgress) {
            if let item = importingItem {
                ImportProgressSheet(
                    item: item,
                    currentFile: importProgress.current,
                    totalFiles: importProgress.total,
                    currentTrack: importProgress.track
                )
            }
        }
    }
    
    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "tray.fill")
                .font(.system(size: 64))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            VStack(spacing: 8) {
                Text("Inbox is Empty")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text("Drag and drop music folders here to add them to your inbox")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 400)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Drop Overlay
    private var dropOverlay: some View {
        ZStack {
            Color.blue.opacity(0.1)
            
            VStack(spacing: 16) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.blue)
                
                Text("Drop folder to add to inbox")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    style: StrokeStyle(lineWidth: 3, dash: [10])
                )
                .foregroundColor(.blue)
                .padding(24)
        )
    }
    
    // MARK: - Drop Handler
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { (item, error) in
                guard let data = item as? Data,
                      let url = URL(dataRepresentation: data, relativeTo: nil) else {
                    return
                }
                
                DispatchQueue.main.async {
                    var isDirectory: ObjCBool = false
                    if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory),
                       isDirectory.boolValue {
                        inboxManager.addFolder(url)
                    }
                }
            }
        }
        return true
    }
}

// MARK: - Inbox Tracks Table
struct InboxTracksTable: View {
    let tracks: [InboxTrack]
    let onPlay: (InboxTrack) -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Table Header
                HStack(spacing: 0) {
                    Text("Title")
                        .frame(width: 250, alignment: .leading)
                    Text("Artist")
                        .frame(width: 200, alignment: .leading)
                    Text("Album")
                        .frame(width: 200, alignment: .leading)
                    Text("Duration")
                        .frame(width: 80, alignment: .trailing)
                    Text("Format")
                        .frame(width: 80, alignment: .leading)
                    Text("Size")
                        .frame(width: 100, alignment: .trailing)
                }
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                
                Divider()
                
                // Tracks
                ForEach(Array(tracks.enumerated()), id: \.element.id) { index, track in
                    InboxTrackRow(track: track, index: index, onPlay: {
                        onPlay(track)
                    })
                }
            }
        }
    }
}

// MARK: - Inbox Track Row
struct InboxTrackRow: View {
    let track: InboxTrack
    let index: Int
    let onPlay: () -> Void
    @State private var isHovering = false
    
    var body: some View {
        HStack(spacing: 0) {
            Text(track.title)
                .frame(width: 250, alignment: .leading)
                .lineLimit(1)
                .truncationMode(.tail)
            
            Text(track.artist)
                .frame(width: 200, alignment: .leading)
                .lineLimit(1)
                .truncationMode(.tail)
            
            Text(track.album)
                .frame(width: 200, alignment: .leading)
                .lineLimit(1)
                .truncationMode(.tail)
            
            Text(track.formattedDuration)
                .frame(width: 80, alignment: .trailing)
            
            Text(track.format)
                .frame(width: 80, alignment: .leading)
            
            Text(track.formattedFileSize)
                .frame(width: 100, alignment: .trailing)
        }
        .font(.system(size: 13))
        .foregroundColor(.primary)
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(
            Group {
                if isHovering {
                    Color.blue.opacity(0.1)
                } else if index % 2 == 0 {
                    Color(NSColor.controlBackgroundColor).opacity(0.3)
                } else {
                    Color.clear
                }
            }
        )
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            onPlay()
        }
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

// MARK: - Inbox Item Row
struct InboxItemRow: View {
    let item: InboxItem
    let onSelect: () -> Void
    let onImport: () -> Void
    let onRemove: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(statusColor.opacity(0.15))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: statusIcon)
                        .font(.system(size: 20))
                        .foregroundColor(statusColor)
                }
                
                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.folderName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 12) {
                        if let trackCount = item.trackCount {
                            Label("\(trackCount) track\(trackCount == 1 ? "" : "s")", systemImage: "music.note")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        
                        if let totalSize = item.totalSize {
                            Label(InboxManager.shared.formatSize(totalSize), systemImage: "internaldrive")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        
                        Text(item.status.rawValue)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(statusColor)
                    }
                }
                
                Spacer()
                
                // Actions
                HStack(spacing: 8) {
                    if item.status == .ready {
                        Button("View Tracks") {
                            onSelect()
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        
                        Button("Import All") {
                            onImport()
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }
                    
                    if item.status != .importing {
                        Button(action: onRemove) {
                            Image(systemName: "trash")
                                .font(.system(size: 14))
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    if item.status == .scanning || item.status == .importing {
                        ProgressView()
                            .scaleEffect(0.7)
                    }
                }
            }
            .padding(16)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    private var statusColor: Color {
        switch item.status {
        case .pending: return .gray
        case .scanning: return .blue
        case .ready: return .green
        case .importing: return .blue
        case .failed: return .red
        }
    }
    
    private var statusIcon: String {
        switch item.status {
        case .pending: return "clock"
        case .scanning: return "magnifyingglass"
        case .ready: return "checkmark.circle.fill"
        case .importing: return "arrow.down.circle.fill"
        case .failed: return "exclamationmark.triangle.fill"
        }
    }
}

// MARK: - Import Progress Sheet
struct ImportProgressSheet: View {
    let item: InboxItem
    let currentFile: Int
    let totalFiles: Int
    let currentTrack: String
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "arrow.down.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(.blue)
            
            VStack(spacing: 8) {
                Text("Importing \(item.folderName)")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text("\(currentFile) of \(totalFiles) tracks")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                
                if !currentTrack.isEmpty {
                    Text(currentTrack)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .frame(width: 300)
                }
            }
            
            ProgressView(value: Double(currentFile), total: Double(totalFiles))
                .progressViewStyle(.linear)
                .frame(width: 300)
        }
        .padding(40)
        .frame(width: 400, height: 300)
    }
}

#Preview {
    InboxView()
}
