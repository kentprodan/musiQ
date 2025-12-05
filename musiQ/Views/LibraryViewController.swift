import Cocoa
import Combine

/// High-performance AppKit-based library view
/// Uses NSTableView to handle 50k+ tracks without breaking a sweat
class LibraryViewController: NSViewController {
    
    // MARK: - UI Components
    private var scrollView: NSScrollView!
    private var tableView: NSTableView!
    
    // MARK: - Data
    private var tracks: [TrackRecord] = []
    private var filteredTracks: [TrackRecord] = []
    private var cancellables = Set<AnyCancellable>()

        // MARK: - Context Menu
        private func setupContextMenu() {
            let menu = NSMenu()
            let deleteItem = NSMenuItem(title: "Delete", action: #selector(deleteSelectedTracks), keyEquivalent: "")
            deleteItem.target = self
            menu.addItem(deleteItem)
            tableView.menu = menu
        }
    
    // MARK: - Columns
    private enum ColumnIdentifier: String {
        case title = "title"
        case artist = "artist"
        case album = "album"
        case duration = "duration"
        case genre = "genre"
        case year = "year"
        case bitrate = "bitrate"
        case format = "format"
        case playCount = "playCount"
        case rating = "rating"
    }
    
    // MARK: - Lifecycle
    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 800, height: 600))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        loadTracks()
        setupObservers()
    }
    
    // MARK: - Setup
    private func setupTableView() {
        // Scroll view
        scrollView = NSScrollView(frame: view.bounds)
        scrollView.autoresizingMask = [.width, .height]
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        
        // Table view
        tableView = NSTableView(frame: scrollView.bounds)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.allowsMultipleSelection = true
        tableView.allowsColumnReordering = true
        tableView.allowsColumnResizing = true
        tableView.usesAlternatingRowBackgroundColors = true
        setupContextMenu()
        tableView.columnAutoresizingStyle = .uniformColumnAutoresizingStyle
        tableView.rowSizeStyle = .default
        tableView.target = self
        tableView.doubleAction = #selector(handleDoubleClick)
        
        // Add columns
        addColumn(identifier: .title, title: "Title", width: 250)
        addColumn(identifier: .artist, title: "Artist", width: 150)
        addColumn(identifier: .album, title: "Album", width: 200)
        addColumn(identifier: .duration, title: "Duration", width: 80)
        addColumn(identifier: .genre, title: "Genre", width: 100)
        addColumn(identifier: .year, title: "Year", width: 60)
        addColumn(identifier: .bitrate, title: "Bitrate", width: 80)
        addColumn(identifier: .format, title: "Format", width: 60)
        addColumn(identifier: .playCount, title: "Plays", width: 60)
        addColumn(identifier: .rating, title: "★", width: 80)
        
        scrollView.documentView = tableView
        view.addSubview(scrollView)
    }
    
    // MARK: - Delete Action
    @objc private func deleteSelectedTracks() {
        let selectedIndexes = tableView.selectedRowIndexes
        guard !selectedIndexes.isEmpty else { return }

        let tracksToDelete = selectedIndexes.compactMap { index -> TrackRecord? in
            guard index < filteredTracks.count else { return nil }
            return filteredTracks[index]
        }

        // Remove from database
        DispatchQueue.global(qos: .userInitiated).async {
            for track in tracksToDelete {
                if let id = track.id {
                    try? DatabaseManager.shared.deleteTrack(id: id)
                }
            }
            DispatchQueue.main.async {
                // Remove from UI
                self.filteredTracks.removeAll { track in
                    tracksToDelete.contains(where: { $0.id == track.id })
                }
                self.tracks.removeAll { track in
                    tracksToDelete.contains(where: { $0.id == track.id })
                }
                self.tableView.reloadData()
                print("🗑️ Deleted \(tracksToDelete.count) track(s) from library and database.")
            }
        }
    }
    
    private func addColumn(identifier: ColumnIdentifier, title: String, width: CGFloat) {
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(identifier.rawValue))
        column.title = title
        column.width = width
        column.minWidth = 40
        column.maxWidth = 600
        column.resizingMask = .userResizingMask
        
        // Sort descriptor
        let descriptor = NSSortDescriptor(key: identifier.rawValue, ascending: true)
        column.sortDescriptorPrototype = descriptor
        
        tableView.addTableColumn(column)
    }
    
    private func setupObservers() {
        // Observe database changes
        NotificationCenter.default.publisher(for: .databaseDidChange)
            .sink { [weak self] _ in
                self?.loadTracks()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Data Loading
    private func loadTracks() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                let allTracks = try DatabaseManager.shared.getAllTracks()
                
                DispatchQueue.main.async {
                    self?.tracks = allTracks
                    self?.filteredTracks = allTracks
                    self?.tableView.reloadData()
                    
                    print("📚 Loaded \(allTracks.count) tracks")
                }
            } catch {
                print("❌ Failed to load tracks: \(error)")
            }
        }
    }
    
    // MARK: - Actions
    @objc private func handleDoubleClick() {
        let row = tableView.clickedRow
        print("[DEBUG] Double-click detected on row: \(row)")
        guard row >= 0 && row < filteredTracks.count else { return }

        let track = filteredTracks[row]
        print("[DEBUG] Playing track: \(track.title)")
        playTrack(track)
    }
    
    private func playTrack(_ track: TrackRecord) {
        let playTrack = track.toTrack()
        guard let fileURL = playTrack.fileURL else {
            print("❌ No file URL for track: \(playTrack.title)")
            return
        }
        let filePath = fileURL.path
        print("📁 LibraryViewController: Playing track - ID: \(playTrack.id), Title: \(playTrack.title), FileURL: \(filePath)")
        let fileExists = FileManager.default.fileExists(atPath: filePath)
        print("📂 File exists at path: \(fileExists)")
        if fileExists {
            AudioEngine.shared.play(track: playTrack)
        } else {
            print("❌ File does not exist at path: \(filePath)")
        }
        
        // Update play count
        var updatedTrack = track
        updatedTrack.playCount += 1
        updatedTrack.lastPlayed = Date()
        
        DispatchQueue.global(qos: .background).async {
            try? DatabaseManager.shared.updateTrack(updatedTrack)
        }
    }
    
    // MARK: - Search
    func search(query: String) {
        if query.isEmpty {
            filteredTracks = tracks
        } else {
            filteredTracks = tracks.filter { track in
                track.title.localizedCaseInsensitiveContains(query) ||
                track.artist.localizedCaseInsensitiveContains(query) ||
                track.album.localizedCaseInsensitiveContains(query)
            }
        }
        tableView.reloadData()
    }
    
    // MARK: - Selection
    func getSelectedTracks() -> [TrackRecord] {
        tableView.selectedRowIndexes.compactMap { index in
            guard index < filteredTracks.count else { return nil }
            return filteredTracks[index]
        }
    }
}

