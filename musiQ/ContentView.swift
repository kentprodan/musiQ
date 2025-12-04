//
//  ContentView.swift
//  musiQ
//
//  Created by Cristian Prodan on 04.12.25.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedNavItem: NavigationItem = .songs
    @State private var searchText = ""
    @State private var isPlaying = true
    @State private var currentTime: Double = 45
    @State private var duration: Double = 218
    @State private var sidebarWidth: CGFloat = 220
    @State private var isDraggingSidebar = false
    @State private var showSidebar = true
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    // 1. Liquid Glass Floating Sidebar
                    if showSidebar {
                        LiquidGlassSidebar(selectedItem: $selectedNavItem, showSidebar: $showSidebar)
                            .frame(width: sidebarWidth, height: geometry.size.height)
                            .transition(.move(edge: .leading))
                        
                        // Resize Divider
                        ResizeDivider(sidebarWidth: $sidebarWidth, isDragging: $isDraggingSidebar)
                    }
                    
                    // 2. Main Content Area
                    ZStack(alignment: .bottom) {
                        MainContentView(
                            selectedNavItem: selectedNavItem,
                            searchText: $searchText,
                            showSidebar: showSidebar
                        )
                        .frame(width: showSidebar ? max(200, geometry.size.width - sidebarWidth - 1) : geometry.size.width, height: geometry.size.height)
                        
                        // Floating Liquid Glass Playback Bar
                        BottomPlaybackBar(
                            isPlaying: $isPlaying,
                            currentTime: $currentTime,
                            duration: $duration
                        )
                        .frame(width: min(showSidebar ? geometry.size.width - sidebarWidth - 60 : geometry.size.width - 60, 1400), height: 100)
                        .padding(.bottom, 16)
                    }
                }
            }
            .background(Color(nsColor: .windowBackgroundColor))
            
            // Floating traffic lights when sidebar is hidden
            if !showSidebar {
                HStack(spacing: 0) {
                    TrafficLights()
                        .padding(.leading, 12)
                        .padding(.top, 12)
                    Spacer()
                }
                .frame(height: 40)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .toggleSidebar)) { _ in
            withAnimation(.easeInOut(duration: 0.2)) {
                showSidebar.toggle()
            }
        }
    }
}// MARK: - Navigation Item Enum
enum NavigationItem: String, CaseIterable {
    case home = "Home"
    case inbox = "Inbox"
    case recentlyAdded = "Recent"
    case artists = "Artists"
    case albums = "Albums"
    case songs = "Songs"
    case genres = "Genres"
    case playlists = "Playlists"
    
    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .inbox: return "tray.fill"
        case .recentlyAdded: return "clock.fill"
        case .artists: return "music.mic"
        case .albums: return "square.stack.fill"
        case .songs: return "music.note.list"
        case .genres: return "guitars.fill"
        case .playlists: return "music.note.list"
        }
    }
}

// MARK: - 1. Liquid Glass Sidebar
struct LiquidGlassSidebar: View {
    @Binding var selectedItem: NavigationItem
    @Binding var showSidebar: Bool
    @AppStorage("showRecentlyAdded") private var showRecentlyAdded = true
    @AppStorage("showArtists") private var showArtists = true
    @AppStorage("showAlbums") private var showAlbums = true
    @AppStorage("showSongs") private var showSongs = true
    @AppStorage("showGenres") private var showGenres = true
    @AppStorage("playlistsCollapsed") private var playlistsCollapsed = false
    @State private var showLibrarySettings = false
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Window controls area
                HStack(spacing: 0) {
                    TrafficLights()
                        .padding(.leading, 12)
                        .padding(.top, 12)
                    Spacer()
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showSidebar = false
                        }
                    }) {
                        Image(systemName: "sidebar.left")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                            .frame(width: 24, height: 24)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, 12)
                    .padding(.top, 12)
                }
                .frame(height: 40)
                
                // Content area
                ScrollView {
                    VStack(spacing: 0) {
                        // Main Navigation
                        VStack(spacing: 1) {
                            SidebarItem(icon: "house.fill", title: "Home", isSelected: selectedItem == .home) {
                                selectedItem = .home
                            }
                            SidebarItem(icon: "tray.fill", title: "Inbox", isSelected: selectedItem == .inbox) {
                                selectedItem = .inbox
                            }
                        }
                        .padding(.horizontal, 8)
                        
                        // Library Section
                        SectionHeader(title: "Library", showEditButton: true, isEditing: showLibrarySettings, onEdit: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showLibrarySettings.toggle()
                            }
                            print("📝 Library Edit toggled: \(showLibrarySettings)")
                        })
                        .padding(.top, 16)
                        
                        VStack(spacing: 1) {
                            if showLibrarySettings {
                                // Edit mode - show checkboxes
                                LibraryCheckboxItem(icon: "clock.fill", title: "Recent", isChecked: $showRecentlyAdded)
                                LibraryCheckboxItem(icon: "music.mic", title: "Artists", isChecked: $showArtists)
                                LibraryCheckboxItem(icon: "square.stack.fill", title: "Albums", isChecked: $showAlbums)
                                LibraryCheckboxItem(icon: "music.note.list", title: "Songs", isChecked: $showSongs)
                                LibraryCheckboxItem(icon: "guitars.fill", title: "Genres", isChecked: $showGenres)
                            } else {
                                // Normal mode - show only checked items
                                if showRecentlyAdded {
                                    SidebarItem(icon: "clock.fill", title: "Recent", isSelected: selectedItem == .recentlyAdded) {
                                        selectedItem = .recentlyAdded
                                    }
                                }
                                if showArtists {
                                    SidebarItem(icon: "music.mic", title: "Artists", isSelected: selectedItem == .artists) {
                                        selectedItem = .artists
                                    }
                                }
                                if showAlbums {
                                    SidebarItem(icon: "square.stack.fill", title: "Albums", isSelected: selectedItem == .albums) {
                                        selectedItem = .albums
                                    }
                                }
                                if showSongs {
                                    SidebarItem(icon: "music.note.list", title: "Songs", isSelected: selectedItem == .songs) {
                                        selectedItem = .songs
                                    }
                                }
                                if showGenres {
                                    SidebarItem(icon: "guitars.fill", title: "Genres", isSelected: selectedItem == .genres) {
                                        selectedItem = .genres
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 8)
                        
                        // Playlists Section
                        SectionHeader(
                            title: "Playlists",
                            showCollapseButton: true,
                            isCollapsed: playlistsCollapsed,
                            onCollapse: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    playlistsCollapsed.toggle()
                                }
                            }
                        )
                        .padding(.top, 16)
                        
                        if !playlistsCollapsed {
                            VStack(spacing: 1) {
                                SidebarItem(icon: "music.note.list", title: "All Playlists", isSelected: selectedItem == .playlists) {
                                    selectedItem = .playlists
                                }
                            }
                            .padding(.horizontal, 8)
                        }
                    }
                }
                
                Spacer(minLength: 0)
                
                // Bottom settings button
                VStack(spacing: 0) {
                    Divider()
                        .padding(.horizontal, 12)
                    
                    Button(action: {
                        NotificationCenter.default.post(name: .openSettings, object: nil)
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(.secondary)
                                .frame(width: 32, height: 32)
                            
                            Text("Settings")
                                .font(.system(size: 13))
                                .foregroundStyle(.primary)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .background(Color.clear)
                }
            }
        }
        .background(
            ZStack {
                // Extended background blur effect
                Color.clear
                    .background(.ultraThinMaterial)
                    .padding(.leading, -40)
                    .padding(.trailing, -20)
                    .padding(.vertical, -10)
                
                // Base liquid glass material
                Color.clear
                    .background(.ultraThinMaterial)
                
                // Subtle tint for depth
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.03),
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.15),
                            Color.white.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: .black.opacity(0.25), radius: 20, x: 0, y: 5)
        .padding(.leading, 10)
        .padding(.vertical, 10)
    }
}

