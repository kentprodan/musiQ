# Changelog

All notable changes to musiQ will be documented in this file.

## [0.0.3] - 2025-12-04

### Added - Home Dashboard
- **HomeView**: Complete library statistics dashboard
  - Display total songs, albums, artists, and genres
  - Show storage used and total duration
  - Track total play count across library
  - Colorful stat cards with icons (orange, blue, purple, pink, green, indigo, red)
  - Grid layout with responsive cards
  - Real-time updates when library changes
  - Loading and error states
- **LibraryStats**: Database statistics model
  - Counts for songs, albums, artists, genres
  - Total file size with formatted display (GB/MB)
  - Total duration with formatted display (hours/minutes)
  - Total play count aggregation
  - `getLibraryStats()` method in DatabaseManager

### Changed
- Home view now displays statistics instead of placeholder
- Removed search field from sidebar for cleaner design
- Removed top navigation bar from home view for full-screen dashboard

### Fixed
- SQL syntax for counting distinct album/artist combinations using subquery
- Database statistics queries properly handle NULL and empty values

### Technical
- Added comprehensive logging to statistics loading
- ByteCountFormatter for disk usage display
- Duration formatting helper methods
- Error handling with user-friendly messages

## [0.0.2] - 2025-12-04

### Added - Library Customization & Organization
- **Genres View**: Browse music by genre
  - Grid layout with genre cards
  - Purple-pink gradient backgrounds with guitar icons
  - Track count display for each genre
  - Database query with GROUP BY genre
  - Integrated into customizable library categories
- **Library Category Customization**: Edit button in Library section header
  - Inline checkbox editing mode (no popup)
  - Toggle visibility for Recently Added, Artists, Albums, Songs, Genres
  - Settings persist using @AppStorage (UserDefaults)
  - Edit/Done button with hover state
  - All categories visible by default
- **Playlists Section Collapse**: Minimize playlists in sidebar
  - Chevron icon appears on hover over Playlists header
  - Click to collapse/expand playlist items
  - Smooth animation (0.2s ease-in-out)
  - State persists across app launches
  - Helps reduce sidebar clutter

### Changed
- Library section now fully customizable with 5 category options
- SectionHeader component enhanced with edit and collapse functionality
- Playlists section can be collapsed to save sidebar space

### Changed - Sidebar UI/UX Refinements
- Sidebar navigation items now use white text/icons with orange for selected state
- Section headers (Library, Playlists) reduced to 10pt font size with sentence case
- "Recently Added" renamed to "Recent" for brevity
- Edit mode checkboxes match regular sidebar item dimensions and spacing
- Unchecked items in edit mode appear greyed out (40% opacity)
- Edit and collapse buttons stay visible when hovering over them
- Orange accent color for selected items and checked states

### Fixed
- Library Edit button now properly interactive with correct hover behavior
- Playlists collapse button stays visible and clickable during hover
- Section header buttons maintain visibility when cursor moves to them

### Technical
- Added `getAllGenres()` to DatabaseManager with SQL GROUP BY
- LibraryCheckboxItem component for inline editing
- Enhanced SectionHeader with dual button support (edit + collapse)
- @AppStorage for showRecentlyAdded, showArtists, showAlbums, showSongs, showGenres, playlistsCollapsed
- GenresView follows same pattern as ArtistsView/AlbumsView with grid layout
- Button hover handlers keep state active for interactive elements
- Consistent 10px horizontal, 6px vertical padding across all sidebar items

## [0.0.1] - 2025-12-04

### Added - Initial Release
- musiQ - A modern, high-fidelity music player for macOS
- Modern macOS design with liquid glass UI
- Support for high-quality audio formats (FLAC, DSD, Opus, etc.)
- BASS audio engine for professional playback
- Complete library management system
- Inbox system for organizing music imports
- Database-driven library with GRDB.swift
- Comprehensive settings and initial setup flow

### Core Components
- Audio Engine: BASS-powered playback with real-time controls
- Database Manager: SQLite-based music library
- Library Importer: Batch metadata extraction and import
- Inbox Manager: Temporary storage for new music
- Settings Manager: User preferences and library configuration

### Library Views
- Songs: Complete track listing with metadata
- Recently Added: Chronological import history
- Artists: Grid view of all artists with track counts
- Albums: Grid view of all albums with artwork placeholders
- Inbox: Drag-and-drop music import workflow

### UI Features
- Resizable liquid glass sidebar
- Top navigation bar with search
- Bottom playback control bar
- Real-time progress tracking
- Volume control with slider
- Play/pause, skip controls

## [Archived Versions]

## [0.2.0] - 2025-12-04

