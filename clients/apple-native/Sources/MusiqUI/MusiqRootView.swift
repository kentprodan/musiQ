import SwiftUI
import MusiqFFI

/// Entry point every platform's thin Xcode app target wraps in a
/// `WindowGroup` / `WKApplication` / tvOS scene. Layout adapts per
/// platform via `#if os(...)` rather than maintaining separate root
/// views — `NavigationSplitView` collapses to a single column on
/// watchOS/tvOS automatically, so only the player chrome needs explicit
/// branching.
public struct MusiqRootView: View {
    @State private var selection: LibrarySection? = .albums

    public init() {}

    public var body: some View {
        #if os(watchOS)
        WatchNowPlayingView()
        #else
        NavigationSplitView {
            List(LibrarySection.allCases, selection: $selection) { section in
                Label(section.title, systemImage: section.symbolName)
            }
            .navigationTitle("musiQ")
        } detail: {
            ZStack(alignment: .bottom) {
                LibraryDetailView(section: selection ?? .albums)
                PlayerBarView()
                    .padding(.horizontal)
                    .padding(.bottom, 12)
            }
        }
        #endif
    }
}

public enum LibrarySection: String, CaseIterable, Identifiable {
    case albums, artists, tracks, genres

    public var id: String { rawValue }
    var title: String { rawValue.capitalized }
    var symbolName: String {
        switch self {
        case .albums: return "square.stack"
        case .artists: return "music.mic"
        case .tracks: return "music.note.list"
        case .genres: return "guitars"
        }
    }
}

struct LibraryDetailView: View {
    let section: LibrarySection

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 16)], spacing: 16) {
                ForEach(0..<18) { index in
                    VStack(alignment: .leading, spacing: 4) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.linearGradient(colors: [.accentColor.opacity(0.4), .secondary.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .aspectRatio(1, contentMode: .fit)
                        Text("Untitled Album \(index + 1)")
                            .font(.footnote.weight(.semibold))
                        Text("Unknown Artist")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
            .padding(.bottom, 80) // room for the floating PlayerBarView
        }
        .navigationTitle(section.title)
    }
}

struct WatchNowPlayingView: View {
    var body: some View {
        VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 12).fill(.secondary.opacity(0.2)).frame(width: 80, height: 80)
            Text("Nothing playing").font(.footnote)
            HStack(spacing: 20) {
                Image(systemName: "backward.fill")
                Image(systemName: "play.fill")
                Image(systemName: "forward.fill")
            }
        }
        .padding()
    }
}