// MARK: - Traffic Lights
struct TrafficLights: View {
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 8) {
            TrafficLightButton(color: .red, icon: "xmark", action: {
                NSApplication.shared.windows.first?.close()
            })
            TrafficLightButton(color: .yellow, icon: "minus", action: {
                NSApplication.shared.windows.first?.miniaturize(nil)
            })
            TrafficLightButton(color: .green, icon: "arrow.up.left.and.arrow.down.right", action: {
                NSApplication.shared.windows.first?.zoom(nil)
            })
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
}

struct TrafficLightButton: View {
    let color: Color
    let icon: String
    let action: () -> Void
    @State private var isHovered = false
    @State private var isGroupHovered = false
    
    var body: some View {
        Button(action: action) {
            Circle()
                .fill(color.opacity(0.9))
                .frame(width: 12, height: 12)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 5, weight: .bold))
                        .foregroundStyle(.black.opacity(0.6))
                        .opacity(isHovered ? 1 : 0)
                )
                .overlay(
                    Circle()
                        .strokeBorder(color.opacity(0.3), lineWidth: 0.5)
                )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Search Field
struct SearchField: View {
    @State private var searchText = ""
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12))
                .foregroundStyle(.tertiary)
            
            Text("Search")
                .font(.system(size: 13))
                .foregroundStyle(.tertiary)
            
            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(Color.black.opacity(0.08))
        )
    }
}

// MARK: - Section Header
struct SectionHeader: View {
    let title: String
    var showEditButton: Bool = false
    var isEditing: Bool = false
    var onEdit: (() -> Void)? = nil
    var showCollapseButton: Bool = false
    var isCollapsed: Bool = false
    var onCollapse: (() -> Void)? = nil
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
            
            Spacer()
            