### Added - Settings System
- **SettingsManager**: Persistent settings storage with UserDefaults
  - Library location configuration
  - Music location configuration
  - Music management mode (copy vs read from location)
  - First-launch setup flag
  - Library structure auto-creation (Music/Artwork/Database/Playlists folders)
- **InitialSetupView**: 4-step first-launch wizard
  - Step 1: Library location selection with folder picker
  - Step 2: Music location selection
  - Step 3: Music management mode (copy to library or read from location)
  - Step 4: Settings confirmation and review
  - Dark themed UI with liquid glass aesthetics
  - Progress tracking and validation
  - Back/Continue navigation
- **SettingsView**: Comprehensive settings interface
  - General tab: Application and appearance settings
  - Library tab: Library/music location management, import settings
  - Playback tab: Audio output, crossfade, DSP effects configuration
  - Advanced tab: Database management, performance tuning, reset options
  - Tabbed sidebar navigation
  - Apply/Reset buttons for unsaved changes
  - NSOpenPanel integration for folder selection
- **Settings Button**: Added to sidebar bottom (replaces user profile)
- **App Menu Integration**: Settings command in musiQ menu (⌘,)
- **Database Path Integration**: DatabaseManager now uses SettingsManager for database location
- **Settings Documentation**: Complete documentation in SETTINGS_DOCUMENTATION.md

### Changed
- Sidebar bottom section: Replaced user profile with settings button
- Database initialization: Now respects user-configured library location
- App launch flow: Shows initial setup wizard if not configured
- Settings accessible via three methods: app menu, sidebar, keyboard shortcut

### Technical
- Added Combine framework import to SettingsManager for ObservableObject
- NotificationCenter integration for settings sheet presentation
- Custom button styles: PrimaryButtonStyle, SecondaryButtonStyle, DangerButtonStyle
- UserDefaults persistence for all settings
- Automatic library folder structure creation
- Fallback to Application Support if library location not set

## [0.1.0] - 2025-12-04

### Added - Core Engine Implementation
- **AudioEngine**: BASS library integration with Swift wrapper
  - Multi-format support (FLAC, DSD, OGG, OPUS, MP3, WAV, AIFF)
  - Playback control (play, pause, resume, stop, seek)
  - Volume control with real-time adjustments
  - Position tracking with 100ms update timer
  - DSP plugin support preparation
- **DatabaseManager**: SQLite database via GRDB.swift
  - Type-safe query interface
  - Automatic migration system
  - Full schema: tracks, albums, artists, playlists, playlistTracks
  - Optimized indexes for artist, album, genre, dateAdded
  - Batch import with progress tracking
  - Full-text search across title, artist, album
- **LibraryViewController**: AppKit NSTableView for high-performance library
  - Handles 50k+ tracks without performance degradation
  - 10 sortable columns: title, artist, album, duration, genre, year, bitrate, format, plays, rating
  - Double-click to play functionality
  - Multi-selection support
  - Real-time search filtering
  - Column reordering and resizing
  - Alternating row colors
- **PlayerView**: SwiftUI-based player controls
  - Play/pause/previous/next controls
  - Interactive progress bar with seek
  - Volume slider with visual feedback
  - Track metadata display (title, artist)
  - Album artwork placeholder
  - Time display (current/duration)
- **HybridMainView**: AppKit + SwiftUI integration layer
  - NSViewControllerRepresentable wrapper for LibraryViewController
  - Tab switching (Library/Albums/Artists/Playlists)
  - Search bar with live filtering
  - Segmented control for view switching
  - AppCoordinator for cross-component communication

### Architecture
- Hybrid UI: AppKit for data-heavy views, SwiftUI for chrome
- Three-tier architecture: UI → Business Logic → Storage
- Singleton pattern for AudioEngine and DatabaseManager
- Combine framework for reactive updates
- Observer pattern for database change notifications

### Documentation
- `ENGINE_SETUP.md`: Complete setup and integration guide
- `DEPENDENCIES.md`: Dependency installation instructions
- BASS bridging header with format-specific imports
- Inline code documentation for all major components

## [0.0.12] - 2025-12-04

### Removed
- Visual divider between playback controls and album artwork

## [0.0.11] - 2025-12-04

### Added
- Complete liquid glass floating playback control bar (Apple Music Tahoe style)
- Extended blur halo effect on playback bar
- Interactive progress bar overlay with hover states and time labels
- Volume slider with expand-on-hover animation
- Track quality badge (Hi-Res/HQ)
- Tap gesture on album art for mini player expansion