// MARK: - NSTableViewDataSource
extension LibraryViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return filteredTracks.count
    }
    
    func tableView(_ tableView: NSTableView, sortDescriptorsDidChange oldDescriptors: [NSSortDescriptor]) {
        guard let sortDescriptor = tableView.sortDescriptors.first else { return }
        
        filteredTracks.sort { track1, track2 in
            let key = sortDescriptor.key ?? ""
            let ascending = sortDescriptor.ascending
            
            let value1 = getValue(from: track1, key: key)
            let value2 = getValue(from: track2, key: key)
            
            if ascending {
                return value1 < value2
            } else {
                return value1 > value2
            }
        }
        
        tableView.reloadData()
    }
    
    private func getValue(from track: TrackRecord, key: String) -> String {
        switch key {
        case "title": return track.title
        case "artist": return track.artist
        case "album": return track.album
        case "genre": return track.genre ?? ""
        case "year": return "\(track.year ?? 0)"
        case "format": return track.format
        default: return ""
        }
    }
}

// MARK: - NSTableViewDelegate
extension LibraryViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let identifier = tableColumn?.identifier else { return nil }
        guard row < filteredTracks.count else { return nil }
        
        let track = filteredTracks[row]
        
        // Reuse or create cell
        let cellIdentifier = NSUserInterfaceItemIdentifier("Cell")
        var cell = tableView.makeView(withIdentifier: cellIdentifier, owner: nil) as? NSTableCellView
        
        if cell == nil {
            cell = NSTableCellView()
            cell?.identifier = cellIdentifier
            
            let textField = NSTextField()
            textField.isBordered = false
            textField.isEditable = false
            textField.backgroundColor = .clear
            textField.translatesAutoresizingMaskIntoConstraints = false
            
            cell?.addSubview(textField)
            cell?.textField = textField
            
            NSLayoutConstraint.activate([
                textField.leadingAnchor.constraint(equalTo: cell!.leadingAnchor, constant: 4),
                textField.trailingAnchor.constraint(equalTo: cell!.trailingAnchor, constant: -4),
                textField.centerYAnchor.constraint(equalTo: cell!.centerYAnchor)
            ])
        }
        
        // Set cell value
        let columnId = ColumnIdentifier(rawValue: identifier.rawValue)
        cell?.textField?.stringValue = getCellValue(track: track, column: columnId)
        
        return cell
    }
    
    private func getCellValue(track: TrackRecord, column: ColumnIdentifier?) -> String {
        guard let column = column else { return "" }
        
        switch column {
        case .title: return track.title
        case .artist: return track.artist
        case .album: return track.album
        case .duration: return formatDuration(track.duration)
        case .genre: return track.genre ?? "-"
        case .year: return track.year != nil ? "\(track.year!)" : "-"
        case .bitrate: return track.bitrate != nil ? "\(track.bitrate! / 1000) kbps" : "-"
        case .format: return track.format.uppercased()
        case .playCount: return "\(track.playCount)"
        case .rating: return String(repeating: "★", count: track.rating)
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Notifications
extension Notification.Name {
    static let databaseDidChange = Notification.Name("databaseDidChange")
}