            if showEditButton {
                Button(action: {
                    onEdit?()
                }) {
                    Text(isEditing ? "Done" : "Edit")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(isEditing ? .blue : (isHovered ? .primary : .secondary))
                        .frame(height: 20)
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
                .opacity(isEditing || isHovered ? 1.0 : 0.0)
                .allowsHitTesting(true)
                .onHover { hovering in
                    if hovering {
                        isHovered = true
                    }
                }
            }
            
            if showCollapseButton {
                Button(action: {
                    onCollapse?()
                }) {
                    Image(systemName: isCollapsed ? "chevron.right" : "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(isHovered ? .primary : .secondary)
                        .frame(width: 20, height: 20)
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
                .opacity(isHovered ? 1.0 : 0.0)
                .allowsHitTesting(true)
                .onHover { hovering in
                    if hovering {
                        isHovered = true
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.bottom, 4)
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Library Checkbox Item
struct LibraryCheckboxItem: View {
    let icon: String
    let title: String
    @Binding var isChecked: Bool
    
    var body: some View {
        Button(action: {
            isChecked.toggle()
        }) {
            HStack(spacing: 10) {
                Image(systemName: isChecked ? "checkmark.square.fill" : "square")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(isChecked ? .orange : .white.opacity(0.6))
                    .frame(width: 18)
                
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(isChecked ? .white : .white.opacity(0.4))
                    .frame(width: 18)
                
                Text(title)
                    .font(.system(size: 13))
                    .foregroundStyle(isChecked ? .white : .white.opacity(0.4))
                
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(Color.clear)
    }
}

// MARK: - Sidebar Item
struct SidebarItem: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .frame(width: 18)
                    .foregroundStyle(isSelected ? .orange : .white)
                
                Text(title)
                    .font(.system(size: 13))
                    .foregroundStyle(isSelected ? .orange : .white)
                
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(isSelected ? Color.orange.opacity(0.15) : (isHovered ? Color.white.opacity(0.05) : Color.clear))
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Playlist Item
struct PlaylistItem: View {
    let icon: String
    let title: String
    let color: Color
    @State private var isHovered = false
    
    var body: some View {
        Button(action: {}) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(color)
                        .frame(width: 18, height: 18)
                    
                    Image(systemName: icon)
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.white)
                }
                
                Text(title)
                    .font(.system(size: 13))
                    .foregroundStyle(.primary)
                
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(isHovered ? Color.black.opacity(0.05) : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}



// MARK: - 2. Main Content View
struct MainContentView: View {
    let selectedNavItem: NavigationItem
    @Binding var searchText: String
    let showSidebar: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Route to appropriate view based on navigation item
            switch selectedNavItem {
            case .inbox:
                InboxView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
            case .songs:
                NewSongsView(showSidebar: showSidebar)
                    .padding(.bottom, 72)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
            case .recentlyAdded:
                VStack(spacing: 0) {
                    TopNavigationBar(searchText: $searchText, title: "Recently Added")
                        .frame(height: 52)
                        .background(Color(nsColor: .windowBackgroundColor))
                    Divider()
                    RecentlyAddedView()
                        .padding(.bottom, 72)
                }
                
            case .artists:
                VStack(spacing: 0) {
                    TopNavigationBar(searchText: $searchText, title: "Artists")
                        .frame(height: 52)
                        .background(Color(nsColor: .windowBackgroundColor))
                    Divider()
                    ArtistsView()
                        .padding(.bottom, 72)
                }
                
            case .albums:
                VStack(spacing: 0) {
                    TopNavigationBar(searchText: $searchText, title: "Albums")
                        .frame(height: 52)
                        .background(Color(nsColor: .windowBackgroundColor))
                    Divider()
                    AlbumsView()
                        .padding(.bottom, 72)
                }
                
            case .genres:
                VStack(spacing: 0) {
                    TopNavigationBar(searchText: $searchText, title: "Genres")
                        .frame(height: 52)
                        .background(Color(nsColor: .windowBackgroundColor))
                    Divider()
                    GenresView()
                        .padding(.bottom, 72)
                }
                
            case .home:
                HomeView()
                    .padding(.bottom, 72)
                
            case .playlists:
                VStack(spacing: 0) {
                    TopNavigationBar(searchText: $searchText, title: "Playlists")
                        .frame(height: 52)
                        .background(Color(nsColor: .windowBackgroundColor))
                    Divider()
                    PlaceholderView(title: "Playlists")
                        .padding(.bottom, 72)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

// MARK: - Home View
struct HomeView: View {
    @State private var stats: LibraryStats?
    @State private var isLoading = true
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                if isLoading {
                    VStack {
                        Spacer()
                        ProgressView("Loading library statistics...")
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, minHeight: 400)
                } else if let stats = stats {
                    // Header
                    VStack(spacing: 8) {
                        Text("Your Library")
                            .font(.system(size: 32, weight: .bold))
                        Text("Overview of your music collection")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 40)
                    
                    // Stats Grid
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 20),
                        GridItem(.flexible(), spacing: 20),
                        GridItem(.flexible(), spacing: 20),
                        GridItem(.flexible(), spacing: 20)
                    ], spacing: 20) {
                        StatCard(
                            icon: "music.note",
                            title: "Songs",
                            value: "\(stats.songCount)",
                            color: .orange
                        )
                        
                        StatCard(
                            icon: "square.stack.fill",
                            title: "Albums",
                            value: "\(stats.albumCount)",
                            color: .blue
                        )
                        
                        StatCard(
                            icon: "music.mic",
                            title: "Artists",
                            value: "\(stats.artistCount)",
                            color: .purple
                        )
                        
                        StatCard(
                            icon: "guitars.fill",
                            title: "Genres",
                            value: "\(stats.genreCount)",
                            color: .pink
                        )
                    }
                    .padding(.horizontal, 40)
                    
                    // Additional Stats
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 20),
                        GridItem(.flexible(), spacing: 20),
                        GridItem(.flexible(), spacing: 20)
                    ], spacing: 20) {
                        StatCard(
                            icon: "externaldrive.fill",
                            title: "Storage Used",
                            value: stats.formattedSize,
                            color: .green
                        )
                        
                        StatCard(
                            icon: "clock.fill",
                            title: "Total Duration",
                            value: stats.formattedDuration,
                            color: .indigo
                        )
                        
                        StatCard(
                            icon: "play.circle.fill",
                            title: "Total Plays",
                            value: "\(stats.totalPlayCount)",
                            color: .red
                        )
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 40)
                } else {
                    VStack(spacing: 16) {
                        Spacer()
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        Text("Unable to load library statistics")
                            .font(.system(size: 16, weight: .medium))
                        Text("Your library might be empty or there was an error")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, minHeight: 400)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .onAppear {
            print("🏠 HomeView appeared, loading stats...")
            loadStats()
        }
        .onReceive(NotificationCenter.default.publisher(for: .databaseDidChange)) { _ in
            loadStats()
        }
    }
    
    private func loadStats() {
        print("🔄 Starting to load library stats...")
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                print("📊 Fetching stats from database...")
                let loadedStats = try DatabaseManager.shared.getLibraryStats()
                print("✅ Stats fetched: \(loadedStats.songCount) songs, \(loadedStats.albumCount) albums, \(loadedStats.artistCount) artists")
                DispatchQueue.main.async {
                    self.stats = loadedStats
                    self.isLoading = false
                    print("✅ Stats applied to UI")
                }
            } catch {
                print("❌ Failed to load library stats: \(error)")
                DispatchQueue.main.async {
                    self.stats = nil
                    self.isLoading = false
                }
            }
        }
    }
}

struct StatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 80, height: 80)
                
                Image(systemName: icon)
                    .font(.system(size: 32, weight: .medium))
                    .foregroundStyle(color)
            }
            