### Changed
- Reorganized playback bar layout: Controls | Artwork + Metadata | Quality + Utilities
- Playback controls made more compact (smaller icons and spacing)
- Bar adapts responsively to window width (850px - 1400px max)
- Controls hide progressively at smaller widths (Quality > More > Lyrics > Queue)
- Pill shape with 24px corner radius
- Improved shadow and glass material effects
- Progress bar now overlays at bottom edge with drag gesture support

### Fixed
- Playback bar now properly floats above content with correct positioning
- Bar scales correctly when resizing window or toggling sidebar
- Material blur extends beyond bounds for authentic liquid glass effect

## [0.0.10] - 2025-12-04

### Added
- Liquid glass background extension effect on sidebar
- Extended blur/vibrancy halo around sidebar edges

### Changed
- Window minimum width increased to 1000px
- Enhanced sidebar visual depth with extended material effect

## [0.0.9] - 2025-12-04

### Added
- Sidebar resize functionality with drag handle (180px - 320px range)
- Sidebar toggle button in top-right corner
- Menu command "Toggle Sidebar" with icon in View menu
- Keyboard shortcut ⌘⌃S for sidebar toggle
- Floating traffic lights when sidebar is hidden
- ScrollView for main content area (horizontal and vertical)
- GeometryReader for proper layout calculations

### Changed
- Content area now aligns to top-left corner
- Main content area resizes dynamically from right side only
- Sidebar maintains fixed width during window resize
- Window minimum size reduced to 800x600
- Content area is now scrollable when smaller than content size
- Removed right sidebar/panel

### Fixed
- Full-size content view with no top bar space
- Sidebar no longer hides under window edge
- Content area no longer overlaps with sidebar
- Proper window maximize behavior

## [0.0.8] - 2025-12-04

### Added
- Fully functional traffic lights (close, minimize, zoom)
- NSApplication integration for window controls
- Button actions for all three traffic light buttons

### Changed
- Traffic lights now use Button with proper actions
- Updated TrafficLightButton to accept action closure
- Improved button interaction with .buttonStyle(.plain)

### Fixed
- Traffic lights now properly control the window
- Hidden default macOS titlebar to prevent duplication
- Window controls only appear in custom sidebar

## [0.0.5] - 2025-12-04

### Added
- Resizable sidebar with drag handle (180px - 320px range)
- Rounded bottom-left corner for floating card effect
- Window controls spacing at top of sidebar
- Subtle shadow on right edge for depth
- Liquid glass border highlighting on rounded corner
- Interactive resize handle with hover cursor feedback
- Visual feedback during drag (thicker divider)

### Changed
- Enhanced user profile section with better spacing
- Improved sidebar layout to match Apple Music's floating design

## [0.0.4] - 2025-12-04

### Changed
- Proper Liquid Glass sidebar implementation (macOS Sequoia style)
- Removed animated mesh gradients (not part of true liquid glass)
- Implemented pure ultra-thin material for maximum wallpaper transparency
- Simplified to system vibrancy materials only
- Removed excessive overlays, gradients, and shadows
- Clean, minimal look that lets wallpaper colors bleed through
- Proper hover states with subtle control backgrounds
- Simplified playlist icons without extra effects

## [0.0.3] - 2025-12-04

### Added
- Animated mesh gradient background for sidebar
- Enhanced search box with ultra-thin material
- Gradient overlays and shadow effects for depth
- Hover effects for interactive elements
- Edge highlights and borders for glass definition
- User profile section with gradient avatar

### Changed
- Improved navigation buttons with glass material when selected
- Enhanced playlist icons with gradients and glows

## [0.0.2] - 2025-12-04

### Added
- Apple Music-style interface design
- Complete navigation items (Home, New, Radio)
- Library section (Recently Added, Artists, Albums, Songs)
- Playlists section with colorful playlist icons
- Songs table view with sortable headers
- Continue Playing panel on right side
- Bottom playback bar matching Apple Music design

### Changed
- Updated sidebar to match Apple Music design with search box
- Redesigned main content area with table layout
- Adjusted spacing, fonts, and colors to match screenshot

### Removed
- Unused components and simplified structure

## [0.0.1] - 2025-12-04

### Added
- Initial Liquid Glass interface layout
- Three-section layout: Sidebar, Main Content, Right Panel
- Liquid Glass sidebar with navigation (Home, Inbox, Library)
- Main content area with top navigation and search bar
- Bottom playback bar with waveform seekbar and controls
- Right panel for lyrics, queue, and track info
- Empty states for all views

---

**Legend:**
- Added: New features
- Changed: Changes in existing functionality
- Deprecated: Soon-to-be removed features
- Removed: Removed features
- Fixed: Bug fixes
- Security: Vulnerability fixes
