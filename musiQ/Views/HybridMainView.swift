import SwiftUI
import AppKit

/// Hybrid view that wraps AppKit LibraryViewController in SwiftUI
struct LibraryViewWrapper: NSViewControllerRepresentable {
    @Binding var searchText: String
    
    func makeNSViewController(context: Context) -> LibraryViewController {
        let controller = LibraryViewController()
        context.coordinator.libraryController = controller
        return controller
    }
    
    func updateNSViewController(_ nsViewController: LibraryViewController, context: Context) {
        // Update search when binding changes
        if context.coordinator.lastSearchText != searchText {
            nsViewController.search(query: searchText)
            context.coordinator.lastSearchText = searchText
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator {
        weak var libraryController: LibraryViewController?
        var lastSearchText: String = ""
    }
}

/// Main hybrid view combining AppKit library with SwiftUI chrome
struct HybridMainView: View {
    @State private var searchText = ""
    @State private var selectedTab: ViewTab = .library
    
    enum ViewTab {
        case library, albums, artists, playlists
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Top toolbar
            toolbar
            
            // Main content with tab switching
            ZStack {
                switch selectedTab {
                case .library:
                    LibraryViewWrapper(searchText: $searchText)
                case .albums:
                    Text("Albums View - Coming Soon")
                        .font(.title)
                        .foregroundColor(.secondary)
                case .artists:
                    Text("Artists View - Coming Soon")
                        .font(.title)
                        .foregroundColor(.secondary)
                case .playlists:
                    Text("Playlists View - Coming Soon")
                        .font(.title)
                        .foregroundColor(.secondary)
                }
            }
            
            // Bottom player
            PlayerView()
        }
    }
    
    // MARK: - Toolbar
    private var toolbar: some View {
        HStack {
            // Tab selector
            Picker("View", selection: $selectedTab) {
                Text("Library").tag(ViewTab.library)
                Text("Albums").tag(ViewTab.albums)
                Text("Artists").tag(ViewTab.artists)
                Text("Playlists").tag(ViewTab.playlists)
            }
            .pickerStyle(.segmented)
            .frame(width: 400)
            
            Spacer()
            
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search library...", text: $searchText)
                    .textFieldStyle(.plain)
                    .frame(width: 250)
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)
            
            Spacer().frame(width: 16)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

// MARK: - App Coordinator
/// Coordinates between AppKit and SwiftUI components
class AppCoordinator: ObservableObject {
    static let shared = AppCoordinator()
    
    @Published var currentView: String = "library"
    @Published var isPlayerVisible: Bool = false
    
    private init() {
        setupObservers()
    }
    
    private func setupObservers() {
        // Observe audio engine state
        AudioEngine.shared.$isPlaying
            .sink { [weak self] isPlaying in
                self?.isPlayerVisible = isPlaying
            }
            .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
}

import Combine