            VStack(spacing: 4) {
                Text(value)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.primary)
                
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - Placeholder View
struct PlaceholderView: View {
    let title: String
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: iconForTitle())
                .font(.system(size: 64))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text(title)
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.primary)
            
            Text("This section is under development")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func iconForTitle() -> String {
        switch title.lowercased() {
        case "home": return "house.fill"
        case "recently added": return "clock.fill"
        case "artists": return "music.mic"
        case "albums": return "square.stack.fill"
        case "playlists": return "music.note.list"
        default: return "music.note"
        }
    }
}

struct TopNavigationBar: View {
    @Binding var searchText: String
    let title: String
    
    var body: some View {
        HStack(spacing: 16) {
            // Title
            Text(title)
                .font(.system(size: 20, weight: .bold))
                .padding(.leading, 20)
            
            Spacer()
            
            // Menu and Search
            HStack(spacing: 12) {
                Button(action: {}) {
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    TextField("Find in Songs", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.black.opacity(0.05))
                )
                .frame(width: 200)
            }
            .padding(.trailing, 20)
        }
    }
}

// MARK: - New Songs View
struct NewSongsView: View {
    let showSidebar: Bool
    @State private var tracks: [TrackRecord] = []
    @State private var isLoading = false
    @State private var searchText = ""
    @State private var sortColumn: SongColumn = .title
    @State private var sortAscending = true
    @ObservedObject var audioEngine = AudioEngine.shared
    
    enum SongColumn: String, CaseIterable {
        case title = "Title"
        case time = "Time"
        case artist = "Artist"
        case album = "Album"
        case genre = "Genre"
        case rating = "Rating"
        case plays = "Plays"
    }
    
    var filteredTracks: [TrackRecord] {
        let filtered = searchText.isEmpty ? tracks : tracks.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.artist.localizedCaseInsensitiveContains(searchText) ||
            $0.album.localizedCaseInsensitiveContains(searchText) ||
            ($0.genre?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
        
        return filtered.sorted { track1, track2 in
            let result: Bool
            switch sortColumn {
            case .title:
                result = track1.title.localizedCompare(track2.title) == .orderedAscending
            case .time:
                result = track1.duration < track2.duration
            case .artist:
                result = track1.artist.localizedCompare(track2.artist) == .orderedAscending
            case .album:
                result = track1.album.localizedCompare(track2.album) == .orderedAscending
            case .genre:
                result = (track1.genre ?? "").localizedCompare(track2.genre ?? "") == .orderedAscending
            case .rating:
                result = track1.rating < track2.rating
            case .plays:
                result = track1.playCount < track2.playCount
            }
            return sortAscending ? result : !result
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with title, filter, and search
            HStack(spacing: 16) {
                Text("Songs")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.primary)
                    .padding(.leading, showSidebar ? 0 : 68)
                
                Spacer()
                
                Button(action: {
                    // Filter action placeholder
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .font(.system(size: 16))
                        Text("Filter")
                            .font(.system(size: 13))
                    }
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color(nsColor: .controlBackgroundColor))
                    )
                }
                .buttonStyle(.plain)
                
                // Search field
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                    
                    TextField("Search songs", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(width: 280)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Color(nsColor: .windowBackgroundColor))
            .frame(maxWidth: .infinity)
            
            Divider()
            
            // Table
            if isLoading {
                VStack {
                    Spacer()
                    ProgressView("Loading tracks...")
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if filteredTracks.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "music.note.list")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text(searchText.isEmpty ? "No tracks in library" : "No matching tracks")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Table(filteredTracks) {
                    TableColumn("Title") { track in
                        Text(track.title)
                            .font(.system(size: 13))
                            .foregroundStyle(.primary)
                    }
                    .width(min: 150, ideal: 300)
                    
                    TableColumn("Time") { track in
                        Text(formatDuration(track.duration))
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    }
                    .width(min: 50, ideal: 60)
                    
                    TableColumn("Artist") { track in
                        Text(track.artist)
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    }
                    .width(min: 100, ideal: 180)
                    
                    TableColumn("Album") { track in
                        Text(track.album)
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    }
                    .width(min: 100, ideal: 180)
                    
                    TableColumn("Genre") { track in
                        Text(track.genre ?? "")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    }
                    .width(min: 80, ideal: 120)
                    
                    TableColumn("Rating") { track in
                        HStack(spacing: 2) {
                            ForEach(0..<5) { index in
                                Image(systemName: index < track.rating ? "star.fill" : "star")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.orange)
                            }
                        }
                    }
                    .width(min: 80, ideal: 90)
                    
                    TableColumn("Plays") { track in
                        Text("\\(track.playCount)")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    }
                    .width(min: 50, ideal: 60)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            loadTracks()
        }
        .onReceive(NotificationCenter.default.publisher(for: .databaseDidChange)) { _ in
            loadTracks()
        }
    }
    
    private func loadTracks() {
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let loadedTracks = try DatabaseManager.shared.getAllTracks()
                DispatchQueue.main.async {
                    self.tracks = loadedTracks
                    self.isLoading = false
                    print("📚 Loaded \\(loadedTracks.count) tracks")
                }
            } catch {
                DispatchQueue.main.async {
                    self.tracks = []
                    self.isLoading = false
                    print("❌ Failed to load tracks: \\(error)")
                }
            }
        }
    }
    
    private func formatDuration(_ duration: Double) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Songs Table View (OLD - Keep for reference)
struct SongsTableView: View {
    @State private var tracks: [TrackRecord] = []
    @State private var isLoading = false
    @ObservedObject var audioEngine = AudioEngine.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Table Header
            HStack(spacing: 0) {
                Text("Title")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(width: 40, alignment: .leading)
                    .padding(.leading, 20)
                
                Spacer()
                    .frame(width: 300)
                
                Image(systemName: "icloud")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .frame(width: 30)
                
                Text("Time")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(width: 60, alignment: .leading)
                
                HStack(spacing: 4) {
                    Text("Artist")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                    Image(systemName: "chevron.up")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .frame(width: 150, alignment: .leading)
                
                Text("Album")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(width: 150, alignment: .leading)
                
                Text("Genre")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(width: 100, alignment: .leading)
                
                Image(systemName: "star")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .frame(width: 40)
                
                Text("Plays")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(width: 60, alignment: .trailing)
                    .padding(.trailing, 20)
            }
            .padding(.vertical, 8)
            .background(Color(nsColor: .windowBackgroundColor))
            
            Divider()
            
            // Table content
            if isLoading {
                Spacer()
                ProgressView("Loading tracks...")
                Spacer()
            } else if tracks.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "music.note.list")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("No tracks in library")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                    Text("Import music from the Inbox to get started")
                        .font(.system(size: 12))
                        .foregroundStyle(.tertiary)
                }
                Spacer()
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(tracks, id: \.id) { track in
                            SongRow(track: track)
                                .onTapGesture(count: 2) {
                                    // Convert TrackRecord to AudioEngine Track
                                    let engineTrack = Track(
                                        id: track.id ?? 0,
                                        title: track.title,
                                        artist: track.artist,
                                        album: track.album,
                                        duration: track.duration,
                                        fileURL: URL(string: track.fileURL)!,
                                        bitrate: track.bitrate ?? 0,
                                        sampleRate: track.sampleRate ?? 0,
                                        format: track.format
                                    )
                                    audioEngine.play(track: engineTrack)
                                }
                            Divider()
                        }
                    }
                }
            }
        }
        .onAppear {
            loadTracks()
        }
        .onReceive(NotificationCenter.default.publisher(for: .databaseDidChange)) { _ in
            loadTracks()
        }
    }
    
    private func loadTracks() {
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let loadedTracks = try DatabaseManager.shared.getAllTracks()
                DispatchQueue.main.async {
                    self.tracks = loadedTracks
                    self.isLoading = false
                    print("📚 Loaded \(loadedTracks.count) tracks from database")
                }
            } catch {
                DispatchQueue.main.async {
                    self.tracks = []
                    self.isLoading = false
                    print("❌ Failed to load tracks: \(error)")
                }
            }
        }
    }
}

struct SongRow: View {
    let track: TrackRecord
    @State private var isHovering = false
    
    var body: some View {
        HStack(spacing: 0) {
            // Play indicator / Row number
            Text(String(track.id ?? 0))
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .frame(width: 40, alignment: .leading)
                .padding(.leading, 20)
            
            // Title
            Text(track.title)
                .font(.system(size: 13))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .frame(width: 300, alignment: .leading)
            
            // Cloud status
            Image(systemName: "checkmark.icloud")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .frame(width: 30)
            
            // Duration
            Text(formatDuration(track.duration))
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .frame(width: 60, alignment: .leading)
            
            // Artist
            Text(track.artist)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .frame(width: 150, alignment: .leading)
            
            // Album
            Text(track.album)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .frame(width: 150, alignment: .leading)
            
            // Genre
            Text(track.genre ?? "")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .frame(width: 100, alignment: .leading)
            
            // Rating
            HStack(spacing: 2) {
                ForEach(0..<5) { index in
                    Image(systemName: index < track.rating ? "star.fill" : "star")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 40)
            
            // Play count
            Text(String(track.playCount))
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .frame(width: 60, alignment: .trailing)
                .padding(.trailing, 20)
        }
        .frame(height: 44)
        .background(isHovering ? Color.white.opacity(0.05) : Color.clear)
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovering = hovering
        }
    }
    
    private func formatDuration(_ duration: Double) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Recently Added View
struct RecentlyAddedView: View {
    @State private var tracks: [TrackRecord] = []
    @State private var isLoading = false
    @ObservedObject var audioEngine = AudioEngine.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if isLoading {
                Spacer()
                ProgressView("Loading recently added tracks...")
                Spacer()
            } else if tracks.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "clock")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("No recently added tracks")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                Spacer()
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(tracks, id: \.id) { track in
                            SongRow(track: track)
                                .onTapGesture(count: 2) {
                                    let engineTrack = Track(
                                        id: track.id ?? 0,
                                        title: track.title,
                                        artist: track.artist,
                                        album: track.album,
                                        duration: track.duration,
                                        fileURL: URL(string: track.fileURL)!,
                                        bitrate: track.bitrate ?? 0,
                                        sampleRate: track.sampleRate ?? 0,
                                        format: track.format
                                    )
                                    audioEngine.play(track: engineTrack)
                                }
                            Divider()
                        }
                    }
                }
            }
        }
        .onAppear {
            loadTracks()
        }
        .onReceive(NotificationCenter.default.publisher(for: .databaseDidChange)) { _ in
            loadTracks()
        }
    }
    
    private func loadTracks() {
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let loadedTracks = try DatabaseManager.shared.getRecentlyAddedTracks(limit: 100)
                DispatchQueue.main.async {
                    self.tracks = loadedTracks
                    self.isLoading = false
                    print("📅 Loaded \(loadedTracks.count) recently added tracks")
                }
            } catch {
                DispatchQueue.main.async {
                    self.tracks = []
                    self.isLoading = false
                    print("❌ Failed to load recently added tracks: \(error)")
                }
            }
        }
    }
}

// MARK: - Artists View
struct ArtistsView: View {
    @State private var artists: [(artist: String, trackCount: Int)] = []
    @State private var isLoading = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if isLoading {
                Spacer()
                ProgressView("Loading artists...")
                Spacer()
            } else if artists.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "music.mic")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("No artists in library")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 160, maximum: 200), spacing: 20)
                    ], spacing: 20) {
                        ForEach(artists, id: \.artist) { artist in
                            ArtistCard(name: artist.artist, trackCount: artist.trackCount)
                        }
                    }
                    .padding(20)
                }
            }
        }
        .onAppear {
            loadArtists()
        }
        .onReceive(NotificationCenter.default.publisher(for: .databaseDidChange)) { _ in
            loadArtists()
        }
    }
    
    private func loadArtists() {
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let loadedArtists = try DatabaseManager.shared.getAllArtists()
                DispatchQueue.main.async {
                    self.artists = loadedArtists
                    self.isLoading = false
                    print("🎤 Loaded \(loadedArtists.count) artists")
                }
            } catch {
                DispatchQueue.main.async {
                    self.artists = []
                    self.isLoading = false
                    print("❌ Failed to load artists: \(error)")
                }
            }
        }
    }
}

struct ArtistCard: View {
    let name: String
    let trackCount: Int
    @State private var isHovering = false
    
    var body: some View {
        VStack(spacing: 12) {
            // Circular artist placeholder
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue.opacity(0.6), .purple.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 140, height: 140)
                
                Image(systemName: "music.mic")
                    .font(.system(size: 48))
                    .foregroundStyle(.white.opacity(0.9))
            }
            
            VStack(spacing: 4) {
                Text(name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                Text("\(trackCount) \(trackCount == 1 ? "song" : "songs")")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(isHovering ? Color.white.opacity(0.05) : Color.clear)
        .cornerRadius(8)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

// MARK: - Albums View
struct AlbumsView: View {
    @State private var albums: [(album: String, artist: String, trackCount: Int, year: Int?)] = []
    @State private var isLoading = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if isLoading {
                Spacer()
                ProgressView("Loading albums...")
                Spacer()
            } else if albums.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "square.stack")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("No albums in library")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 160, maximum: 200), spacing: 20)
                    ], spacing: 20) {
                        ForEach(albums, id: \.album) { album in
                            AlbumCard(
                                title: album.album,
                                artist: album.artist,
                                trackCount: album.trackCount,
                                year: album.year
                            )
                        }
                    }
                    .padding(20)
                }
            }
        }
        .onAppear {
            loadAlbums()
        }
        .onReceive(NotificationCenter.default.publisher(for: .databaseDidChange)) { _ in
            loadAlbums()
        }
    }
    
    private func loadAlbums() {
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let loadedAlbums = try DatabaseManager.shared.getAllAlbums()
                DispatchQueue.main.async {
                    self.albums = loadedAlbums
                    self.isLoading = false
                    print("💿 Loaded \(loadedAlbums.count) albums")
                }
            } catch {
                DispatchQueue.main.async {
                    self.albums = []
                    self.isLoading = false
                    print("❌ Failed to load albums: \(error)")
                }
            }
        }
    }
}

struct AlbumCard: View {
    let title: String
    let artist: String
    let trackCount: Int
    let year: Int?
    @State private var isHovering = false
    
    var body: some View {
        VStack(spacing: 12) {
            // Square album artwork placeholder
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [.blue.opacity(0.6), .purple.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 160, height: 160)
                
                Image(systemName: "music.note")
                    .font(.system(size: 48))
                    .foregroundStyle(.white.opacity(0.9))
            }
            
            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                Text(artist)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    if let year = year {
                        Text(String(year))
                            .font(.system(size: 11))
                            .foregroundStyle(.tertiary)
                        Text("•")
                            .font(.system(size: 11))
                            .foregroundStyle(.tertiary)
                    }
                    Text("\(trackCount) \(trackCount == 1 ? "song" : "songs")")
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(12)
        .background(isHovering ? Color.white.opacity(0.05) : Color.clear)
        .cornerRadius(8)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

// MARK: - Genres View
struct GenresView: View {
    @State private var genres: [(genre: String, trackCount: Int)] = []
    @State private var isLoading = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if isLoading {
                Spacer()
                ProgressView("Loading genres...")
                Spacer()
            } else if genres.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "guitars.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("No genres in library")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 160, maximum: 200), spacing: 20)
                    ], spacing: 20) {
                        ForEach(genres, id: \.genre) { genre in
                            GenreCard(name: genre.genre, trackCount: genre.trackCount)
                        }
                    }
                    .padding(20)
                }
            }
        }
        .onAppear {
            loadGenres()
        }
        .onReceive(NotificationCenter.default.publisher(for: .databaseDidChange)) { _ in
            loadGenres()
        }
    }
    
    private func loadGenres() {
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let loadedGenres = try DatabaseManager.shared.getAllGenres()
                DispatchQueue.main.async {
                    self.genres = loadedGenres
                    self.isLoading = false
                    print("🎸 Loaded \(loadedGenres.count) genres")
                }
            } catch {
                DispatchQueue.main.async {
                    self.genres = []
                    self.isLoading = false
                    print("❌ Failed to load genres: \(error)")
                }
            }
        }
    }
}

struct GenreCard: View {
    let name: String
    let trackCount: Int
    @State private var isHovering = false
    
    var body: some View {
        VStack(spacing: 12) {
            // Genre icon/visual
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [.purple.opacity(0.6), .pink.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 160, height: 160)
                
                Image(systemName: "guitars.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.white.opacity(0.9))
            }
            
            VStack(spacing: 4) {
                Text(name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                Text("\(trackCount) \(trackCount == 1 ? "song" : "songs")")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(isHovering ? Color.white.opacity(0.05) : Color.clear)
        .cornerRadius(8)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

// MARK: - 2.3 Bottom Playback Bar
struct BottomPlaybackBar: View {
    @Binding var isPlaying: Bool
    @Binding var currentTime: Double
    @Binding var duration: Double
    @ObservedObject var audioEngine = AudioEngine.shared
    @State private var isHoveringProgress = false
    @State private var volume: Double = 0.75
    @State private var isHoveringVolume = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                // Main glass pill container
                HStack(spacing: geometry.size.width < 900 ? 12 : 20) {
                    // Left: Playback Controls
                    HStack(spacing: geometry.size.width < 900 ? 12 : 18) {
                        Button(action: {}) {
                            Image(systemName: "shuffle")
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: {}) {
                            Image(systemName: "backward.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(.primary)
                        }
                        .buttonStyle(.plain)
                        
                        // Primary play/pause button
                        Button(action: { 
                            if audioEngine.isPlaying {
                                audioEngine.pause()
                            } else {
                                audioEngine.resume()
                            }
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.12))
                                    .frame(width: 36, height: 36)
                                
                                Image(systemName: audioEngine.isPlaying ? "pause.fill" : "play.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(.primary)
                            }
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: {}) {
                            Image(systemName: "forward.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(.primary)
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: {}) {
                            Image(systemName: "repeat")
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    // Center: Album Art & Metadata
                    HStack(spacing: 12) {
                        // Album Artwork
                        ZStack {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.purple, Color.blue],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 56, height: 56)
                            
                            Image(systemName: "music.note")
                                .font(.system(size: 22))
                                .foregroundStyle(.white)
                        }
                        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                        
                        // Metadata
                        VStack(alignment: .leading, spacing: 3) {
                            Text(audioEngine.currentTrack?.title ?? "Not Playing")
                                .font(.system(size: 13, weight: .semibold))
                                .lineLimit(1)
                            Text("\(audioEngine.currentTrack?.artist ?? "Unknown Artist") — \(audioEngine.currentTrack?.album ?? "Unknown Album")")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        .frame(width: min(250, max(120, geometry.size.width * 0.25)), alignment: .leading)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        // Expand to mini player / full view
                    }
                    
                    Spacer()
                    
                    // Right: Quality, More, Lyrics, Queue, Volume
                    HStack(spacing: geometry.size.width < 900 ? 10 : 16) {
                        // Track Quality Badge
                        if geometry.size.width >= 1100 {
                            Text("Hi-Res")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.secondary.opacity(0.15))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        
                        // More button (3 dots)
                        if geometry.size.width >= 1000 {
                            Button(action: {}) {
                                Image(systemName: "ellipsis")
                                    .font(.system(size: 16))
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                        
                        // Lyrics button
                        if geometry.size.width >= 950 {
                            Button(action: {}) {
                                Image(systemName: "quote.bubble")
                                    .font(.system(size: 16))
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                        
                        // Queue button
                        if geometry.size.width >= 900 {
                            Button(action: {}) {
                                Image(systemName: "list.bullet")
                                    .font(.system(size: 16))
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                        
                        // Volume control
                        HStack(spacing: 8) {
                            Image(systemName: audioEngine.volume > 0.5 ? "speaker.wave.2.fill" : audioEngine.volume > 0 ? "speaker.wave.1.fill" : "speaker.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(.secondary)
                            
                            if isHoveringVolume && geometry.size.width >= 850 {
                                Slider(value: Binding(
                                    get: { Double(audioEngine.volume) },
                                    set: { audioEngine.setVolume(Float($0)) }
                                ), in: 0...1)
                                    .frame(width: 80)
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .frame(width: isHoveringVolume && geometry.size.width >= 850 ? 120 : 20)
                        .onHover { hovering in
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isHoveringVolume = hovering
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .frame(height: 80)
                .background(
                    ZStack {
                        // Extended background blur for halo effect
                        Color.clear
                            .background(.ultraThinMaterial)
                            .padding(.horizontal, -30)
                            .padding(.vertical, -15)
                        
                        // Main material
                        Color.clear
                            .background(.ultraThinMaterial)
                        
                        // Subtle white overlay for depth
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.08),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
                )
                .opacity(0.95)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.2),
                                    Color.white.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: .black.opacity(0.25), radius: 30, x: 0, y: 15)
                
                // Progress bar overlay (invisible slider at bottom edge)
                VStack {
                    Spacer()
                    ZStack(alignment: .leading) {
                        // Background track
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .fill(Color.white.opacity(0.15))
                            .frame(height: isHoveringProgress ? 6 : 4)
                        
                        // Progress fill
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .fill(Color.accentColor)
                            .frame(width: audioEngine.duration > 0 ? geometry.size.width * CGFloat(audioEngine.currentTime / audioEngine.duration) : 0, height: isHoveringProgress ? 6 : 4)
                        
                        // Time labels on hover
                        if isHoveringProgress {
                            HStack {
                                Text(formatTime(audioEngine.currentTime))
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(formatTime(audioEngine.duration))
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal, 8)
                            .offset(y: -12)
                        }
                    }
                    .frame(height: isHoveringProgress ? 6 : 4)
                    .contentShape(Rectangle().size(width: geometry.size.width, height: 20))
                    .onHover { hovering in
                        withAnimation(.easeInOut(duration: 0.15)) {
                            isHoveringProgress = hovering
                        }
                    }
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                if audioEngine.duration > 0 {
                                    let newTime = (value.location.x / geometry.size.width) * audioEngine.duration
                                    let clampedTime = min(max(newTime, 0), audioEngine.duration)
                                    audioEngine.seek(to: clampedTime)
                                }
                            }
                    )
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 2)
            }
            .frame(maxWidth: 1200)
            .frame(width: geometry.size.width)
        }
    }
    
    private func formatTime(_ time: Double) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Waveform Seekbar
struct WaveformSeekbar: View {
    @Binding var currentTime: Double
    let duration: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background waveform (simplified)
                HStack(spacing: 1) {
                    ForEach(0..<200, id: \.self) { i in
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 2, height: CGFloat.random(in: 2...4))
                    }
                }
                .frame(height: 4)
                
                // Progress overlay
                HStack(spacing: 1) {
                    ForEach(0..<200, id: \.self) { i in
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color.accentColor)
                            .frame(width: 2, height: CGFloat.random(in: 2...4))
                    }
                }
                .frame(width: geometry.size.width * CGFloat(currentTime / duration), height: 4)
                .clipped()
            }
        }
        .onAppear {
            // Simulate playback for demo
            Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
                if currentTime < duration {
                    currentTime += 0.1
                } else {
                    currentTime = 0
                }
            }
        }
    }
}

// MARK: - 3. Right Panel
struct RightPanel: View {
    let songs = [
        ("Останься", "NIO & Асия — Оста...", "2021"),
        ("INDUSTRY BABY", "Lil Nas X & Jack Ha...", ""),
        ("Write This Down", "Nieve & SoulChef...", ""),
        ("Ziua lu' Ioana", "Jo — Ziua lu' Ioana...", ""),
        ("Zburătorul", "EMAA — Zburătorul...", ""),
        ("Love Tonight", "Shouse — Love Ton...", ""),
        ("первое свидание", "алёна швец — пер...", ""),
        ("Muzika", "Intelligency — Muzi...", ""),
        ("Сиди дома", "Ирина Кайратовна...", ""),
        ("Nebuna", "EMAA — Macii Inflo...", ""),
        ("All Mine", "PLAZA — All Mine -...", ""),
        ("Фонари", "Rem Digga & NyBra...", ""),
        ("Босс", "JONY & The Limba...", ""),
        ("If You Want It", "Wilkinson — If You...", ""),
        ("Spirals", "BCee & Solah — Sp...", "")
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Continue Playing")
                    .font(.system(size: 14, weight: .semibold))
                Spacer()
                Button("Clear") {
                    
                }
                .font(.system(size: 12))
                .foregroundStyle(.red)
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            Text("From 2021")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            
            Divider()
            
            // Songs List
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(Array(songs.enumerated()), id: \.offset) { index, song in
                        ContinuePlayingSongRow(
                            title: song.0,
                            subtitle: song.1,
                            year: song.2
                        )
                        if index < songs.count - 1 {
                            Divider()
                                .padding(.leading, 72)
                        }
                    }
                }
            }
            .padding(.bottom, 72) // Space for bottom player
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

struct ContinuePlayingSongRow: View {
    let title: String
    let subtitle: String
    let year: String
    
    var body: some View {
        HStack(spacing: 10) {
            // Album Art
            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            colors: [Color.blue, Color.purple, Color.pink].shuffled(),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)
                
                Image(systemName: "music.note")
                    .font(.system(size: 18))
                    .foregroundStyle(.white)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12))
                    .lineLimit(1)
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Button(action: {}) {
                Image(systemName: "ellipsis")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }
}

#Preview {
    ContentView()
        .frame(width: 1280, height: 800)
}

// MARK: - Right Panel Content Views
struct LyricsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "music.note")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            Text("No Lyrics Available")
                .font(.title3)
                .foregroundStyle(.secondary)
            Text("Lyrics will appear here when playing")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}

struct QueueView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "list.bullet")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            Text("Queue is Empty")
                .font(.title3)
                .foregroundStyle(.secondary)
            Text("Add songs to see what's playing next")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}

struct InfoView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Track Information")
                .font(.headline)
                .padding(.top, 20)
            
            VStack(alignment: .leading, spacing: 8) {
                InfoRow(label: "Title", value: "—")
                InfoRow(label: "Artist", value: "—")
                InfoRow(label: "Album", value: "—")
                InfoRow(label: "Duration", value: "—")
                InfoRow(label: "Bitrate", value: "—")
                InfoRow(label: "Format", value: "—")
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .foregroundStyle(.primary)
        }
    }
}

// MARK: - Resize Divider
struct ResizeDivider: View {
    @Binding var sidebarWidth: CGFloat
    @Binding var isDragging: Bool
    @State private var isHovering = false
    
    private let minWidth: CGFloat = 180
    private let maxWidth: CGFloat = 320
    
    var body: some View {
        Rectangle()
            .fill(Color.clear)
            .frame(width: isDragging ? 4 : 1)
            .overlay(
                Rectangle()
                    .fill(isHovering || isDragging ? Color.gray.opacity(0.3) : Color.clear)
            )
            .contentShape(Rectangle())
            .onHover { hovering in
                isHovering = hovering
                if hovering {
                    NSCursor.resizeLeftRight.push()
                } else if !isDragging {
                    NSCursor.pop()
                }
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        isDragging = true
                        let newWidth = sidebarWidth + value.translation.width
                        sidebarWidth = min(max(newWidth, minWidth), maxWidth)
                    }
                    .onEnded { _ in
                        isDragging = false
                        if !isHovering {
                            NSCursor.pop()
                        }
                    }
            )
    }
}

#Preview {
    ContentView()
        .frame(width: 1200, height: 800)
}
